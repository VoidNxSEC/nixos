//! Request types for LLM operations

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Chat completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatRequest {
    /// Model identifier
    pub model: String,
    
    /// Messages in the conversation
    pub messages: Vec<Message>,
    
    /// Temperature (0.0 - 2.0)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,
    
    /// Maximum tokens to generate
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<u32>,
    
    /// Top-p sampling
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,
    
    /// Frequency penalty
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frequency_penalty: Option<f32>,
    
    /// Presence penalty
    #[serde(skip_serializing_if = "Option::is_none")]
    pub presence_penalty: Option<f32>,
    
    /// Stop sequences
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stop: Option<Vec<String>>,
    
    /// Whether to stream the response
    #[serde(default)]
    pub stream: bool,
    
    /// Additional provider-specific parameters
    #[serde(flatten)]
    pub extra: HashMap<String, serde_json::Value>,
}

impl ChatRequest {
    /// Create a new chat request
    pub fn new(model: impl Into<String>) -> Self {
        Self {
            model: model.into(),
            messages: Vec::new(),
            temperature: None,
            max_tokens: None,
            top_p: None,
            frequency_penalty: None,
            presence_penalty: None,
            stop: None,
            stream: false,
            extra: HashMap::new(),
        }
    }

    /// Add a message to the conversation
    pub fn add_message(mut self, message: Message) -> Self {
        self.messages.push(message);
        self
    }

    /// Add a user message
    pub fn user_message(self, content: impl Into<String>) -> Self {
        self.add_message(Message {
            role: MessageRole::User,
            content: MessageContent::Text(content.into()),
            name: None,
            metadata: None,
        })
    }

    /// Add a system message
    pub fn system_message(self, content: impl Into<String>) -> Self {
        self.add_message(Message {
            role: MessageRole::System,
            content: MessageContent::Text(content.into()),
            name: None,
            metadata: None,
        })
    }

    /// Add an assistant message
    pub fn assistant_message(self, content: impl Into<String>) -> Self {
        self.add_message(Message {
            role: MessageRole::Assistant,
            content: MessageContent::Text(content.into()),
            name: None,
            metadata: None,
        })
    }

    /// Set temperature
    pub fn with_temperature(mut self, temperature: f32) -> Self {
        self.temperature = Some(temperature);
        self
    }

    /// Set max tokens
    pub fn with_max_tokens(mut self, max_tokens: u32) -> Self {
        self.max_tokens = Some(max_tokens);
        self
    }

    /// Enable streaming
    pub fn with_streaming(mut self) -> Self {
        self.stream = true;
        self
    }

    /// Estimate token count (rough approximation)
    pub fn estimate_tokens(&self) -> u32 {
        self.messages
            .iter()
            .map(|m| m.estimate_tokens())
            .sum::<u32>()
            + 10 // Overhead
    }
}

/// Message in a conversation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    /// Message role
    pub role: MessageRole,
    
    /// Message content
    pub content: MessageContent,
    
    /// Optional message name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    
    /// Optional metadata
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

impl Message {
    /// Estimate token count for this message (rough approximation)
    pub fn estimate_tokens(&self) -> u32 {
        match &self.content {
            MessageContent::Text(text) => (text.len() / 4) as u32, // Rough: 4 chars per token
            MessageContent::MultiPart(parts) => parts
                .iter()
                .map(|p| match p {
                    ContentPart::Text { text } => (text.len() / 4) as u32,
                    ContentPart::Image { .. } => 85, // Rough estimate for image tokens
                })
                .sum(),
        }
    }
}

/// Message role
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    /// System message (instructions)
    System,
    /// User message
    User,
    /// Assistant message
    Assistant,
    /// Function/tool message
    #[serde(rename = "function")]
    Function,
}

/// Message content (text or multi-part)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum MessageContent {
    /// Simple text content
    Text(String),
    /// Multi-part content (text + images)
    MultiPart(Vec<ContentPart>),
}

impl MessageContent {
    /// Get text content if available
    pub fn as_text(&self) -> Option<&str> {
        match self {
            MessageContent::Text(text) => Some(text),
            MessageContent::MultiPart(_) => None,
        }
    }
}

/// Part of multi-part content
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ContentPart {
    /// Text part
    Text {
        text: String,
    },
    /// Image part
    #[serde(rename = "image_url")]
    Image {
        #[serde(rename = "image_url")]
        url: ImageUrl,
    },
}

/// Image URL in multi-part content
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageUrl {
    /// URL or base64 data
    pub url: String,
    
    /// Optional detail level
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chat_request_builder() {
        let request = ChatRequest::new("gpt-4")
            .user_message("Hello!")
            .with_temperature(0.7)
            .with_max_tokens(100);

        assert_eq!(request.model, "gpt-4");
        assert_eq!(request.messages.len(), 1);
        assert_eq!(request.temperature, Some(0.7));
        assert_eq!(request.max_tokens, Some(100));
    }

    #[test]
    fn test_message_roles() {
        let system = Message {
            role: MessageRole::System,
            content: MessageContent::Text("You are helpful".into()),
            name: None,
            metadata: None,
        };

        assert_eq!(system.role, MessageRole::System);
    }

    #[test]
    fn test_token_estimation() {
        let request = ChatRequest::new("test")
            .user_message("Hello world"); // ~3 tokens + overhead

        let estimated = request.estimate_tokens();
        assert!(estimated > 0);
    }
}