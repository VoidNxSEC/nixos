# NixOS Configuration Framework

A modular, production-grade NixOS configuration covering desktop, development, ML/AI infrastructure, and enterprise security. Designed to be forked and adapted — not tied to any single machine or user.

[!\[NixOS\](https://img.shields.io/badge/NixOS-Unstable-blue?logo=nixos\&logoColor=white)](https://nixos.org)
[!\[CI\](https://github.com/VoidNxLabs/nixos/actions/workflows/nixos-public.yml/badge.svg)](https://github.com/VoidNxLabs/nixos/actions/workflows/nixos-public.yml)
[!\[SOPS Encrypted\](https://img.shields.io/badge/Secrets-SOPS%2Fage-purple)](https://github.com/getsops/sops)
[!\[Cachix\](https://img.shields.io/badge/Cache-Cachix-blue)](https://app.cachix.org)

---

## What's included

| Domain          | Highlights                                                                           |
| --------------- | ------------------------------------------------------------------------------------ |
| **ML / AI**     | llama.cpp, vLLM, model registry, VRAM orchestration, MCP servers, AI agent ecosystem |
| **Security**    | Kernel hardening, AIDE FIM, ClamAV, AppArmor, audit rules, SSH hardening             |
| **SOC / SIEM**  | Wazuh EDR, Suricata IDS/IPS, OpenSearch, Grafana, threat intelligence                |
| **Desktop**     | Hyprland (Wayland), i3 (X11), PipeWire audio, Waybar, glassmorphism theming          |
| **Development** | Dev shells (Python, Rust, CUDA, infra), containers, VMs, macOS KVM                   |
| **Network**     | Tailscale mesh VPN, nftables zones, DNSCrypt, DNS-over-TLS, NGINX                    |
| **Kubernetes**  | K3s cluster, Cilium CNI, Longhorn storage                                            |
| **CI/CD**       | BuildBot, GitHub Actions (self-hosted runner), GitLab CI                             |
| **Secrets**     | sops-nix with age encryption                                                         |

---

## Quick start

### Use as a template

````bash
git clone https://github.com/VoidNxLabs/nixos.git /etc/nixos
cd /etc/nixos

# Generate hardware config for your machine
sudo nixos-generate-config --show-hardware-config > hosts/my-machine/hardware-configuration.nix

# Create host configuration
mkdir -p hosts/my-machine
cat > hosts/my-machine/configuration.nix <<'EOF'
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../_examples/desktop-workstation.nix  # or minimal-server.nix, k8s-node.nix
  ];

  networking.hostName = "my-machine";
  system.user.username = "myusername";   # propagates to all modules
}
### Use as a template (Recommended)

The easiest way to start a new configuration using this framework:

```bash
# Initialize a new project in the current directory
nix flake init -t github:VoidNxSEC/nixos

# Then follow the instructions in the generated README.md
````

### Use as a Framework

You can also use the modules directly in your own `flake.nix` without cloning this repo:

```javascript
# flake.nix
inputs.void-nixos.url = "github:VoidNxSEC/nixos";

# In your nixosSystem
modules = [
  void-nixos.nixosModules.default # Imports all framework modules + overlays
  ./configuration.nix
];
```

### Enabling features

Once the framework is imported, enable features using the `kernelcore.*` (or standard `services.*`) options:

---

## Repository structure

```javascript
/etc/nixos/
├── flake.nix                     # Entry point, inputs, host declarations
├── hosts/
│   ├── _examples/                # Starting-point host templates
│   │   ├── desktop-workstation.nix
│   │   ├── minimal-server.nix
│   │   └── k8s-node.nix
│   ├── kernelcore/               # Full workstation instance
│   ├── workstation/
│   └── k8s-node/
├── modules/                      # ~280 NixOS modules across 21 categories
│   ├── ml/                       # ML/AI infrastructure + agent ecosystem
│   │   ├── infrastructure/       # Storage, VRAM monitoring, hardware
│   │   ├── services/             # llama.cpp, vLLM, TabbyAPI
│   │   ├── integrations/         # MCP servers, Neovim integration
│   │   ├── orchestration/        # Container/K8s ML workloads
│   │   └── agents/               # AI agents (neoland, neotron, cerebro, phantom)
│   ├── security/                 # Hardening + SOC
│   │   ├── *.nix                 # Kernel, boot, SSH, audit, ClamAV, AIDE
│   │   └── soc/                  # IDS, EDR, SIEM, dashboards, alerting
│   ├── desktop/                  # Hyprland, i3, Wayland compositing
│   ├── network/                  # VPN, DNS, firewall, monitoring
│   ├── development/              # Dev environments, CI/CD, Jupyter
│   ├── containers/               # Docker, Podman, K3s, Longhorn
│   ├── virtualization/           # QEMU/KVM, vmctl, macOS guest
│   ├── hardware/                 # NVIDIA, Intel, thermal management
│   ├── audio/                    # PipeWire, professional audio stack
│   ├── shell/                    # Aliases, completions, CLI helpers
│   ├── system/                   # Boot, users, Nix daemon, SSH config
│   ├── services/                 # MCP server, GPU orchestration, Mosh
│   ├── blockchain/               # Algorand, crypto tooling
│   └── ...                       # applications, tools, packages, secrets
├── lib/                          # Reusable builders and helpers
├── overlays/                     # nixpkgs customizations
├── secrets/                      # SOPS-encrypted secrets
├── flakes/
│   └── personal.nix.example      # Template for private/SSH flake inputs
├── ci-cd/                        # BuildBot pipelines
└── docs/
    └── runbooks/                 # Step-by-step operational guides
```

---

## Customization

### Change username system-wide

All modules reference `config.system.user.username` — set it once in your host:

```javascript
# hosts/my-machine/configuration.nix
system.user.username = "alice";   # home paths, users, Home Manager all follow
```

See `modules/system/user-config.nix` for the full option set.

### Add private flake inputs

Private repos, local paths, and SSH-authenticated inputs belong in `flakes/personal.nix`
to keep the main flake community-clean:

```bash
cp flakes/personal.nix.example flakes/personal.nix
# edit with your inputs, then reference from flake.nix
```

### Enable optional features

```javascript
# ML inference stack (requires GPU)
kernelcore.ml.llama.enable = true;

# Security Operations Center
kernelcore.soc.enable = true;
kernelcore.soc.profile = "standard";  # minimal | standard | enterprise

# SecureLLM MCP server
services.securellm-mcp.enable = true;
```

---

## Notable implementations

**Thermal forensics** (`modules/hardware/laptop-defense/`) — structured evidence collection
for hardware warranty claims: baseline → stress → rebuild thermal profiles with automated reports.

**Advanced rebuild** (`modules/shell/aliases/nix/rebuild-advanced.nix`) — pre-flight
validation, thermal monitoring, and binary cache integration wrapped around `nixos-rebuild`.

**GPU orchestration** (`modules/services/`) — automatic model unloading when VRAM drops
below threshold, service priority queues, real-time monitoring.

**SOC on a workstation** (`modules/security/soc/`) — full Wazuh + OpenSearch + Suricata
stack running as NixOS services, declaratively configured.

Known issues: The server needs more optimization

**Tricks: try git-commit-ai for automated commits (check if you have a local gpu)&#x20;**

---

## Development shells

```bash
nix develop .#default   # general development
nix develop .#python    # Python + ML libraries
nix develop .#cuda      # CUDA development
nix develop .#rust      # Rust toolchain
nix develop .#infra     # Terraform, Ansible, kubectl
```

---

## CI/CD

Self-hosted GitHub Actions runner on NixOS with Cachix binary cache.
GitLab CI mirrors the pipeline with artifact-based caching.

Checks on every push: `nix flake check`, nixfmt, secret scanning, vulnix CVE scan.
On merge to main: full build matrix (toplevel, ISO, VM image) + deployment.

See `ci-cd/` for BuildBot pipelines and `.github/workflows/` for Actions configs.

---

## Security

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption.
No plaintext credentials exist in this repository.

Security modules are imported last in the module chain, ensuring they have highest priority
and cannot be weakened by other modules.

---

## Contributing

Modules must:

- Use `mkEnableOption` / `mkOption` with descriptions on all options
- Avoid hardcoded usernames or absolute paths (use `config.system.user.*`)
- Pass `nix flake check` before submission

See `docs/runbooks/` for operational guides and `hosts/_examples/` for reference configurations.

---

## License

MIT — see [LICENSE](LICENSE).
