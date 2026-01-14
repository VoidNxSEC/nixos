/// Error types for ML Offload API
///
/// Structured errors with clear messages for clients

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Model not found: {0}")]
    ModelNotFound(String),

    #[error("Backend not available: {backend}")]
    BackendUnavailable { backend: String },

    #[error("Insufficient VRAM: need {need_gb:.2}GB, available {available_gb:.2}GB")]
    InsufficientVram { need_gb: f64, available_gb: f64 },

    #[error("Model already loaded: {0}")]
    ModelAlreadyLoaded(String),

    #[error("No model currently loaded")]
    NoModelLoaded,

    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    #[error("Backend error: {0}")]
    BackendError(String),

    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),

   #[error("VRAM monitoring error: {0}")]
    VramMonitoringError(String),

    #[error("Internal server error: {0}")]
    InternalError(String),
}

impl From<anyhow::Error> for ApiError {
    fn from(err: anyhow::Error) -> Self {
        ApiError::InternalError(err.to_string())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, error_type, message) = match self {
            ApiError::ModelNotFound(_) => (
                StatusCode::NOT_FOUND,
                "model_not_found",
                self.to_string(),
            ),
            ApiError::BackendUnavailable { .. } => (
                StatusCode::SERVICE_UNAVAILABLE,
                "backend_unavailable",
                self.to_string(),
            ),
            ApiError::InsufficientVram { .. } => (
                StatusCode::INSUFFICIENT_STORAGE,
                "insufficient_vram",
                self.to_string(),
            ),
            ApiError::ModelAlreadyLoaded(_) => (
                StatusCode::CONFLICT,
                "model_already_loaded",
                self.to_string(),
            ),
            ApiError::NoModelLoaded => (
                StatusCode::BAD_REQUEST,
                "no_model_loaded",
                self.to_string(),
            ),
            ApiError::InvalidRequest(_) => (
                StatusCode::BAD_REQUEST,
                "invalid_request",
                self.to_string(),
            ),
            ApiError::BackendError(_) => (
                StatusCode::BAD_GATEWAY,
                "backend_error",
                self.to_string(),
            ),
            ApiError::DatabaseError(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "database_error",
                "Database operation failed".to_string(),
            ),
            ApiError::VramMonitoringError(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "vram_monitoring_error",
                self.to_string(),
            ),
            ApiError::InternalError(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "internal_error",
                "An internal error occurred".to_string(),
            ),
        };

        let body = Json(json!({
            "error": {
                "type": error_type,
                "message": message,
            }
        }));

        (status, body).into_response()
    }
}

/// Result type alias for API operations
pub type ApiResult<T> = Result<T, ApiError>;
