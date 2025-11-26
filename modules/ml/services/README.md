# ML Services Layer

Systemd services for ML inference: llama.cpp and Ollama.

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

### ollama/

Ollama service with automatic GPU memory management.

#### service.nix (Base Service)

Standard Ollama service configuration.

```nix
services.ollama = {
  enable = true;
  # Standard Ollama configuration
};
```

#### gpu-manager.nix

Automatic GPU memory management for Ollama.

**Configuration**:
```nix
services.ollama-gpu-manager = {
  enable = true;
  unloadOnShellExit = true;   # Trap shell exit
  idleTimeout = 300;           # 5 minutes
  monitoringInterval = 30;     # Check every 30s
};
```

**Features**:
- Auto-unload models after idle timeout
- Shell exit hook for cleanup
- Idle detection and offloading
- Manual unload command: `ollama-unload`

**Aliases**:
- `ollama-unload` - Manually unload models from GPU
- `ollama-status` - Check loaded models (JSON)
- `ollama-models` - List available models

**Service**:
```bash
# Check idle monitor
systemctl status ollama-gpu-idle-monitor

# Logs
journalctl -xeu ollama-gpu-idle-monitor
```

## Architecture

```
User Request
     │
     ▼
┌─────────────────┐
│ llama.cpp       │  Port 8080
│ or              │
│ Ollama          │  Port 11434
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

### Ollama

```bash
# List models
ollama list

# Run model
ollama run llama3.2

# Check status
ollama-status

# Unload from GPU
ollama-unload
```

## Troubleshooting

### VRAM Issues

```bash
# Check VRAM
nvidia-smi

# Unload Ollama
ollama-unload

# Restart llama.cpp
systemctl restart llamacpp
```

### Service Won't Start

```bash
# Check logs
journalctl -xeu llamacpp
journalctl -xeu ollama

# Check GPU access
ls -l /dev/nvidia*

# Verify model file exists
ls -l /var/lib/ml-models/llamacpp/models/
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Infrastructure: [infrastructure/README.md](../infrastructure/README.md)
- Orchestration: [orchestration/README.md](../orchestration/README.md)
