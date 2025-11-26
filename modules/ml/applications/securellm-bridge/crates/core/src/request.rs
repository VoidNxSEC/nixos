use crate::{Error, Message, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

/// Secure request wrapper for LLM calls
/// 
/// This structure enforces security patterns and provides
/// metadata for auditing and rate limiting.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Request {
    /// Unique request ID for tracking and auditing
    pub id: Uuid,
    
    /// Provider to use (e.g., "openai", "anthropic", "deepseek")
    pub provider: String,
    
    /// Model to use (e.g., "gpt-4", "claude-sonnet-4", "deepseek-chat")
    pub model: String,
    
    /// Messages in the conversation
    pub messages: Vec<Message>,
    
    /// Optional system prompt
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system: Option<String>,
    
    /// Request parameters
    #[serde(flatten)]
    pub parameters: RequestParameters,
    
    /// Request metadata (not sent to provider)
    #[serde(skip)]
    pub metadata: RequestMetadata,
}

/// Request parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RequestParameters {
    /// Maximum tokens to generate
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<u32>,
    
    /// Temperature (0.0 - 2.0)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,
    
    /// Top-p sampling
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,
    
    /// Top-k sampling
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_k: Option<u32>,
    
    /// Enable streaming
    #[serde(default)]
    pub stream: bool,
    
    /// Stop sequences
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stop: Option<Vec<String>>,
    
    /// Additional provider-specific parameters
    #[serde(flatten)]
    pub extra: HashMap<String, serde_json::Value>,
}

/// Request metadata for internal use
#[derive(Debug, Clone)]
pub struct RequestMetadata {
    /// Timestamp when request was created
    pub created_at: chrono::DateTime<chrono::Utc>,
    
    /// User or organization ID making the request
    pub caller_id: Option<String>,
    
    /// Request priority (for rate limiting)
    pub priority: RequestPriority,
    
    /// Whether this request contains sensitive data
    pub sensitive: bool,
    
    /// Request tags for categorization
    pub tags: Vec<String>,
    
    /// Retry attempt number
    pub retry_count: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RequestPriority {
    Low,
    Normal,
    High,
    Critical,
}

impl Request {
    /// Create a new request with basic validation
    pub fn new(provider: impl Into<String>, model: impl Into<String>) -> Self {
        Self {
            id: Uuid::new_v4(),
            provider: provider.into(),
            model: model.into(),
            messages: Vec::new(),
            system: None,
            parameters: RequestParameters::default(),
            metadata: RequestMetadata::default(),
        }
    }
    
    /// Add a message to the request
    pub fn add_message(mut self, message: Message) -> Self {
        self.messages.push(message);
        self
    }
    
    /// Set system prompt
    pub fn with_system(mut self, system: impl Into<String>) -> Self {
        self.system = Some(system.into());
        self
    }
    
    /// Set max tokens
    pub fn with_max_tokens(mut self, max_tokens: u32) -> Self {
        self.parameters.max_tokens = Some(max_tokens);
        self
    }
    
    /// Set temperature
    pub fn with_temperature(mut self, temperature: f32) -> Self {
        self.parameters.temperature = Some(temperature);
        self
    }
    
    /// Enable streaming
    pub fn with_streaming(mut self, stream: bool) -> Self {
        self.parameters.stream = stream;
        self
    }
    
    /// Mark as sensitive data
    pub fn mark_sensitive(mut self) -> Self {
        self.metadata.sensitive = true;
        self
    }
    
    /// Set caller ID
    pub fn with_caller_id(mut self, caller_id: impl Into<String>) -> Self {
        self.metadata.caller_id = Some(caller_id.into());
        self
    }
    
    /// Validate request before sending
    pub fn validate(&self) -> Result<()> {
        // Provider name validation
        if self.provider.is_empty() {
            return Err(Error::InvalidRequest("Provider cannot be empty".to_string()));
        }
        
        // Model name validation
        if self.model.is_empty() {
            return Err(Error::InvalidRequest("Model cannot be empty".to_string()));
        }
        
        // Messages validation
        if self.messages.is_empty() {
            return Err(Error::InvalidRequest("At least one message is required".to_string()));
        }
        
        // Parameter validation
        if let Some(temp) = self.parameters.temperature {
            if !(0.0..=2.0).contains(&temp) {
                return Err(Error::InvalidRequest(
                    "Temperature must be between 0.0 and 2.0".to_string()
                ));
            }
        }
        
        if let Some(top_p) = self.parameters.top_p {
            if !(0.0..=1.0).contains(&top_p) {
                return Err(Error::InvalidRequest(
                    "Top-p must be between 0.0 and 1.0".to_string()
                ));
            }
        }
        
        if let Some(max_tokens) = self.parameters.max_tokens {
            if max_tokens == 0 {
                return Err(Error::InvalidRequest(
                    "Max tokens must be greater than 0".to_string()
                ));
            }
        }
        
        Ok(())
    }
    
    /// Calculate estimated token count for the request
    pub fn estimate_tokens(&self) -> usize {
        // Simple estimation: ~4 chars per token
        let mut total_chars = 0;
        
        if let Some(system) = &self.system {
            total_chars += system.len();
        }
        
        for message in &self.messages {
            match &message.content {
                crate::MessageContent::Text(text) => {
                    total_chars += text.len();
                }
                crate::MessageContent::Parts(parts) => {
                    for part in parts {
                        if let crate::ContentPart::Text { text } = part {
                            total_chars += text.len();
                        }
                    }
                }
            }
        }
        
        (total_chars / 4).max(1)
    }
}

impl Default for RequestParameters {
    fn default() -> Self {
        Self {
            max_tokens: Some(1024),
            temperature: Some(0.7),
            top_p: None,
            top_k: None,
            stream: false,
            stop: None,
            extra: HashMap::new(),
        }
    }
}

impl Default for RequestMetadata {
    fn default() -> Self {
        Self {
            created_at: chrono::Utc::now(),
            caller_id: None,
            priority: RequestPriority::Normal,
            sensitive: false,
            tags: Vec::new(),
            retry_count: 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{MessageRole, MessageContent};
    
    #[test]
    fn test_request_builder() {
        let req = Request::new("openai", "gpt-4")
            .with_max_tokens(500)
            .with_temperature(0.5)
            .add_message(Message {
                role: MessageRole::User,
                content: MessageContent::Text("Hello".to_string()),
                name: None,
                metadata: None,
            });
        
        assert_eq!(req.provider, "openai");
        assert_eq!(req.model, "gpt-4");
        assert_eq!(req.parameters.max_tokens, Some(500));
        assert_eq!(req.messages.len(), 1);
    }
    
    #[test]
    fn test_request_validation() {
        let mut req = Request::new("", "gpt-4");
        assert!(req.validate().is_err());
        
        req.provider = "openai".to_string();
        req.model = "".to_string();
        assert!(req.validate().is_err());
        
        req.model = "gpt-4".to_string();
        assert!(req.validate().is_err()); // No messages
        
        req.messages.push(Message {
            role: MessageRole::User,
            content: MessageContent::Text("Hello".to_string()),
            name: None,
            metadata: None,
        });
        assert!(req.validate().is_ok());
    }
    
    #[test]
    fn test_temperature_validation() {
        let mut req = Request::new("openai", "gpt-4");
        req.messages.push(Message {
            role: MessageRole::User,
            content: MessageContent::Text("test".to_string()),
            name: None,
            metadata: None,
        });
        
        req.parameters.temperature = Some(3.0);
        assert!(req.validate().is_err());
        
        req.parameters.temperature = Some(-0.1);
        assert!(req.validate().is_err());
        
        req.parameters.temperature = Some(0.7);
        assert!(req.validate().is_ok());
    }
    
    #[test]
    fn test_token_estimation() {
        let req = Request::new("openai", "gpt-4")
            .add_message(Message {
                role: MessageRole::User,
                content: MessageContent::Text("A".repeat(400)),
                name: None,
                metadata: None,
            });
        
        let tokens = req.estimate_tokens();
        assert!(tokens >= 90 && tokens <= 110); // ~100 tokens expected
    }
}
