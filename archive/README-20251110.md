# NixOS Configuration Repository

> **System**: kernelcore @ NixOS 25.11 (Xantusia)
> **Status**: Production | Phase 2 Complete ✅
> **Last Updated**: 2025-11-02

## Overview

This repository contains a comprehensive, security-hardened NixOS configuration with modular architecture, supporting development workflows, machine learning, containerization, and virtualization.

## Repository Structure

```
/etc/nixos/
├── flake.nix                # Flake entry point
├── flake.lock               # Dependency lock file
│
├── hosts/                   # Host-specific configurations
│   └── kernelcore/         # Main workstation configuration
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── home/           # Home-manager configs
│
├── modules/                 # Modular NixOS configurations
│   ├── applications/       # User applications (browsers, editors)
│   ├── containers/         # Docker, Podman, NixOS containers
│   ├── development/        # Development environments
│   ├── hardware/           # Hardware configs (NVIDIA, Trezor, WiFi)
│   ├── ml/                 # Machine learning infrastructure
│   ├── network/            # Networking (DNS, VPN, bridges)
│   ├── security/           # Security hardening modules
│   ├── services/           # System services
│   ├── shell/              # Shell configuration & aliases
│   ├── system/             # Core system configs
│   └── virtualization/     # VMs, QEMU, libvirt
│
├── lib/                     # Custom libraries
│   ├── packages.nix        # Docker images & custom packages
│   └── shells.nix          # Development shells
│
├── sec/                     # Security overrides (final priority)
│   └── hardening.nix       # Final security hardening
│
├── secrets/                 # SOPS-encrypted secrets
│   ├── api-keys/           # API keys (encrypted)
│   └── ssh-keys/           # SSH keys (encrypted)
│
├── overlays/                # Nixpkgs overlays
├── scripts/                 # Utility scripts
├── docs/                    # Documentation
│   ├── guides/             # Setup guides
│   ├── reports/            # Technical reports
│   └── *.md                # Various documentation
│
└── archive/                 # Archived legacy code
    ├── merged-repos/       # Previously merged repositories
    └── old-aliases-20251101/  # Old alias implementations
```

## Quick Start

### Rebuild System
```bash
# Check flake validity
nix flake check

# Rebuild and switch
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

### Development Shells
```bash
# Python environment
nix develop .#python

# Rust environment
nix develop .#rust

# Node.js environment
nix develop .#node

# CUDA/ML environment
nix develop .#cuda
```

### Build Outputs
```bash
# Build ISO image
nix build .#iso

# Build VM image
nix build .#vm-image

# Build Docker images
nix build .#docker-app
```

## Key Features

### 🔒 Security
- Comprehensive security hardening (kernel, boot, network)
- SOPS-encrypted secrets management
- ClamAV antivirus with real-time scanning
- AIDE intrusion detection
- Audit logging with auditd
- Automatic security updates

### 🐳 Containerization
- Docker with NVIDIA GPU support
- Podman rootless containers
- NixOS declarative containers
- Docker Compose integration

### 🤖 Machine Learning
- NVIDIA CUDA support (drivers + toolkit)
- Ollama for local LLMs
- GPU monitoring and optimization
- ML models storage management

### 🖥️ Virtualization
- QEMU/KVM with GPU passthrough
- libvirt management
- vmctl utility for VM operations
- VM templates and automation

### 🛠️ Development
- Multiple language dev shells (Python, Rust, Node, Go)
- VSCode/VSCodium with security sandboxing
- Git workflows with GPG signing
- Claude Code integration

### 🌐 Networking
- Custom DNS resolver (dnsmasq + unbound)
- NordVPN integration
- Network bridges and isolation
- Binary cache server support

## Documentation

### Guides
- [Binary Cache Setup](docs/BINARY-CACHE-SETUP.md)
- [Desktop Troubleshooting](docs/DESKTOP-TROUBLESHOOTING.md)
- [VMCTL Usage](docs/VMCTL-USAGE.md)
- [Secrets Management](docs/guides/SECRETS.md)
- [SOPS Setup](docs/guides/SETUP-SOPS-FINAL.md)

### Reports
- [Security Audit Report](docs/reports/SECURITY_AUDIT_REPORT.md)
- [Services Migration Plan](docs/reports/SERVICES_MIGRATION_PLAN.md)
- [CI/CD Setup](docs/reports/CI_CD_README.md)

### Planning
- [Repository Restructuring Plan](CLAUDE.md)
- [Repository Analysis](REPOSITORY-ANALYSIS.md)
- [Session 1 Summary](SESSION-1-SUMMARY.md)

## Module System

### Module Categories
Each module category has a `default.nix` aggregator for simplified imports:

```nix
# Instead of importing individual modules:
./modules/applications/firefox-privacy.nix
./modules/applications/brave-secure.nix
./modules/applications/vscodium-secure.nix

# Import the entire category:
./modules/applications
```

### Enabling Features
```nix
# In configuration.nix
{
  kernelcore = {
    security.hardening.enable = true;
    ml.ollama.enable = true;
    containers.docker.enable = true;
    virtualization.vms.enable = true;
  };
}
```

## Shell Aliases

Professional alias structure organized by category:

```bash
# Docker
d-build myimage           # Build Docker image
d-run-gpu myimage         # Run with GPU support
dc-up                     # Docker compose up

# Kubernetes
k-pods                    # List pods
k-logs pod-name -f        # Follow logs

# GCloud
gc-vms                    # List VMs
gc-ssh vm-name            # SSH to VM

# AI/ML
ollama-list               # List Ollama models
ai-up                     # Start AI stack

# Nix
nx-rebuild                # Rebuild system
nx-search pkg             # Search packages

# System
ll                        # ls -lah
gs                        # git status
```

See [modules/shell/aliases/README.md](modules/shell/aliases/README.md) for complete list.

## Security Model

### Security Layer Hierarchy
1. **Base modules** (`modules/security/*.nix`) - Core hardening
2. **Service modules** - Service-specific security
3. **Final overrides** (`sec/hardening.nix`) - Highest priority

### Secrets Management
All secrets encrypted with SOPS-nix:
- API keys in `secrets/api-keys/`
- SSH keys in `secrets/ssh-keys/`
- Managed with Age encryption

## Git Workflow

### Committing Changes
```bash
# Check status
git status

# Add changes
git add .

# Commit with descriptive message
git commit -m "Description of changes"

# Push to remote
git push
```

### Before Rebuild
Always validate configuration:
```bash
nix flake check
```

## Troubleshooting

### Common Issues

**Build Errors**: Check `nix flake check --show-trace`
**Runtime Errors**: Check `journalctl -xe`
**Module Conflicts**: Review security hierarchy in `sec/hardening.nix`

### Support

- Documentation: [docs/](docs/)
- Issues: Check [TODO.md](docs/TODO.md)
- Claude Code: `.claude/CLAUDE.md` for AI assistant instructions

## Maintenance

### Regular Tasks
- `nix flake update` - Update dependencies
- `nix-collect-garbage -d` - Clean old generations
- Review security updates in audit logs

### Backup Strategy
- Configuration tracked in Git
- Secrets encrypted with SOPS
- Generations preserved for rollback

## Contributing

1. Read [CLAUDE.md](CLAUDE.md) for architecture
2. Follow module structure patterns
3. Test with `nix flake check`
4. Document changes in commit messages

## License

Personal NixOS configuration - Use at your own risk.

## Credits

- **System Owner**: kernelcore
- **AI Assistant**: Claude Code
- **NixOS Community**: Inspiration and modules

---

**Repository Status**: ✅ Organized, ✅ Documented, ✅ Production-Ready
**Last Restructuring**: Session 2 - 2025-11-02
