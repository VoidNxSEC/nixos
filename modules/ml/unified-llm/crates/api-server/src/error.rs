use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use std::fmt;

/// Application-wide error type
#[derive(Debug)]
pub enum ApiError {
    /// Configuration error
    ConfigError(String),
    /// Database error
    DatabaseError(String),
    /// Provider error
    ProviderError(String),
    /// Rate limit exceeded
    RateLimitExceeded(String),
    /// Invalid request
    BadRequest(String),
    /// Not found
    NotFound(String),
    /// Internal server error
    InternalError(String),
    /// Circuit breaker open
    CircuitBreakerOpen(String),
    /// Timeout
    Timeout(String),
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ApiError::ConfigError(msg) => write!(f, "Configuration error: {}", msg),
            ApiError::DatabaseError(msg) => write!(f, "Database error: {}", msg),
            ApiError::ProviderError(msg) => write!(f, "Provider error: {}", msg),
            ApiError::RateLimitExceeded(msg) => write!(f, "Rate limit exceeded: {}", msg),
            ApiError::BadRequest(msg) => write!(f, "Bad request: {}", msg),
            ApiError::NotFound(msg) => write!(f, "Not found: {}", msg),
            ApiError::InternalError(msg) => write!(f, "Internal error: {}", msg),
            ApiError::CircuitBreakerOpen(msg) => write!(f, "Circuit breaker open: {}", msg),
            ApiError::Timeout(msg) => write!(f, "Timeout: {}", msg),
        }
    }
}

impl std::error::Error for ApiError {}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, error_type, message) = match self {
            ApiError::ConfigError(msg) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "config_error",
                msg,
            ),
            ApiError::DatabaseError(msg) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "database_error",
                msg,
            ),
            ApiError::ProviderError(msg) => (
                StatusCode::BAD_GATEWAY,
                "provider_error",
                msg,
            ),
            ApiError::RateLimitExceeded(msg) => (
                StatusCode::TOO_MANY_REQUESTS,
                "rate_limit_exceeded",
                msg,
            ),
            ApiError::BadRequest(msg) => (
                StatusCode::BAD_REQUEST,
                "bad_request",
                msg,
            ),
            ApiError::NotFound(msg) => (
                StatusCode::NOT_FOUND,
                "not_found",
                msg,
            ),
            ApiError::InternalError(msg) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "internal_error",
                msg,
            ),
            ApiError::CircuitBreakerOpen(msg) => (
                StatusCode::SERVICE_UNAVAILABLE,
                "circuit_breaker_open",
                msg,
            ),
            ApiError::Timeout(msg) => (
                StatusCode::GATEWAY_TIMEOUT,
                "timeout",
                msg,
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

// Conversion implementations
impl From<anyhow::Error> for ApiError {
    fn from(err: anyhow::Error) -> Self {
        ApiError::InternalError(err.to_string())
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(err: sqlx::Error) -> Self {
        ApiError::DatabaseError(err.to_string())
    }
}

impl From<redis::RedisError> for ApiError {
    fn from(err: redis::RedisError) -> Self {
        ApiError::InternalError(format!("Redis error: {}", err))
    }
}

impl From<reqwest::Error> for ApiError {
    fn from(err: reqwest::Error) -> Self {
        if err.is_timeout() {
            ApiError::Timeout(err.to_string())
        } else {
            ApiError::ProviderError(err.to_string())
        }
    }
}

pub type ApiResult<T> = Result<T, ApiError>;