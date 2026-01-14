# Container Kits Usage Guide

Quick start guide for using the new ML/AI and Development container kits.

## Quick Start

### 1. Enable ML Containers

Add to your `hosts/kernelcore/configuration.nix`:

```nix
{
  # Enable ML container infrastructure
  kernelcore.containers.ml = {
    enable = true;

    # Ollama (LLM inference)
    ollama = {
      enable = true;
      port = 11434;
      modelsPath = "/var/lib/ollama/models";
    };

    # Jupyter Lab (ML development)
    jupyter = {
      enable = true;
      port = 8888;
      notebooksPath = "/home/kernelcore/dev/notebooks";
    };
  };
}
```

### 2. Enable Development Containers

```nix
{
  # Enable dev container infrastructure
  kernelcore.containers.dev = {
    enable = true;

    # Development ML environment
    dev-ml = {
      enable = true;
      port = 8889;
      workspacePath = "/home/kernelcore/dev/workspace";
    };

    # PostgreSQL database
    postgres = {
      enable = true;
      port = 5432;
      dataPath = "/var/lib/postgres-dev";
    };
  };
}
```

### 3. Rebuild System

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

## Common Usage Patterns

### ML/AI Workloads

#### Ollama LLM Inference

```bash
# Check Ollama status
ml-ollama-status

# Enter container
ml-ollama-enter

# List models via API
ollama-list

# Pull a model (from host)
curl -X POST http://192.168.200.11:11434/api/pull -d '{"name": "llama2"}'
```

#### Jupyter Lab

```bash
# Start Jupyter
ml-jupyter-start

# Get Jupyter token
nixos-container run ml-jupyter -- jupyter-lab list

# Access at: http://192.168.200.12:8888
```

#### ComfyUI Image Generation

```bash
# Enable in configuration.nix
kernelcore.containers.ml.comfyui.enable = true;

# Rebuild
sudo nixos-rebuild switch

# Access at: http://192.168.200.13:8188
```

### Development Workflows

#### Full Stack Development

```bash
# Enable dev-ml, postgres, and code-server
kernelcore.containers.dev = {
  enable = true;
  dev-ml.enable = true;
  postgres.enable = true;
  code-server.enable = true;
};

# Access services:
# - Code Server: http://192.168.210.13:8443
# - Dev-ML Jupyter: http://192.168.210.11:8889
# - PostgreSQL: 192.168.210.15:5432
```

#### Database Development

```bash
# Connect to PostgreSQL
dev-pg-psql

# From container shell
nixos-container root-login dev-postgres
psql -U devuser -d devdb
```

#### Chat UI Development

```bash
# Enable chat-ui
kernelcore.containers.dev.chat-ui = {
  enable = true;
  port = 3000;
};

# Access at: http://192.168.210.12:3000
```

## Building Docker Images

### Build Single Image

```bash
# Build Ollama image
nix build .#image-ollama

# Load into Docker
docker load < result

# Verify
docker images | grep ollama
```

### Build All Images

```bash
# Use the automated script
/etc/nixos/scripts/build-container-images.sh --all

# Or build specific image
/etc/nixos/scripts/build-container-images.sh image-python-ml
```

### Push to Registry

```bash
# Tag image
docker tag ghcr.io/voidnxlabs/ollama:latest ghcr.io/voidnxlabs/ollama:v1.0.0

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push
docker push ghcr.io/voidnxlabs/ollama:v1.0.0
```

## Advanced Configuration

### Custom Network Configuration

```nix
# Override network base (in module)
# Default ML network: 192.168.200.0/24
# Default Dev network: 192.168.210.0/24

# To change, edit:
# - /etc/nixos/modules/containers/ml-containers.nix
# - /etc/nixos/modules/containers/dev-containers.nix
```

### GPU Memory Limits

```nix
# Add to container config
environment.variables = {
  CUDA_VISIBLE_DEVICES = "0";  # Use first GPU only
  PYTORCH_CUDA_ALLOC_CONF = "max_split_size_mb:512";
};
```

### Resource Limits (systemd)

```nix
# Add to container definition
systemd.services."container@ml-ollama" = {
  serviceConfig = {
    MemoryMax = "16G";
    CPUQuota = "400%";  # 4 cores
  };
};
```

## Monitoring

### Container Status

```bash
# All ML containers
ml-status-all

# All dev containers
dev-status-all

# Specific container
nixos-container status ml-ollama
```

### Resource Usage

```bash
# CPU/Memory usage
systemd-cgtop

# GPU usage (in GPU containers)
nixos-container run ml-ollama -- nvidia-smi
```

### Logs

```bash
# Follow logs
journalctl -u container@ml-ollama -f

# Last 100 lines
journalctl -u container@ml-jupyter -n 100

# Since boot
journalctl -u container@dev-postgres -b
```

## Integration Examples

### Ollama + Chat UI

```nix
{
  kernelcore.containers.ml.ollama.enable = true;
  kernelcore.containers.dev.chat-ui = {
    enable = true;
    port = 3000;
  };

  # Configure Chat UI to use Ollama
  # Edit in container: /opt/chat-ui/.env
  # OLLAMA_API_BASE=http://192.168.200.11:11434
}
```

### Jupyter + PostgreSQL

```nix
{
  kernelcore.containers.ml.jupyter.enable = true;
  kernelcore.containers.dev.postgres.enable = true;

  # Connect from Jupyter:
  # import psycopg2
  # conn = psycopg2.connect(
  #     host="192.168.210.15",
  #     port=5432,
  #     database="devdb",
  #     user="devuser",
  #     password="devpass"
  # )
}
```

### vLLM + Code Server

```nix
{
  kernelcore.containers.ml.vllm.enable = true;
  kernelcore.containers.dev.code-server.enable = true;

  # Access vLLM API from Code Server:
  # curl http://192.168.200.14:8000/v1/models
}
```

## Troubleshooting

### Container Won't Start

```bash
# Check systemd status
systemctl status container@ml-ollama

# Check for errors
journalctl -u container@ml-ollama -p err

# Manually start
nixos-container start ml-ollama

# Check configuration
nixos-container show-ip ml-ollama
```

### Network Connectivity Issues

```bash
# Test from host to container
ping 192.168.200.11

# Test from container to internet
nixos-container run ml-ollama -- ping 8.8.8.8

# Check NAT rules
sudo iptables -t nat -L -n -v | grep 192.168.200
```

### GPU Not Available

```bash
# Verify host GPU
nvidia-smi

# Check container GPU
nixos-container run ml-ollama -- nvidia-smi

# Verify device binds
ls -la /var/lib/nixos-containers/ml-ollama/dev/nvidia*

# Check permissions
nixos-container run ml-ollama -- ls -la /dev/nvidia*
```

### Port Already in Use

```bash
# Find what's using the port
sudo lsof -i :11434

# Change port in configuration
kernelcore.containers.ml.ollama.port = 11435;

# Rebuild
sudo nixos-rebuild switch
```

## Migration from Docker Compose

### Converting docker-compose.yml

Example: Migrating Ollama from docker-compose to NixOS container

**Before (docker-compose.yml):**
```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

**After (NixOS config):**
```nix
{
  kernelcore.containers.ml.ollama = {
    enable = true;
    port = 11434;
    modelsPath = "/var/lib/ollama/models";
  };
}
```

## Performance Tips

1. **Use SSD for container data**: Mount bind paths on SSD
2. **Increase shared memory**: For ML workloads, increase `/dev/shm`
3. **Pin CPU cores**: Use `systemd.services.*.serviceConfig.CPUAffinity`
4. **Use hugepages**: For large memory workloads
5. **Optimize network**: Use host network mode for low latency (trade-off: less isolation)

## Security Best Practices

1. **Don't expose containers directly**: Use reverse proxy (dev-proxy)
2. **Change default passwords**: Especially for postgres, code-server
3. **Use private networks**: Keep container networks isolated
4. **Regular updates**: Rebuild containers with updated packages
5. **Audit access**: Monitor who accesses containers

## Next Steps

- Explore `/etc/nixos/modules/containers/README.md` for detailed documentation
- Build custom images using `/etc/nixos/lib/packages.nix` as reference
- Create custom container modules following the established patterns
- Integrate with CI/CD for automated image builds
- Set up monitoring with Prometheus + Grafana

## See Also

- [Container Modules README](/etc/nixos/modules/containers/README.md)
- [Docker Image Builder Script](/etc/nixos/scripts/build-container-images.sh)
- [NixOS Containers Manual](https://nixos.org/manual/nixos/stable/#ch-containers)
