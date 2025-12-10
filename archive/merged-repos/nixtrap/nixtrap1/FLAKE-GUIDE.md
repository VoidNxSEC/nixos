# NixOS Cache Server - Flake-Based Installation Guide

Complete guide for setting up a NixOS Cache Server using Nix Flakes.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation Methods](#installation-methods)
- [Configuration Options](#configuration-options)
- [Post-Installation](#post-installation)
- [Client Configuration](#client-configuration)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Minimum**: 2 CPU cores, 4GB RAM, 50GB disk
- **Recommended**: 4+ CPU cores, 8GB+ RAM, 200GB+ disk
- **Network**: Static IP or reliable DHCP reservation
- **OS**: NixOS 24.11 or later

### Knowledge Requirements

- Basic Linux command line
- Understanding of Nix/NixOS concepts
- Familiarity with flakes (optional but helpful)

---

## Quick Start

### Option 1: Use a Template (Easiest)

```bash
# Minimal setup (cache server only)
nix flake init -t github:yourusername/nixtrap#minimal

# Full setup (with monitoring)
nix flake init -t github:yourusername/nixtrap#full
```

### Option 2: Clone Repository

```bash
git clone https://github.com/yourusername/nixtrap.git
cd nixtrap
```

### Option 3: Direct Flake Reference

```bash
nixos-install --flake github:yourusername/nixtrap#cache-server-full
```

---

## Installation Methods

### Method 1: From NixOS Live ISO (Fresh Install)

#### Step 1: Boot Live ISO

Download and boot from [NixOS ISO](https://nixos.org/download.html).

#### Step 2: Partition Disk

```bash
# Example: Simple single partition setup
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart primary 1MB 100%
sudo parted /dev/sda -- set 1 boot on

# Format
sudo mkfs.ext4 -L nixos /dev/sda1

# Mount
sudo mount /dev/sda1 /mnt
```

#### Step 3: Generate Hardware Config

```bash
sudo nixos-generate-config --root /mnt
```

#### Step 4: Create Flake Configuration

```bash
cd /mnt/etc/nixos

# Option A: Use template
nix flake init -t github:yourusername/nixtrap#full

# Option B: Create custom flake.nix
cat > flake.nix << 'EOF'
{
  description = "NixOS Cache Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixtrap.url = "github:yourusername/nixtrap";
  };

  outputs = { self, nixpkgs, nixtrap }: {
    nixosConfigurations.cache-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        nixtrap.nixosModules.default

        {
          services.nixos-cache-server = {
            enable = true;
            hostName = "cache.example.com";
            enableTLS = true;
            enableMonitoring = true;
          };

          services.nixos-cache-api.enable = true;
          services.nixos-cache-monitoring.enable = true;

          # Basic config
          boot.loader.grub.device = "/dev/sda";
          networking.hostName = "nixos-cache";
          time.timeZone = "UTC";

          users.users.admin = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "changeme";
          };

          services.openssh.enable = true;
          system.stateVersion = "24.11";
        }
      ];
    };
  };
}
EOF
```

#### Step 5: Install

```bash
sudo nixos-install --flake .#cache-server
```

#### Step 6: Reboot

```bash
sudo reboot
```

---

### Method 2: On Existing NixOS System

#### Step 1: Clone or Create Configuration

```bash
cd /etc/nixos
sudo git clone https://github.com/yourusername/nixtrap.git
cd nixtrap
```

#### Step 2: Create Flake

```bash
sudo vim flake.nix
# Add configuration (see examples above)
```

#### Step 3: Build and Switch

```bash
sudo nixos-rebuild switch --flake .#cache-server
```

---

### Method 3: Remote Deployment

#### Using SSH

```bash
# On local machine
nixos-rebuild switch --flake .#cache-server \
  --target-host root@cache.example.com \
  --build-host localhost
```

#### Using deploy-rs

```nix
# flake.nix
{
  outputs = { self, nixpkgs, deploy-rs, nixtrap }: {
    deploy.nodes.cache-server = {
      hostname = "cache.example.com";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.cache-server;
      };
    };
  };
}
```

```bash
nix run github:serokell/deploy-rs .#cache-server
```

---

## Configuration Options

### Minimal Configuration

```nix
{
  services.nixos-cache-server = {
    enable = true;
    hostName = "cache.local";
  };
}
```

### Full Configuration

```nix
{
  services.nixos-cache-server = {
    enable = true;
    hostName = "cache.example.com";
    port = 5000;
    priority = 40;

    enableTLS = true;
    enableMonitoring = true;

    workers = 4;

    storage = {
      maxSize = "100G";
      gcKeepOutputs = true;
      gcKeepDerivations = true;
      autoOptimise = true;
    };

    ssl = {
      certificatePath = "/path/to/cert.pem";  # null for auto-generated
      keyPath = "/path/to/key.pem";
    };
  };

  services.nixos-cache-api = {
    enable = true;
    port = 8080;
  };

  services.nixos-cache-monitoring = {
    enable = true;
    enablePrometheus = true;
    enableNodeExporter = true;
    enableGrafana = true;

    grafana = {
      port = 3000;
      domain = "grafana.example.com";
      adminPassword = "CHANGE_ME";
    };
  };
}
```

### Using Let's Encrypt (Production)

```nix
{
  services.nixos-cache-server = {
    enable = true;
    hostName = "cache.example.com";
    enableTLS = true;

    ssl = {
      certificatePath = "/var/lib/acme/cache.example.com/cert.pem";
      keyPath = "/var/lib/acme/cache.example.com/key.pem";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
    certs."cache.example.com" = {
      webroot = "/var/lib/acme/acme-challenge";
    };
  };
}
```

---

## Post-Installation

### 1. Verify Services

```bash
# Check service status
systemctl status nix-serve
systemctl status nginx
systemctl status prometheus
systemctl status nixos-cache-api

# Check all at once
systemctl status nix-serve nginx prometheus nixos-cache-api
```

### 2. Get Cache Public Key

```bash
# View public key
cat /var/cache-nix-serve/cache-pub-key.pem

# View cache info
/etc/nixos-cache/scripts/show-cache-info.sh
```

### 3. Test Cache Endpoint

```bash
# Local test
curl http://localhost:5000/nix-cache-info

# Public test (if TLS enabled)
curl https://cache.example.com/nix-cache-info

# Expected output:
# StoreDir: /nix/store
# WantMassQuery: 1
# Priority: 40
```

### 4. Health Check

```bash
/etc/nixos-cache/scripts/health-check.sh
```

### 5. Monitor System

```bash
# Real-time monitoring
/etc/nixos-cache/scripts/monitor.sh

# View metrics API
curl http://localhost:8080/api/metrics | jq

# View Prometheus (via SSH tunnel)
ssh -L 9090:localhost:9090 admin@cache.example.com
# Open browser: http://localhost:9090
```

---

## Client Configuration

### Add Cache to Client Machine

Edit `/etc/nixos/configuration.nix` on client:

```nix
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://cache.example.com"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.example.com:YOUR_PUBLIC_KEY_HERE"
    ];
  };
}
```

Apply configuration:

```bash
sudo nixos-rebuild switch
```

### Test Client

```bash
# Clear local cache to test substitution
nix-store --delete /nix/store/some-package

# Rebuild something to trigger download from cache
nixos-rebuild test --option substituters "https://cache.example.com"
```

### Verify Cache Usage

```bash
# Check if cache is being used
nix build --print-build-logs nixpkgs#hello

# View download sources in logs
journalctl -u nix-daemon | grep "downloading"
```

---

## Maintenance

### Update System

```bash
# Update flake inputs
nix flake update

# Rebuild with updates
sudo nixos-rebuild switch --flake .#cache-server
```

### Garbage Collection

```bash
# Manual GC
sudo nix-collect-garbage -d

# Delete old generations
sudo nix-collect-garbage --delete-older-than 30d

# Optimize store
sudo nix-store --optimise
```

### View Logs

```bash
# Service logs
journalctl -u nix-serve -f
journalctl -u nginx -f
journalctl -u nixos-cache-api -f

# System logs
journalctl -xe

# View last 100 lines
journalctl -u nix-serve -n 100
```

### Backup Critical Files

```bash
# Create backup directory
mkdir -p /backup/cache-keys

# Backup signing keys (CRITICAL!)
sudo cp -p /var/cache-nix-serve/cache-priv-key.pem /backup/cache-keys/
sudo cp -p /var/cache-nix-serve/cache-pub-key.pem /backup/cache-keys/

# Backup SSL certificates
sudo cp -rp /var/lib/nixos-cache/ /backup/ssl-certs/

# Backup configuration
sudo cp -rp /etc/nixos/ /backup/nixos-config/
```

### Restore from Backup

```bash
# Restore signing keys
sudo mkdir -p /var/cache-nix-serve
sudo cp /backup/cache-keys/* /var/cache-nix-serve/
sudo chmod 600 /var/cache-nix-serve/cache-priv-key.pem
sudo chmod 644 /var/cache-nix-serve/cache-pub-key.pem

# Restart services
sudo systemctl restart nix-serve nginx
```

---

## Troubleshooting

### Services Not Starting

```bash
# Check service status
systemctl status nix-serve
systemctl status nginx

# View detailed logs
journalctl -xe -u nix-serve
journalctl -xe -u nginx

# Check configuration syntax
nix flake check

# Test nginx configuration
sudo nginx -t
```

### Cache Not Accessible

```bash
# Test local endpoint
curl -v http://localhost:5000/nix-cache-info

# Test public endpoint
curl -v https://cache.example.com/nix-cache-info

# Check firewall
sudo iptables -L -n
sudo nft list ruleset

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### SSL Certificate Issues

```bash
# Check certificate validity
openssl x509 -in /var/lib/nixos-cache/cert.pem -text -noout

# Regenerate self-signed certificate
sudo rm /var/lib/nixos-cache/{cert,key}.pem
sudo nixos-rebuild switch --flake .#cache-server

# For Let's Encrypt issues
sudo systemctl status acme-cache.example.com
journalctl -u acme-cache.example.com
```

### High Disk Usage

```bash
# Check disk usage
df -h /nix/store
du -sh /nix/store

# Check number of store paths
ls /nix/store | wc -l

# Force garbage collection
sudo nix-collect-garbage -d
sudo nix-store --gc

# Optimize store (deduplicate)
sudo nix-store --optimise
```

### Memory Issues

```bash
# Check memory usage
free -h
htop

# Check per-service memory
systemctl status nix-serve | grep Memory
systemctl status nginx | grep Memory

# Adjust service memory limits in configuration
services.nixos-cache-server.workers = 2;  # Reduce workers
```

### Network Issues

```bash
# Test connectivity
ping cache.example.com
curl -I https://cache.example.com

# Check listening ports
sudo ss -tlnp | grep -E '(5000|443|8080)'

# Check active connections
sudo ss -tanp | grep ESTAB

# Test from another machine
curl -v https://cache.example.com/nix-cache-info
```

### Build Failures

```bash
# Check nix-daemon logs
journalctl -u nix-daemon -f

# Test build locally
nix build nixpkgs#hello --print-build-logs

# Check available disk space
df -h /

# Check build users
id nixbld1
```

---

## Advanced Topics

### Distributed Builds

Configure the cache server as a remote builder:

```nix
# On client machine
{
  nix.buildMachines = [{
    hostName = "cache.example.com";
    system = "x86_64-linux";
    maxJobs = 4;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  }];

  nix.distributedBuilds = true;
}
```

### Custom Signing Keys

```bash
# Generate custom keys
nix-store --generate-binary-cache-key \
  custom-cache-name \
  /path/to/private-key.pem \
  /path/to/public-key.pem

# Use in configuration
services.nix-serve.secretKeyFile = "/path/to/private-key.pem";
```

### Multi-Architecture Support

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.nixos-cache-server = {
    enable = true;
    # Configuration applies to all architectures
  };
}
```

---

## Security Best Practices

1. **Use Let's Encrypt in production** instead of self-signed certificates
2. **Keep monitoring ports internal** (use SSH tunneling for access)
3. **Change default passwords** immediately (Grafana admin, etc.)
4. **Backup private keys** to secure location
5. **Use SSH keys** instead of passwords for authentication
6. **Enable automatic security updates**
7. **Monitor logs regularly** for suspicious activity
8. **Restrict firewall rules** to minimum necessary ports
9. **Use strong passwords** for all accounts
10. **Keep system updated** with latest security patches

---

## Support and Resources

- **Repository**: https://github.com/yourusername/nixtrap
- **Issues**: https://github.com/yourusername/nixtrap/issues
- **NixOS Manual**: https://nixos.org/manual/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **NixOS Wiki**: https://nixos.wiki/
- **Community**: https://discourse.nixos.org/

---

## License

MIT License - See LICENSE file for details

---

**Made with ❤️ for the NixOS community**
