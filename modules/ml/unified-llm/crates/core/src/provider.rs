//! Provider trait and types for LLM providers

use async_trait::async_trait;
use serde::{Deserialize, Serialize};

use crate::{ChatRequest, ChatResponse, Error, ModelInfo, Result};

/// Main trait for LLM providers (cloud and local)
#[async_trait]
pub trait LLMProvider: Send + Sync {
    /// Provider name (e.g., "deepseek", "openai", "llamacpp")
    fn name(&self) -> &str;

    /// Provider type (cloud or local)
    fn provider_type(&self) -> ProviderType;

    /// Check if provider is available and healthy
    async fn health_check(&self) -> Result<HealthStatus>;

    /// Send chat completion request
    async fn chat(&self, request: ChatRequest) -> Result<ChatResponse>;

    /// List available models
    async fn list_models(&self) -> Result<Vec<ModelInfo>>;

    /// Get cost estimate for request (if applicable)
    fn estimate_cost(&self, request: &ChatRequest) -> Option<f64> {
        None
    }

    /// Get current availability status
    async fn get_availability(&self) -> Result<ProviderAvailability>;
}

/// Type of provider
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ProviderType {
    /// Cloud-based provider (DeepSeek, OpenAI, Anthropic)
    Cloud,
    /// Local provider (llama.cpp, Ollama, vLLM)
    Local,
    /// Hybrid (can do both)
    Hybrid,
}

/// Health status of a provider
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthStatus {
    /// Provider is healthy and available
    pub healthy: bool,
    /// Optional status message
    pub message: Option<String>,
    /// Response time in milliseconds
    pub response_time_ms: Option<u64>,
    /// Last check timestamp
    pub checked_at: chrono::DateTime<chrono::Utc>,
}

impl HealthStatus {
    /// Create a healthy status
    pub fn healthy() -> Self {
        Self {
            healthy: true,
            message: None,
            response_time_ms: None,
            checked_at: chrono::Utc::now(),
        }
    }

    /// Create an unhealthy status
    pub fn unhealthy(message: impl Into<String>) -> Self {
        Self {
            healthy: false,
            message: Some(message.into()),
            response_time_ms: None,
            checked_at: chrono::Utc::now(),
        }
    }

    /// Set response time
    pub fn with_response_time(mut self, ms: u64) -> Self {
        self.response_time_ms = Some(ms);
        self
    }
}

/// Provider availability information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProviderAvailability {
    /// Provider is available for requests
    pub available: bool,
    /// Current load percentage (0.0 - 100.0)
    pub load_percent: f32,
    /// Available VRAM in GB (for local providers)
    pub vram_available_gb: Option<f32>,
    /// Estimated latency in milliseconds
    pub estimated_latency_ms: Option<u64>,
    /// Number of active requests
    pub active_requests: usize,
    /// Last updated timestamp
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

impl ProviderAvailability {
    /// Create a new availability status
    pub fn new(available: bool) -> Self {
        Self {
            available,
            load_percent: 0.0,
            vram_available_gb: None,
            estimated_latency_ms: None,
            active_requests: 0,
            updated_at: chrono::Utc::now(),
        }
    }

    /// Check if provider is under heavy load
    pub fn is_overloaded(&self) -> bool {
        self.load_percent > 80.0
    }

    /// Check if provider has sufficient VRAM (for local providers)
    pub fn has_sufficient_vram(&self, required_gb: f32) -> bool {
        self.vram_available_gb
            .map(|available| available >= required_gb)
            .unwrap_or(true) // Assume OK if VRAM not tracked
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_health_status() {
        let healthy = HealthStatus::healthy();
        assert!(healthy.healthy);

        let unhealthy = HealthStatus::unhealthy("Connection failed");
        assert!(!unhealthy.healthy);
        assert!(unhealthy.message.is_some());
    }

    #[test]
    fn test_provider_availability() {
        let avail = ProviderAvailability::new(true);
        assert!(avail.available);
        assert!(!avail.is_overloaded());

        let mut overloaded = avail.clone();
        overloaded.load_percent = 85.0;
        assert!(overloaded.is_overloaded());
    }

    #[test]
    fn test_vram_check() {
        let mut avail = ProviderAvailability::new(true);
        avail.vram_available_gb = Some(8.0);

        assert!(avail.has_sufficient_vram(4.0));
        assert!(!avail.has_sufficient_vram(10.0));
    }
}