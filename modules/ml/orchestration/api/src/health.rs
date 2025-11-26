/// Health check module
///
/// Provides health status for the API and backend services

use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use serde::{Deserialize, Serialize};
use tracing::{info, warn};

use crate::backends::llamacpp::LlamaCppBackend;
use crate::AppState;

/// Health check response
#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub backends: BackendHealthStatus,
}

/// Backend health status
#[derive(Debug, Serialize, Deserialize)]
pub struct BackendHealthStatus {
    pub llamacpp: BackendStatus,
}

/// Individual backend status
#[derive(Debug, Serialize, Deserialize)]
pub struct BackendStatus {
    pub available: bool,
    pub ready: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}

/// Health check handler
pub async fn health_check_handler(
    State(_state): State<AppState>,
) -> impl IntoResponse {
    info!("Health check requested");

    // Check llamacpp backend
    let llamacpp_status = check_llamacpp_backend().await;

    let overall_status = if llamacpp_status.available && llamacpp_status.ready {
        "healthy"
    } else if llamacpp_status.available {
        "degraded"
    } else {
        "unhealthy"
    };

    let response = HealthResponse {
        status: overall_status.to_string(),
        backends: BackendHealthStatus {
            llamacpp: llamacpp_status,
        },
    };

    Json(response)
}

/// Check llamacpp backend health
async fn check_llamacpp_backend() -> BackendStatus {
    match LlamaCppBackend::with_defaults() {
        Ok(backend) => {
            // Check if backend is ready
            let ready = backend.is_ready().await;

            if ready {
                BackendStatus {
                    available: true,
                    ready: true,
                    details: Some("llama-server is running and ready".to_string()),
                }
            } else {
                // Try to get more details
                match backend.health_check().await {
                    Ok(health) => BackendStatus {
                        available: true,
                        ready: false,
                        details: Some(format!(
                            "llama-server available but not ready (status: {})",
                            health.status
                        )),
                    },
                    Err(e) => BackendStatus {
                        available: false,
                        ready: false,
                        details: Some(format!("Connection failed: {}", e)),
                    },
                }
            }
        }
        Err(e) => {
            warn!("Failed to create llamacpp backend: {}", e);
            BackendStatus {
                available: false,
                ready: false,
                details: Some(format!("Backend initialization failed: {}", e)),
            }
        }
    }
}

/// Detailed backend info handler
pub async fn backend_info_handler(
    State(_state): State<AppState>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    info!("Backend info requested");

    let backend = match LlamaCppBackend::with_defaults() {
        Ok(b) => b,
        Err(e) => {
            warn!("Failed to create llamacpp backend: {}", e);
            return Err((
                StatusCode::SERVICE_UNAVAILABLE,
                Json(serde_json::json!({
                    "error": {
                        "message": "Backend not available",
                        "type": "service_unavailable"
                    }
                })),
            ));
        }
    };

    // Get model info
    match backend.get_model_info().await {
        Ok(info) => Ok(Json(info)),
        Err(e) => {
            warn!("Failed to get backend info: {}", e);
            Err((
                StatusCode::BAD_GATEWAY,
                Json(serde_json::json!({
                    "error": {
                        "message": "Failed to retrieve backend info",
                        "type": "backend_error"
                    }
                })),
            ))
        }
    }
}
