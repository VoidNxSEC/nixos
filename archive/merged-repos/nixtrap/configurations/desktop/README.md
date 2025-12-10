# Desktop Configuration

Lightweight i3 desktop environment with distributed build support and binary cache.

## Features

- **Window Manager**: i3 (lightweight, tiling)
- **Display Manager**: LightDM with GTK greeter
- **Performance**: ZRAM, kernel tuning, memory optimization
- **Build Offloading**: Distributed builds to remote servers
- **Binary Cache**: Local cache server with nginx proxy
- **MCP Automation**: Intelligent build offload automation

## Usage

```bash
# Deploy this configuration
sudo nixos-rebuild switch --flake /path/to/nixtrap#desktop

# Or copy configuration.nix to /etc/nixos/
sudo cp configuration.nix /etc/nixos/
sudo nixos-rebuild switch
```

## Requirements

- NixOS 25.05 or later
- 8GB+ RAM recommended
- SSD recommended for best performance

## Customization

1. Copy your hardware-configuration.nix
2. Update hostname and user settings
3. Adjust memory limits in cache-server.nix if needed
4. Configure remote builders in offload-client.nix

## Management Commands

```bash
# System status
cache-server-status
systemctl status nix-serve nginx

# Distributed build status
nix store ping --store ssh://builder@remote

# Theme management
theme-toggle
theme-dark
theme-light
```
