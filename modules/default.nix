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
    # SECURITY (imported early, overridden last via sec/hardening.nix)
    # ═══════════════════════════════════════════════════════════
    ./security # Boot, kernel, network, SSH hardening, audit
    ./soc # Security Operations Center (NSA-level)

    # ═══════════════════════════════════════════════════════════
    # NETWORK
    # ═══════════════════════════════════════════════════════════
    ./network # DNS, VPN (Tailscale, NordVPN), proxy, firewall, monitoring

    # ═══════════════════════════════════════════════════════════
    # SERVICES
    # ═══════════════════════════════════════════════════════════
    ./services # Offload, users, GPU orchestration, Mosh, mobile workspace, MCP server

    # ═══════════════════════════════════════════════════════════
    # DEVELOPMENT & ML
    # ═══════════════════════════════════════════════════════════
    ./development # Dev environments, Claude profiles, Jupyter, CI/CD
    ./machine-learning # Machine Learning infrastructure (llama.cpp-turbo, vLLM)

    # ═══════════════════════════════════════════════════════════
    # CONTAINERS & VIRTUALIZATION
    # ═══════════════════════════════════════════════════════════
    ./containers # Docker, Podman, NixOS containers
    ./virtualization # VMs, vmctl, macOS KVM

    # Kubernetes Orquestration
    # TODO: CRITICAL: Work to do
    ./modules/system/base.nix
    ./modules/containers/k3s-cluster.nix
    ./modules/network/cilium-cni.nix
    ./modules/containers/longhorn-storage.nix

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

    # ═══════════════════════════════════════════════════════════
    # DEBUG (optional - comment out if not needed)
    # ═══════════════════════════════════════════════════════════
    ./debug # Swissknife diagnostic tools
  ];
}
