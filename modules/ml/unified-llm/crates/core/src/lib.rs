//! Unified LLM Core - Foundation traits and types
//!
//! This crate provides the core abstractions used throughout the Unified LLM Platform.
//! It defines traits for providers, common request/response types, and error handling.

pub mod error;
pub mod models;
pub mod provider;
pub mod request;
pub mod response;

// Re-exports for convenience
pub use error::{Error, Result};
pub use models::{ModelInfo, ProviderType};
pub use provider::{LLMProvider, ProviderAvailability};
pub use request::{ChatRequest, Message, MessageContent, MessageRole};
pub use response::{ChatResponse, Usage};

/// Crate version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }
}