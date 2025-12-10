# 🚀 NixTrap - Unified NixOS Infrastructure

**Production-ready NixOS configurations for binary cache servers, lightweight desktops, and distributed build systems.**

> **Merged from nixtrap1 & nixtrap2**: Combining enterprise-grade cache infrastructure with performance-optimized desktop environments and intelligent build offloading.

[![NixOS](https://img.shields.io/badge/NixOS-25.05-blue.svg)](https://nixos.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📋 What Is This?

NixTrap is a comprehensive NixOS configuration repository providing:

1. **Binary Cache Server** - Production-ready cache with TLS, signing, and monitoring
2. **Desktop Environment** - Lightweight i3 setup with developer tools
3. **Distributed Builds** - SSH-based build offloading with MCP automation
4. **Hybrid Setup** - All-in-one: desktop + cache + offload

---

## ✨ Key Features

### 🔐 Security First
- ✅ Cryptographic cache signing
- ✅ TLS/HTTPS with nginx
- ✅ Systemd hardening
- ✅ Firewall rules
- ✅ GPG commit signing

### ⚡ Performance Optimized
- ✅ ZRAM compression (25% RAM)
- ✅ Kernel tuning (swappiness, VFS cache)
- ✅ Resource limits (OOM protection)
- ✅ Auto-optimize Nix store
- ✅ Intelligent build distribution

### 🎯 Production Ready
- ✅ Health monitoring
- ✅ Automated garbage collection
- ✅ Resource quotas
- ✅ Logging and metrics
- ✅ Management scripts

### 🛠️ Developer Friendly
- ✅ Nix Flakes-based
- ✅ Modular architecture
- ✅ Ready-to-use templates
- ✅ Comprehensive documentation
- ✅ CI/CD integration

---

## 🎯 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/nixtrap.git
cd nixtrap
```

### 2. Choose Your Configuration

#### Option A: Minimal Cache Server
```bash
sudo nixos-rebuild switch --flake .#cache-server-minimal
```

#### Option B: Full Cache Server (with monitoring)
```bash
sudo nixos-rebuild switch --flake .#cache-server-full
```

#### Option C: Desktop Environment (i3 + offload)
```bash
sudo nixos-rebuild switch --flake .#voidnx
```

#### Option D: Hybrid (desktop + cache + offload)
```bash
sudo nixos-rebuild switch --flake .#hybrid
```

### 3. Verify Installation

```bash
# Check cache server
cache-server-status
curl http://localhost:5000/nix-cache-info

# Check services
systemctl status nix-serve nginx

# Get public key for clients
cat /var/cache-nix-serve/cache-pub-key.pem
```

---

## 📂 Repository Structure

```
nixtrap/
├── 📖 README.md                      # You are here
├── 📖 CLAUDE.md                      # AI assistant guidance
├── 🔧 flake.nix                      # Unified flake configuration
│
├── 📦 modules/                       # NixOS modules
│   ├── cache-server.nix             # Unified cache server (merged)
│   ├── api-server.nix               # REST API for metrics
│   ├── monitoring.nix               # Prometheus + Node Exporter
│   ├── offload-server.nix           # Remote build server
│   ├── laptop-offload-client.nix    # Client-side offload
│   ├── mcp-offload-automation.nix   # Intelligent offload
│   ├── cache-bucket-setup.nix       # S3-compatible storage
│   ├── nginx-module.nix             # Nginx reverse proxy
│   └── nar-server.nix               # Custom NAR server
│
├── 📋 configurations/                # Ready-to-use configs
│   ├── cache-server/                # Dedicated cache server
│   │   ├── configuration.nix
│   │   └── README.md
│   ├── desktop/                     # i3 desktop environment
│   │   ├── configuration.nix
│   │   └── README.md
│   └── hybrid/                      # Desktop + cache + offload
│       ├── configuration.nix
│       └── README.md
│
├── 📋 templates/                     # Flake templates
│   ├── minimal-cache/               # Quick cache setup
│   ├── desktop/                     # Desktop template
│   └── hybrid/                      # Hybrid template
│
├── 🧪 tests/                         # Testing framework
│   ├── bootstrap-test.sh
│   └── integration-test.sh
│
├── 🏗️  terraform/                    # Infrastructure as Code
│   ├── main.tf
│   ├── modules/nixos-vm/
│   └── environments/
│
├── 🔧 scripts/                       # Helper scripts
│   ├── debug-deployment.sh
│   └── quick-deploy.sh
│
└── 📚 Legacy directories
    ├── nixtrap1/                    # Original cache server
    └── nixtrap2/                    # Original desktop config
```

---

## 🎨 Configuration Matrix

| Configuration | Cache Server | Desktop | Offload | Monitoring | Use Case |
|--------------|--------------|---------|---------|------------|----------|
| **cache-server-minimal** | ✅ | ❌ | ❌ | ❌ | Basic cache |
| **cache-server-full** | ✅ | ❌ | ❌ | ✅ | Production cache |
| **voidnx** (desktop) | ✅ | ✅ | ✅ | ❌ | Developer workstation |
| **hybrid** | ✅ | ✅ | ✅ | ✅ | Ultimate setup |

---

## 📖 Usage Scenarios

### Scenario 1: Home Lab Cache Server

**Goal**: Provide binary cache for home network

```bash
# Deploy on dedicated server
sudo nixos-rebuild switch --flake .#cache-server-full

# On client machines, add to configuration.nix:
nix.settings = {
  substituters = [ "https://cache.nixos.org" "https://cache.local" ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cache.local:YOUR_PUBLIC_KEY"
  ];
};
```

### Scenario 2: Developer Workstation

**Goal**: Fast rebuilds with local cache + remote offload

```bash
# Deploy hybrid config
sudo nixos-rebuild switch --flake .#hybrid

# Configure remote builder
# Edit nixtrap2/offload-client.nix with your build server

# Heavy builds automatically offload to remote
nix-build '<nixpkgs>' -A firefox
```

### Scenario 3: CI/CD Build Server

**Goal**: Distributed builds for CI pipeline

```bash
# Use Terraform to deploy
cd terraform
terraform init
terraform apply

# Run integration tests
cd ../tests
./integration-test.sh server-ip
```

---

## 🔧 Management Commands

### System Management
```bash
nrs                              # nixos-rebuild switch
nrt                              # nixos-rebuild test
nix flake update                 # Update inputs
nix-collect-garbage -d           # Clean old generations
```

### Cache Server
```bash
cache-server-status              # Check status
cache-server-restart             # Restart services
cache-server-logs                # View logs
systemctl status nix-serve nginx # Check services
```

### Distributed Builds
```bash
nix store ping --store ssh://builder@remote  # Test connection
nix-build '<nixpkgs>' -A hello --max-jobs 0  # Force remote build
```

### Desktop
```bash
theme-toggle                     # Toggle light/dark theme
theme-dark                       # Dark theme
theme-light                      # Light theme
status                           # System status
```

---

## 🔬 Testing & Development

### Local Development

```bash
# Enter development shell
nix develop

# Check flake validity
nix flake check

# Show all outputs
nix flake show

# Format Nix files
nix fmt
```

### Run Tests

```bash
# Bootstrap validation
./tests/bootstrap-test.sh <server-ip>

# Integration tests
./tests/integration-test.sh <server-ip>

# Terraform deployment
cd terraform
terraform apply -var-file=environments/test/terraform.tfvars
```

### CI/CD Pipeline

The repository includes GitHub Actions workflows:
- `.github/workflows/ci.yml` - Main CI pipeline
- `.github/workflows/bootstrap-test.yml` - Bootstrap validation
- `.github/workflows/terraform-deploy.yml` - Deployment automation

---

## 📊 System Requirements

### Minimal Cache Server
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 50GB
- **Network**: 100Mbps

### Recommended Cache Server
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 500GB+ SSD
- **Network**: 1Gbps

### Desktop Environment
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 100GB SSD
- **GPU**: Optional (works with integrated)

### Hybrid Setup
- **CPU**: 8+ cores
- **RAM**: 16GB+
- **Disk**: 500GB+ NVMe
- **Network**: 1Gbps

---

## 🔐 Security Best Practices

1. **Backup signing keys** regularly:
   ```bash
   sudo cp -r /var/cache-nix-serve /backup/location/
   ```

2. **Use real SSL certificates** in production:
   ```nix
   services.nixos-cache-server.ssl = {
     certificatePath = "/var/lib/acme/cache.example.com/fullchain.pem";
     keyPath = "/var/lib/acme/cache.example.com/key.pem";
   };
   ```

3. **Enable firewall**:
   ```nix
   networking.firewall.enable = true;
   networking.firewall.allowedTCPPorts = [ 22 443 ];
   ```

4. **Disable root SSH login**:
   ```nix
   services.openssh.settings.PermitRootLogin = "no";
   ```

5. **Keep system updated**:
   ```bash
   nix-channel --update && sudo nixos-rebuild switch
   ```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `nix flake check`
5. Format code: `nix fmt`
6. Submit a pull request

---

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive guide for AI assistants
- **[configurations/cache-server/README.md](configurations/cache-server/README.md)** - Cache server setup
- **[configurations/desktop/README.md](configurations/desktop/README.md)** - Desktop environment
- **[configurations/hybrid/README.md](configurations/hybrid/README.md)** - Hybrid setup
- **[PIPELINE.md](PIPELINE.md)** - CI/CD pipeline documentation

### External Resources
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Binary Cache Guide](https://nixos.wiki/wiki/Binary_Cache)
- [Distributed Builds](https://nixos.wiki/wiki/Distributed_build)

---

## 🐛 Troubleshooting

### Cache Server Won't Start

```bash
# Check logs
journalctl -u nix-serve -xe

# Verify keys exist
ls -la /var/cache-nix-serve/

# Test directly
curl http://localhost:5000/nix-cache-info
```

### Clients Can't Connect

```bash
# Test from client
curl https://cache.example.com/nix-cache-info

# Check firewall
sudo iptables -L -n

# Verify nginx
systemctl status nginx
```

### High Memory Usage

```bash
# Check resource usage
systemctl show nix-serve --property=MemoryCurrent

# Reduce workers
# Edit modules/cache-server.nix:
services.nixos-cache-server.workers = 2;
```

### Distributed Builds Failing

```bash
# Test SSH
ssh builder@remote

# Check builder
nix store ping --store ssh://builder@remote

# View nix-daemon logs
journalctl -u nix-daemon -f
```

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **NixOS Community** - For the amazing ecosystem
- **nixtrap1** - Enterprise cache server foundation
- **nixtrap2** - Desktop environment and offload expertise

---

## 🎉 Get Started Now!

```bash
# 1. Clone
git clone https://github.com/yourusername/nixtrap.git
cd nixtrap

# 2. Choose configuration
nix flake show

# 3. Deploy
sudo nixos-rebuild switch --flake .#<configuration>

# 4. Enjoy!
cache-server-status
```

**Questions?** Open an issue or check [CLAUDE.md](CLAUDE.md) for detailed guidance.

---

**Made with ❤️ for the NixOS community**

*Unified infrastructure for caching, desktop, and distributed builds*
