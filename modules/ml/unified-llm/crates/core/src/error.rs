//! Error types for the Unified LLM Platform

use std::fmt;

/// Result type for Unified LLM operations
pub type Result<T> = std::result::Result<T, Error>;

/// Main error type for the Unified LLM Platform
#[derive(Debug, thiserror::Error)]
pub enum Error {
    /// Provider-specific error
    #[error("Provider error: {0}")]
    Provider(String),

    /// Network/HTTP error
    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    /// Serialization/deserialization error
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Configuration error
    #[error("Configuration error: {0}")]
    Configuration(String),

    /// Authentication error
    #[error("Authentication failed: {0}")]
    Authentication(String),

    /// Rate limit exceeded
    #[error("Rate limit exceeded: {0}")]
    RateLimit(String),

    /// Insufficient resources (e.g., VRAM)
    #[error("Insufficient resources: {0}")]
    InsufficientResources(String),

    /// Model not found
    #[error("Model not found: {0}")]
    ModelNotFound(String),

    /// Backend not available
    #[error("Backend not available: {0}")]
    BackendUnavailable(String),

    /// All providers failed
    #[error("All providers failed. Attempted: {attempted:?}, Original error: {original_error}")]
    AllProvidersFailed {
        attempted: Vec<String>,
        original_error: String,
    },

    /// Invalid request
    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    /// Timeout
    #[error("Operation timed out: {0}")]
    Timeout(String),

    /// Internal error
    #[error("Internal error: {0}")]
    Internal(String),

    /// Generic error with anyhow
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl Error {
    /// Create a provider error
    pub fn provider(msg: impl fmt::Display) -> Self {
        Error::Provider(msg.to_string())
    }

    /// Create a configuration error
    pub fn configuration(msg: impl fmt::Display) -> Self {
        Error::Configuration(msg.to_string())
    }

    /// Create an authentication error
    pub fn authentication(msg: impl fmt::Display) -> Self {
        Error::Authentication(msg.to_string())
    }

    /// Create a rate limit error
    pub fn rate_limit(msg: impl fmt::Display) -> Self {
        Error::RateLimit(msg.to_string())
    }

    /// Create an insufficient resources error
    pub fn insufficient_resources(msg: impl fmt::Display) -> Self {
        Error::InsufficientResources(msg.to_string())
    }

    /// Create a model not found error
    pub fn model_not_found(msg: impl fmt::Display) -> Self {
        Error::ModelNotFound(msg.to_string())
    }

    /// Create a backend unavailable error
    pub fn backend_unavailable(msg: impl fmt::Display) -> Self {
        Error::BackendUnavailable(msg.to_string())
    }

    /// Create an invalid request error
    pub fn invalid_request(msg: impl fmt::Display) -> Self {
        Error::InvalidRequest(msg.to_string())
    }

    /// Create a timeout error
    pub fn timeout(msg: impl fmt::Display) -> Self {
        Error::Timeout(msg.to_string())
    }

    /// Create an internal error
    pub fn internal(msg: impl fmt::Display) -> Self {
        Error::Internal(msg.to_string())
    }

    /// Check if error is retryable
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            Error::Network(_) | Error::RateLimit(_) | Error::Timeout(_) | Error::BackendUnavailable(_)
        )
    }

    /// Check if error is a resource issue
    pub fn is_resource_issue(&self) -> bool {
        matches!(self, Error::InsufficientResources(_))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_creation() {
        let err = Error::provider("test error");
        assert!(matches!(err, Error::Provider(_)));
    }

    #[test]
    fn test_retryable() {
        assert!(Error::rate_limit("test").is_retryable());
        assert!(!Error::authentication("test").is_retryable());
    }

    #[test]
    fn test_resource_issue() {
        assert!(Error::insufficient_resources("test").is_resource_issue());
        assert!(!Error::provider("test").is_resource_issue());
    }
}