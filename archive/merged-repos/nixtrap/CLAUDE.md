# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **unified NixOS configuration repository** combining two distinct approaches to NixOS binary cache server infrastructure:

- **nixtrap1**: Enterprise-grade cache server with Nix Flakes, modular architecture, templates, and monitoring
- **nixtrap2**: Production i3 desktop environment with distributed build offloading, MCP automation, and lightweight performance optimizations

## Architecture

### nixtrap1: Binary Cache Server Infrastructure

**Core Purpose**: Provide a reusable, modular, flake-based NixOS binary cache server solution

**Key Components**:
- `flake.nix` - Main flake with nixosConfigurations, modules, templates, and packages
- `modules/cache-server.nix` - Declarative binary cache server module with nix-serve
- `modules/api-server.nix` - REST API for cache metrics and monitoring
- `modules/monitoring.nix` - Prometheus, Node Exporter, and optional Grafana integration
- `templates/` - Ready-to-use flake templates (minimal and full)
- Dashboard (React/TypeScript/Vite) for real-time monitoring UI

**Design Philosophy**:
- Hardware-aware auto-configuration
- Progressive disclosure (simple to complex)
- Security-first defaults (TLS, signed cache, firewall)
- Observable (Prometheus metrics, REST API, health checks)

### nixtrap2: Production Desktop + Distributed Builds

**Core Purpose**: Lightweight i3 desktop with advanced build offloading and automation

**Key Components**:
- `flake.nix` - Desktop-focused flake with home-manager integration
- `configuration.nix` - Main system config (i3, LightDM, performance tuning)
- `home.nix` - User environment with Git GPG signing, aliases, shell configs
- `offload-server.nix` - SSH-based distributed build server configuration
- `laptop-offload-client.nix` - Laptop-side offload client setup
- `mcp-offload-automation.nix` - Model Context Protocol automation for offload management
- `cache-server.nix` - Simplified cache server for desktop use
- `cache-bucket-setup.nix` - S3-compatible cache bucket integration
- `nginx-module.nix` - Nginx reverse proxy for HTTPS cache access
- `nar-server.nix` - Custom NAR (Nix Archive) server implementation

**Design Philosophy**:
- Minimal resource usage (i3 vs KDE, LightDM vs SDDM)
- High memory optimization (zram, kernel tuning)
- Distributed build capabilities (remote builders, SSH offload)
- Developer-focused workflow (GPG signing, Git automation)

## Common Development Commands

### System Management

```bash
# Apply configuration (nixtrap2 pattern)
sudo nixos-rebuild switch --flake .#voidnx

# Test configuration without persistence
sudo nixos-rebuild test --flake .#voidnx

# Update flake inputs
nix flake update

# Garbage collection
nix-collect-garbage -d
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### Cache Server Operations

```bash
# Check nix-serve status
systemctl status nix-serve

# Restart cache services
sudo systemctl restart nix-serve
sudo systemctl restart nginx  # If using TLS

# View nix-serve logs
journalctl -u nix-serve -f

# Test cache server locally
curl http://localhost:5000/nix-cache-info

# Test via HTTPS (if nginx configured)
curl https://cache.local/nix-cache-info
```

### Distributed Build Management

```bash
# Check offload builder connectivity
nix store ping --store ssh://builder@remote-server

# Test remote build (nixtrap2 setup)
nix-build '<nixpkgs>' -A hello --option builders 'ssh://builder@remote-server'

# Monitor active builds
watch 'ps aux | grep nix-build'

# Check distributed build logs
journalctl -u nix-daemon -f
```

### Monitoring & Metrics

```bash
# Check Prometheus metrics (if monitoring enabled)
curl http://localhost:9090/metrics

# Check Node Exporter
curl http://localhost:9100/metrics

# API server metrics (nixtrap1)
curl http://localhost:8080/api/metrics | jq

# Cache server status
systemctl status nix-serve nginx prometheus node-exporter
```

### Development Workflow

```bash
# Format Nix files
nix fmt

# Check flake validity
nix flake check

# Show flake outputs
nix flake show

# Enter dev shell (if defined)
nix develop

# Build specific flake output
nix build .#cache-api-server
```

## Key Configuration Patterns

### Binary Cache Signing (nixtrap1 & nixtrap2)

Both repos use cryptographic signing for cache security:

```nix
# Keys typically stored in:
/var/cache-nix-serve/cache-priv-key.pem  # Private key
/var/cache-nix-serve/cache-pub-key.pem   # Public key

# Or in nixtrap2:
./cache-keys/cache-priv-key.pem
./cache-keys/cache-pub-key.pem
```

**IMPORTANT**: Always backup private keys before system changes!

### Flake Structure Differences

**nixtrap1** exports:
- `nixosModules.{cache-server, api-server, monitoring, default}`
- `nixosConfigurations.{cache-server-minimal, cache-server-full}`
- `templates.{minimal, full}`
- `packages.{cache-api-server, cache-bootstrap, dashboard}`

**nixtrap2** exports:
- `nixosConfigurations.voidnx` (single desktop configuration)
- Integrates home-manager directly
- No templates (monolithic config)

### Module Import Patterns

**nixtrap1** (modular):
```nix
imports = [
  ./hardware-configuration.nix
  ./modules/cache-server.nix
  ./modules/api-server.nix
  ./modules/monitoring.nix
];
```

**nixtrap2** (component-based):
```nix
imports = [
  ./hardware-configuration.nix
  ./cache-server.nix
  ./cache-bucket-setup.nix
  ./nginx-module.nix
  ./offload-server.nix
  ./mcp-offload-automation.nix
];
```

### Performance Optimizations (nixtrap2 specific)

```nix
# ZRAM configuration
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 25;
};

# Kernel tuning
boot.kernel.sysctl = {
  "vm.swappiness" = 10;
  "vm.vfs_cache_pressure" = 50;
  "vm.dirty_ratio" = 15;
  "vm.dirty_background_ratio" = 5;
};

# Nix build optimization
nix.settings = {
  auto-optimise-store = true;
  cores = 0;  # Use all available cores
  builders-use-substitutes = true;
};
```

## Git Workflow (nixtrap2)

GPG signing is configured via home-manager:

```nix
programs.git = {
  signing = {
    key = "0x590731EE4043D7E8";
    signByDefault = true;
  };
};
```

**GPG Key ID**: `0x590731EE4043D7E8`
**User**: `voidnxlab <pina@voidnx.com>`

All commits are automatically signed. Verify with:
```bash
git log --show-signature
```

## MCP Offload Automation (nixtrap2)

The `mcp-offload-automation.nix` module provides intelligent build offloading:

- Automatic detection of resource-intensive builds
- Dynamic switching between local and remote builders
- Load balancing based on system metrics
- WebSocket-based real-time coordination

**Key Service**: `nix-mcp-offload-automation.service`

Check status:
```bash
systemctl status nix-mcp-offload-automation
journalctl -u nix-mcp-offload-automation -f
```

## Security Considerations

### SSL/TLS Certificates

**nixtrap1**: Auto-generates self-signed certs or uses Let's Encrypt
**nixtrap2**: Manual cert management in `./certs/`

```bash
# Certs location (nixtrap2)
./certs/server.crt
./certs/server.key
```

**WARNING**: Replace self-signed certs with proper CA-signed certs in production!

### Firewall Configuration

**nixtrap1**: Restrictive by default (HTTPS 443 only)
**nixtrap2**: Configurable per-service (SSH 22, cache ports)

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 443 ];  # SSH and HTTPS
};
```

### SSH Keys for Offload Builds (nixtrap2)

Distributed builds require SSH key authentication:

```bash
# Generate build user SSH key
sudo -u nixbld1 ssh-keygen -t ed25519

# Copy to remote builder
sudo -u nixbld1 ssh-copy-id builder@remote-server
```

## Testing & Validation

### Test Cache Server

```bash
# Local test
nix-build '<nixpkgs>' -A hello --option substituters 'http://localhost:5000'

# Remote test
nix-build '<nixpkgs>' -A hello \
  --option substituters 'https://cache.local' \
  --option trusted-public-keys 'cache.local:BASE64_PUBLIC_KEY'
```

### Test Distributed Builds

```bash
# Force remote build
nix-build '<nixpkgs>' -A hello \
  --builders 'ssh://builder@remote-server x86_64-linux' \
  --max-jobs 0  # Disable local builds
```

### Validate Flake

```bash
nix flake check
nix flake show
```

## Troubleshooting

### Cache Server Not Accessible

1. Check nix-serve is running: `systemctl status nix-serve`
2. Check nginx proxy (if enabled): `systemctl status nginx`
3. Test local connectivity: `curl http://localhost:5000/nix-cache-info`
4. Check firewall: `sudo iptables -L -n`
5. Review logs: `journalctl -u nix-serve -u nginx`

### Distributed Builds Failing

1. Test SSH connectivity: `ssh builder@remote-server`
2. Verify builder key: `nix store ping --store ssh://builder@remote-server`
3. Check nix-daemon: `journalctl -u nix-daemon -f`
4. Verify remote builder config: `cat /etc/nix/machines`

### Memory Issues (nixtrap2)

1. Check zram: `zramctl`
2. Monitor memory: `free -h; swapon --show`
3. Reduce parallel builds: Lower `nix.settings.max-jobs`
4. Enable more aggressive GC: `nix-collect-garbage -d`

### Flake Update Issues

```bash
# Clear flake cache
rm -rf ~/.cache/nix

# Re-evaluate flake
nix flake metadata --refresh

# Update specific input
nix flake lock --update-input nixpkgs
```

## Desktop Environment (nixtrap2)

**Window Manager**: i3 (lightweight, tiling)
**Display Manager**: LightDM with GTK greeter
**Compositor**: Picom (optional transparency/shadows)

**Key Bindings** (configured in home.nix):
- `Super+Return` - Terminal (Alacritty)
- `Super+D` - Launcher (Rofi)
- `Super+W` - Firefox
- `Super+L` - Lock screen

**Theme Management**:
```bash
theme-toggle      # Switch light/dark
theme-dark        # Apply dark theme
theme-light       # Apply light theme
```

## Build Optimization Settings

### nixtrap1 (Cache-focused)
```nix
services.nixos-cache-server = {
  workers = 4;
  storage = {
    maxSize = "100G";
    gcKeepOutputs = true;
    autoOptimise = true;
  };
};
```

### nixtrap2 (Desktop + Offload)
```nix
nix.settings = {
  cores = 0;  # Use all cores
  max-jobs = "auto";
  builders-use-substitutes = true;

  # Remote builders
  builders = "ssh://builder@server x86_64-linux";
};
```

## Important File Locations

### nixtrap1
- Modules: `./modules/*.nix`
- Templates: `./templates/{minimal,full}/`
- Bootstrap: `./nixos-cache-bootstrap.sh`
- Dashboard: `./dashboard/` (React/Vite project)

### nixtrap2
- Main config: `./configuration.nix`
- Home config: `./home.nix`
- Cache keys: `./cache-keys/`
- SSL certs: `./certs/`
- Hardware: `./hardware-configuration.nix`

## Dashboard Development (nixtrap1)

The React dashboard provides real-time cache monitoring:

```bash
cd dashboard/

# Install dependencies
npm install

# Development server
npm run dev

# Production build
npm run build

# Preview production build
npm run preview
```

**API Endpoints**:
- `GET /api/metrics` - System metrics (CPU, RAM, disk, network)
- `GET /api/services` - Service status
- `GET /api/cache-info` - Cache server information

## Best Practices

1. **Always backup keys before system changes**
   - Cache signing keys
   - SSH keys for build offloading
   - GPG keys for commit signing

2. **Test configurations before applying**
   ```bash
   sudo nixos-rebuild test --flake .#voidnx
   ```

3. **Use declarative module options**
   - Prefer module options over imperative scripts
   - Document custom options in module files

4. **Monitor resource usage**
   - Watch build memory usage on limited systems
   - Enable garbage collection automation
   - Use `nix-store --optimise` regularly

5. **Version flake inputs**
   ```bash
   nix flake lock
   git add flake.lock
   ```

6. **Separate secrets from config**
   - Never commit private keys to git
   - Use sops-nix or agenix for secrets management

## Merge Strategy

When merging nixtrap1 and nixtrap2:

1. **Keep both flake structures** - They serve different purposes
2. **Extract common modules** - Share cache-server logic
3. **Unify monitoring approach** - Use nixtrap1's Prometheus setup
4. **Preserve desktop config** - Keep nixtrap2's i3/home-manager setup
5. **Consolidate templates** - Extend nixtrap1 templates with offload options
6. **Document differences** - Maintain README for each use case

## System Requirements

### Minimum (Cache Server)
- 2 CPU cores
- 4GB RAM
- 50GB disk

### Recommended (Desktop + Cache + Offload)
- 4+ CPU cores
- 8GB+ RAM
- 200GB+ SSD
- 1Gbps network (for distributed builds)

## Useful Aliases (nixtrap2)

Defined in home.nix:

```bash
nrs    # nixos-rebuild switch
nrt    # nixos-rebuild test
nup    # nix flake update
ncl    # nix-collect-garbage -d
status # system status report
```

---

**Hostname**: nixos (voidnx user)
**Architecture**: x86_64-linux
**NixOS Version**: 25.05
**Timezone**: America/Bahia (pt_BR.UTF-8)
