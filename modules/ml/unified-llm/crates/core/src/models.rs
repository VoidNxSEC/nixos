//! Model information and metadata types

use serde::{Deserialize, Serialize};

pub use crate::provider::ProviderType;

/// Information about an available model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfo {
    /// Unique model identifier
    pub id: String,
    
    /// Human-readable model name
    pub name: String,
    
    /// Provider that serves this model
    pub provider: String,
    
    /// Provider type (cloud or local)
    pub provider_type: ProviderType,
    
    /// Model architecture (e.g., "LLaMA", "Mistral", "GPT")
    pub architecture: Option<String>,
    
    /// Model size in billions of parameters
    pub parameter_count_b: Option<f32>,
    
    /// Size on disk in GB
    pub size_gb: Option<f32>,
    
    /// Quantization format (e.g., "Q4_K_M", "fp16")
    pub quantization: Option<String>,
    
    /// Context window size in tokens
    pub context_length: Option<u32>,
    
    /// Number of layers (for layer-wise offloading)
    pub layer_count: Option<u32>,
    
    /// Model capabilities
    pub capabilities: ModelCapabilities,
    
    /// Additional metadata
    #[serde(default)]
    pub metadata: std::collections::HashMap<String, serde_json::Value>,
    
    /// Model file path (for local models)
    pub path: Option<String>,
    
    /// Whether model is currently loaded (for local models)
    #[serde(default)]
    pub loaded: bool,
}

/// Model capabilities
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ModelCapabilities {
    /// Supports chat/conversation
    #[serde(default = "default_true")]
    pub chat: bool,
    
    /// Supports completions
    #[serde(default = "default_true")]
    pub completion: bool,
    
    /// Supports embeddings
    #[serde(default)]
    pub embeddings: bool,
    
    /// Supports function calling
    #[serde(default)]
    pub function_calling: bool,
    
    /// Supports vision/image inputs
    #[serde(default)]
    pub vision: bool,
    
    /// Supports streaming responses
    #[serde(default = "default_true")]
    pub streaming: bool,
}

fn default_true() -> bool {
    true
}

impl ModelInfo {
    /// Create a new model info with minimal details
    pub fn new(id: impl Into<String>, name: impl Into<String>, provider: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            provider: provider.into(),
            provider_type: ProviderType::Cloud,
            architecture: None,
            parameter_count_b: None,
            size_gb: None,
            quantization: None,
            context_length: None,
            layer_count: None,
            capabilities: ModelCapabilities::default(),
            metadata: Default::default(),
            path: None,
            loaded: false,
        }
    }

    /// Set provider type
    pub fn with_provider_type(mut self, provider_type: ProviderType) -> Self {
        self.provider_type = provider_type;
        self
    }

    /// Set architecture
    pub fn with_architecture(mut self, architecture: impl Into<String>) -> Self {
        self.architecture = Some(architecture.into());
        self
    }

    /// Set parameter count
    pub fn with_parameter_count(mut self, billions: f32) -> Self {
        self.parameter_count_b = Some(billions);
        self
    }

    /// Set size in GB
    pub fn with_size_gb(mut self, size: f32) -> Self {
        self.size_gb = Some(size);
        self
    }

    /// Set context length
    pub fn with_context_length(mut self, length: u32) -> Self {
        self.context_length = Some(length);
        self
    }

    /// Set layer count
    pub fn with_layer_count(mut self, count: u32) -> Self {
        self.layer_count = Some(count);
        self
    }

    /// Set file path (for local models)
    pub fn with_path(mut self, path: impl Into<String>) -> Self {
        self.path = Some(path.into());
        self
    }

    /// Mark as loaded
    pub fn mark_loaded(mut self) -> Self {
        self.loaded = true;
        self
    }

    /// Check if model fits in available VRAM
    pub fn fits_in_vram(&self, available_gb: f32) -> bool {
        self.size_gb.map(|size| size <= available_gb).unwrap_or(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_model_info_builder() {
        let model = ModelInfo::new("test-id", "Test Model", "test-provider")
            .with_provider_type(ProviderType::Local)
            .with_parameter_count(7.0)
            .with_size_gb(4.5)
            .with_context_length(8192);

        assert_eq!(model.id, "test-id");
        assert_eq!(model.parameter_count_b, Some(7.0));
        assert_eq!(model.context_length, Some(8192));
    }

    #[test]
    fn test_vram_check() {
        let model = ModelInfo::new("test", "Test", "provider").with_size_gb(4.0);

        assert!(model.fits_in_vram(8.0));
        assert!(model.fits_in_vram(4.0));
        assert!(!model.fits_in_vram(2.0));
    }
}