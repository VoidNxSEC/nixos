/// llama.cpp backend driver
///
/// Provides HTTP client interface to llama-server running at 127.0.0.1:8080
/// Implements OpenAI-compatible API proxy and model management

use anyhow::{Context, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;

/// llama.cpp backend configuration
#[derive(Debug, Clone)]
pub struct LlamaCppConfig {
    pub base_url: String,
    pub timeout_secs: u64,
}

impl Default for LlamaCppConfig {
    fn default() -> Self {
        Self {
            base_url: "http://127.0.0.1:8080".to_string(),
            timeout_secs: 300, // 5 minutes for large model loads
        }
    }
}

/// llama.cpp backend HTTP client
pub struct LlamaCppBackend {
    client: Client,
    config: LlamaCppConfig,
}

/// Health check response from llama-server
#[derive(Debug, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    #[serde(default)]
    pub slots_idle: Option<u32>,
    #[serde(default)]
    pub slots_processing: Option<u32>,
}

/// Model metadata from llama-server
#[derive(Debug, Deserialize, Serialize)]
pub struct ModelInfo {
    #[serde(default)]
    pub model: String,
    #[serde(default)]
    pub n_ctx: u32,
    #[serde(default)]
    pub n_gpu_layers: u32,
    #[serde(default)]
    pub n_threads: u32,
}

/// Slot information for concurrent requests
#[derive(Debug, Deserialize)]
pub struct SlotInfo {
    pub id: u32,
    pub state: String,
    #[serde(default)]
    pub task_id: Option<u32>,
}

/// Slots response from llama-server
#[derive(Debug, Deserialize)]
struct SlotsResponse {
    #[serde(default)]
    slots: Vec<SlotInfo>,
}

impl LlamaCppBackend {
    /// Create new llama.cpp backend client
    pub fn new(config: LlamaCppConfig) -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.timeout_secs))
            .build()
            .context("Failed to build HTTP client")?;

        Ok(Self { client, config })
    }

    /// Create backend with default configuration
    pub fn with_defaults() -> Result<Self> {
        Self::new(LlamaCppConfig::default())
    }

    /// Health check - verify llama-server is running and responsive
    pub async fn health_check(&self) -> Result<HealthResponse> {
        let url = format!("{}/health", self.config.base_url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to connect to llama-server")?;

        if !response.status().is_success() {
            anyhow::bail!(
                "Health check failed with status: {}",
                response.status()
            );
        }

        let health: HealthResponse = response
            .json()
            .await
            .context("Failed to parse health response")?;

        Ok(health)
    }

    /// Get current model information
    pub async fn get_model_info(&self) -> Result<ModelInfo> {
        let url = format!("{}/props", self.config.base_url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to get model info")?;

        if !response.status().is_success() {
            anyhow::bail!(
                "Get model info failed with status: {}",
                response.status()
            );
        }

        let info: ModelInfo = response
            .json()
            .await
            .context("Failed to parse model info")?;

        Ok(info)
    }

    /// Get slot information for concurrent request management
    pub async fn get_slots(&self) -> Result<Vec<SlotInfo>> {
        let url = format!("{}/slots", self.config.base_url);

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .context("Failed to get slots info")?;

        if !response.status().is_success() {
            anyhow::bail!("Get slots failed with status: {}", response.status());
        }

        let slots_response: SlotsResponse = response
            .json()
            .await
            .context("Failed to parse slots response")?;

        Ok(slots_response.slots)
    }

    /// Proxy chat completion request to llama-server
    ///
    /// Forwards OpenAI-compatible chat completion to llama-server
    /// Returns raw response for client to handle
    pub async fn proxy_chat_completion(
        &self,
        request_body: serde_json::Value,
    ) -> Result<reqwest::Response> {
        let url = format!("{}/v1/chat/completions", self.config.base_url);

        let response = self
            .client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .context("Failed to send chat completion request")?;

        Ok(response)
    }

    /// Proxy embeddings request to llama-server
    ///
    /// Forwards OpenAI-compatible embeddings to llama-server
    /// Returns raw response for client to handle
    pub async fn proxy_embeddings(
        &self,
        request_body: serde_json::Value,
    ) -> Result<reqwest::Response> {
        let url = format!("{}/v1/embeddings", self.config.base_url);

        let response = self
            .client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .context("Failed to send embeddings request")?;

        Ok(response)
    }

    /// Check if llama-server is ready for inference
    pub async fn is_ready(&self) -> bool {
        match self.health_check().await {
            Ok(health) => health.status == "ok" || health.status == "ready",
            Err(_) => false,
        }
    }

    /// Get base URL for this backend
    pub fn base_url(&self) -> &str {
        &self.config.base_url
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_backend_creation() {
        let backend = LlamaCppBackend::with_defaults();
        assert!(backend.is_ok());
    }

    #[tokio::test]
    async fn test_health_check_url() {
        let backend = LlamaCppBackend::with_defaults().unwrap();
        assert_eq!(backend.base_url(), "http://127.0.0.1:8080");
    }
}
