# Container Modules Documentation

Declarative NixOS container infrastructure inspired by the ML-clusters kits pattern.

## Architecture Overview

```
/etc/nixos/modules/containers/
├── default.nix              # Module aggregator
├── docker.nix               # Docker runtime
├── podman.nix               # Podman runtime
├── nixos-containers.nix     # Base NixOS containers
├── docker-hub.nix           # Docker Hub integration
├── ml-containers.nix        # ✨ AI/ML workload containers
├── dev-containers.nix       # ✨ Development environment containers
├── k3s-cluster.nix          # Kubernetes cluster
└── longhorn-storage.nix     # Persistent storage
```

## ML/AI Containers (`ml-containers.nix`)

### Features

- **Ollama**: LLM inference with CUDA support
- **Jupyter Lab**: ML development environment
- **ComfyUI**: Stable Diffusion image generation
- **vLLM**: High-performance LLM inference
- **LocalAI**: Multi-modal AI inference

### Configuration

```nix
# hosts/kernelcore/configuration.nix
{
  kernelcore.containers.ml = {
    enable = true;

    # Enable individual containers
    ollama = {
      enable = true;
      port = 11434;
      modelsPath = "/var/lib/ollama/models";
    };

    jupyter = {
      enable = true;
      port = 8888;
      notebooksPath = "/home/kernelcore/dev/notebooks";
    };

    comfyui.enable = true;
    vllm.enable = true;
    localai.enable = true;
  };
}
```

### Network Layout

```
Network: 192.168.200.0/24
Host:    192.168.200.10

Containers:
├── ml-ollama      192.168.200.11:11434
├── ml-jupyter     192.168.200.12:8888
├── ml-comfyui     192.168.200.13:8188
├── ml-vllm        192.168.200.14:8000
└── ml-localai     192.168.200.15:8080
```

### Shell Aliases

```bash
# Individual container management
ml-ollama-enter      # Enter Ollama container
ml-ollama-status     # Check Ollama status
ml-ollama-start      # Start Ollama
ml-ollama-stop       # Stop Ollama

# Ollama-specific commands
ollama-list          # List models via API

# Bulk operations
ml-status-all        # Status of all ML containers
ml-start-all         # Start all ML containers
ml-stop-all          # Stop all ML containers
```

## Development Containers (`dev-containers.nix`)

### Features

- **Dev-ML**: Full ML development environment
- **Chat-UI**: LLM chat interface
- **Code-Server**: VS Code in browser
- **Proxy**: Caddy reverse proxy
- **PostgreSQL**: Development database

### Configuration

```nix
# hosts/kernelcore/configuration.nix
{
  kernelcore.containers.dev = {
    enable = true;

    dev-ml = {
      enable = true;
      port = 8889;
      workspacePath = "/home/kernelcore/dev/workspace";
    };

    chat-ui = {
      enable = true;
      port = 3000;
    };

    code-server = {
      enable = true;
      port = 8443;
      workspacePath = "/home/kernelcore/dev";
    };

    proxy = {
      enable = true;
      httpPort = 80;
      httpsPort = 443;
    };

    postgres = {
      enable = true;
      port = 5432;
      dataPath = "/var/lib/postgres-dev";
    };
  };
}
```

### Network Layout

```
Network: 192.168.210.0/24
Host:    192.168.210.10

Containers:
├── dev-ml           192.168.210.11:8889
├── dev-chat-ui      192.168.210.12:3000
├── dev-code-server  192.168.210.13:8443
├── dev-proxy        192.168.210.14:80,443
└── dev-postgres     192.168.210.15:5432
```

### Shell Aliases

```bash
# Dev-ML environment
dev-ml-enter         # Enter dev-ml container
dev-ml-start         # Start dev-ml

# Chat-UI
dev-chat-enter       # Enter chat-ui container
dev-chat-start       # Start chat-ui

# Code-Server
dev-code-enter       # Enter code-server
dev-code-start       # Start code-server

# PostgreSQL
dev-pg-enter         # Enter postgres container
dev-pg-psql          # Connect to psql
dev-pg-start         # Start postgres

# Bulk operations
dev-status-all       # Status of all dev containers
dev-start-all        # Start all dev containers
dev-stop-all         # Stop all dev containers
```

## Docker Images (`/etc/nixos/lib/packages.nix`)

### Building Images

```bash
# Build single image
nix build .#image-ollama
docker load < result

# Build all images (automated script)
/etc/nixos/scripts/build-container-images.sh --all

# Build specific image
/etc/nixos/scripts/build-container-images.sh image-ollama
```

### Available Images

| Image | Tag | Purpose |
|-------|-----|---------|
| `ghcr.io/voidnxlabs/app` | `dev` | Basic app template |
| `ghcr.io/voidnxlabs/cuda-runtime` | `cuda-12` | CUDA runtime base |
| `ghcr.io/voidnxlabs/ollama` | `latest` | Ollama with CUDA |
| `ghcr.io/voidnxlabs/python-ml` | `latest` | Python ML dev env |
| `ghcr.io/voidnxlabs/nodejs-dev` | `22` | Node.js development |
| `ghcr.io/voidnxlabs/go-dev` | `latest` | Go development |
| `ghcr.io/voidnxlabs/postgres-dev` | `16` | PostgreSQL 16 |
| `ghcr.io/voidnxlabs/nginx-proxy` | `latest` | Nginx reverse proxy |
| `ghcr.io/voidnxlabs/redis` | `latest` | Redis cache |

### Image Features

- **Reproducible**: Built from Nix, fully deterministic
- **Minimal**: Only necessary dependencies
- **Secure**: No unnecessary packages or services
- **GPU Support**: CUDA images include proper drivers

## GPU Passthrough

All ML containers support GPU passthrough:

```nix
bindMounts = {
  "/dev/nvidia0" = { hostPath = "/dev/nvidia0"; isReadOnly = false; };
  "/dev/nvidiactl" = { hostPath = "/dev/nvidiactl"; isReadOnly = false; };
  "/dev/nvidia-uvm" = { hostPath = "/dev/nvidia-uvm"; isReadOnly = false; };
};

allowedDevices = [
  { node = "/dev/nvidia0"; modifier = "rw"; }
  { node = "/dev/nvidiactl"; modifier = "rw"; }
  { node = "/dev/nvidia-uvm"; modifier = "rw"; }
];
```

## Common Workflows

### Starting ML Stack

```bash
# Enable in configuration.nix
kernelcore.containers.ml.enable = true;
kernelcore.containers.ml.ollama.enable = true;
kernelcore.containers.ml.jupyter.enable = true;

# Rebuild
sudo nixos-rebuild switch

# Check status
ml-status-all

# Access services
curl http://192.168.200.11:11434/api/tags  # Ollama
open http://192.168.200.12:8888            # Jupyter
```

### Starting Dev Stack

```bash
# Enable in configuration.nix
kernelcore.containers.dev.enable = true;
kernelcore.containers.dev.code-server.enable = true;
kernelcore.containers.dev.postgres.enable = true;

# Rebuild
sudo nixos-rebuild switch

# Access services
open http://192.168.210.13:8443            # Code Server
dev-pg-psql                                 # PostgreSQL
```

### Building and Pushing Images

```bash
# Build all images
/etc/nixos/scripts/build-container-images.sh --all

# Build specific image
nix build .#image-python-ml

# Load into Docker
docker load < result

# Push to registry
docker tag ghcr.io/voidnxlabs/python-ml:latest ghcr.io/voidnxlabs/python-ml:v1.0.0
docker push ghcr.io/voidnxlabs/python-ml:v1.0.0
```

## Troubleshooting

### Container Won't Start

```bash
# Check systemd status
systemctl status container@ml-ollama

# Check container logs
journalctl -u container@ml-ollama -f

# Manually start container
nixos-container start ml-ollama
```

### Network Issues

```bash
# Check NAT configuration
iptables -t nat -L -n -v

# Check routing
ip route show

# Test connectivity from container
nixos-container run ml-ollama -- ping 8.8.8.8
```

### GPU Not Detected

```bash
# Verify host GPU
nvidia-smi

# Check container GPU access
nixos-container run ml-ollama -- nvidia-smi

# Verify bind mounts
ls -la /var/lib/nixos-containers/ml-ollama/dev/
```

## Best Practices

1. **Use Private Networks**: Keep containers isolated
2. **Bind Mount Data**: Use host paths for persistent data
3. **Resource Limits**: Set memory/CPU limits in production
4. **Security**: Don't expose containers directly to internet
5. **Backups**: Backup bind mount paths regularly

## Integration with Docker Hub Project

The `docker-hub.nix` module integrates with the external docker-hub project:

```bash
# Located at: ~/dev/projects/docker-hub
# Orchestrator: ~/dev/projects/docker-hub/main.py

# Quick commands (when docker-hub.nix is enabled)
docker-hub ai          # Start AI stack
docker-hub gpu         # Start GPU stack
docker-hub status      # Show status
```

## See Also

- `/etc/nixos/lib/packages.nix` - Docker image definitions
- `/etc/nixos/scripts/build-container-images.sh` - Image builder
- NixOS Containers Manual: https://nixos.org/manual/nixos/stable/#ch-containers
- Docker Tools: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools
