// SecureLLM Bridge - Core Library
// Provides secure abstractions for LLM communication

pub mod error;
pub mod models;
pub mod request;
pub mod response;
pub mod audit;
pub mod rate_limit;

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

pub use error::{Error, Result};
pub use models::*;
pub use request::Request;
pub use response::{
    Choice, FinishReason, LogProbs, RateLimitInfo, Response, ResponseMetadata, 
    StreamChunk, StreamDelta, TokenUsage,
};

/// Core trait for LLM providers
/// 
/// All providers must implement this trait to be used with SecureLLM Bridge.
/// The trait enforces secure patterns and provides consistent interface.
#[async_trait]
pub trait LLMProvider: Send + Sync {
    /// Provider name (e.g., "openai", "anthropic", "deepseek", "ollama")
    fn name(&self) -> &str;
    
    /// Provider version/API version
    fn version(&self) -> &str;
    
    /// Validate configuration before use
    fn validate_config(&self) -> Result<()>;
    
    /// Send a request to the LLM provider
    /// 
    /// This method handles all provider-specific logic while maintaining
    /// security guarantees from the security layer.
    async fn send_request(&self, request: Request) -> Result<Response>;
    
    /// Check if the provider is available/healthy
    async fn health_check(&self) -> Result<ProviderHealth>;
    
    /// Get provider capabilities
    fn capabilities(&self) -> ProviderCapabilities;
    
    /// Get supported models
    async fn list_models(&self) -> Result<Vec<ModelInfo>>;
}

/// Provider health status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderHealth {
    pub status: HealthStatus,
    pub latency_ms: Option<u64>,
    pub message: Option<String>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum HealthStatus {
    Healthy,
    Degraded,
    Unhealthy,
    Unknown,
}

/// Provider capabilities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderCapabilities {
    pub streaming: bool,
    pub function_calling: bool,
    pub vision: bool,
    pub embeddings: bool,
    pub max_tokens: Option<u32>,
    pub max_context_window: Option<u32>,
    pub supports_system_prompts: bool,
}

/// Model information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfo {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub context_window: Option<u32>,
    pub max_output_tokens: Option<u32>,
    pub capabilities: Vec<String>,
    pub pricing: Option<ModelPricing>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelPricing {
    pub input_cost_per_1k: f64,
    pub output_cost_per_1k: f64,
    pub currency: String,
}

/// Message structure for LLM conversations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub role: MessageRole,
    pub content: MessageContent,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    System,
    User,
    Assistant,
    Function,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum MessageContent {
    Text(String),
    Parts(Vec<ContentPart>),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ContentPart {
    Text { text: String },
    Image { image_url: ImageUrl },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageUrl {
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

/// Configuration trait for providers
pub trait ProviderConfig: Send + Sync {
    fn provider_type(&self) -> &str;
    fn api_endpoint(&self) -> Option<&str>;
    fn validate(&self) -> Result<()>;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_message_serialization() {
        let msg = Message {
            role: MessageRole::User,
            content: MessageContent::Text("Hello".to_string()),
            name: None,
            metadata: None,
        };
        
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("\"role\":\"user\""));
    }
    
    #[test]
    fn test_health_status() {
        let health = ProviderHealth {
            status: HealthStatus::Healthy,
            latency_ms: Some(150),
            message: None,
            timestamp: chrono::Utc::now(),
        };
        
        assert_eq!(health.status, HealthStatus::Healthy);
    }
}
