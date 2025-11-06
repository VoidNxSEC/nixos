use crate::{ProviderError, Result};
use async_trait::async_trait;
use unified_llm_core::{
    Choice, ContentPart, Error, HealthStatus, LLMProvider, Message, MessageContent,
    MessageRole, ModelInfo, ModelPricing, ProviderCapabilities, ProviderHealth, Request, 
    Response, FinishReason, TokenUsage, ResponseMetadata,
};
use secrecy::{ExposeSecret, SecretString};
use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};

const DEFAULT_ENDPOINT: &str = "https://api.openai.com/v1";
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(60);

/// OpenAI provider configuration
#[derive(Debug, Clone)]
pub struct OpenAIConfig {
    /// API key for authentication
    pub api_key: SecretString,
    
    /// API endpoint (defaults to https://api.openai.com/v1)
    pub endpoint: String,
    
    /// Request timeout
    pub timeout: Duration,
    
    /// Enable request/response logging
    pub logging_enabled: bool,
    
    /// Organization ID (optional)
    pub organization_id: Option<String>,
}

impl OpenAIConfig {
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

/// OpenAI provider implementation
pub struct OpenAIProvider {
    config: OpenAIConfig,
    client: reqwest::Client,
}

impl OpenAIProvider {
    pub fn new(config: OpenAIConfig) -> Result<Self> {
        let client = reqwest::Client::builder()
            .timeout(config.timeout)
            .build()
            .map_err(|e| ProviderError::Http(format!("Failed to create HTTP client: {}", e)))?;
        
        Ok(Self { config, client })
    }
    
    /// Convert SecureLLM request to OpenAI API format
    fn convert_request(&self, request: &Request) -> Result<OpenAIRequest> {
        let messages = request.messages.iter().map(|msg| {
            OpenAIMessage {
                role: match msg.role {
                    MessageRole::System => "system".to_string(),
                    MessageRole::User => "user".to_string(),
                    MessageRole::Assistant => "assistant".to_string(),
                    MessageRole::Function => "function".to_string(),
                },
                content: match &msg.content {
                    MessageContent::Text(text) => OpenAIMessageContent::Text(text.clone()),
                    MessageContent::Parts(parts) => {
                        // OpenAI supports multimodal content
                        let content_parts: Vec<OpenAIContentPart> = parts.iter().map(|part| {
                            match part {
                                ContentPart::Text { text } => OpenAIContentPart::Text {
                                    r#type: "text".to_string(),
                                    text: text.clone(),
                                },
                                ContentPart::Image { url, detail } => OpenAIContentPart::ImageUrl {
                                    r#type: "image_url".to_string(),
                                    image_url: ImageUrl {
                                        url: url.clone(),
                                        detail: detail.clone(),
                                    },
                                },
                            }
                        }).collect();
                        OpenAIMessageContent::Parts(content_parts)
                    }
                },
                name: msg.name.clone(),
            }
        }).collect();
        
        Ok(OpenAIRequest {
            model: request.model.clone(),
            messages,
            max_tokens: request.parameters.max_tokens,
            temperature: request.parameters.temperature,
            top_p: request.parameters.top_p,
            stream: Some(request.parameters.stream),
            stop: request.parameters.stop.clone(),
            presence_penalty: request.parameters.presence_penalty,
            frequency_penalty: request.parameters.frequency_penalty,
        })
    }
    
    /// Convert OpenAI API response to SecureLLM format
    fn convert_response(
        &self,
        request_id: uuid::Uuid,
        openai_response: OpenAIResponse,
        processing_time: Duration,
    ) -> Result<Response> {
        let choices = openai_response.choices.into_iter().map(|choice| {
            let content = match choice.message.content {
                OpenAIMessageContent::Text(text) => MessageContent::Text(text),
                OpenAIMessageContent::Parts(parts) => {
                    // Extract text from parts
                    let text = parts.into_iter()
                        .filter_map(|part| {
                            if let OpenAIContentPart::Text { text, .. } = part {
                                Some(text)
                            } else {
                                None
                            }
                        })
                        .collect::<Vec<_>>()
                        .join(" ");
                    MessageContent::Text(text)
                }
            };
            
            Choice {
                index: choice.index,
                message: Message {
                    role: match choice.message.role.as_str() {
                        "assistant" => MessageRole::Assistant,
                        "user" => MessageRole::User,
                        "system" => MessageRole::System,
                        "function" => MessageRole::Function,
                        _ => MessageRole::Assistant,
                    },
                    content,
                    name: choice.message.name,
                    metadata: None,
                },
                finish_reason: match choice.finish_reason.as_str() {
                    "stop" => FinishReason::Stop,
                    "length" => FinishReason::Length,
                    "content_filter" => FinishReason::ContentFilter,
                    "function_call" => FinishReason::FunctionCall,
                    _ => FinishReason::Unknown,
                },
                logprobs: None,
            }
        }).collect();
        
        let usage = TokenUsage {
            prompt_tokens: openai_response.usage.prompt_tokens,
            completion_tokens: openai_response.usage.completion_tokens,
            total_tokens: openai_response.usage.total_tokens,
            estimated_cost: None, // Could calculate based on OpenAI pricing
        };
        
        let mut metadata = ResponseMetadata {
            created_at: chrono::Utc::now(),
            processing_time_ms: processing_time.as_millis() as u64,
            cached: false,
            rate_limit_info: None,
            extra: std::collections::HashMap::new(),
        };
        
        metadata.extra.insert(
            "openai_id".to_string(),
            serde_json::Value::String(openai_response.id.clone()),
        );
        
        metadata.extra.insert(
            "system_fingerprint".to_string(),
            serde_json::Value::String(openai_response.system_fingerprint.clone()),
        );
        
        Ok(Response {
            request_id,
            id: openai_response.id,
            provider: "openai".to_string(),
            model: openai_response.model,
            choices,
            usage,
            metadata,
        })
    }
}

#[async_trait]
impl LLMProvider for OpenAIProvider {
    fn name(&self) -> &str {
        "openai"
    }
    
    fn version(&self) -> &str {
        "v1"
    }
    
    fn validate_config(&self) -> unified_llm_core::Result<()> {
        if self.config.api_key.expose_secret().is_empty() {
            return Err(Error::Config("OpenAI API key is empty".to_string()));
        }
        
        if self.config.endpoint.is_empty() {
            return Err(Error::Config("OpenAI endpoint is empty".to_string()));
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
                "Sending request to OpenAI"
            );
        }
        
        // Convert to OpenAI format
        let openai_request = self.convert_request(&request)
            .map_err(|e| Error::Provider {
                provider: "openai".to_string(),
                message: format!("Request conversion failed: {}", e),
            })?;
        
        // Build HTTP request
        let url = format!("{}/chat/completions", self.config.endpoint);
        let start = Instant::now();
        
        let mut req_builder = self.client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.config.api_key.expose_secret()))
            .header("Content-Type", "application/json")
            .json(&openai_request);
        
        if let Some(org_id) = &self.config.organization_id {
            req_builder = req_builder.header("OpenAI-Organization", org_id);
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
                provider: "openai".to_string(),
                message: format!("API error ({}): {}", status, error_body),
            });
        }
        
        // Parse response
        let openai_response: OpenAIResponse = response
            .json()
            .await
            .map_err(|e| Error::Serialization(format!("Failed to parse response: {}", e)))?;
        
        // Convert to SecureLLM format
        let securellm_response = self.convert_response(
            request.id,
            openai_response,
            processing_time,
        ).map_err(|e| Error::Provider {
            provider: "openai".to_string(),
            message: format!("Response conversion failed: {}", e),
        })?;
        
        // Log response if enabled
        if self.config.logging_enabled {
            tracing::info!(
                request_id = %request.id,
                tokens = securellm_response.usage.total_tokens,
                duration_ms = processing_time.as_millis(),
                "Received response from OpenAI"
            );
        }
        
        Ok(securellm_response)
    }
    
    async fn health_check(&self) -> unified_llm_core::Result<ProviderHealth> {
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
            vision: true,
            embeddings: true,
            max_tokens: Some(4096),
            max_context_window: Some(128000),
            supports_system_prompts: true,
        }
    }
    
    async fn list_models(&self) -> unified_llm_core::Result<Vec<ModelInfo>> {
        // OpenAI's main models
        Ok(vec![
            ModelInfo {
                id: "gpt-4o".to_string(),
                name: "GPT-4o".to_string(),
                description: Some("Most advanced multimodal model with vision support".to_string()),
                context_window: Some(128000),
                max_output_tokens: Some(4096),
                capabilities: vec!["chat".to_string(), "vision".to_string(), "function_calling".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.005,
                    output_cost_per_1k: 0.015,
                    currency: "USD".to_string(),
                }),
            },
            ModelInfo {
                id: "gpt-4o-mini".to_string(),
                name: "GPT-4o Mini".to_string(),
                description: Some("Affordable and intelligent small model for fast, lightweight tasks".to_string()),
                context_window: Some(128000),
                max_output_tokens: Some(16384),
                capabilities: vec!["chat".to_string(), "vision".to_string(), "function_calling".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.00015,
                    output_cost_per_1k: 0.0006,
                    currency: "USD".to_string(),
                }),
            },
            ModelInfo {
                id: "gpt-4-turbo".to_string(),
                name: "GPT-4 Turbo".to_string(),
                description: Some("Previous generation GPT-4 with 128K context".to_string()),
                context_window: Some(128000),
                max_output_tokens: Some(4096),
                capabilities: vec!["chat".to_string(), "vision".to_string(), "function_calling".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.01,
                    output_cost_per_1k: 0.03,
                    currency: "USD".to_string(),
                }),
            },
            ModelInfo {
                id: "gpt-3.5-turbo".to_string(),
                name: "GPT-3.5 Turbo".to_string(),
                description: Some("Fast and affordable model for simple tasks".to_string()),
                context_window: Some(16385),
                max_output_tokens: Some(4096),
                capabilities: vec!["chat".to_string(), "function_calling".to_string()],
                pricing: Some(ModelPricing {
                    input_cost_per_1k: 0.0005,
                    output_cost_per_1k: 0.0015,
                    currency: "USD".to_string(),
                }),
            },
        ])
    }
}

// OpenAI API types
#[derive(Debug, Serialize)]
struct OpenAIRequest {
    model: String,
    messages: Vec<OpenAIMessage>,
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
    #[serde(skip_serializing_if = "Option::is_none")]
    presence_penalty: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    frequency_penalty: Option<f32>,
}

#[derive(Debug, Serialize, Deserialize)]
struct OpenAIMessage {
    role: String,
    content: OpenAIMessageContent,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(untagged)]
enum OpenAIMessageContent {
    Text(String),
    Parts(Vec<OpenAIContentPart>),
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
enum OpenAIContentPart {
    #[serde(rename = "text")]
    Text {
        r#type: String,
        text: String,
    },
    #[serde(rename = "image_url")]
    ImageUrl {
        r#type: String,
        image_url: ImageUrl,
    },
}

#[derive(Debug, Serialize, Deserialize)]
struct ImageUrl {
    url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    detail: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OpenAIResponse {
    id: String,
    model: String,
    choices: Vec<OpenAIChoice>,
    usage: OpenAIUsage,
    system_fingerprint: String,
}

#[derive(Debug, Deserialize)]
struct OpenAIChoice {
    index: u32,
    message: OpenAIMessage,
    finish_reason: String,
}

#[derive(Debug, Deserialize)]
struct OpenAIUsage {
    prompt_tokens: u32,
    completion_tokens: u32,
    total_tokens: u32,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_config_builder() {
        let config = OpenAIConfig::new("test_key")
            .with_timeout(Duration::from_secs(30))
            .with_logging(true);
        
        assert_eq!(config.api_key.expose_secret(), "test_key");
        assert_eq!(config.timeout, Duration::from_secs(30));
        assert!(config.logging_enabled);
    }
    
    #[test]
    fn test_provider_capabilities() {
        let config = OpenAIConfig::new("test");
        let provider = OpenAIProvider::new(config).unwrap();
        
        let caps = provider.capabilities();
        assert!(caps.streaming);
        assert!(caps.function_calling);
        assert!(caps.vision);
        assert_eq!(caps.max_context_window, Some(128000));
    }
    
    #[tokio::test]
    async fn test_list_models() {
        let config = OpenAIConfig::new("test");
        let provider = OpenAIProvider::new(config).unwrap();
        
        let models = provider.list_models().await.unwrap();
        assert!(models.len() >= 4);
        assert!(models.iter().any(|m| m.id == "gpt-4o"));
        assert!(models.iter().any(|m| m.id == "gpt-3.5-turbo"));
    }
}
