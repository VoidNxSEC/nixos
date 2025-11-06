//! Response types for LLM operations

use serde::{Deserialize, Serialize};

/// Chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatResponse {
    /// Unique response identifier
    pub id: String,
    
    /// Model that generated the response
    pub model: String,
    
    /// Response choices
    pub choices: Vec<Choice>,
    
    /// Token usage statistics
    #[serde(skip_serializing_if = "Option::is_none")]
    pub usage: Option<Usage>,
    
    /// Response metadata
    #[serde(flatten)]
    pub metadata: std::collections::HashMap<String, serde_json::Value>,
    
    /// Timestamp
    pub created: i64,
}

impl ChatResponse {
    /// Create a new response
    pub fn new(id: impl Into<String>, model: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            model: model.into(),
            choices: Vec::new(),
            usage: None,
            metadata: std::collections::HashMap::new(),
            created: chrono::Utc::now().timestamp(),
        }
    }

    /// Add a choice
    pub fn add_choice(mut self, choice: Choice) -> Self {
        self.choices.push(choice);
        self
    }

    /// Set usage statistics
    pub fn with_usage(mut self, usage: Usage) -> Self {
        self.usage = Some(usage);
        self
    }

    /// Get the first choice's message content
    pub fn text(&self) -> Option<&str> {
        self.choices
            .first()
            .and_then(|c| c.message.content.as_deref())
    }

    /// Get all choice messages
    pub fn messages(&self) -> Vec<&str> {
        self.choices
            .iter()
            .filter_map(|c| c.message.content.as_deref())
            .collect()
    }

    /// Check if generation was stopped due to length
    pub fn was_truncated(&self) -> bool {
        self.choices
            .iter()
            .any(|c| c.finish_reason == Some(FinishReason::Length))
    }
}

/// A single choice in the response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Choice {
    /// Choice index
    pub index: usize,
    
    /// Generated message
    pub message: ResponseMessage,
    
    /// Reason for stopping generation
    #[serde(skip_serializing_if = "Option::is_none")]
    pub finish_reason: Option<FinishReason>,
}

impl Choice {
    /// Create a new choice
    pub fn new(index: usize, content: impl Into<String>) -> Self {
        Self {
            index,
            message: ResponseMessage {
                role: "assistant".to_string(),
                content: Some(content.into()),
                function_call: None,
            },
            finish_reason: Some(FinishReason::Stop),
        }
    }

    /// Set finish reason
    pub fn with_finish_reason(mut self, reason: FinishReason) -> Self {
        self.finish_reason = Some(reason);
        self
    }
}

/// Message in a response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResponseMessage {
    /// Message role (typically "assistant")
    pub role: String,
    
    /// Message content
    pub content: Option<String>,
    
    /// Function call (if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub function_call: Option<FunctionCall>,
}

/// Function call in response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionCall {
    /// Function name
    pub name: String,
    
    /// Function arguments (JSON string)
    pub arguments: String,
}

/// Reason for stopping generation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FinishReason {
    /// Natural stop
    Stop,
    /// Reached max tokens
    Length,
    /// Content filter triggered
    ContentFilter,
    /// Function call
    FunctionCall,
    /// Error occurred
    Error,
}

/// Token usage statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Usage {
    /// Tokens in the prompt
    pub prompt_tokens: u32,
    
    /// Tokens in the completion
    pub completion_tokens: u32,
    
    /// Total tokens used
    pub total_tokens: u32,
}

impl Usage {
    /// Create new usage statistics
    pub fn new(prompt_tokens: u32, completion_tokens: u32) -> Self {
        Self {
            prompt_tokens,
            completion_tokens,
            total_tokens: prompt_tokens + completion_tokens,
        }
    }

    /// Estimate cost (rough approximation, provider-specific)
    pub fn estimate_cost(&self, cost_per_1k_tokens: f64) -> f64 {
        (self.total_tokens as f64 / 1000.0) * cost_per_1k_tokens
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chat_response() {
        let response = ChatResponse::new("resp-123", "gpt-4")
            .add_choice(Choice::new(0, "Hello, world!"))
            .with_usage(Usage::new(10, 20));

        assert_eq!(response.text(), Some("Hello, world!"));
        assert_eq!(response.usage.as_ref().unwrap().total_tokens, 30);
    }

    #[test]
    fn test_usage_cost() {
        let usage = Usage::new(100, 200);
        let cost = usage.estimate_cost(0.01); // $0.01 per 1K tokens
        
        assert_eq!(cost, 0.003); // 300 tokens * $0.01 / 1000
    }

    #[test]
    fn test_finish_reason() {
        let choice = Choice::new(0, "test").with_finish_reason(FinishReason::Length);
        assert_eq!(choice.finish_reason, Some(FinishReason::Length));
    }

    #[test]
    fn test_truncation_detection() {
        let response = ChatResponse::new("test", "model")
            .add_choice(Choice::new(0, "text").with_finish_reason(FinishReason::Length));

        assert!(response.was_truncated());
    }
}