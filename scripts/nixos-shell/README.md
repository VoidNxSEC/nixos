# NixOS Shell Module

Sistema modular de aliases, scripts e automação para NixOS.

## Estrutura

```
/etc/nixos/modules/shell/
├── default.nix                 # Este arquivo (orquestrador)
├── gpu-flags.nix               # Flags GPU testadas
├── aliases/
│   ├── default.nix             # Agregador de aliases
│   ├── docker/                 # Docker aliases
│   ├── kubernetes/             # Kubernetes aliases
│   ├── gcloud/                 # GCloud aliases
│   ├── ai/                     # AI/ML aliases
│   ├── nix/                    # Nix system aliases
│   └── system/                 # System utilities
└── scripts/
    └── python/
        ├── gpu_monitor.py      # Monitor GPU
        └── model_manager.py    # Gerenciador modelos
```

## Uso

### GPU Flags
Flags testadas e documentadas em `gpu-flags.nix`:
```bash
--device=nvidia.com/gpu=all
--ipc=host
--ulimit stack=67108864
--shm-size=8g
```

### Docker Build/Run
```bash
# Build com tag automática
dbuild-tag myapp

# Run com GPU
drun-gpu pytorch/pytorch:latest

# Test GPU
dgpu-test
```

### GPU Monitoring
```bash
# Monitor interativo
gpu-monitor

# JSON output
gpu-monitor-json

# Summary
gpu-monitor-summary
```

### Model Management
```bash
# Buscar modelos
model-search llama

# Instalar
model-install llama3.2        # Ollama
model-install meta-llama/Llama-2-7b  # HuggingFace

# Listar
model-list

# Remover
model-remove llama3.2
```

## Customização

Para adicionar novos aliases, edite:
- `aliases/docker/` para Docker
- `aliases/kubernetes/` para Kubernetes
- `aliases/*/default.nix` para aliases gerais de cada categoria

Para adicionar scripts Python:
1. Adicione em `scripts/python/`
2. Registre em `environment.etc` no `default.nix`
3. Crie alias em `environment.shellAliases`

## Flags GPU - Referência

Documentação completa: `gpu-flags.nix`

Problemas comuns e soluções:
- CUDA out of memory → Aumentar `--shm-size`
- DataLoader crashes → Adicionar `--ipc=host`
- Stack overflow → `--ulimit stack=67108864` obrigatório

## Suporte

Arquivos de log:
- Docker: `docker logs <container>`
- System: `journalctl -u docker`
- GPU: `nvidia-smi dmon`
