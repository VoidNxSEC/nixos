# Hybrid Configuration

Ultimate NixOS setup combining desktop environment, binary cache server, and distributed build support.

## What You Get

### Desktop Environment
- **i3 window manager** - Lightweight, tiling
- **LightDM** - Fast display manager
- **Essential apps** - Firefox, Vivaldi, Thunar, Alacritty
- **Development tools** - Git, Neovim, CMake, GCC, Python

### Binary Cache Server
- **nix-serve** - Binary cache with signing
- **Nginx proxy** - HTTPS access
- **Resource limits** - OOM protection
- **Health monitoring** - Automated checks

### Distributed Builds
- **Remote builders** - Offload to powerful servers
- **SSH offloading** - Secure build distribution
- **MCP automation** - Intelligent offload management
- **Cache bucket** - S3-compatible storage

### Performance Optimizations
- **ZRAM** - 25% RAM for compressed swap
- **Kernel tuning** - VM parameters optimized
- **Auto-optimize store** - Deduplication enabled
- **Memory management** - Low swappiness, efficient caching

## Quick Start

```bash
# 1. Deploy configuration
sudo nixos-rebuild switch --flake /path/to/nixtrap#hybrid

# 2. Configure remote builders (optional)
# Edit offload-client.nix with your builder details

# 3. Test cache server
cache-server-status
curl http://localhost:5000/nix-cache-info

# 4. Test distributed build
nix-build '<nixpkgs>' -A hello
```

## System Requirements

### Minimum
- 4 CPU cores
- 8GB RAM
- 100GB SSD

### Recommended
- 8+ CPU cores
- 16GB+ RAM
- 500GB+ NVMe SSD
- 1Gbps network

## Use Cases

### Development Workstation
- Full desktop environment for daily work
- Local cache for faster rebuilds
- Offload heavy builds to remote servers

### Home Server + Desktop
- Serve binary cache to other machines
- Use as daily driver
- Distribute builds across home network

### CI/CD Node
- Desktop GUI for debugging
- Cache artifacts locally
- Offload builds to build farm

## Configuration Locations

```
/etc/nixos/
├── configuration.nix          # Main config
├── hardware-configuration.nix # Hardware auto-detection
├── cache-keys/                # Binary cache signing keys
│   ├── cache-priv-key.pem
│   └── cache-pub-key.pem
└── certs/                     # SSL certificates
    ├── server.crt
    └── server.key
```

## Management Commands

### System Management
```bash
# Rebuild system
sudo nixos-rebuild switch

# Update flake inputs
nix flake update

# Garbage collection
nix-collect-garbage -d
```

### Cache Server
```bash
cache-server-status   # Check status
cache-server-restart  # Restart services
cache-server-logs     # View logs
```

### Distributed Builds
```bash
# Test remote builder
nix store ping --store ssh://builder@remote

# Force remote build
nix-build '<nixpkgs>' -A hello --max-jobs 0
```

### Desktop
```bash
# Theme management
theme-toggle
theme-dark
theme-light

# System info
status
hwinfo
```

## Customization

### Adjust Memory Limits

Edit cache-server.nix:
```nix
# For systems with more RAM
MemoryMax = "4G";
MemoryHigh = "3.5G";
```

### Add Remote Builders

Edit offload-client.nix:
```nix
nix.buildMachines = [
  {
    hostName = "builder.example.com";
    system = "x86_64-linux";
    maxJobs = 8;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }
];
```

### Configure Cache Bucket

Edit cache-bucket-setup.nix to use S3-compatible storage.

## Troubleshooting

### Desktop Won't Start

```bash
# Check display manager
systemctl status lightdm

# View X logs
cat /var/log/X.0.log

# Test i3 manually
startx
```

### Cache Server Issues

```bash
# Check services
systemctl status nix-serve nginx

# Test locally
curl http://localhost:5000/nix-cache-info

# Check signing keys
ls -la /etc/nixos/cache-keys/
```

### Distributed Builds Not Working

```bash
# Test SSH connection
ssh builder@remote

# Check nix-daemon logs
journalctl -u nix-daemon -f

# Verify builder config
cat /etc/nix/machines
```

### High Memory Usage

```bash
# Check zram
zramctl

# Monitor processes
htop

# Reduce cache workers
# Edit cache-server.nix, set workers = 2
```

## Performance Tips

1. **Use SSD/NVMe** for Nix store
2. **Enable ZRAM** for systems <16GB RAM
3. **Tune GC settings** based on disk space
4. **Offload to remote** for large builds
5. **Monitor resources** with `htop` and `btop`
6. **Keep system updated** regularly

## Security Considerations

- SSH keys for remote builds stored securely
- Cache signing keys backed up regularly
- Firewall restricts external access
- systemd hardening applied to services
- Regular security updates via `nixos-rebuild`

## Backup Strategy

```bash
# Backup important data
sudo tar czf /backup/nixos-config.tar.gz \
  /etc/nixos/configuration.nix \
  /etc/nixos/cache-keys/ \
  /etc/nixos/certs/

# Backup user data
rsync -av /home/voidnx/ /backup/home-voidnx/
```

## Further Reading

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Binary Cache Guide](https://nixos.wiki/wiki/Binary_Cache)
- [Distributed Builds](https://nixos.wiki/wiki/Distributed_build)
