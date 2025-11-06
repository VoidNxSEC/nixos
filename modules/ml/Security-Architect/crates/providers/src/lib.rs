use thiserror::Error;

pub mod deepseek;
pub mod openai;
pub mod anthropic;
pub mod ollama;

/// Provider-specific error types
#[derive(Error, Debug)]
pub enum ProviderError {
    #[error("HTTP error: {0}")]
    Http(String),
    
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("API error: {0}")]
    Api(String),
}

/// Result type for provider operations
pub type Result<T> = std::result::Result<T, ProviderError>;
