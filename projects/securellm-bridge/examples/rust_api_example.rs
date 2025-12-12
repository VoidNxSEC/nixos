use securellm_core::*;
use securellm_providers::deepseek::{DeepSeekConfig, DeepSeekProvider};
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Configure DeepSeek provider
    let config = DeepSeekConfig::new(std::env::var("SECURELLM_API_KEY")?)
        .with_timeout(Duration::from_secs(60))
        .with_logging(true);
    
    let provider = DeepSeekProvider::new(config)?;
    
    // Build a request
    let request = Request::new("deepseek", "deepseek-chat")
        .with_system("You are a helpful assistant")
        .add_message(Message {
            role: MessageRole::User,
            content: MessageContent::Text("What is Rust?".to_string()),
            name: None,
            metadata: None,
        })
        .with_max_tokens(500)
        .with_temperature(0.7);
    
    // Send request
    println!("Sending request...");
    let response = provider.send_request(request).await?;
    
    // Print response
    println!("\nResponse:");
    println!("{}", response.text()?);
    
    println!("\nUsage:");
    println!("  Prompt tokens: {}", response.usage.prompt_tokens);
    println!("  Completion tokens: {}", response.usage.completion_tokens);
    println!("  Total tokens: {}", response.usage.total_tokens);
    
    Ok(())
}
