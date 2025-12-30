# ML Orchestration Layer

Multi-backend orchestration, model registry, and unified ML offload system.

## Overview

The orchestration layer provides:
- **Offload Manager**: Coordinate inference across multiple backends
- **Model Registry**: Discover and track available models
- **Multi-Backend Support**: llama.cpp, vLLM, TGI
- **REST API**: Unified control interface (port 9000)

## Components

### manager.nix

Offload orchestration logic and coordination.

### registry/

Model discovery and database management.

**database.nix**: SQLite registry for models
**discovery.nix**: Planned - Automatic model discovery (future enhancement)

### backends/

Support for multiple inference backends.

**Available Backends**:
- **llamacpp.nix**: llama.cpp backend (primary, production-ready)
- **vllm.nix**: Planned - vLLM backend for high-throughput scenarios
- **tgi.nix**: Planned - Text Generation Inference for production deployments

### Implementation Status

**Production Ready**:
- ✅ **llamacpp.nix** - llama.cpp backend with CUDA optimization and VRAM monitoring

**Planned (Future Enhancements)**:
- 📋 **vllm.nix** - Will be added when high-throughput is required
- 📋 **tgi.nix** - Will be added for production deployments
- 📋 **discovery.nix** - Automatic model registry discovery

### api/

Rust REST API for unified ML operations.

**Endpoints** (Port 9000):
- `GET /health` - Health check
- `GET /vram/status` - VRAM usage and availability
- `GET /models` - List registered models
- `POST /inference` - Run inference request
- `GET /backends` - List available backends

**Build**:
```bash
cd /etc/nixos/modules/ml/orchestration/api
cargo build --release
```

## Configuration

```nix
kernelcore.ml.offload = {
  enable = true;
  dataDir = "/var/lib/ml-offload";         # Data directory
  modelsPath = "/var/lib/ml-models";       # Models path
};
```

**Auto-enables**:
- `kernelcore.ml.models-storage.enable` (infrastructure)
- `kernelcore.system.ml-gpu-users.enable` (ml-offload user)

**Python Environment**:
Includes: fastapi, uvicorn, pydantic, aiohttp, psutil, nvidia-ml-py

## Architecture

```
┌─────────────────────────────────────────┐
│  Offload Manager                        │
│  - Request routing                      │
│  - Load balancing                       │
│  - VRAM awareness                       │
└────────────┬────────────────────────────┘
             │
     ┌───────┼───────┐
     │       │       │
┌────▼──┐ ┌──▼───┐ ┌▼────┐
│Llama  │ │      │ │vLLM │
│cpp    │ │      │ │     │
└───────┘ └──────┘ └─────┘
     │       │       │
     └───────┼───────┘
             │
        ┌────▼────┐
        │   GPU   │
        └─────────┘
```

## Usage

### REST API

```bash
# Health check
curl http://localhost:9000/health

# VRAM status
curl http://localhost:9000/vram/status

# List models
curl http://localhost:9000/models

# List backends
curl http://localhost:9000/backends

# Run inference
curl http://localhost:9000/inference \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2",
    "prompt": "Explain quantum computing",
    "backend": "llamacpp"
  }'
```

### Service Management

```bash
# Check offload service
systemctl status ml-offload-api

# Logs
journalctl -xeu ml-offload-api

# Restart
systemctl restart ml-offload-api
```

### Model Registry

```bash
# List registered models
curl http://localhost:9000/models | jq

# Check specific model
curl http://localhost:9000/models/llama3.2 | jq
```

## Backend Selection

The offload manager automatically selects backends based on:

1. **Model Availability**: Which backends have the model
2. **VRAM Availability**: Current GPU memory state
3. **Backend Load**: Current request queue
4. **Model Size**: Match model to backend capacity

**Priority Order** (default):
1. llama.cpp (primary, VRAM-aware)
2. vLLM (for high-throughput scenarios)
3. TGI (for production deployments)

## Integration with Applications

### SecureLLM Bridge

The SecureLLM Bridge can use the offload API as a local provider:

```rust
// In SecureLLM Bridge
pub struct LocalProvider {
    offload_api_url: String,  // http://localhost:9000
}

impl LocalProvider {
    async fn inference(&self, request: ChatRequest) -> Result<ChatResponse> {
        // Check VRAM
        let vram = self.client.get("/vram/status").await?;

        // Route to offload API
        self.client.post("/inference")
            .json(&request)
            .send()
            .await
    }
}
```

## Development

### Adding a New Backend

1. Create `backends/mybackend.nix`
2. Implement backend interface:
   ```nix
   {
     name = "mybackend";
     models = [ "model1" "model2" ];
     healthCheck = "curl http://localhost:PORT/health";
     inference = {
       endpoint = "http://localhost:PORT/api";
       format = "openai";  # or "custom"
     };
   }
   ```
3. Add to `backends/default.nix` imports
4. Update API to register backend

### Testing

```bash
# Build API
cd api/
cargo build

# Run tests
cargo test

# Start API manually
cargo run
```

## Troubleshooting

### API Won't Start

```bash
# Check logs
journalctl -xeu ml-offload-api

# Check port availability
ss -tlnp | grep 9000

# Check Python environment
python3 -c "import fastapi, uvicorn, pydantic"
```

### VRAM Issues

```bash
# Check VRAM via API
curl http://localhost:9000/vram/status

# Check directly
nvidia-smi

# Restart llama.cpp to free VRAM
systemctl restart llamacpp-turbo
```

### Backend Not Available

```bash
# Check backend services
systemctl status llamacpp-turbo

# Check backend health
curl http://localhost:8080/health  # llama.cpp
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Services: [services/README.md](../services/README.md)
- Applications: [applications/README.md](../applications/README.md)
- API Docs: `api/README.md` (if exists)
