// Ollama local provider implementation
// TODO: Implement Ollama API adapter for local models

use async_trait::async_trait;
use unified_llm_core::*;

pub struct OllamaProvider;

#[async_trait]
impl LLMProvider for OllamaProvider {
    fn name(&self) -> &str {
        "ollama"
    }
    
    fn version(&self) -> &str {
        "v1"
    }
    
    fn validate_config(&self) -> unified_llm_core::Result<()> {
        todo!("Ollama provider not yet implemented")
    }
    
    async fn send_request(&self, _request: Request) -> unified_llm_core::Result<Response> {
        todo!("Ollama provider not yet implemented")
    }
    
    async fn health_check(&self) -> unified_llm_core::Result<ProviderHealth> {
        todo!("Ollama provider not yet implemented")
    }
    
    fn capabilities(&self) -> ProviderCapabilities {
        ProviderCapabilities {
            streaming: true,
            function_calling: false,
            vision: false,
            embeddings: true,
            max_tokens: None,
            max_context_window: None,
            supports_system_prompts: true,
        }
    }
    
    async fn list_models(&self) -> unified_llm_core::Result<Vec<ModelInfo>> {
        todo!("Ollama provider not yet implemented")
    }
}
