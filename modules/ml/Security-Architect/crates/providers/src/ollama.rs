use crate::{ProviderError, Result};
use async_trait::async_trait;
use unified_llm_core::{
    Choice, ContentPart, Error, HealthStatus, LLMProvider, Message, MessageContent,
    MessageRole, ModelInfo, ModelPricing, ProviderCapabilities, ProviderHealth, Request, 
    Response, FinishReason, TokenUsage, ResponseMetadata,
};
use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};

const DEFAULT_ENDPOINT: &str = "http://127.0.0.1:8080";
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(120); // Local inference can be slower

/// Ollama/llama.cpp provider configuration
/// Connects to local llama.cpp server (configured in /etc/nixos/modules/ml/llama.nix)
#[derive(Debug, Clone)]
pub struct OllamaConfig {
    /// API endpoint (defaults to http://127.0.0.1:8080)
    pub endpoint: String,
    
    /// Request timeout (local inference can take longer)
    pub timeout: Duration,
    
    /// Enable request/response logging
    pub logging_enabled: bool,
    
    /// Model name/path (optional, can be set in request)
    pub default_model: Option<String>,
}

impl OllamaConfig {
    pub fn new() -> Self {
        Self {
            endpoint: DEFAULT_ENDPOINT.to_string(),
            timeout: DEFAULT_TIMEOUT,
            logging_enabled: false,
            default_model: None,
        }
    }
    
    pub fn with_endpoint(mut self, endpoint: impl Into<String>) -> Self {
        self.endpoint = endpoint.into();
        self
    }
    
    pub fn with_timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }
    
    pub fn with_logging(mut self, enabled: bool) -> Self {
        self.logging_enabled = enabled;
        self
    }
    
    pub fn with_default_model(mut self, model: impl Into<String>) -> Self {
        self.default_model = Some(model.into());
        self
    }
}

impl Default for OllamaConfig {
    fn default() -> Self {
        Self::new()
    }
}

/// Ollama provider implementation (connects to llama.cpp server)
pub struct OllamaProvider {
    config: OllamaConfig,
    client: reqwest::Client,
}

impl OllamaProvider {
    pub fn new(config: OllamaConfig) -> Result<Self> {
        let client = reqwest::Client::builder()
            .timeout(config.timeout)
            .build()
            .map_err(|e| ProviderError::Http(format!("Failed to create HTTP client: {}", e)))?;
        
        Ok(Self { config, client })
    }
    
    /// Convert SecureLLM request to llama.cpp API format
    /// llama.cpp uses OpenAI-compatible API
    fn convert_request(&self, request: &Request) -> Result<OllamaRequest> {
        let messages = request.messages.iter().map(|msg| {
            OllamaMessage {
                role: match msg.role {
                    MessageRole::System => "system".to_string(),
                    MessageRole::User => "user".to_string(),
                    MessageRole::Assistant => "assistant".to_string(),
                    MessageRole::Function => "user".to_string(), // Map function to user
                },
                content: match &msg.content {
                    MessageContent::Text(text) => text.clone(),
                    MessageContent::Parts(parts) => {
                        // llama.cpp primarily uses text, combine parts
                        parts.iter()
                            .filter_map(|part| {
                                if let ContentPart::Text { text } = part {
                                    Some(text.as_str())
                                } else {
                                    None
                                }
                            })
                            .collect::<Vec<_>>()
                            .join(" ")
                    }
                },
            }
        }).collect();
        
        // Use model from request or default
        let model = if !request.model.is_empty() {
            request.model.clone()
        } else if let Some(default) = &self.config.default_model {
            default.clone()
        } else {
            "local-model".to_string() // Fallback name
        };
        
        Ok(OllamaRequest {
            model,
            messages,
            max_tokens: request.parameters.max_tokens,
            temperature: request.parameters.temperature,
            top_p: request.parameters.top_p,
            stream: Some(request.parameters.stream),
            stop: request.parameters.stop.clone(),
        })
    }
    
    /// Convert llama.cpp API response to SecureLLM format
    fn convert_response(
        &self,
        request_id: uuid::Uuid,
        ollama_response: OllamaResponse,
        processing_time: Duration,
    ) -> Result<Response> {
        let choices = ollama_response.choices.into_iter().map(|choice| {
            Choice {
                index: choice.index,
                message: Message {
                    role: match choice.message.role.as_str() {
                        "assistant" => MessageRole::Assistant,
                        "user" => MessageRole::User,
                        "system" => MessageRole::System,
                        _ => MessageRole::Assistant,
                    },
                    content: MessageContent::Text(choice.message.content),
                    name: None,
                    metadata: None,
                },
                finish_reason: match choice.finish_reason.as_deref() {
                    Some("stop") => FinishReason::Stop,
                    Some("length") => FinishReason::Length,
                    _ => FinishReason::Unknown,
                },
                logprobs: None,
            }
        }).collect();
        
        let usage = TokenUsage {
            prompt_tokens: ollama_response.usage.prompt_tokens,
            completion_tokens: ollama_response.usage.completion_tokens,
            total_tokens: ollama_response.usage.total_tokens,
            estimated_cost: Some(0.0), // Local inference is free
        };
        
        let mut metadata = ResponseMetadata {
            created_at: chrono::Utc::now(),
            processing_time_ms: processing_time.as_millis() as u64,
            cached: false,
            rate_limit_info: None,
            extra: std::collections::HashMap::new(),
        };
        
        metadata.extra.insert(
            "ollama_id".to_string(),
            serde_json::Value::String(ollama_response.id.clone()),
        );
        
        metadata.extra.insert(
            "backend".to_string(),
            serde_json::Value::String("llama.cpp".to_string()),
        );
        
        Ok(Response {
            request_id,
            id: ollama_response.id,
            provider: "ollama".to_string(),
            model: ollama_response.model,
            choices,
            usage,
            metadata,
        })
    }
}

#[async_trait]
impl LLMProvider for OllamaProvider {
    fn name(&self) -> &str {
        "ollama"
    }
    
    fn version(&self) -> &str {
        "v1"
    }
    
    fn validate_config(&self) -> unified_llm_core::Result<()> {
        if self.config.endpoint.is_empty() {
            return Err(Error::Config("Ollama endpoint is empty".to_string()));
        }
        
        Ok(())
    }
    
    async fn send_request(&self, request: Request) -> unified_llm_core::Result<Response> {
        // Validate request
        request.validate()?;
        
        // Log request if enabled
        if self.config.logging_enabled {
            tracing::info!(
                request_id = %request.id,
                model = %request.model,
                "Sending request to Ollama/llama.cpp"
            );
        }
        
        // Convert to llama.cpp format
        let ollama_request = self.convert_request(&request)
            .map_err(|e| Error::Provider {
                provider: "ollama".to_string(),
                message: format!("Request conversion failed: {}", e),
            })?;
        
        // Build HTTP request (OpenAI-compatible endpoint)
        let url = format!("{}/v1/chat/completions", self.config.endpoint);
        let start = Instant::now();
        
        let req_builder = self.client
            .post(&url)
            .header("Content-Type", "application/json")
            .json(&ollama_request);
        
        // Send request
        let response = req_builder
            .send()
            .await
            .map_err(|e| Error::Network(format!("HTTP request failed: {}", e)))?;
        
        let status = response.status();
        let processing_time = start.elapsed();
        
        // Handle errors
        if !status.is_success() {
            let error_body = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            
            return Err(Error::Provider {
                provider: "ollama".to_string(),
                message: format!("API error ({}): {}", status, error_body),
            });
        }
        
        // Parse response
        let ollama_response: OllamaResponse = response
            .json()
            .await
            .map_err(|e| Error::Serialization(format!("Failed to parse response: {}", e)))?;
        
        // Convert to SecureLLM format
        let securellm_response = self.convert_response(
            request.id,
            ollama_response,
            processing_time,
        ).map_err(|e| Error::Provider {
            provider: "ollama".to_string(),
            message: format!("Response conversion failed: {}", e),
        })?;
        
        // Log response if enabled
        if self.config.logging_enabled {
            tracing::info!(
                request_id = %request.id,
                tokens = securellm_response.usage.total_tokens,
                duration_ms = processing_time.as_millis(),
                "Received response from Ollama/llama.cpp"
            );
        }
        
        Ok(securellm_response)
    }
    
    async fn health_check(&self) -> unified_llm_core::Result<ProviderHealth> {
        let start = Instant::now();
        
        // Try to access the health endpoint or models endpoint
        let url = format!("{}/health", self.config.endpoint);
        let response = self.client
            .get(&url)
            .send()
            .await;
        
        let latency = start.elapsed();
        
        let status = match response {
            Ok(resp) if resp.status().is_success() => HealthStatus::Healthy,
            Ok(resp) if resp.status().is_server_error() => HealthStatus::Degraded,
            _ => {
                // Fallback: try /v1/models endpoint
                let models_url = format!("{}/v1/models", self.config.endpoint);
                match self.client.get(&models_url).send().await {
                    Ok(resp) if resp.status().is_success() => HealthStatus::Healthy,
                    _ => HealthStatus::Unhealthy,
                }
            }
        };
        
        Ok(ProviderHealth {
            status,
            latency_ms: Some(latency.as_millis() as u64),
            message: None,
            timestamp: chrono::Utc::now(),
        })
    }
    
    fn capabilities(&self) -> ProviderCapabilities {
        ProviderCapabilities {
            streaming: true,
            function_calling: false, // llama.cpp basic support
            vision: false,           // Depends on model
            embeddings: true,
            max_tokens: None,        // Depends on model and context
            max_context_window: None, // Depends on model
            supports_system_prompts: true,
        }
    }
    
    async fn list_models(&self) -> unified_llm_core::Result<Vec<ModelInfo>> {
        // Try to fetch models from llama.cpp server
        let url = format!("{}/v1/models", self.config.endpoint);
        
        match self.client.get(&url).send().await {
            Ok(response) if response.status().is_success() => {
                // Try to parse response
                if let Ok(models_response) = response.json::<OllamaModelsResponse>().await {
                    Ok(models_response.data.into_iter().map(|m| {
                        ModelInfo {
                            id: m.id,
                            name: m.id.clone(),
                            description: Some(format!("Local model via llama.cpp: {}", m.id)),
                            context_window: None, // Would need to query model metadata
                            max_output_tokens: None,
                            capabilities: vec!["chat".to_string(), "local".to_string()],
                            pricing: Some(ModelPricing {
                                input_cost_per_1k: 0.0,
                                output_cost_per_1k: 0.0,
                                currency: "USD".to_string(),
                            }),
                        }
                    }).collect())
                } else {
                    // Fallback: return generic model info
                    Ok(vec![self.get_default_model_info()])
                }
            }
            _ => {
                // Return default model info if server is not responding
                Ok(vec![self.get_default_model_info()])
            }
        }
    }
}

impl OllamaProvider {
    fn get_default_model_info(&self) -> ModelInfo {
        ModelInfo {
            id: self.config.default_model.clone()
                .unwrap_or_else(|| "local-model".to_string()),
            name: "Local LLaMA Model".to_string(),
            description: Some("Local model running via llama.cpp server (see /etc/nixos/modules/ml/llama.nix)".to_string()),
            context_window: Some(4096), // Default from llama.nix config
            max_output_tokens: Some(4096),
            capabilities: vec!["chat".to_string(), "local".to_string(), "cuda".to_string()],
            pricing: Some(ModelPricing {
                input_cost_per_1k: 0.0,
                output_cost_per_1k: 0.0,
                currency: "USD".to_string(),
            }),
        }
    }
}

// llama.cpp API types (OpenAI-compatible)
#[derive(Debug, Serialize)]
struct OllamaRequest {
    model: String,
    messages: Vec<OllamaMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    max_tokens: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    top_p: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    stream: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    stop: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct OllamaMessage {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct OllamaResponse {
    id: String,
    model: String,
    choices: Vec<OllamaChoice>,
    usage: OllamaUsage,
}

#[derive(Debug, Deserialize)]
struct OllamaChoice {
    index: u32,
    message: OllamaMessage,
    #[serde(default)]
    finish_reason: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OllamaUsage {
    prompt_tokens: u32,
    completion_tokens: u32,
    total_tokens: u32,
}

#[derive(Debug, Deserialize)]
struct OllamaModelsResponse {
    data: Vec<OllamaModelData>,
}

#[derive(Debug, Deserialize)]
struct OllamaModelData {
    id: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_config_builder() {
        let config = OllamaConfig::new()
            .with_endpoint("http://localhost:8080")
            .with_timeout(Duration::from_secs(90))
            .with_logging(true)
            .with_default_model("llama-3-8b");
        
        assert_eq!(config.endpoint, "http://localhost:8080");
        assert_eq!(config.timeout, Duration::from_secs(90));
        assert!(config.logging_enabled);
        assert_eq!(config.default_model, Some("llama-3-8b".to_string()));
    }
    
    #[test]
    fn test_provider_capabilities() {
        let config = OllamaConfig::new();
        let provider = OllamaProvider::new(config).unwrap();
        
        let caps = provider.capabilities();
        assert!(caps.streaming);
        assert!(!caps.vision); // Local models typically don't have vision
        assert!(caps.embeddings);
        assert!(caps.supports_system_prompts);
    }
    
    #[tokio::test]
    async fn test_list_models() {
        let config = OllamaConfig::new().with_default_model("test-model");
        let provider = OllamaProvider::new(config).unwrap();
        
        let models = provider.list_models().await.unwrap();
        assert!(!models.is_empty());
        assert_eq!(models[0].pricing.as_ref().unwrap().input_cost_per_1k, 0.0);
    }
    
    #[test]
    fn test_default_endpoint() {
        let config = OllamaConfig::default();
        assert_eq!(config.endpoint, "http://127.0.0.1:8080");
    }
}
