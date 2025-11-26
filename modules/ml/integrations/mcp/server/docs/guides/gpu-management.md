# GPU Management Guide
tags: [gpu, nvidia, cuda, ml, docker]

Comprehensive guide for managing NVIDIA GPUs in NixOS with security and isolation.

## GPU Access Patterns

### 1. Development Shells (Recommended)
```bash
# CUDA development
nix develop .#cuda
nvidia-smi  # Works (user in nvidia group)
```

### 2. Docker Containers
```bash
# Explicit GPU access
docker run --gpus all nvidia/cuda:12.0-base nvidia-smi

# CDI syntax
docker run --device=nvidia.com/gpu=all nvidia/cuda:12.0-base nvidia-smi
```

### 3. Systemd Services
```nix
systemd.services.myservice.serviceConfig = {
  DeviceAllow = [
    "/dev/nvidia0 rw"
    "/dev/nvidiactl rw"
    "/dev/nvidia-uvm rw"
  ];
  SupplementaryGroups = [ "nvidia" ];
  Environment = [
    "CUDA_VISIBLE_DEVICES=0"
  ];
};
```

## Common Issues

**Issue**: `nvidia-smi` fails with permission denied
**Fix**: Add user to `nvidia` group:
```bash
sudo usermod -a -G nvidia $USER
# Re-login required
```

**Issue**: Container doesn't see GPU
**Fix**: Use explicit flags: `--gpus all` or `--device=nvidia.com/gpu=all`

**Issue**: Service can't access GPU
**Fix**: Add `DeviceAllow` and `SupplementaryGroups` to serviceConfig

## Monitoring

```bash
# GPU status
nvidia-smi

# Continuous monitoring
watch -n 1 nvidia-smi

# GPU processes
nvidia-smi pmon

# GPU memory
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

## Security Best Practices

1. **Never** set `CUDA_VISIBLE_DEVICES` globally
2. **Always** use group-based access control
3. **Audit** GPU access with auditd rules
4. **Restrict** which services can access GPU
5. **Monitor** GPU usage regularly

## Reference

- NVIDIA module: `/etc/nixos/modules/hardware/nvidia.nix`
- CUDA shells: `/etc/nixos/lib/shells.nix`
- GPU orchestration: `/etc/nixos/modules/services/gpu-orchestration.nix`