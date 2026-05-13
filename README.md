# NixOS Configuration

A modular, hardened NixOS configuration covering ML infrastructure, defense-in-depth security, custom package management, and automated CI/CD.

[![NixOS](https://img.shields.io/badge/NixOS-Unstable-blue?logo=nixos&logoColor=white)](https://nixos.org)
[![CI](https://github.com/VoidNxSEC/nixos/actions/workflows/ci.yml/badge.svg)](https://github.com/VoidNxSEC/nixos/actions/workflows/ci.yml)
[![GitLab CI](https://img.shields.io/badge/GitLab%20CI-passing-success?logo=gitlab)](https://gitlab.com/VoidNxSEC/nixos)
[![Cachix](https://img.shields.io/badge/Cachix-Enabled-blue?logo=nix&logoColor=white)](https://app.cachix.org)
[![SOPS](https://img.shields.io/badge/Secrets-SOPS-purple?logo=keycdn&logoColor=white)](#security-notice)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Overview

This repository contains the declarative configuration for a production NixOS workstation. It is structured as a Nix flake with 278 modules across 20 categories. Notable features:

- **ML Infrastructure** — GPU orchestration with llama.cpp, vLLM, and TabbyAPI backends.
- **Defense-in-Depth Security** — Kernel hardening, AIDE, ClamAV, AppArmor, and a full SOC stack (Wazuh, OpenSearch, Suricata).
- **Custom Package System** — Sandboxed package builders with Firejail/Bubblewrap isolation and audit trails.
- **Developer Tooling** — SecureLLM Bridge, MCP servers, AI-assisted CLI utilities.
- **Observability** — Prometheus, Grafana, Vector, and structured logging across the stack.

---

## Architecture

```mermaid
graph TB
    subgraph "Security Layer"
        AIDE[AIDE FIM]
        ClamAV[ClamAV]
        Wazuh[Wazuh EDR]
        Suricata[Suricata IDS]
    end

    subgraph "ML Infrastructure"
        LlamaCPP[llama.cpp]
        vLLM[vLLM]
        TabbyAPI[TabbyAPI]
        VRAM[VRAM Monitor]
        Registry[Model Registry]
    end

    subgraph "Dev Tools"
        SecureLLM[SecureLLM Bridge]
        MCP[MCP Servers]
        Phantom[Phantom AI]
        Swissknife[Swissknife Debug]
    end

    subgraph "Network Stack"
        Tailscale[Tailscale VPN]
        Firewall[nftables Zones]
        DNS[DNS Hardening]
        NordVPN[NordVPN]
    end

    LlamaCPP --> VRAM
    vLLM --> VRAM
    TabbyAPI --> VRAM
    VRAM --> Registry
    SecureLLM --> MCP
    Wazuh --> Suricata
    AIDE --> Wazuh
```

### Module Distribution

| Category       | Modules | Notes                                       |
| -------------- | ------- | ------------------------------------------- |
| Security + SOC | 39      | AIDE, ClamAV, Wazuh, Suricata, hardening    |
| ML             | 36      | llama.cpp, vLLM, TabbyAPI, model registry   |
| Packages       | 36      | Sandboxed package builders                  |
| Shell          | 35      | Aliases, rebuild system, utilities          |
| Services       | 16      | GPU orchestration, MCP servers              |
| Network        | 12      | Tailscale, VPN, DNS, firewall zones         |
| Hardware       | 12      | Thermal forensics, NVIDIA tuning            |

**Totals**: 20 categories, 278 modules, ~48k lines of Nix.

---

## Key Subsystems

### ML Infrastructure

GPU-accelerated LLM stack integrated as NixOS modules:

```nix
kernelcore.ml.offload.enable = true;
```

- Backends: llama.cpp (turbo + swap variants), vLLM, TabbyAPI.
- SQLite model registry with auto-discovery.
- Rust-based REST control API on port 9000.
- Real-time VRAM monitoring with automatic offloading under pressure.
- MCP protocol integration for IDE clients.

### Security & SOC

Defense-in-depth with a complete SOC stack:

```nix
kernelcore.soc.enable = true;
kernelcore.security.hardening.enable = true;
```

- **File integrity & AV**: AIDE, ClamAV with scheduled scans.
- **Endpoint & network**: Wazuh EDR, Suricata IDS/IPS, AppArmor.
- **Hardening**: kernel sysctl/boot params, compiler hardening (PIE/RELRO/SSP), SSH hardening with key-only auth.
- **SIEM/Logs**: OpenSearch, Grafana, Vector, threat-intel feeds.

### Custom Package Management

Sandboxed package builders with audit logging:

- `.deb` packages under Firejail isolation.
- `tar.gz` extraction with FHS environments.
- npm packages with sandbox profiles.
- Automatic hash verification and GitHub release tracking.
- Examples: AppFlowy, Gemini CLI, Proton Suite, Cursor.

### Developer Tools

```nix
services.securellm-mcp.enable = true;
kernelcore.tools.enable = true;
kernelcore.swissknife.enable = true;
```

- **SecureLLM Bridge** — Multi-provider LLM orchestration (OpenAI, Anthropic, Bedrock, local) with rate limiting and fallback.
- **Tools CLI** — `nix-utils`, `secops`, `diagnostics`, `llm`, `mcp`.
- **Swissknife** — Thermal forensics, VRAM monitoring, emergency abort, build reproducibility analysis.

Dev shells:

```bash
nix develop .#python    # Python with ML libs
nix develop .#cuda      # CUDA toolchain
nix develop .#rust      # Rust toolchain
nix develop .#infra     # Infrastructure tools
```

### Network Security

- Tailscale mesh VPN (zero-config peer-to-peer).
- NordVPN with kill-switch and post-quantum encryption.
- nftables-based firewall zones.
- DNSCrypt + DNS-over-TLS with caching.
- NGINX reverse proxy for Tailscale-exposed services.

### Desktop

- **Hyprland** (Wayland): custom v0.52.2 overlay, Waybar, Wofi, Wlogout.
- **i3** (X11): Polybar, Rofi, Picom.

---

## Notable Implementations

**Thermal Forensics** (760 lines)

```bash
thermal-forensics --duration 180
laptop-verdict /var/lib/thermal-evidence
```

3-phase stress test collecting baseline/stress/rebuild thermal data for hardware warranty claims.

**Advanced Rebuild** (674 lines)

```bash
rebuild-advanced --profile workstation --check-thermal
```

Pre-flight checks, thermal monitoring, and binary cache integration during rebuilds.

**GPU Orchestration** (252 lines)
Unloads llama.cpp models when VRAM drops below 2GB; maintains service priority queues.

**SOC Stack**
Full Wazuh + OpenSearch + Suricata deployment running on a workstation-class machine.

---

## Repository Structure

```
/etc/nixos/
├── flake.nix                # Flake entry point
├── modules/                 # 278 modules / 20 categories
│   ├── ml/                  # ML infrastructure (36)
│   ├── security/            # Security + SOC (39)
│   ├── packages/            # Custom packages (36)
│   ├── shell/               # Shell configuration (35)
│   ├── services/            # System services (16)
│   ├── network/             # Networking (12)
│   ├── hardware/            # Hardware tuning (12)
│   └── ...                  # 13 more categories
├── hosts/kernelcore/        # Host configuration
├── overlays/                # Package overlays
├── lib/                     # Reusable functions
├── secrets/                 # SOPS-encrypted secrets
└── docs/                    # Documentation
```

---

## Quick Start

### Prerequisites

- NixOS 23.11+ or nixos-unstable
- NVIDIA GPU (optional, for ML features)
- Git

### Installation

```bash
git clone https://github.com/VoidNxSEC/nixos.git /etc/nixos
cd /etc/nixos

# Review host configuration
cat hosts/kernelcore/configuration.nix

# Dry-run build
sudo nixos-rebuild build --flake .#kernelcore

# Apply
sudo nixos-rebuild switch --flake .#kernelcore
```

### Feature Flags

```nix
{
  kernelcore.ml.offload.enable = true;          # ML infrastructure
  kernelcore.soc.enable = true;                 # SOC/SIEM stack
  kernelcore.security.hardening.enable = true;  # Kernel/compiler hardening
  services.securellm-mcp.enable = true;         # SecureLLM Bridge
  kernelcore.tools.enable = true;               # Unified CLI suite
  kernelcore.swissknife.enable = true;          # Debug toolkit
}
```

---

## CI/CD

### GitHub Actions

The repository uses several workflows under [`.github/workflows/`](.github/workflows/):

| Workflow                | Purpose                                              |
| ----------------------- | ---------------------------------------------------- |
| `ci.yml`                | Main CI: flake check + kernelcore closure build      |
| `pr-validation.yml`     | Reusable PR validation (format, build, security)     |
| `nixos-build.yml`       | Build & test with optional tmate debug               |
| `ci-observability.yml`  | Reusable observability/debug with Discord/Telegram   |
| `deploy.yml`            | Manual deploy via `workflow_dispatch`                |
| `rollback.yml`          | Manual rollback with health checks                   |
| `setup-sops.yml`        | Reusable SOPS secret decryption                      |
| `update-lock.yml`       | Weekly `flake.lock` updates (Mondays 06:00 UTC)      |

See [.github/README.md](.github/README.md) for composite actions and usage details.

### GitLab CI

[`.gitlab-ci.yml`](./.gitlab-ci.yml) provides a 4-stage pipeline (check, build, test, security) with Vulnix + Trivy scans and Pages-published reports.

### Binary Cache

Cachix (`marcosfpina`) is populated by CI; local rebuilds pull pre-built closures when available.

---

## Documentation

- [Technical Overview](docs/TECHNICAL-OVERVIEW.md)
- [CI/CD Architecture](docs/CI-CD-ARCHITECTURE.md)
- [GitHub Actions guide](.github/README.md)
- [Workflows guide](.github/workflows/README.md)

---

## Security Notice

- **Environment**: production workstation.
- **Posture**: hardened (kernel, compiler, network, filesystem).
- **Secrets**: encrypted with SOPS + age.
- **Audit**: AIDE + auditd + Wazuh logging across system surfaces.

Sensitive material (API keys, SSH keys, certificates) lives encrypted in `secrets/`. Decryption requires the appropriate age key.

---

## Stats

- **Modules**: 278 across 20 categories
- **Nix lines**: ~47,800
- **Security + SOC modules**: 39
- **ML modules**: 36
- **Custom packages**: 36
- **Shell modules**: 35

Largest modules:

1. `vmctl` — 959 lines (VM orchestration CLI)
2. `thermal-forensics` — 760 lines (hardware evidence collection)
3. `rebuild-advanced` — 674 lines (safe rebuild system)

---

## License

[MIT](LICENSE)

---

## Acknowledgments

Built on:

- [NixOS](https://nixos.org) — declarative Linux distribution
- [Hyprland](https://hyprland.org) — Wayland compositor
- [Wazuh](https://wazuh.com) — XDR/SIEM platform
- [llama.cpp](https://github.com/ggerganov/llama.cpp) — LLM inference engine

---

**Maintained by**: [@VoidNxSEC](https://github.com/VoidNxSEC)
**Hardware**: Lenovo ThinkPad + NVIDIA GPU
**Channel**: nixos-unstable
**Status**: production (daily driver)
