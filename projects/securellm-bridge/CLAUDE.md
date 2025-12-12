# SecureLLM Bridge - AI Assistant Guide

**Project**: SecureLLM Bridge  
**Version**: 0.1.0  
**Last Updated**: 2025-11-06  
**Maintainer**: kernelcore  

---

## Executive Summary

### Project Overview

**SecureLLM Bridge** is a secure, production-ready proxy for Large Language Model APIs with enterprise-grade security features. Built in Rust, it provides:

- **Unified API Interface**: Single consistent interface for multiple LLM providers
- **Enterprise Security**: TLS mutual authentication, rate limiting, audit logging, sandboxing
- **Provider Support**: DeepSeek, OpenAI, Anthropic, Ollama with extensible architecture
- **Zero-Trust Design**: Every request validated, logged, and rate-limited
- **Local ML Integration**: Ready for ml-offload-api integration for local inference

### Current State

**Status**: ✅ Core functionality complete, tested with DeepSeek API  
**Build System**: Nix flakes + Cargo workspace  
**Architecture**: 5 crates (core, security, providers, cli, desktop)  
**Security Level**: Production-ready with comprehensive hardening  

### Goals

1. **Primary**: Provide secure proxy for LLM API access
2. **Secondary**: Integrate with ml-offload-api for local model fallback
3. **Tertiary**: Desktop GUI for non-technical users
4. **Future**: Multi-tenant support, advanced observability

---

## Architecture Overview

### Workspace Structure

```
SecureLLM Bridge/
├── crates/
│   ├── core/          # Core types, traits, unified interface
│   ├── security/      # TLS, rate limiting, audit logs, sandboxing
│   ├── providers/     # LLM provider implementations
│   ├── cli/           # Command-line interface
│   └── desktop/       # GUI application (WIP)
├── mcp-server/        # MCP server for IDE integration
├── .claude/           # AI assistant infrastructure
├── nix/               # Nix build configurations
└── config.toml        # Runtime configuration
```

### Crate Responsibilities

#### 1. `crates/core/` - Foundation
- **Purpose**: Core abstractions and unified interface
- **Key Components**:
  - `LLMProvider` trait: Unified interface for all providers
  - `Message`, `ChatRequest`, `ChatResponse` types
  - `ProviderConfig` for provider-specific settings
  - Error handling with `anyhow`
- **Dependencies**: Minimal (serde, anyhow, tokio)

#### 2. `crates/security/` - Security Layer
- **Purpose**: Enterprise-grade security features
- **Key Components**:
  - **TLS**: Mutual authentication with `rustls`, client certificates
  - **Rate Limiting**: Token-bucket algorithm, per-provider limits
  - **Audit Logging**: Structured JSON logs, rotation, retention
  - **Sandboxing**: Process isolation, resource limits
  - **Secrets Management**: `secrecy` crate for sensitive data
- **Security Standards**: OWASP compliant, defense-in-depth
- **Dependencies**: rustls, tokio, secrecy, serde_json

#### 3. `crates/providers/` - LLM Integrations
- **Purpose**: Provider-specific implementations
- **Supported Providers**:
  - **DeepSeek**: ✅ Tested and working (api.deepseek.com)
  - **OpenAI**: ✅ Implementation complete (GPT-4, GPT-3.5)
  - **Anthropic**: ✅ Implementation complete (Claude models)
  - **Ollama**: ✅ Local inference support (localhost:11434)
  - **ML-Offload-API**: 🚧 Planned integration (port 9000)
- **Features**: 
  - Automatic retry with exponential backoff
  - Request/response transformation
  - Provider-specific error handling
  - Cost tracking (tokens, API calls)
- **Dependencies**: reqwest, serde_json, tokio

#### 4. `crates/cli/` - Command-Line Interface
- **Purpose**: CLI for testing and automation
- **Commands**:
  - `securellm test <provider>` - Test provider connectivity
  - `securellm chat <provider>` - Interactive chat session
  - `securellm config validate` - Validate configuration
  - `securellm security audit` - Run security audit
- **Features**: Interactive REPL, streaming responses, configuration management
- **Dependencies**: clap, tokio, serde

#### 5. `crates/desktop/` - GUI Application
- **Purpose**: User-friendly desktop interface
- **Status**: 🚧 Work in progress
- **Planned Features**:
  - Multi-provider chat interface
  - Configuration wizard
  - Security dashboard
  - Usage analytics
- **Technology**: TBD (Tauri, egui, or Dioxus)

---

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────┐
│  1. TLS Mutual Authentication           │
│     - Client certificates required      │
│     - Server certificate validation     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  2. Rate Limiting                       │
│     - Per-provider token buckets        │
│     - Request rate limits               │
│     - Burst protection                  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  3. Input Validation & Sanitization     │
│     - Schema validation                 │
│     - Prompt injection protection       │
│     - Content filtering                 │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  4. Audit Logging                       │
│     - All requests logged               │
│     - Structured JSON format            │
│     - Tamper-proof logs                 │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  5. Sandboxing                          │
│     - Process isolation                 │
│     - Resource limits (CPU, memory)     │
│     - Network restrictions              │
└─────────────────────────────────────────┘
```

### TLS Configuration

**Certificates**:
- Server certificate: `/etc/securellm/certs/server.crt`
- Server key: `/etc/securellm/certs/server.key`
- Client CA: `/etc/securellm/certs/client-ca.crt`

**Configuration** (`config.toml`):
```toml
[security.tls]
enabled = true
cert_path = "/etc/securellm/certs/server.crt"
key_path = "/etc/securellm/certs/server.key"
client_ca_path = "/etc/securellm/certs/client-ca.crt"
require_client_cert = true
```

### Rate Limiting

**Algorithm**: Token bucket with refill  
**Configuration**:
```toml
[security.rate_limit]
enabled = true
requests_per_minute = 60
burst_size = 10
per_provider = true
```

**Limits by Provider**:
- DeepSeek: 60 req/min, 10 burst
- OpenAI: 3500 req/min (API tier dependent)
- Anthropic: 50 req/min, 5 burst
- Ollama: Unlimited (local)

### Audit Logging

**Format**: Structured JSON  
**Fields**: timestamp, user_id, provider, model, prompt_tokens, completion_tokens, cost, duration_ms, status  
**Rotation**: Daily with 90-day retention  
**Storage**: `/var/log/securellm/audit.log`

**Example Log Entry**:
```json
{
  "timestamp": "2025-11-06T01:54:32Z",
  "request_id": "req_abc123",
  "user_id": "user_001",
  "provider": "deepseek",
  "model": "deepseek-chat",
  "prompt_tokens": 126,
  "completion_tokens": 748,
  "total_cost": 0.000437,
  "duration_ms": 738,
  "status": "success"
}
```

---

## Provider Integration Guide

### Adding a New Provider

1. **Create Provider Module** (`crates/providers/src/newprovider.rs`):
```rust
use crate::core::{LLMProvider, ChatRequest, ChatResponse, ProviderError};

pub struct NewProvider {
    api_key: String,
    base_url: String,
}

#[async_trait::async_trait]
impl LLMProvider for NewProvider {
    async fn chat(&self, request: ChatRequest) -> Result<ChatResponse, ProviderError> {
        // Implementation
    }
}
```

2. **Add to Provider Registry** (`crates/providers/src/lib.rs`):
```rust
pub mod newprovider;
pub use newprovider::NewProvider;
```

3. **Add Configuration** (`config.toml`):
```toml
[providers.newprovider]
enabled = true
api_key = "${NEW_PROVIDER_API_KEY}"
base_url = "https://api.newprovider.com"
```

4. **Implement Tests**:
```rust
#[tokio::test]
async fn test_newprovider() {
    let provider = NewProvider::new(config);
    let response = provider.chat(test_request).await.unwrap();
    assert!(!response.content.is_empty());
}
```

### Provider Testing

**Test Script**: `basic_usage.sh`
```bash
#!/bin/bash
export DEEPSEEK_API_KEY="your-key"
cargo run --bin securellm -- test deepseek
```

**Expected Output**:
```
Testing DeepSeek provider...
Request sent in 738ms
Response: 874 tokens
Status: ✅ Success
```

---

## ML-Offload-API Integration Plan

### Integration Architecture

```
┌────────────────────────┐
│   SecureLLM Bridge     │
│   (This Project)       │
│                        │
│   ┌────────────────┐   │
│   │ Cloud Providers│   │
│   │ - DeepSeek     │   │
│   │ - OpenAI       │   │
│   │ - Anthropic    │   │
│   └────────────────┘   │
│                        │
│   ┌────────────────┐   │
│   │ Local Provider │   │
│   │ (NEW)          │   │
│   │                │   │
│   │  ┌──────────┐  │   │
│   │  │ ML-Offload│◄─┼───┼─── Port 9000
│   │  │ API       │  │   │
│   │  └──────────┘  │   │
│   │                │   │
│   │  - VRAM check  │   │
│   │  - Model mgmt  │   │
│   │  - llama.cpp   │   │
│   └────────────────┘   │
└────────────────────────┘
```

### Integration Steps (Phase 1)

**Week 1: Research & Design**
- [x] Analyze ml-offload-api endpoints
- [ ] Design LocalProvider implementation
- [ ] Define fallback strategy (cloud → local)
- [ ] Plan VRAM-aware routing

**Week 2: Implementation**
- [ ] Create `crates/providers/src/local.rs`
- [ ] Implement OpenAI-compatible client
- [ ] Add VRAM monitoring integration
- [ ] Implement model availability checks

**Week 3: Testing & Integration**
- [ ] Unit tests for LocalProvider
- [ ] Integration tests with ml-offload-api
- [ ] Load testing and performance tuning
- [ ] Documentation and examples

### LocalProvider Design

```rust
pub struct LocalProvider {
    client: reqwest::Client,
    base_url: String, // http://localhost:9000
    vram_threshold_mb: u64, // Minimum VRAM for inference
}

impl LocalProvider {
    async fn check_vram(&self) -> Result<VramState, ProviderError> {
        // GET /health/vram
    }
    
    async fn get_available_models(&self) -> Result<Vec<ModelInfo>, ProviderError> {
        // GET /v1/models
    }
    
    async fn select_model(&self, request: &ChatRequest) -> Result<String, ProviderError> {
        // Intelligent model selection based on:
        // - Request complexity
        // - Available VRAM
        // - Model capabilities
    }
}

#[async_trait::async_trait]
impl LLMProvider for LocalProvider {
    async fn chat(&self, request: ChatRequest) -> Result<ChatResponse, ProviderError> {
        // Check VRAM availability
        let vram = self.check_vram().await?;
        if vram.free_mb < self.vram_threshold_mb {
            return Err(ProviderError::InsufficientResources);
        }
        
        // Select appropriate model
        let model = self.select_model(&request).await?;
        
        // POST /v1/chat/completions
        let response = self.client
            .post(&format!("{}/v1/chat/completions", self.base_url))
            .json(&request)
            .send()
            .await?;
            
        // Transform response
        Ok(response.json().await?)
    }
}
```

---

## Development Guide

### Prerequisites

- **Nix**: 2.18+ with flakes enabled
- **Rust**: 1.70+ (via Nix devShell)
- **System**: Linux (tested on NixOS)

### Initial Setup

```bash
# Clone repository
git clone /path/to/securellm-bridge
cd securellm-bridge

# Enter Nix development shell
nix develop

# Build all crates
cargo build

# Run tests
cargo test
```

### Development Workflow

1. **Make Changes**: Edit Rust code
2. **Format**: `cargo fmt`
3. **Lint**: `cargo clippy`
4. **Test**: `cargo test`
5. **Build**: `cargo build --release`

### Testing Providers

**DeepSeek**:
```bash
export DEEPSEEK_API_KEY="your-key-here"
./basic_usage.sh
```

**Ollama** (requires local Ollama server):
```bash
ollama serve  # Start Ollama server
cargo run --bin securellm -- test ollama
```

### Configuration Management

**Development** (`config.toml`):
```toml
[providers.deepseek]
enabled = true
api_key = "${DEEPSEEK_API_KEY}"
base_url = "https://api.deepseek.com"
model = "deepseek-chat"

[security.tls]
enabled = false  # Disable for local dev

[security.rate_limit]
enabled = true
requests_per_minute = 60
```

**Production** (`config.production.toml`):
```toml
[security.tls]
enabled = true
cert_path = "/etc/securellm/certs/server.crt"
key_path = "/etc/securellm/certs/server.key"
client_ca_path = "/etc/securellm/certs/client-ca.crt"
require_client_cert = true

[security.audit]
enabled = true
log_path = "/var/log/securellm/audit.log"
rotation = "daily"
retention_days = 90
```

### Docker Deployment

```bash
# Build Docker image
docker build -t securellm-bridge:latest -f Dockerfile .

# Run container
docker run -d \
  --name securellm-bridge \
  -p 8443:8443 \
  -v /etc/securellm:/etc/securellm:ro \
  -v /var/log/securellm:/var/log/securellm \
  -e DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY}" \
  securellm-bridge:latest
```

### NixOS Deployment

```nix
# /etc/nixos/configuration.nix
{
  services.securellm-bridge = {
    enable = true;
    port = 8443;
    configFile = "/etc/securellm/config.toml";
    tlsCertFile = "/etc/securellm/certs/server.crt";
    tlsKeyFile = "/etc/securellm/certs/server.key";
  };
}
```

---

## Best Practices

### Code Style

1. **Formatting**: Use `rustfmt` with default settings
2. **Linting**: Address all `clippy` warnings
3. **Naming**: 
   - Types: `PascalCase`
   - Functions/methods: `snake_case`
   - Constants: `SCREAMING_SNAKE_CASE`
4. **Error Handling**: Use `Result<T, E>` everywhere, never `panic!` in library code
5. **Async**: Use `tokio` runtime, avoid blocking operations

### Security Guidelines

1. **Secrets**: Never hardcode secrets, use environment variables or secrets management
2. **Validation**: Validate all external inputs (API responses, user input, config files)
3. **Logging**: Log security events, sanitize logs (no secrets in logs)
4. **Dependencies**: Regular security audits with `cargo audit`
5. **Updates**: Keep dependencies updated, monitor CVEs

### Testing Strategy

**Unit Tests**: Test individual components in isolation
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_rate_limiter() {
        let limiter = RateLimiter::new(60, 10);
        assert!(limiter.check_limit().is_ok());
    }
}
```

**Integration Tests**: Test provider integrations
```rust
#[tokio::test]
async fn test_deepseek_integration() {
    let provider = DeepSeekProvider::new(test_config());
    let response = provider.chat(test_request()).await;
    assert!(response.is_ok());
}
```

**Security Tests**: Validate security features
```rust
#[tokio::test]
async fn test_rate_limit_enforcement() {
    // Exceed rate limit and verify rejection
}
```

### Git Workflow

1. **Branches**: 
   - `main`: Stable, production-ready
   - `develop`: Integration branch
   - `feature/*`: New features
   - `fix/*`: Bug fixes
2. **Commits**: Use conventional commits (feat:, fix:, docs:, test:)
3. **PRs**: Require tests, documentation, and review
4. **Versioning**: Semantic versioning (major.minor.patch)

---

## MCP Server Integration

### Overview

The MCP (Model Context Protocol) server provides IDE integration for SecureLLM Bridge development. It exposes tools and resources that Cline (Claude Code) can use for:

- Testing providers
- Security auditing
- Build automation
- Configuration validation

### Available Tools

1. **`provider_test`**: Test LLM provider connectivity
2. **`security_audit`**: Run security checks
3. **`rate_limit_check`**: Check rate limit status
4. **`build_and_test`**: Build and test project
5. **`provider_config_validate`**: Validate provider configuration
6. **`crypto_key_generate`**: Generate TLS certificates

### Available Resources

1. **`config://current`**: Current configuration state
2. **`logs://audit`**: Audit log access
3. **`metrics://usage`**: Provider usage metrics
4. **`docs://api`**: API documentation

### Configuration

Add to Claude Desktop config (`~/.config/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "node",
      "args": [
        "/home/kernelcore/Downloads/ClaudeSkills/Security-Architect/mcp-server/build/index.js"
      ],
      "env": {
        "PROJECT_ROOT": "/home/kernelcore/Downloads/ClaudeSkills/Security-Architect"
      }
    }
  }
}
```

### Usage in Cline

```typescript
// Test DeepSeek provider
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "provider_test",
  arguments: {
    provider: "deepseek",
    prompt: "Hello, world!",
    model: "deepseek-chat"
  }
});

// Run security audit
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "security_audit",
  arguments: {
    config_file: "./config.toml"
  }
});
```

---

## Troubleshooting

### Build Issues

**Error**: `error: linking with cc failed`
**Solution**: Ensure all system dependencies are installed
```bash
nix develop  # Nix will provide all dependencies
```

**Error**: `cannot find crate secrecy`
**Solution**: Clean and rebuild
```bash
cargo clean
cargo build
```

### Provider Issues

**Error**: `DeepSeek API authentication failed`
**Solution**: Check API key is set correctly
```bash
echo $DEEPSEEK_API_KEY  # Verify key is set
export DEEPSEEK_API_KEY="sk-your-key-here"
```

**Error**: `Rate limit exceeded`
**Solution**: Wait for rate limit reset or adjust configuration
```toml
[security.rate_limit]
requests_per_minute = 30  # Reduce rate
```

### TLS Issues

**Error**: `TLS handshake failed`
**Solution**: Verify certificate paths and validity
```bash
openssl x509 -in /etc/securellm/certs/server.crt -text -noout
```

### Runtime Issues

**Error**: `VRAM insufficient for inference`
**Solution**: 
1. Check VRAM availability: `nvidia-smi`
2. Reduce model size or batch size
3. Use cloud provider fallback

---

## Roadmap

### Phase 1: Foundation (Complete ✅)
- [x] Core architecture and traits
- [x] Security module (TLS, rate limiting, audit)
- [x] DeepSeek provider integration
- [x] OpenAI provider integration
- [x] Anthropic provider integration
- [x] Ollama provider integration
- [x] CLI interface
- [x] Docker support

### Phase 2: ML-Offload Integration (In Progress 🚧)
- [ ] LocalProvider implementation
- [ ] VRAM-aware routing
- [ ] Model availability checks
- [ ] Cloud → Local fallback
- [ ] Performance optimization
- [ ] Integration tests

### Phase 3: Advanced Features (Planned 📋)
- [ ] Desktop GUI application
- [ ] Multi-tenant support
- [ ] Advanced observability (Prometheus, Grafana)
- [ ] Cost optimization engine
- [ ] Prompt caching
- [ ] Response streaming

### Phase 4: Enterprise Features (Future 🔮)
- [ ] Kubernetes operator
- [ ] Multi-region deployment
- [ ] Advanced RBAC
- [ ] Compliance reporting (SOC2, HIPAA)
- [ ] Plugin system
- [ ] GraphQL API

---

## Contributing

### Code Contributions

1. Fork repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test thoroughly
4. Commit with conventional commits (`git commit -m 'feat: add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open Pull Request

### Documentation Contributions

- Improve this CLAUDE.md
- Add inline code documentation
- Create tutorials and guides
- Report issues and suggest improvements

### Testing Contributions

- Add unit tests
- Create integration tests
- Perform security testing
- Load/performance testing

---

## Support & Resources

### Documentation
- This file: `CLAUDE.md`
- API docs: `cargo doc --open`
- Examples: `examples/` directory

### Community
- Issues: File via `/reportbug` in Cline
- Discussions: Project discussions
- Maintainer: kernelcore

### Related Projects
- **ml-offload-api**: `/etc/nixos/modules/ml/offload/`
- **NixOS Configuration**: `/etc/nixos/`

---

## Appendix

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `DEEPSEEK_API_KEY` | DeepSeek API authentication | `sk-...` |
| `OPENAI_API_KEY` | OpenAI API authentication | `sk-...` |
| `ANTHROPIC_API_KEY` | Anthropic API authentication | `sk-ant-...` |
| `OLLAMA_BASE_URL` | Ollama server URL | `http://localhost:11434` |
| `CONFIG_PATH` | Configuration file path | `/etc/securellm/config.toml` |
| `LOG_LEVEL` | Logging verbosity | `debug`, `info`, `warn`, `error` |

### Configuration Reference

See `config.toml` for complete configuration options.

### Performance Metrics

**Typical Response Times**:
- DeepSeek: 500-1000ms
- OpenAI GPT-4: 1000-3000ms
- Anthropic Claude: 800-2000ms
- Ollama (local): 200-500ms

**Resource Usage**:
- Memory: ~50MB base + ~200MB per active connection
- CPU: Minimal (<1% idle, 5-10% under load)
- Network: Depends on model and usage

---

**Last Updated**: 2025-11-06  
**Version**: 1.0.0  
**Maintained By**: kernelcore
