use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::{net::SocketAddr, sync::Arc};
use tokio::sync::RwLock;
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};
use tracing::{info, warn};

mod api;
mod backends;
mod db;
mod models;
mod vram;

use db::Database;
use models::*;
use vram::VramMonitor;

/// Application state shared across handlers
#[derive(Clone)]
pub struct AppState {
    db: Arc<Database>,
    vram_monitor: Arc<RwLock<VramMonitor>>,
    config: Arc<Config>,
}

/// Configuration from environment variables
#[derive(Clone)]
pub struct Config {
    host: String,
    port: u16,
    data_dir: String,
    models_path: String,
    db_path: String,
    cors_enabled: bool,
}

impl Config {
    fn from_env() -> Self {
        Self {
            host: std::env::var("ML_OFFLOAD_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            port: std::env::var("ML_OFFLOAD_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(9000),
            data_dir: std::env::var("ML_OFFLOAD_DATA_DIR")
                .unwrap_or_else(|_| "/var/lib/ml-offload".to_string()),
            models_path: std::env::var("ML_OFFLOAD_MODELS_PATH")
                .unwrap_or_else(|_| "/var/lib/ml-models".to_string()),
            db_path: std::env::var("ML_OFFLOAD_DB_PATH")
                .unwrap_or_else(|_| "/var/lib/ml-offload/registry.db".to_string()),
            cors_enabled: std::env::var("ML_OFFLOAD_CORS_ENABLED")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(false),
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "ml_offload_api=info,axum=info,tower_http=info".into()),
        )
        .init();

    // Load configuration
    let config = Arc::new(Config::from_env());
    info!("Starting ML Offload Manager API");
    info!("Host: {}", config.host);
    info!("Port: {}", config.port);
    info!("Data directory: {}", config.data_dir);
    info!("Models path: {}", config.models_path);
    info!("Database: {}", config.db_path);

    // Initialize database
    let db = Arc::new(Database::new(&config.db_path).await?);
    info!("Database initialized");

    // Initialize VRAM monitor
    let vram_monitor = Arc::new(RwLock::new(VramMonitor::new()?));
    info!("VRAM monitor initialized");

    // Create application state
    let app_state = AppState {
        db,
        vram_monitor,
        config: config.clone(),
    };

    // Build router
    let app = Router::new()
        // Root endpoint
        .route("/", get(root_handler))
        // Health check
        .route("/health", get(health_handler))
        // Backends
        .route("/backends", get(list_backends_handler))
        // Models
        .route("/models", get(list_models_handler))
        .route("/models/:id", get(get_model_handler))
        .route("/models/scan", post(trigger_scan_handler))
        // Status
        .route("/status", get(status_handler))
        // VRAM
        .route("/vram", get(vram_handler))
        // Load/Unload/Switch
        .route("/load", post(load_model_handler))
        .route("/unload", post(unload_model_handler))
        .route("/switch", post(switch_model_handler))
        // Add state
        .with_state(app_state)
        // Add middleware
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::default().include_headers(false)),
        );

    // Add CORS if enabled
    let app = if config.cors_enabled {
        info!("CORS enabled");
        app.layer(CorsLayer::permissive())
    } else {
        app
    };

    // Start server
    let addr = SocketAddr::from((
        config.host.parse::<std::net::IpAddr>()?,
        config.port,
    ));
    info!("Listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

// =============================================================================
// Handlers
// =============================================================================

async fn root_handler() -> impl IntoResponse {
    Json(serde_json::json!({
        "name": "ML Offload Manager API",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
        "endpoints": {
            "backends": "/backends",
            "models": "/models",
            "status": "/status",
            "vram": "/vram",
        }
    }))
}

async fn health_handler(State(state): State<AppState>) -> impl IntoResponse {
    let services = serde_json::json!({
        "registry_db": std::path::Path::new(&state.config.db_path).exists(),
        "models_path": std::path::Path::new(&state.config.models_path).exists(),
        "vram_monitor": true,
    });

    let all_healthy = services
        .as_object()
        .map(|obj| obj.values().all(|v| v.as_bool().unwrap_or(false)))
        .unwrap_or(false);

    Json(serde_json::json!({
        "status": if all_healthy { "healthy" } else { "degraded" },
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "version": "0.1.0",
        "services": services,
    }))
}

async fn list_backends_handler() -> impl IntoResponse {
    // TODO: Implement backend detection
    let backends = vec![
        serde_json::json!({
            "name": "ollama",
            "status": "unknown",
            "type": "systemd",
            "host": "127.0.0.1",
            "port": 11434,
        }),
        serde_json::json!({
            "name": "llamacpp",
            "status": "unknown",
            "type": "systemd",
            "host": "127.0.0.1",
            "port": 8080,
        }),
    ];

    Json(backends)
}

#[derive(Deserialize)]
struct ModelsQuery {
    format: Option<String>,
    backend: Option<String>,
    limit: Option<i64>,
}

async fn list_models_handler(
    State(state): State<AppState>,
    Query(query): Query<ModelsQuery>,
) -> Result<impl IntoResponse, StatusCode> {
    match state
        .db
        .list_models(
            query.format.as_deref(),
            query.backend.as_deref(),
            query.limit.unwrap_or(100),
        )
        .await
    {
        Ok(models) => Ok(Json(models)),
        Err(e) => {
            warn!("Error listing models: {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

async fn get_model_handler(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<impl IntoResponse, StatusCode> {
    match state.db.get_model_by_id(id).await {
        Ok(Some(model)) => Ok(Json(model)),
        Ok(None) => Err(StatusCode::NOT_FOUND),
        Err(e) => {
            warn!("Error getting model {}: {}", id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

async fn trigger_scan_handler() -> impl IntoResponse {
    // Trigger systemd service
    tokio::spawn(async {
        if let Err(e) = tokio::process::Command::new("systemctl")
            .args(["start", "ml-registry-scan.service"])
            .output()
            .await
        {
            warn!("Failed to trigger scan: {}", e);
        }
    });

    Json(serde_json::json!({
        "status": "scan_triggered",
        "message": "Model registry scan started in background"
    }))
}

async fn status_handler(State(state): State<AppState>) -> impl IntoResponse {
    let vram_monitor = state.vram_monitor.read().await;
    let vram_state = vram_monitor.get_state();

    Json(serde_json::json!({
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "vram": {
            "total_gb": vram_state.total_gb,
            "used_gb": vram_state.used_gb,
            "free_gb": vram_state.free_gb,
            "utilization_percent": vram_state.utilization_percent,
        },
        "backends": [],
        "loaded_models": [],
        "pending_queue": [],
    }))
}

async fn vram_handler(State(state): State<AppState>) -> impl IntoResponse {
    let vram_monitor = state.vram_monitor.read().await;
    let vram_state = vram_monitor.get_state();

    Json(vram_state)
}

async fn load_model_handler(
    State(_state): State<AppState>,
    Json(_payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    // TODO: Implement in Phase 2
    (
        StatusCode::NOT_IMPLEMENTED,
        Json(serde_json::json!({
            "error": "Model loading not yet implemented"
        })),
    )
}

async fn unload_model_handler(
    State(_state): State<AppState>,
    Json(_payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    // TODO: Implement in Phase 2
    (
        StatusCode::NOT_IMPLEMENTED,
        Json(serde_json::json!({
            "error": "Model unloading not yet implemented"
        })),
    )
}

async fn switch_model_handler(
    State(_state): State<AppState>,
    Json(_payload): Json<serde_json::Value>,
) -> impl IntoResponse {
    // TODO: Implement in Phase 2
    (
        StatusCode::NOT_IMPLEMENTED,
        Json(serde_json::json!({
            "error": "Model switching not yet implemented"
        })),
    )
}
