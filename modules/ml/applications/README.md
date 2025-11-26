# ML Applications Layer

Standalone ML applications with their own build systems and deployment workflows.

## Components

### securellm-bridge/

Secure LLM proxy with enterprise-grade security features (formerly `unified-llm`).

**Complete Documentation**: See [securellm-bridge/CLAUDE.md](securellm-bridge/CLAUDE.md)

#### Overview

SecureLLM Bridge is a production-ready proxy for Large Language Model APIs with:

- **Unified API Interface**: Single interface for multiple LLM providers
- **Enterprise Security**: TLS mutual auth, rate limiting, audit logging, sandboxing
- **Provider Support**: DeepSeek, OpenAI, Anthropic, Ollama, local ML integration
- **Zero-Trust Design**: Every request validated, logged, and rate-limited

#### Architecture

```
External Clients
      │
      ▼
┌──────────────────────────────┐
│  SecureLLM Bridge            │
│                              │
│  ┌────────────────────────┐  │
│  │ Security Layer         │  │
│  │ - TLS + mTLS           │  │
│  │ - Rate limiting        │  │
│  │ - Audit logging        │  │
│  │ - Input validation     │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Provider Router        │  │
│  │ - DeepSeek             │  │
│  │ - OpenAI               │  │
│  │ - Anthropic            │  │
│  │ - Ollama (local)       │  │
│  │ - ML Offload API       │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
      │
      ▼
Cloud APIs / Local Inference
```

#### Quick Start

**Build**:
```bash
cd /etc/nixos/modules/ml/applications/securellm-bridge
nix build
```

**Develop**:
```bash
nix develop
cargo build
cargo test
```

**Run**:
```bash
# Set API keys
export DEEPSEEK_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."

# Start server
cargo run --bin securellm
```

**Test Provider**:
```bash
./examples/basic_usage.sh
```

#### Configuration

**config.toml**:
```toml
[providers.deepseek]
enabled = true
api_key = "${DEEPSEEK_API_KEY}"
base_url = "https://api.deepseek.com"
model = "deepseek-chat"

[providers.local]
enabled = true
base_url = "http://localhost:9000"  # ML Offload API

[security.tls]
enabled = true
cert_path = "/etc/securellm/certs/server.crt"
key_path = "/etc/securellm/certs/server.key"

[security.rate_limit]
enabled = true
requests_per_minute = 60
```

#### Features

**Security**:
- TLS 1.3 with mutual authentication
- Token-bucket rate limiting (per-provider)
- Structured audit logging (JSON, rotated, tamper-proof)
- Process sandboxing and resource limits

**Providers**:
- **DeepSeek**: ✅ Tested and working
- **OpenAI**: ✅ GPT-4, GPT-3.5
- **Anthropic**: ✅ Claude models
- **Ollama**: ✅ Local inference (port 11434)
- **ML-Offload-API**: 🚧 Integration planned (port 9000)

**Observability**:
- Prometheus metrics
- Request/response logging
- Cost tracking (tokens, API calls)
- Error rate monitoring

#### MCP Server

SecureLLM Bridge includes a Model Context Protocol server for IDE integration.

**Location**: `securellm-bridge/mcp-server/` (moved to [integrations/mcp/](../integrations/mcp/))

See [integrations/mcp/README.md](../integrations/mcp/README.md) for details.

#### Project Structure

```
securellm-bridge/
├── flake.nix              # Nix build
├── Cargo.toml             # Rust workspace
├── CLAUDE.md              # Complete documentation (807 lines)
├── README.md
├── config/
│   └── config.toml        # Runtime configuration
├── crates/
│   ├── core/              # Core types and traits
│   ├── security/          # Security layer (TLS, rate limit, audit)
│   ├── providers/         # LLM provider implementations
│   ├── cli/               # Command-line interface
│   └── api-server/        # HTTP API server
├── docs/                  # Additional documentation
├── examples/              # Usage examples
├── docker/                # Docker deployment
└── tests/                 # Integration tests
```

#### Use Cases

1. **Secure LLM Proxy**: Protect API keys, enforce rate limits
2. **Multi-Provider Routing**: Switch between providers seamlessly
3. **Cost Control**: Track and limit API usage
4. **Audit Compliance**: Comprehensive request logging
5. **Local Fallback**: Route to local models when cloud unavailable

#### Integration with ML Stack

**With Orchestration Layer**:
```rust
// LocalProvider in securellm-bridge
pub struct LocalProvider {
    offload_api_client: reqwest::Client,
    base_url: String,  // http://localhost:9000
}

impl LocalProvider {
    async fn check_vram(&self) -> Result<VramState> {
        self.offload_api_client
            .get(&format!("{}/vram/status", self.base_url))
            .send()
            .await?
            .json()
            .await
    }

    async fn inference(&self, request: ChatRequest) -> Result<ChatResponse> {
        // Check VRAM first
        let vram = self.check_vram().await?;
        if vram.available_mb < 2000 {
            return Err("Insufficient VRAM");
        }

        // Route to offload API
        self.offload_api_client
            .post(&format!("{}/inference", self.base_url))
            .json(&request)
            .send()
            .await?
            .json()
            .await
    }
}
```

## Adding New Applications

To add a new standalone ML application:

1. Create directory in `applications/my-app/`
2. Add `default.nix` (can be empty if standalone flake)
3. Add `flake.nix` for build system
4. Create README.md with usage instructions
5. Add to `applications/default.nix` imports

**Example default.nix**:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:

# My Application
#
# This is a standalone application with its own flake.nix.
# Build: cd /etc/nixos/modules/ml/applications/my-app && nix build

{
  # Empty module - standalone application
}
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Orchestration: [orchestration/README.md](../orchestration/README.md)
- Integrations: [integrations/README.md](../integrations/README.md)
- SecureLLM Bridge: [securellm-bridge/CLAUDE.md](securellm-bridge/CLAUDE.md)
