{ ... }:

# ═══════════════════════════════════════════════════════════════
# KERNELCORE NIXOS - CENTRAL MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: Single entry point for ALL system modules
# Pattern: Flake-parts compatible, modular architecture
# Usage: In flake.nix → imports = [ ./modules ];
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    # ═══════════════════════════════════════════════════════════
    # CORE SYSTEM
    # ═══════════════════════════════════════════════════════════
    ./system # Nix config, memory, aliases, binary cache, SSH
    ./hardware # NVIDIA, Intel, thermal, i915-governor
    ./audio # Pipewire, video production

    # ═══════════════════════════════════════════════════════════
    # SECURITY (imported early, hardened profile: modules/security/profiles/hardened.nix)
    # ═══════════════════════════════════════════════════════════
    ./security # Boot, kernel, network, SSH hardening, audit + SOC (security/soc/)

    # ═══════════════════════════════════════════════════════════
    # NETWORK
    # ═══════════════════════════════════════════════════════════
    ./network # DNS, VPN (Tailscale, NordVPN), proxy, firewall, monitoring

    # ═══════════════════════════════════════════════════════════
    # SERVICES
    # ═══════════════════════════════════════════════════════════
    ./services # Offload, users, GPU orchestration, Mosh, mobile workspace, MCP server

    # ═══════════════════════════════════════════════════════════
    # BLOCKCHAIN & CRYPTO INTELLIGENCE
    # ═══════════════════════════════════════════════════════════
    ./blockchain # Algorand dev env, CHAINSCOPE crypto research pipeline

    # ═══════════════════════════════════════════════════════════
    # DEVELOPMENT & ML
    # ═══════════════════════════════════════════════════════════
    ./development # Dev environments, Claude profiles, Jupyter, CI/CD
    # ./devops # DevOps tools - imported in home-manager (hosts/kernelcore/home/home.nix)
    ./ml # ML infrastructure + AI agents (consolidates machine-learning/ + ai/)

    # ═══════════════════════════════════════════════════════════
    # CONTAINERS & VIRTUALIZATION
    # ═══════════════════════════════════════════════════════════
    ./containers # Docker, Podman, NixOS containers
    ./virtualization # VMs, vmctl, macOS KVM

    # ═══════════════════════════════════════════════════════════
    # KUBERNETES (modules loaded; activation via specialisations)
    # See: hosts/kernelcore/specialisations/k8s-lab.nix
    #      hosts/kernelcore/specialisations/k8s-prod.nix
    # ═══════════════════════════════════════════════════════════
    ./kubernetes # K3s, Kind, Longhorn, Cilium CNI

    # ═══════════════════════════════════════════════════════════
    # DESKTOP & APPLICATIONS
    # ═══════════════════════════════════════════════════════════
    ./desktop # GNOME, Yazi, desktop environment
    ./applications # Browsers (Firefox, Brave), editors (VSCode, VSCodium)
    ./programs # User programs and utilities

    # ═══════════════════════════════════════════════════════════
    # TOOLS & PACKAGES
    # ═══════════════════════════════════════════════════════════
    ./tools # Unified CLI (SecOps, Intel, Nix utils, LLM, MCP, arch-analyzer)
    ./packages # Declarative .deb, flatpak, tar packages (Zellij, Gemini CLI, Lynis)

    # ═══════════════════════════════════════════════════════════
    # SHELL & SECRETS
    # ═══════════════════════════════════════════════════════════
    ./shell # Shell aliases, GPU flags, professional alias structure
    ./secrets # SOPS config, API keys, AWS Bedrock, Tailscale secrets

    ./debug # Swissknife debug tools, io-monitor, debug-init
  ];
}
