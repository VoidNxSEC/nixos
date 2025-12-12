// SecureLLM Bridge - Provider Implementations
// Secure adapters for different LLM providers

pub mod deepseek;
pub mod openai;
pub mod anthropic;
pub mod ollama;

use securellm_core::error::Error as CoreError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProviderError {
    #[error("HTTP error: {0}")]
    Http(String),
    
    #[error("API error from {provider}: {message}")]
    Api {
        provider: String,
        message: String,
        status_code: Option<u16>,
    },
    
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    #[error("Configuration error: {0}")]
    Configuration(String),
    
    #[error("Model not supported: {0}")]
    UnsupportedModel(String),
    
    #[error(transparent)]
    Core(#[from] CoreError),
    
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, ProviderError>;

/// Convert provider errors to core errors
impl From<ProviderError> for CoreError {
    fn from(err: ProviderError) -> Self {
        match err {
            ProviderError::Api { provider, message, .. } => {
                CoreError::Provider { provider, message }
            }
            ProviderError::Configuration(msg) => CoreError::Config(msg),
            ProviderError::UnsupportedModel(msg) => CoreError::ModelNotFound(msg),
            ProviderError::Http(msg) | ProviderError::Serialization(msg) => {
                CoreError::Network(msg)
            }
            ProviderError::Core(e) => e,
            ProviderError::Other(e) => CoreError::Other(e),
        }
    }
}
