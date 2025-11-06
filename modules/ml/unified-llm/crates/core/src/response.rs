use crate::{Error, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

/// Secure response wrapper for LLM responses
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Response {
    /// Request ID this response is for
    pub request_id: Uuid,
    
    /// Response ID
    pub id: String,
    
    /// Provider that generated this response
    pub provider: String,
    
    /// Model that generated this response
    pub model: String,
    
    /// Generated choices/completions
    pub choices: Vec<Choice>,
    
    /// Token usage information
    pub usage: TokenUsage,
    
    /// Response metadata
    pub metadata: ResponseMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Choice {
    /// Choice index
    pub index: u32,
    
    /// Generated message
    pub message: crate::Message,
    
    /// Finish reason
    pub finish_reason: FinishReason,
    
    /// Log probabilities (if requested)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub logprobs: Option<LogProbs>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FinishReason {
    /// Natural completion
    Stop,
    
    /// Maximum tokens reached
    Length,
    
    /// Content filtered
    ContentFilter,
    
    /// Function call requested
    FunctionCall,
    
    /// Tool use requested
    ToolUse,
    
    /// Error occurred
    Error,
    
    /// Unknown reason
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogProbs {
    pub tokens: Vec<String>,
    pub token_logprobs: Vec<f32>,
    pub top_logprobs: Vec<HashMap<String, f32>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenUsage {
    /// Tokens in the prompt
    pub prompt_tokens: u32,
    
    /// Tokens in the completion
    pub completion_tokens: u32,
    
    /// Total tokens used
    pub total_tokens: u32,
    
    /// Estimated cost (if available)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub estimated_cost: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResponseMetadata {
    /// When the response was created
    pub created_at: chrono::DateTime<chrono::Utc>,
    
    /// Processing time in milliseconds
    pub processing_time_ms: u64,
    
    /// Whether response was from cache
    pub cached: bool,
    
    /// Rate limit information
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rate_limit_info: Option<RateLimitInfo>,
    
    /// Additional provider-specific metadata
    #[serde(flatten)]
    pub extra: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RateLimitInfo {
    /// Remaining requests in current window
    pub remaining_requests: Option<u32>,
    
    /// Remaining tokens in current window
    pub remaining_tokens: Option<u32>,
    
    /// When the rate limit resets
    pub reset_at: Option<chrono::DateTime<chrono::Utc>>,
    
    /// Current limit
    pub limit: Option<u32>,
}

impl Response {
    /// Create a new response
    pub fn new(
        request_id: Uuid,
        provider: impl Into<String>,
        model: impl Into<String>,
    ) -> Self {
        Self {
            request_id,
            id: Uuid::new_v4().to_string(),
            provider: provider.into(),
            model: model.into(),
            choices: Vec::new(),
            usage: TokenUsage::default(),
            metadata: ResponseMetadata::default(),
        }
    }
    
    /// Add a choice to the response
    pub fn add_choice(mut self, choice: Choice) -> Self {
        self.choices.push(choice);
        self
    }
    
    /// Set token usage
    pub fn with_usage(mut self, usage: TokenUsage) -> Self {
        self.usage = usage;
        self
    }
    
    /// Get the first choice (most common use case)
    pub fn first_choice(&self) -> Result<&Choice> {
        self.choices.first().ok_or_else(|| {
            Error::InvalidResponse("Response has no choices".to_string())
        })
    }
    
    /// Get the text content from the first choice
    pub fn text(&self) -> Result<String> {
        let choice = self.first_choice()?;
        match &choice.message.content {
            crate::MessageContent::Text(text) => Ok(text.clone()),
            crate::MessageContent::Parts(parts) => {
                let mut result = String::new();
                for part in parts {
                    if let crate::ContentPart::Text { text } = part {
                        result.push_str(text);
                        result.push(' ');
                    }
                }
                Ok(result.trim().to_string())
            }
        }
    }
    
    /// Check if the response was truncated due to length
    pub fn was_truncated(&self) -> bool {
        self.choices.iter().any(|c| c.finish_reason == FinishReason::Length)
    }
    
    /// Check if the response was filtered
    pub fn was_filtered(&self) -> bool {
        self.choices.iter().any(|c| c.finish_reason == FinishReason::ContentFilter)
    }
    
    /// Validate response structure
    pub fn validate(&self) -> Result<()> {
        if self.choices.is_empty() {
            return Err(Error::InvalidResponse(
                "Response must have at least one choice".to_string()
            ));
        }
        
        if self.usage.total_tokens != self.usage.prompt_tokens + self.usage.completion_tokens {
            return Err(Error::InvalidResponse(
                "Token usage calculation is inconsistent".to_string()
            ));
        }
        
        Ok(())
    }
}

impl Default for TokenUsage {
    fn default() -> Self {
        Self {
            prompt_tokens: 0,
            completion_tokens: 0,
            total_tokens: 0,
            estimated_cost: None,
        }
    }
}

impl Default for ResponseMetadata {
    fn default() -> Self {
        Self {
            created_at: chrono::Utc::now(),
            processing_time_ms: 0,
            cached: false,
            rate_limit_info: None,
            extra: HashMap::new(),
        }
    }
}

/// Streaming response chunk
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamChunk {
    pub request_id: Uuid,
    pub chunk_id: String,
    pub delta: StreamDelta,
    pub finish_reason: Option<FinishReason>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamDelta {
    pub role: Option<crate::MessageRole>,
    pub content: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Message, MessageRole, MessageContent};
    
    #[test]
    fn test_response_builder() {
        let request_id = Uuid::new_v4();
        let response = Response::new(request_id, "openai", "gpt-4")
            .add_choice(Choice {
                index: 0,
                message: Message {
                    role: MessageRole::Assistant,
                    content: MessageContent::Text("Hello!".to_string()),
                    name: None,
                    metadata: None,
                },
                finish_reason: FinishReason::Stop,
                logprobs: None,
            })
            .with_usage(TokenUsage {
                prompt_tokens: 10,
                completion_tokens: 5,
                total_tokens: 15,
                estimated_cost: Some(0.001),
            });
        
        assert_eq!(response.request_id, request_id);
        assert_eq!(response.choices.len(), 1);
        assert_eq!(response.usage.total_tokens, 15);
    }
    
    #[test]
    fn test_response_text_extraction() {
        let request_id = Uuid::new_v4();
        let response = Response::new(request_id, "openai", "gpt-4")
            .add_choice(Choice {
                index: 0,
                message: Message {
                    role: MessageRole::Assistant,
                    content: MessageContent::Text("Hello, world!".to_string()),
                    name: None,
                    metadata: None,
                },
                finish_reason: FinishReason::Stop,
                logprobs: None,
            });
        
        let text = response.text().unwrap();
        assert_eq!(text, "Hello, world!");
    }
    
    #[test]
    fn test_response_validation() {
        let request_id = Uuid::new_v4();
        let mut response = Response::new(request_id, "openai", "gpt-4");
        
        // No choices
        assert!(response.validate().is_err());
        
        // Add choice
        response = response.add_choice(Choice {
            index: 0,
            message: Message {
                role: MessageRole::Assistant,
                content: MessageContent::Text("test".to_string()),
                name: None,
                metadata: None,
            },
            finish_reason: FinishReason::Stop,
            logprobs: None,
        });
        
        // Invalid token usage
        response.usage = TokenUsage {
            prompt_tokens: 10,
            completion_tokens: 5,
            total_tokens: 20, // Should be 15
            estimated_cost: None,
        };
        assert!(response.validate().is_err());
        
        // Fix token usage
        response.usage.total_tokens = 15;
        assert!(response.validate().is_ok());
    }
    
    #[test]
    fn test_finish_reason_checks() {
        let request_id = Uuid::new_v4();
        let response = Response::new(request_id, "openai", "gpt-4")
            .add_choice(Choice {
                index: 0,
                message: Message {
                    role: MessageRole::Assistant,
                    content: MessageContent::Text("...".to_string()),
                    name: None,
                    metadata: None,
                },
                finish_reason: FinishReason::Length,
                logprobs: None,
            });
        
        assert!(response.was_truncated());
        assert!(!response.was_filtered());
    }
}
