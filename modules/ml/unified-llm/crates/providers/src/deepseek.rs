use crate::{ProviderError, Result};
use async_trait::async_trait;
use securellm_core::{
    Choice, ContentPart, Error, HealthStatus, LLMProvider, Message, MessageContent, 
    MessageRole, ModelInfo, ModelPricing, ProviderCapabilities, ProviderHealth, Request, 
    Response, FinishReason, TokenUsage, ResponseMetadata,
};
use secrecy::{ExposeSecret, SecretString};
use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};

const DEFAULT_ENDPOINT: &str = "https://api.deepseek.com/v1";
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(60);

/// DeepSeek provider configuration
#[derive(Debug, Clone)]
pub struct DeepSeekConfig {
    /// API key for authentication
    pub api_key: SecretString,
    
    /// API endpoint (defaults to https://api.deepseek.com/v1)
    pub endpoint: String,
    
    /// Request timeout
    pub timeout: Duration,
    
    /// Enable request/response logging
    pub logging_enabled: bool,
    
    /// Organization ID (optional)
    pub organization_id: Option<String>,
}

impl DeepSeekConfig {
    pub fn new(api_key: impl Into<String>) -> Self {
        Self {
            api_key: SecretString::new(api_key.into().into()),
            endpoint: DEFAULT_ENDPOINT.to_string(),
            timeout: DEFAULT_TIMEOUT,
            logging_enabled: false,
            organization_id: None,
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
    
    pub fn with_organization(mut self, org_id: impl Into<String>) -> Self {
        self.organization_id = Some(org_id.into());
        self
    }
}

/// DeepSeek provider implementation
pub struct DeepSeekProvider {
    config: DeepSeekConfig,
    client: reqwest::Client,
}

impl DeepSeekProvider {
    pub fn new(config: DeepSeekConfig) -> Result<Self> {
        let client = reqwest::Client::builder()
            .timeout(config.timeout)
            .build()
            .map_err(|e| ProviderError::Http(format!("Failed to create HTTP client: {}", e)))?;
        
        Ok(Self { config, client })
    }
    
    /// Convert SecureLLM request to DeepSeek API format
    fn convert_request(&self, request: &Request) -> Result<DeepSeekRequest> {
        let messages = request.messages.iter().map(|msg| {
            DeepSeekMessage {
                role: match msg.role {
                    MessageRole::System => "system".to_string(),
                    MessageRole::User => "user".to_string(),
                    MessageRole::Assistant => "assistant".to_string(),
                    MessageRole::Function => "function".to_string(),
                },
                content: match &msg.content {
                    MessageContent::Text(text) => text.clone(),
                    MessageContent::Parts(parts) => {
                        // DeepSeek primarily uses text, combine parts
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
        
        Ok(DeepSeekRequest {
            model: request.model.clone(),
            messages,
            max_tokens: request.parameters.max_tokens,
            temperature: request.parameters.temperature,
            top_p: request.parameters.top_p,
            stream: Some(request.parameters.stream),
            stop: request.parameters.stop.clone(),
        })
    }
    
    /// Convert DeepSeek API response to SecureLLM format
    fn convert_response(
        &self,
        request_id: uuid::Uuid,
        deepseek_response: DeepSeekResponse,
        processing_time: Duration,
    ) -> Result<Response> {
        let choices = deepseek_response.choices.into_iter().map(|choice| {
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
                finish_reason: match choice.finish_reason.as_str() {
                    "stop" => FinishReason::Stop,
                    "length" => FinishReason::Length,
                    "content_filter" => FinishReason::ContentFilter,
                    _ => FinishReason::Unknown,
                },
                logprobs: None,
            }
        }).collect();
        
        let usage = TokenUsage {
            prompt_tokens: deepseek_response.usage.prompt_tokens,
            completion_tokens: deepseek_response.usage.completion_tokens,
            total_tokens: deepseek_response.usage.total_tokens,
            estimated_cost: None, // Could calculate based on DeepSeek pricing
        };
        
        let mut metadata = ResponseMetadata {
            created_at: chrono::Utc::now(),
            processing_time_ms: processing_time.as_millis() as u64,
            cached: false,
            rate_limit_info: None,
            extra: std::collections::HashMap::new(),
        };
        
        metadata.extra.insert(
            "deepseek_id".to_string(),
            serde_json::Value::String(deepseek_response.id.clone()),
        );
        
        Ok(Response {
            request_id,
            id: deepseek_response.id,
            provider: "deepseek".to_string(),
            model: deepseek_response.model,
            choices,
            usage,
            metadata,
        })
    }
}

#[async_trait]
impl LLMProvider for DeepSeekProvider {
    fn name(&self) -> &str {
        "deepseek"
    }
    
    fn version(&self) -> &str {
        "v1"
    }
    
    fn validate_config(&self) -> securellm_core::Result<()> {
        if self.config.api_key.expose_secret().is_empty() {
            return Err(Error::Config("DeepSeek API key is empty".to_string()));
        }
        
        if self.config.endpoint.is_empty() {
            return Err(Error::Config("DeepSeek endpoint is empty".to_string()));
        }
        
        Ok(())
    }
    
    async fn send_request(&self, request: Request) -> securellm_core::Result<Response> {
        // Validate request
        request.validate()?;
        
        // Log request if enabled
        if self.config.logging_enabled {
            tracing::info!(
                request_id = %request.id,
                model = %request.model,
                "Sending request to DeepSeek"
            );
        }
        
        // Convert to DeepSeek format
        let deepseek_request = self.convert_request(&request)
            .map_err(|e| Error::Provider {
                provider: "deepseek".to_string(),
                message: format!("Request conversion failed: {}", e),
            })?;
        
        // Build HTTP request
        let url = format!("{}/chat/completions", self.config.endpoint);
        let start = Instant::now();
        
        let mut req_builder = self.client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.config.api_key.expose_secret()))
            .header("Content-Type", "application/json")
            .json(&deepseek_request);
        
        if let Some(org_id) = &self.config.organization_id {
            req_builder = req_builder.header("DeepSeek-Organization", org_id);
        }
        
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
                provider: "deepseek".to_string(),
                message: format!("API error ({}): {}", status, error_body),
            });
        }
        
        // Parse response
        let deepseek_response: DeepSeekResponse = response
            .json()
            .await
            .map_err(|e| Error::Serialization(format!("Failed to parse response: {}", e)))?;
        
        // Convert to SecureLLM format
        let securellm_response = self.convert_response(
            request.id,
            deepseek_response,
            processing_time,
        ).map_err(|e| Error::Provider {
            provider: "deepseek".to_string(),
            message: format!("Response conversion failed: {}", e),
        })?;
        
        // Log response if enabled
        if self.config.logging_enabled {
            tracing::info!(
                request_id = %request.id,
                tokens = securellm_response.usage.total_tokens,
                duration_ms = processing_time.as_millis(),
                "Received response from DeepSeek"
            );
        }
        
        Ok(securellm_response)
    }
    
    async fn health_check(&self) -> securellm_core::Result<ProviderHealth> {
        let start = Instant::now();
        
        // Try to list models as a health check
        let url = format!("{}/models", self.config.endpoint);
        let response = self.client
            .get(&url)
            .header("Authorization", format!("Bearer {}", self.config.api_key.expose_secret()))
            .send()
            .await;
        
        let latency = start.elapsed();
        
        let status = match response {
            Ok(resp) if resp.status().is_success() => HealthStatus::Healthy,
            Ok(resp) if resp.status().is_server_error() => HealthStatus::Degraded,
            _ => HealthStatus::Unhealthy,
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
            function_calling: true,
            vision: false,
            embeddings: false,
            max_tokens: Some(32768),
            max_context_window: Some(64000),
            supports_system_prompts: true,
        }
    }
    
    async fn list_models(&self) -> securellm_core::Result<Vec<ModelInfo>> {
        // DeepSeek's main models
        Ok(vec![
            ModelInfo {
                id: "deepseek-chat".to_string(),
                name: "DeepSeek Chat".to_string(),
                description: Some("DeepSeek's chat model with strong reasoning capabilities".to_string()),
                context_window: Some(64000),
                max_output_tokens: Some(4096),
                capabilities: vec!["chat".to_string(), "reasoning".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.0014,
                    output_cost_per_1k: 0.0028,
                    currency: "USD".to_string(),
                }),
            },
            ModelInfo {
                id: "deepseek-coder".to_string(),
                name: "DeepSeek Coder".to_string(),
                description: Some("Specialized model for code generation and understanding".to_string()),
                context_window: Some(64000),
                max_output_tokens: Some(4096),
                capabilities: vec!["chat".to_string(), "code".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.0014,
                    output_cost_per_1k: 0.0028,
                    currency: "USD".to_string(),
                }),
            },
        ])
    }
}

// DeepSeek API types
#[derive(Debug, Serialize)]
struct DeepSeekRequest {
    model: String,
    messages: Vec<DeepSeekMessage>,
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
struct DeepSeekMessage {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct DeepSeekResponse {
    id: String,
    model: String,
    choices: Vec<DeepSeekChoice>,
    usage: DeepSeekUsage,
}

#[derive(Debug, Deserialize)]
struct DeepSeekChoice {
    index: u32,
    message: DeepSeekMessage,
    finish_reason: String,
}

#[derive(Debug, Deserialize)]
struct DeepSeekUsage {
    prompt_tokens: u32,
    completion_tokens: u32,
    total_tokens: u32,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_config_builder() {
        let config = DeepSeekConfig::new("test_key")
            .with_timeout(Duration::from_secs(30))
            .with_logging(true);
        
        assert_eq!(config.api_key.expose_secret(), "test_key");
        assert_eq!(config.timeout, Duration::from_secs(30));
        assert!(config.logging_enabled);
    }
    
    #[test]
    fn test_provider_capabilities() {
        let config = DeepSeekConfig::new("test");
        let provider = DeepSeekProvider::new(config).unwrap();
        
        let caps = provider.capabilities();
        assert!(caps.streaming);
        assert!(caps.function_calling);
        assert!(!caps.vision);
        assert_eq!(caps.max_context_window, Some(64000));
    }
    
    #[tokio::test]
    async fn test_list_models() {
        let config = DeepSeekConfig::new("test");
        let provider = DeepSeekProvider::new(config).unwrap();
        
        let models = provider.list_models().await.unwrap();
        assert!(models.len() >= 2);
        assert!(models.iter().any(|m| m.id == "deepseek-chat"));
    }
}
