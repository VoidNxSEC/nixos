# NixOS Technical Documentation

> **Production-Ready NixOS System** - Modular configuration with ML infrastructure, security hardening, and enterprise-grade tooling

## 🎯 System Overview

Comprehensive NixOS configuration featuring:

- **🤖 ML Infrastructure** - GPU-accelerated model orchestration (Ollama, llama.cpp)
- **🔒 Security Suite** - AIDE, ClamAV, compiler hardening, SOC tools
- **🛠️ Development Tools** - SecureLLM Bridge, MCP servers, dev environments
- **📦 Package Management** - Sandboxed packages with security auditing
- **🌐 Network Services** - Tailscale, NordVPN, DNS optimization, firewall zones
- **🖥️ Desktop Environments** - Hyprland (Wayland) and i3 (X11)

## 📁 Repository Structure

```
/etc/nixos/
├── flake.nix                 # Main entry point
├── modules/                  # Modular configurations
│   ├── ml/                   # Machine learning
│   ├── security/             # Security hardening
│   ├── services/             # System services
│   ├── applications/         # Applications
│   └── ...
├── hosts/kernelcore/         # Host configuration
├── lib/                      # Reusable functions
├── overlays/                 # Package overlays
└── secrets/                  # SOPS-encrypted
```

## 🚀 Quick Reference

### Build System

```bash
# Build and switch
sudo nixos-rebuild switch --flake .#kernelcore

# Build only (safer)
sudo nixos-rebuild build --flake .#kernelcore

# Check configuration
nix flake check
```

### Feature Configuration

Features are enabled in `flake.nix`:

```nix
{
  services.securellm-mcp.enable = true;
  kernelcore.tools.enable = true;
  kernelcore.swissknife.enable = true;
}
```

### Development Shells

```bash
nix develop .#python   # Python dev
nix develop .#cuda     # CUDA dev
nix develop .#rust     # Rust dev
```

## 🔧 Key Features

### ML Infrastructure

- ✅ Ollama + llama.cpp backends
- ✅ VRAM monitoring
- ✅ Model registry
- ✅ REST API (port 9000)
- 📋 vLLM/TGI (planned)

```nix
kernelcore.ml.offload.enable = true;
```

### Security

- AIDE - File integrity
- ClamAV - Antivirus
- Compiler hardening
- Wazuh EDR
- Suricata IDS
- Firewall zones

```nix
kernelcore.security.hardening.enable = true;
```

### Tools Suite

- SecureLLM Bridge
- MCP Servers
- Swissknife debug tools
- Phantom AI toolkit

```nix
kernelcore.tools = {
  enable = true;
  intel.enable = true;
  secops.enable = true;
  llm.enable = true;
};
```

## 📚 Documentation

- [Architecture](ARCHITECTURE-BLUEPRINT.md)
- [Module Guide](../modules/TEMPLATE_GUIDE.md)
- [ML Infrastructure](../modules/ml/README.md)
- [Security](SECURITY.md)
- [Binary Cache](BINARY-CACHE-SETUP.md)

## 🔐 Security Classification

As noted in root README.md, this is a production system with:
- Environment: Production
- Security Level: Hardened
- Data Sensitivity: High

**Note**: See root [README.md](../README.md) for legal notices.
