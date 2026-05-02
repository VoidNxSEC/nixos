# ML Infrastructure Layer

Base infrastructure for ML operations: storage management, VRAM monitoring, and hardware configurations.

## Components

### storage.nix

Standardized model storage structure with automatic directory creation.

**Configuration**:
```nix
kernelcore.ml.models-storage = {
  enable = true;
  baseDirectory = "/var/lib/ml-models";  # Default
};
```

**Directory Structure**:
```
/var/lib/ml-models/
├── llamacpp/models/      # GGUF models
├── ollama/models/        # Ollama models
├── huggingface/          # HF cache
├── gguf/                 # Generic GGUF
├── vllm/                 # vLLM models
├── tgi/                  # Text Generation Inference
├── custom/               # Fine-tuned models
├── conversion/           # Conversion workspace
└── cache/                # Shared cache
```

**Environment Variables**:
- `ML_MODELS_BASE`
- `LLAMACPP_MODELS_PATH`
- `OLLAMA_MODELS_PATH`
- `HF_HOME`, `HF_HUB_CACHE`

**Aliases**:
- `ml-models` - Navigate to models directory
- `ml-ls` - List models with tree view
- `ml-du` - Disk usage by directory
- `ml-clean-cache` - Clean cache directory

### vram/monitoring.nix

VRAM monitoring and metrics collection.

**Features**:
- Real-time VRAM usage tracking
- Budget planning and alerts
- Integration with offload manager
- Metrics export for monitoring systems

### vram/scheduler.nix

**Status**: Planned (Future Enhancement)

Central GPU allocation scheduler.

**Planned Features**:
- Single source of truth for GPU allocation
- Priority-based scheduling
- Automatic load balancing
- Resource quotas per service

### hardware/cuda.nix

**Status**: Planned (Future Enhancement)

CUDA and GPU-specific configurations.

## Usage

```bash
# Check model storage
ml-ls

# View disk usage
ml-du

# Clean cache
ml-clean-cache

# Check VRAM (if monitoring enabled)
nvidia-smi
```

## See Also

- Parent: [modules/ml/README.md](../README.md)
- Services using this: [services/README.md](../services/README.md)
