# ML Modules - Machine Learning Infrastructure

Modular ML infrastructure for NixOS with VRAM management, model orchestration, and secure LLM access.

## Overview

This directory contains a complete, modular ML infrastructure stack organized by function:

- **Infrastructure** - Storage, VRAM monitoring, hardware configurations
- **Services** - ML inference services (llama.cpp, Ollama)
- **Orchestration** - Offload manager, model registry, multi-backend support
- **Applications** - Standalone ML applications (SecureLLM Bridge)
- **Integrations** - External integrations (MCP servers, editor plugins)

## Structure

```
modules/ml/
├── default.nix                    # Main aggregator (import this!)
│
├── infrastructure/                # Base Infrastructure
│   ├── default.nix
│   ├── storage.nix               # Model storage paths & management
│   ├── vram/                     # GPU VRAM monitoring & scheduling
│   │   ├── monitoring.nix
│   │   └── scheduler.nix        # TODO: Central GPU scheduler
│   └── hardware/                 # Hardware-specific configs
│       └── cuda.nix              # CUDA/GPU configs
│
├── services/                      # ML Inference Services
│   ├── default.nix
│   ├── llama-cpp.nix             # LLaMA C++ server (CUDA)
│   └── ollama/                   # Ollama service & GPU manager
│       ├── service.nix
│       └── gpu-manager.nix       # Auto GPU memory management
│
├── orchestration/                 # Offload & Orchestration
│   ├── default.nix               # Offload system config
│   ├── manager.nix               # Offload manager
│   ├── registry/                 # Model registry & discovery
│   │   ├── database.nix
│   │   └── discovery.nix        # TODO: Auto-discovery
│   ├── backends/                 # Multi-backend support
│   │   ├── ollama.nix
│   │   ├── llamacpp.nix
│   │   ├── vllm.nix
│   │   └── tgi.nix
│   ├── api/                      # Rust REST API (port 9000)
│   │   ├── Cargo.toml
│   │   └── src/
│   └── flake.nix                 # Standalone flake for API
│
├── applications/                  # Standalone Applications
│   ├── default.nix
│   └── securellm-bridge/         # Secure LLM proxy (ex unified-llm)
│       ├── flake.nix             # Standalone build
│       ├── CLAUDE.md             # Complete documentation
│       ├── crates/               # Rust workspace
│       │   ├── core/
│       │   ├── security/
│       │   ├── providers/
│       │   ├── cli/
│       │   └── api-server/
│       └── README.md
│
└── integrations/                  # External Integrations
    ├── default.nix
    ├── mcp/                      # Model Context Protocol
    │   ├── config.nix            # MCP configuration
    │   └── server/               # TypeScript MCP server
    │       ├── package.json
    │       └── src/
    └── neovim/                   # Neovim integration
        └── README.md
```

## Quick Start

### Basic Configuration

Import the main ML module in your `flake.nix`:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        ./modules/ml  # Single import for all ML modules!
      ];
    };
  };
}
```

### Enable ML Infrastructure

```nix
# configuration.nix
{
  # Model storage (recommended)
  kernelcore.ml.models-storage.enable = true;
  kernelcore.ml.models-storage.baseDirectory = "/var/lib/ml-models";

  # LLaMA C++ server
  services.llamacpp = {
    enable = true;
    model = "/var/lib/ml-models/llamacpp/models/my-model.gguf";
    n_gpu_layers = 35;  # Adjust based on your GPU
  };

  # Ollama with GPU management
  services.ollama.enable = true;
  services.ollama-gpu-manager = {
    enable = true;
    idleTimeout = 300;  # 5 minutes
  };

  # ML Offload orchestration
  kernelcore.ml.offload = {
    enable = true;
    dataDir = "/var/lib/ml-offload";
  };
}
```

## Components

### Infrastructure Layer

**Purpose**: Base infrastructure for all ML operations

- **storage.nix**: Standardized model storage paths and directory structure
- **vram/monitoring.nix**: VRAM usage monitoring and metrics
- **vram/scheduler.nix**: (TODO) Central GPU allocation scheduler
- **hardware/cuda.nix**: (TODO) CUDA and GPU-specific configurations

**Key Features**:
- Automatic directory creation for models
- Environment variables for model paths
- VRAM monitoring and alerting
- Centralized GPU resource management

### Services Layer

**Purpose**: ML inference services (systemd)

#### llama.cpp Server (`llama-cpp.nix`)

High-performance LLaMA inference with CUDA support.

```nix
services.llamacpp = {
  enable = true;
  model = "/var/lib/ml-models/llamacpp/models/L3-8B-Stheno.gguf";
  host = "127.0.0.1";
  port = 8080;
  n_threads = 6;
  n_gpu_layers = 35;
  n_ctx = 4096;
};
```

#### Ollama with GPU Manager (`ollama/`)

Ollama inference with automatic GPU memory management.

```nix
services.ollama.enable = true;

services.ollama-gpu-manager = {
  enable = true;
  unloadOnShellExit = true;
  idleTimeout = 300;  # Auto-offload after 5min idle
};
```

**Features**:
- Automatic model offloading when idle
- Shell exit hook for cleanup
- VRAM usage monitoring
- Graceful GPU memory release

### Orchestration Layer

**Purpose**: Multi-backend orchestration and model management

**Key Components**:
- **manager.nix**: Offload orchestration logic
- **registry/**: Model discovery and database
- **backends/**: Support for Ollama, llama.cpp, vLLM, TGI
- **api/**: Rust REST API for unified control (port 9000)

**Configuration**:
```nix
kernelcore.ml.offload = {
  enable = true;
  dataDir = "/var/lib/ml-offload";
  modelsPath = "/var/lib/ml-models";
};
```

**API Endpoints** (port 9000):
- `GET /health` - Health check
- `GET /vram/status` - VRAM usage
- `GET /models` - List available models
- `POST /inference` - Run inference

### Applications Layer

**Purpose**: Standalone ML applications with their own build systems

#### SecureLLM Bridge (formerly unified-llm)

Secure LLM proxy with enterprise-grade security features.

**Features**:
- Unified API interface for multiple LLM providers
- TLS mutual authentication
- Rate limiting and audit logging
- Support for DeepSeek, OpenAI, Anthropic, Ollama
- Local ML integration via offload API

**Documentation**: See `applications/securellm-bridge/CLAUDE.md`

**Build**:
```bash
cd /etc/nixos/modules/ml/applications/securellm-bridge
nix build
nix develop
```

### Integrations Layer

**Purpose**: External integrations and editor plugins

#### MCP Server

Model Context Protocol server for IDE integration (Roo Code, Cline, Claude Desktop).

**Tools Available**:
- provider_test, security_audit, rate_limit_check
- build_and_test, provider_config_validate
- create_session, save_knowledge, search_knowledge

**Configuration**:
```nix
kernelcore.ml.mcp = {
  enable = true;
  mcpServerPath = "/etc/nixos/modules/ml/integrations/mcp/server";
  knowledgeDbPath = "/var/lib/mcp-knowledge/knowledge.db";
};
```

## Usage Examples

### Running LLaMA Inference

```bash
# Check service status
systemctl status llamacpp

# Test inference
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Ollama GPU Management

```bash
# Check loaded models
ollama-status

# Manually unload from GPU
ollama-unload

# List available models
ollama list
```

### ML Offload API

```bash
# Check VRAM status
curl http://localhost:9000/vram/status

# List models
curl http://localhost:9000/models
```

### Model Storage

```bash
# View models
ml-ls

# Check disk usage
ml-du

# Clean cache
ml-clean-cache
```

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────┐
│  External Requests                                  │
│  (OpenAI API, CLI, IDE)                             │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│  SecureLLM Bridge (applications/)                   │
│  - Security layer (TLS, rate limiting, audit)       │
│  - Provider routing                                 │
└────────────────┬────────────────────────────────────┘
                 │
        ┌────────┼────────┐
        │                 │
┌───────▼──────┐  ┌──────▼──────────────────────────┐
│ Cloud APIs   │  │ Local Inference (orchestration/) │
│ (DeepSeek,   │  │ - Offload manager                │
│  OpenAI,     │  │ - Model registry                 │
│  Anthropic)  │  │ - Backend selection              │
└──────────────┘  └──────┬───────────────────────────┘
                         │
                  ┌──────┴──────┐
                  │             │
         ┌────────▼───┐  ┌─────▼──────┐
         │ llama.cpp  │  │  Ollama    │
         │ (services/)│  │ (services/)│
         └────────────┘  └────────────┘
                  │             │
                  └──────┬──────┘
                         │
              ┌──────────▼──────────┐
              │ GPU / VRAM          │
              │ (infrastructure/)   │
              └─────────────────────┘
```

### Resource Management

- **Storage** (infrastructure/): Centralized model storage paths
- **VRAM** (infrastructure/vram/): Monitoring and allocation
- **Services**: Request GPU through infrastructure layer
- **Orchestration**: Coordinates multi-backend access
- **Applications**: High-level API for end users

## Development

### Adding a New ML Service

1. Create module in `services/my-service.nix`
2. Add to `services/default.nix` imports
3. Configure systemd service
4. Add VRAM monitoring if GPU-accelerated
5. Register with offload manager if supporting orchestration

### Adding a Backend

1. Create backend in `orchestration/backends/my-backend.nix`
2. Implement standard interface
3. Add to `orchestration/backends/default.nix`
4. Update API to support new backend

## Troubleshooting

### VRAM Issues

```bash
# Check VRAM usage
nvidia-smi

# Check offload API status
curl http://localhost:9000/vram/status

# Force unload Ollama models
ollama-unload
```

### Service Failures

```bash
# Check llama.cpp logs
journalctl -xeu llamacpp

# Check Ollama logs
journalctl -xeu ollama

# Check offload API logs
journalctl -xeu ml-offload-api
```

### Storage Issues

```bash
# Check storage monitor
systemctl status ml-storage-monitor

# Check disk space
df -h /var/lib/ml-models
```

## Migration Notes

**From Old Structure** (pre-2025-11-26):

The ML modules were reorganized for better modularity:

- `llama.nix` → `services/llama-cpp.nix`
- `models-storage.nix` → `infrastructure/storage.nix`
- `ollama-gpu-manager.nix` → `services/ollama/gpu-manager.nix`
- `offload/` → `orchestration/`
- `unified-llm/` → `applications/securellm-bridge/`
- `mcp-config/` + `unified-llm/mcp-server/` → `integrations/mcp/`

**Import Change**:
```nix
# Old (multiple imports)
./modules/ml/llama.nix
./modules/ml/models-storage.nix
./modules/ml/ollama-gpu-manager.nix
./modules/ml/offload
./modules/ml/mcp-config

# New (single import)
./modules/ml
```

## Contributing

See `/etc/nixos/docs/ML-MODULES-RESTRUCTURE-PLAN.md` for architectural decisions and migration details.

## License

Part of the NixOS configuration repository.

---

**Last Updated**: 2025-11-26
**Maintained By**: kernelcore
**Version**: 2.0.0 (Post-restructure)
