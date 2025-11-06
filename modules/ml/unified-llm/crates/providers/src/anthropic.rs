// Anthropic provider implementation
// TODO: Implement Anthropic API adapter

use async_trait::async_trait;
use securellm_core::*;

pub struct AnthropicProvider;

#[async_trait]
impl LLMProvider for AnthropicProvider {
    fn name(&self) -> &str {
        "anthropic"
    }
    
    fn version(&self) -> &str {
        "2023-06-01"
    }
    
    fn validate_config(&self) -> securellm_core::Result<()> {
        todo!("Anthropic provider not yet implemented")
    }
    
    async fn send_request(&self, _request: Request) -> securellm_core::Result<Response> {
        todo!("Anthropic provider not yet implemented")
    }
    
    async fn health_check(&self) -> securellm_core::Result<ProviderHealth> {
        todo!("Anthropic provider not yet implemented")
    }
    
    fn capabilities(&self) -> ProviderCapabilities {
        ProviderCapabilities {
            streaming: true,
            function_calling: true,
            vision: true,
            embeddings: false,
            max_tokens: Some(4096),
            max_context_window: Some(200000),
            supports_system_prompts: true,
        }
    }
    
    async fn list_models(&self) -> securellm_core::Result<Vec<ModelInfo>> {
        todo!("Anthropic provider not yet implemented")
    }
}
