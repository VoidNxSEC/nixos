use axum::{extract::State, http::StatusCode, Json};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{debug, error};

use crate::{error::ApiResult, state::AppState};

/// Health check response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: String,
    pub uptime_seconds: u64,
    pub providers: Vec<ProviderHealth>,
    pub database: ComponentHealth,
    pub redis: ComponentHealth,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderHealth {
    pub name: String,
    pub status: String,
    pub circuit_breaker: String,
    pub latency_ms: Option<u64>,
    pub last_error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComponentHealth {
    pub status: String,
    pub latency_ms: Option<u64>,
    pub error: Option<String>,
}

/// GET /api/health - Comprehensive health check
/// 
/// Returns detailed health information about all components
pub async fn health_check(
    State(state): State<Arc<AppState>>,
) -> ApiResult<Json<HealthResponse>> {
    debug!("Health check requested");

    // Check database health
    let db_health = check_database_health(&state).await;
    
    // Check Redis health
    let redis_health = check_redis_health(&state).await;
    
    // Check all providers
    let provider_healths = check_providers_health(&state).await;

    // Determine overall status
    let overall_status = if db_health.status == "healthy" 
        && redis_health.status == "healthy"
        && provider_healths.iter().any(|p| p.status == "healthy") {
        "healthy"
    } else if provider_healths.iter().all(|p| p.status == "unhealthy") {
        "unhealthy"
    } else {
        "degraded"
    };

    // Calculate uptime (TODO: track actual start time)
    let uptime = 0;

    Ok(Json(HealthResponse {
        status: overall_status.to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        uptime_seconds: uptime,
        providers: provider_healths,
        database: db_health,
        redis: redis_health,
    }))
}

/// GET /api/ready - Readiness probe for Kubernetes
/// 
/// Returns 200 if ready, 503 if not ready
pub async fn readiness_check(
    State(state): State<Arc<AppState>>,
) -> ApiResult<StatusCode> {
    debug!("Readiness check requested");

    // Check critical components
    let db_health = check_database_health(&state).await;
    
    if db_health.status != "healthy" {
        return Ok(StatusCode::SERVICE_UNAVAILABLE);
    }

    // Check if at least one provider is healthy
    let provider_healths = check_providers_health(&state).await;
    let has_healthy_provider = provider_healths.iter().any(|p| p.status == "healthy");

    if !has_healthy_provider {
        return Ok(StatusCode::SERVICE_UNAVAILABLE);
    }

    Ok(StatusCode::OK)
}

/// Check database health
async fn check_database_health(state: &AppState) -> ComponentHealth {
    let start = std::time::Instant::now();
    
    match sqlx::query("SELECT 1").execute(&state.db_pool).await {
        Ok(_) => ComponentHealth {
            status: "healthy".to_string(),
            latency_ms: Some(start.elapsed().as_millis() as u64),
            error: None,
        },
        Err(e) => {
            error!("Database health check failed: {}", e);
            ComponentHealth {
                status: "unhealthy".to_string(),
                latency_ms: Some(start.elapsed().as_millis() as u64),
                error: Some(e.to_string()),
            }
        }
    }
}

/// Check Redis health
async fn check_redis_health(state: &AppState) -> ComponentHealth {
    let start = std::time::Instant::now();
    
    match state.redis_client.get_connection() {
        Ok(mut conn) => {
            match redis::cmd("PING").query::<String>(&mut conn) {
                Ok(_) => ComponentHealth {
                    status: "healthy".to_string(),
                    latency_ms: Some(start.elapsed().as_millis() as u64),
                    error: None,
                },
                Err(e) => {
                    error!("Redis ping failed: {}", e);
                    ComponentHealth {
                        status: "unhealthy".to_string(),
                        latency_ms: Some(start.elapsed().as_millis() as u64),
                        error: Some(e.to_string()),
                    }
                }
            }
        }
        Err(e) => {
            error!("Redis connection failed: {}", e);
            ComponentHealth {
                status: "unhealthy".to_string(),
                latency_ms: Some(start.elapsed().as_millis() as u64),
                error: Some(e.to_string()),
            }
        }
    }
}

/// Check health of all providers
async fn check_providers_health(state: &AppState) -> Vec<ProviderHealth> {
    let provider_names = state.provider_manager.list_providers().await;
    
    let mut healths = Vec::new();
    
    for name in provider_names {
        // TODO: Implement actual provider health checks
        healths.push(ProviderHealth {
            name: name.clone(),
            status: "healthy".to_string(),
            circuit_breaker: "closed".to_string(),
            latency_ms: Some(100),
            last_error: None,
        });
    }
    
    // If no providers, add placeholder
    if healths.is_empty() {
        healths.push(ProviderHealth {
            name: "none".to_string(),
            status: "unhealthy".to_string(),
            circuit_breaker: "n/a".to_string(),
            latency_ms: None,
            last_error: Some("No providers configured".to_string()),
        });
    }
    
    healths
}