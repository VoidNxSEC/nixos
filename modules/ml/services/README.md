# ML Services Layer

Systemd services for ML inference with llama.cpp (CUDA-optimized).

## Components

### llama-cpp.nix

LLaMA C++ server with CUDA support.

**Configuration**:
```nix
services.llamacpp = {
  enable = true;
  model = "/var/lib/ml-models/llamacpp/models/my-model.gguf";
  host = "127.0.0.1";
  port = 8080;
  n_threads = 6;
  n_gpu_layers = 35;     # Adjust based on GPU VRAM
  n_parallel = 1;
  n_ctx = 4096;
  n_batch = 2048;
  extraFlags = [];        # Additional llama-server flags
  openFirewall = false;
};
```

**Service Management**:
```bash
# Status
systemctl status llamacpp

# Logs
journalctl -xeu llamacpp

# Restart
systemctl restart llamacpp
```

**Testing**:
```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}]}'
```

**Features**:
- CUDA GPU acceleration
- OpenAI-compatible API
- Systemd hardening (sandboxed)
- Graceful shutdown for GPU release


## Architecture

```
User Request
     │
     ▼
┌─────────────────┐
│ llama.cpp       │  Port 8080
└────────┬────────┘
         │
         ▼
   GPU (CUDA)
```

## Usage Examples

### LLaMA C++

```bash
# Chat completion
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [{"role": "user", "content": "Explain ML"}],
    "temperature": 0.7
  }'
```

## Troubleshooting

### VRAM Issues

```bash
# Check VRAM
nvidia-smi

# Restart llama.cpp to

 free VRAM
systemctl restart llamacpp
```

### Service Won't Start

```bash
# Check logs
journalctl -xeu llamacpp

# Check GPU access
ls -l /dev/nvidia*

# Verify model file exists
ls -l /var/lib/ml-models/llamacpp/models/
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Infrastructure: [infrastructure/README.md](../infrastructure/README.md)
- Orchestration: [orchestration/README.md](../orchestration/README.md)
