# ML Modules - Machine Learning Infrastructure

Modular ML infrastructure for NixOS with VRAM management, model orchestration, and secure LLM access.

## Structure

```
modules/ml/
├── default.nix                    # Main aggregator
├── infrastructure/                # Base Infrastructure
│   ├── storage.nix               # Model storage paths
│   ├── vram/                     # GPU VRAM monitoring
│   └── hardware/                 # Hardware-specific configs
├── services/                      # ML Inference Services
│   ├── llama-cpp-turbo.nix       # LLaMA C++ (CUDA optimized)
│   └── vllm.nix                  # vLLM high-performance server
├── orchestration/                 # Offload & Orchestration
│   ├── manager.nix               # Rust REST API (port 9000)
│   ├── registry/                 # Model database
│   ├── backends/                 # Backend drivers
│   │   └── vllm-driver.nix       # vLLM integration
│   └── api/                      # Rust API source
└── integrations/                  # External Integrations
    ├── mcp/                      # Model Context Protocol
    └── neovim/                   # Editor integration
```

## Quick Start

```nix
# flake.nix - import ML modules
{
  outputs = { self, nixpkgs }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [ ./modules/ml ];  # Single import
    };
  };
}
```

## Configuration

### Model Storage

```nix
kernelcore.ml.models-storage.enable = true;
kernelcore.ml.models-storage.baseDirectory = "/var/lib/ml-models";
```

### LLaMA.cpp (CUDA Optimized)

```nix
services.llamacpp-turbo = {
  enable = true;
  model = "/var/lib/ml-models/llama-cpp/DeepSeek-R1-8B-Q4_K_M.gguf";
  n_gpu_layers = 30;
  flashAttention = true;
  n_ctx = 8192;
};
```

### vLLM Server

```nix
services.vllm = {
  enable = true;
  model = "meta-llama/Llama-3.1-8B-Instruct";
  tensorParallelSize = 1;
  gpuMemoryUtilization = 0.90;
  quantization = "awq";  # Optional
};
```

### Orchestration API

```nix
kernelcore.ml.offload = {
  enable = true;
  dataDir = "/var/lib/ml-offload";
};

kernelcore.ml.offload.api = {
  enable = true;
  port = 9000;
};
```

## Commands

```bash
# LLaMA.cpp
systemctl status llamacpp-turbo
curl http://127.0.0.1:8080/v1/chat/completions

# vLLM
vllm-status        # Backend status
vllm-health        # Health check
vllm-models        # List loaded models

# Offload API
ml-status          # System status
ml-models          # List all models
ml-backends        # List backends
```

## API Endpoints (port 9000)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/vram/status` | GET | VRAM usage |
| `/models` | GET | List models |
| `/backends` | GET | List backends |
| `/status` | GET | Real-time status |

---

**Last Updated**: 2025-12-16  
**Version**: 3.0.0 (Post-reorganization)
