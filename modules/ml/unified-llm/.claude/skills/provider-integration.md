# Skill: Provider Integration

## Metadata
- **Name**: provider-integration
- **Version**: 1.0.0
- **Category**: Development
- **Dependencies**: cargo, git

## Purpose
Add new LLM provider integrations to SecureLLM Bridge with proper security, rate limiting, and testing.

## Usage
```bash
/skill provider-integration --provider [provider-name] --base-url [url] --auth-type [api-key|bearer|oauth]
```

## Parameters

### Required
- `provider`: Provider name (lowercase, alphanumeric)
- `base-url`: API base URL
- `auth-type`: Authentication type (api-key, bearer, oauth)

### Optional
- `default-model`: Default model name
- `rate-limit`: Requests per minute (default: 60)
- `timeout`: Request timeout in seconds (default: 30)
- `retry-strategy`: Retry strategy (exponential, linear, none)

## Implementation Steps

### 1. Create Provider Module
```rust
// crates/providers/src/[provider].rs
use crate::{Provider, ProviderConfig, ProviderError};
use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};

pub struct [Provider]Provider {
    client: Client,
    config: ProviderConfig,
}

#[async_trait]
impl Provider for [Provider]Provider {
    async fn generate(&self, prompt: &str) -> Result<String, ProviderError> {
        // Implementation
    }
    
    async fn stream_generate(&self, prompt: &str) -> Result<Stream, ProviderError> {
        // Implementation
    }
}
```

### 2. Update lib.rs
```rust
// crates/providers/src/lib.rs
mod [provider];
pub use [provider]::[Provider]Provider;
```

### 3. Add Configuration
```toml
# config.toml
[providers.[provider]]
enabled = true
api_key = "${[PROVIDER]_API_KEY}"
base_url = "[base-url]"
default_model = "[model-name]"
timeout = 30

[providers.[provider].rate_limit]
requests_per_minute = 60
burst_size = 10
```

### 4. Create Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_[provider]_generation() {
        // Test implementation
    }
    
    #[tokio::test]
    async fn test_[provider]_rate_limiting() {
        // Test implementation
    }
}
```

### 5. Update Documentation
- Add provider to README.md
- Document authentication setup
- Add usage examples
- Update CLAUDE.md

## Security Checklist

- [ ] API keys stored in environment variables
- [ ] TLS enabled for all connections
- [ ] Input validation on all parameters
- [ ] Rate limiting configured
- [ ] Audit logging enabled
- [ ] Error messages don't leak sensitive data
- [ ] Timeout configured to prevent hanging
- [ ] Retry logic with exponential backoff

## Validation

### Build Test
```bash
cargo build --features [provider]
cargo test --features [provider]
```

### Integration Test
```bash
cargo run --bin securellm -- test [provider] --prompt "Hello, world!"
```

### Rate Limit Test
```bash
# Should trigger rate limit
for i in {1..100}; do
  cargo run --bin securellm -- test [provider] --prompt "Test $i" &
done
wait
```

## Example: Adding Mistral Provider

```bash
/skill provider-integration \
  --provider mistral \
  --base-url https://api.mistral.ai/v1 \
  --auth-type bearer \
  --default-model mistral-large-latest \
  --rate-limit 120
```

### Generated Files
1. `crates/providers/src/mistral.rs`
2. `crates/providers/tests/mistral_tests.rs`
3. Updated `crates/providers/src/lib.rs`
4. Configuration template in `docs/providers/mistral.md`

## Common Issues

### Authentication Failures
- Verify API key is correctly set in environment
- Check base URL includes correct version path
- Ensure auth header format matches provider requirements

### Rate Limiting
- Adjust `requests_per_minute` based on plan
- Implement proper backoff strategy
- Monitor rate limit headers in responses

### Connection Timeouts
- Increase timeout for slower providers
- Implement retry logic with backoff
- Check network connectivity

## Output Format

```json
{
  "skill": "provider-integration",
  "provider": "mistral",
  "status": "success",
  "files_created": [
    "crates/providers/src/mistral.rs",
    "crates/providers/tests/mistral_tests.rs"
  ],
  "files_modified": [
    "crates/providers/src/lib.rs",
    "config.toml"
  ],
  "next_steps": [
    "Set MISTRAL_API_KEY environment variable",
    "Run: cargo test --features mistral",
    "Test with: cargo run --bin securellm -- test mistral"
  ]
}
```

## Version History

- **1.0.0** (2025-11-06): Initial provider integration skill
