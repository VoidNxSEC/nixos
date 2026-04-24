# 🤖 AI Architecture Report

> **Generated**: 2026-01-03T18:23:05.830458
> **Model**: `default`
> **Duration**: 1415.2s

## Executive Summary

The NixOS repository contains a large number of modules and lines of code, organized into various categories. There are several orphaned files that may need review or cleanup.

**Quality Score: 28/100**

| Metric | Value |
|--------|-------|
| Modules | 299 | 🟢 ↗31 |
| Lines | 61,701 | 🟢 ↗8712 |
| Categories | 23 | - |
| Orphans | 216 | 🔴 ↘36 |

## Priority Actions

1. Review and clean up orphaned files
2. Organize modules into more specific categories
3. Ensure all modules are up-to-date with the latest NixOS standards

## Orphan Modules

Found **216** modules not imported anywhere:

### etc/ (216 orphans)

- `etc/nixos/ci-cd/buildbot/master.nix`
- `etc/nixos/ci-cd/buildbot/projects.nix`
- `etc/nixos/ci-cd/buildbot/workers.nix`
- `etc/nixos/ci-cd/tailscale-integration-test.nix`
- `etc/nixos/docs/TEMPLATE.nix`
- `etc/nixos/docs/guides/KERNELCORE-TAILSCALE-CONFIG.nix`
- `etc/nixos/docs/guides/TAILSCALE-LAPTOP-CLIENT.nix`
- `etc/nixos/docs/guides/TAILSCALE-QUICK-START.nix`
- `etc/nixos/home/niri.nix`
- `etc/nixos/hosts/k8s-node/k8s-original/k8s/cilium-cni.nix`
- `etc/nixos/hosts/k8s-node/k8s-original/k8s/example-k8s-configuration.nix`
- `etc/nixos/hosts/k8s-node/k8s-original/k8s/k3s-cluster.nix`
- `etc/nixos/hosts/k8s-node/k8s-original/k8s/longhorn-storage.nix`
- `etc/nixos/hosts/kernelcore/configurations-template.nix`
- `etc/nixos/hosts/kernelcore/home/alacritty.nix`
- `etc/nixos/hosts/kernelcore/home/aliases/nixos-aliases.nix`
- `etc/nixos/hosts/kernelcore/home/brave.nix`
- `etc/nixos/hosts/kernelcore/home/electron-apps.nix`
- `etc/nixos/hosts/kernelcore/home/electron-config.nix`
- `etc/nixos/hosts/kernelcore/home/firefox.nix`
- `etc/nixos/hosts/kernelcore/home/flameshot.nix`
- `etc/nixos/hosts/kernelcore/home/git.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/agent-hub.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/hyprlock.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/kitty.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/mako.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/swappy.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/wallpaper.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/waybar.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/wlogout.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/wofi.nix`
- `etc/nixos/hosts/kernelcore/home/glassmorphism/zellij.nix`
- `etc/nixos/hosts/kernelcore/home/hyprland.nix`
- `etc/nixos/hosts/kernelcore/home/niri/niri.nix`
- `etc/nixos/hosts/kernelcore/home/niri/waybar-niri.nix`
- `etc/nixos/hosts/kernelcore/home/shell/bash.nix`
- `etc/nixos/hosts/kernelcore/home/shell/options.nix`
- `etc/nixos/hosts/kernelcore/home/shell/zsh.nix`
- `etc/nixos/hosts/kernelcore/home/theme.nix`
- `etc/nixos/hosts/kernelcore/home/tmux.nix`
- `etc/nixos/hosts/kernelcore/home/yazi.nix`
- `etc/nixos/hosts/kernelcore/specialisations/niri.nix`
- `etc/nixos/hosts/kernelcore/users/actions.nix`
- `etc/nixos/hosts/kernelcore/users/claude-code.nix`
- `etc/nixos/hosts/kernelcore/users/codex-agent.nix`
- `etc/nixos/hosts/kernelcore/users/gemini-agent.nix`
- `etc/nixos/hosts/kernelcore/users/gitlab-runner.nix`
- `etc/nixos/lib/shell.nix`
- `etc/nixos/modules/applications/brave-secure.nix`
- `etc/nixos/modules/applications/cache-optimization.nix`
- `etc/nixos/modules/applications/chromium.nix`
- `etc/nixos/modules/applications/electron-tuning-v2.nix`
- `etc/nixos/modules/applications/electron-tuning.nix`
- `etc/nixos/modules/applications/firefox-privacy.nix`
- `etc/nixos/modules/applications/nemo-full.nix`
- `etc/nixos/modules/applications/vscode-secure.nix`
- `etc/nixos/modules/applications/vscodium-secure.nix`
- `etc/nixos/modules/applications/zellij.nix`
- `etc/nixos/modules/audio/production.nix`
- `etc/nixos/modules/audio/video-production.nix`
- `etc/nixos/modules/blockchain/algorand/dao.nix`
- `etc/nixos/modules/containers/docker-hub.nix`
- `etc/nixos/modules/containers/docker.nix`
- `etc/nixos/modules/containers/k3s-cluster.nix`
- `etc/nixos/modules/containers/longhorn-storage.nix`
- `etc/nixos/modules/containers/nixos-containers.nix`
- `etc/nixos/modules/containers/podman.nix`
- `etc/nixos/modules/debug/debug-init.nix`
- `etc/nixos/modules/debug/io-monitor.nix`
- `etc/nixos/modules/debug/test-init.nix`
- `etc/nixos/modules/debug/tools-integration.nix`
- `etc/nixos/modules/desktop/hyprland-modular/examples.nix`
- `etc/nixos/modules/desktop/hyprland-performance.nix`
- `etc/nixos/modules/desktop/hyprland.nix`
- `etc/nixos/modules/desktop/i3-lightweight.nix`
- `etc/nixos/modules/development/cicd.nix`
- `etc/nixos/modules/development/claude-profiles.nix`
- `etc/nixos/modules/development/environments.nix`
- `etc/nixos/modules/development/jupyter.nix`
- `etc/nixos/modules/hardware/bluetooth.nix`
- `etc/nixos/modules/hardware/intel.nix`
- `etc/nixos/modules/hardware/laptop-defense/mcp-integration.nix`
- `etc/nixos/modules/hardware/laptop-defense/rebuild-hooks.nix`
- `etc/nixos/modules/hardware/lenovo-throttled.nix`
- `etc/nixos/modules/hardware/nvidia.nix`
- `etc/nixos/modules/hardware/thermal-profiles.nix`
- `etc/nixos/modules/hardware/trezor.nix`
- `etc/nixos/modules/hardware/wifi-optimization.nix`
- `etc/nixos/modules/machine-learning/infrastructure/storage.nix`
- `etc/nixos/modules/machine-learning/infrastructure/vram/monitoring.nix`
- `etc/nixos/modules/machine-learning/integrations/mcp/config.nix`
- `etc/nixos/modules/machine-learning/services/llama-cpp-turbo.nix`
- `etc/nixos/modules/machine-learning/services/vllm.nix`
- `etc/nixos/modules/network/bridge.nix`
- `etc/nixos/modules/network/cilium-cni.nix`
- `etc/nixos/modules/network/dns-resolver.nix`
- `etc/nixos/modules/network/monitoring/tailscale-monitor.nix`
- `etc/nixos/modules/network/proxy/nginx-tailscale.nix`
- `etc/nixos/modules/network/proxy/tailscale-services.nix`
- `etc/nixos/modules/network/security/firewall-zones.nix`
- `etc/nixos/modules/network/vpn/nordvpn.nix`
- `etc/nixos/modules/network/vpn/tailscale-desktop.nix`
- `etc/nixos/modules/network/vpn/tailscale-laptop.nix`
- `etc/nixos/modules/network/vpn/tailscale.nix`
- `etc/nixos/modules/packages/antigravity/security.nix`
- `etc/nixos/modules/packages/antigravity/tuning-fixed.nix`
- `etc/nixos/modules/packages/antigravity/tuning.nix`
- `etc/nixos/modules/packages/gemini/build-gemini.nix`
- `etc/nixos/modules/packages/gemini/fhs.nix`
- `etc/nixos/modules/packages/gemini/gemini-cli.nix`
- `etc/nixos/modules/packages/gemini/js-packages.nix`
- `etc/nixos/modules/packages/lib/sandbox.nix`
- `etc/nixos/modules/programs/cognitive-vault.nix`
- `etc/nixos/modules/programs/phantom.nix`
- `etc/nixos/modules/programs/vmctl.nix`
- `etc/nixos/modules/secrets/api-keys.nix`
- `etc/nixos/modules/secrets/aws-bedrock.nix`
- `etc/nixos/modules/secrets/k8s.nix`
- `etc/nixos/modules/secrets/sops-config.nix`
- `etc/nixos/modules/secrets/tailscale.nix`
- `etc/nixos/modules/security/aide.nix`
- `etc/nixos/modules/security/audit.nix`
- `etc/nixos/modules/security/auto-upgrade.nix`
- `etc/nixos/modules/security/boot.nix`
- `etc/nixos/modules/security/clamav.nix`
- `etc/nixos/modules/security/compiler-hardening.nix`
- `etc/nixos/modules/security/dev-directory-hardening.nix`
- `etc/nixos/modules/security/hardening.nix`
- `etc/nixos/modules/security/kernel.nix`
- `etc/nixos/modules/security/keyring.nix`
- `etc/nixos/modules/security/network.nix`
- `etc/nixos/modules/security/nix-daemon.nix`
- `etc/nixos/modules/security/pam.nix`
- `etc/nixos/modules/security/ssh.nix`
- `etc/nixos/modules/services/config-auditor.nix`
- `etc/nixos/modules/services/gitea-showcase.nix`
- `etc/nixos/modules/services/gpu-orchestration.nix`
- `etc/nixos/modules/services/laptop-builder-client.nix`
- `etc/nixos/modules/services/laptop-offload-client.nix`
- `etc/nixos/modules/services/mcp-server.nix`
- `etc/nixos/modules/services/mobile-workspace.nix`
- `etc/nixos/modules/services/mosh.nix`
- `etc/nixos/modules/services/offload-server.nix`
- `etc/nixos/modules/services/scripts.nix`
- `etc/nixos/modules/shell/aliases/amazon/aws.nix`
- `etc/nixos/modules/shell/aliases/desktop/hyprland.nix`
- `etc/nixos/modules/shell/aliases/docker/build.nix`
- `etc/nixos/modules/shell/aliases/docker/compose.nix`
- `etc/nixos/modules/shell/aliases/docker/run.nix`
- `etc/nixos/modules/shell/aliases/emergency.nix`
- `etc/nixos/modules/shell/aliases/gcloud/gcloud.nix`
- `etc/nixos/modules/shell/aliases/kubernetes/k8s-cluster.nix`
- `etc/nixos/modules/shell/aliases/kubernetes/kubectl.nix`
- `etc/nixos/modules/shell/aliases/laptop-defense.nix`
- `etc/nixos/modules/shell/aliases/macos-kvm.nix`
- `etc/nixos/modules/shell/aliases/mcp.nix`
- `etc/nixos/modules/shell/aliases/nix/analytics.nix`
- `etc/nixos/modules/shell/aliases/nix/rebuild-advanced.nix`
- `etc/nixos/modules/shell/aliases/nix/rebuild-helpers.nix`
- `etc/nixos/modules/shell/aliases/nix/system.nix`
- `etc/nixos/modules/shell/aliases/nixos-explorer.nix`
- `etc/nixos/modules/shell/aliases/security/secrets.nix`
- `etc/nixos/modules/shell/aliases/service-control.nix`
- `etc/nixos/modules/shell/aliases/sync.nix`
- `etc/nixos/modules/shell/aliases/system/navigation.nix`
- `etc/nixos/modules/shell/aliases/system/utils.nix`
- `etc/nixos/modules/shell/cli-helpers.nix`
- `etc/nixos/modules/shell/gpu-flags.nix`
- `etc/nixos/modules/shell/training-logger.nix`
- `etc/nixos/modules/soc/alerting/alerting.nix`
- `etc/nixos/modules/soc/dashboards/grafana.nix`
- `etc/nixos/modules/soc/edr/edr.nix`
- `etc/nixos/modules/soc/edr/fim.nix`
- `etc/nixos/modules/soc/ids/suricata.nix`
- `etc/nixos/modules/soc/ids/threat-intel.nix`
- `etc/nixos/modules/soc/network/dns-monitor.nix`
- `etc/nixos/modules/soc/network/netflow.nix`
- `etc/nixos/modules/soc/options.nix`
- `etc/nixos/modules/soc/siem/log-aggregator.nix`
- `etc/nixos/modules/soc/siem/opensearch.nix`
- `etc/nixos/modules/soc/siem/wazuh.nix`
- `etc/nixos/modules/soc/tools.nix`
- `etc/nixos/modules/system/aliases.nix`
- `etc/nixos/modules/system/binary-cache.nix`
- `etc/nixos/modules/system/emergency-monitor.nix`
- `etc/nixos/modules/system/io-scheduler.nix`
- `etc/nixos/modules/system/memory.nix`
- `etc/nixos/modules/system/ml-gpu-users.nix`
- `etc/nixos/modules/system/nix.nix`
- `etc/nixos/modules/system/services.nix`
- `etc/nixos/modules/system/ssh-config.nix`
- `etc/nixos/modules/tools/dev.nix`
- `etc/nixos/modules/tools/diagnostics.nix`
- `etc/nixos/modules/tools/intel.nix`
- `etc/nixos/modules/tools/llm.nix`
- `etc/nixos/modules/tools/mcp.nix`
- `etc/nixos/modules/tools/nix-utils.nix`
- `etc/nixos/modules/tools/secops.nix`
- `etc/nixos/modules/tools/secrets.nix`
- `etc/nixos/modules/virtualization/macos-kvm.nix`
- `etc/nixos/modules/virtualization/vmctl.nix`
- `etc/nixos/modules/virtualization/vms.nix`
- `etc/nixos/overlays/antigravity.nix`
- `etc/nixos/overlays/python-packages.nix`
- `etc/nixos/sec/hardening.nix`
- `etc/nixos/skills/nix-expert/nixos-linux-master/assets/flake-templates/smart-template.nix`
- `etc/nixos/templates/cypher-host.nix`
- `etc/nixos/templates/desktop-cfg.nix`
- `etc/nixos/templates/desktop-cfg2.nix`
- `etc/nixos/templates/desktop-config-backup.nix`
- `etc/nixos/templates/desktop-config-clean.nix`
- `etc/nixos/templates/fix-sudo.nix`
- `etc/nixos/templates/fix-sudo2.nix`
- `etc/nixos/templates/fix-sudo3.nix`
- `etc/nixos/templates/hardening-template.nix`
- `etc/nixos/templates/test-remote-build.nix`

## Module Analysis

### applications/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `chromium` | This NixOS module configures and wraps the Chromiu... | 🟡 |
| `vscode-secure` | Configures VSCode with Firejail sandboxing and add... | 🟡 |
| `vscodium-secure` | Configures VSCodium with Firejail sandboxing and r... | 🟡 |
| `zellij` | This NixOS module configures and optimizes Zellij,... | 🟢 |
| `firefox-privacy` | Configures Firefox for enhanced privacy and perfor... | 🟡 |
| `brave-secure` | Configures Brave browser with Firejail GPU memory ... | 🟡 |
| `electron-tuning-v2` | This NixOS module provides a per-app isolation arc... | 🟢 |
| `nemo-full` | This NixOS module configures the Nemo file manager... | 🟢 |
| `cache-optimization` | Optimizes Electron app cache performance by moving... | 🟡 |
| `electron-tuning` | Optimize Electron and Chromium applications for pe... | 🟢 |

### audio/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `production` | Configures an audio production environment with op... | 🟢 |
| `video-production` | Configures an audio/video production environment w... | 🟡 |
| `default` | Aggregates audio-related configurations from produ... | 🟢 |

### blockchain/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `dao` | This NixOS module defines a PyTeal template for an... | 🟡 |
| `default` | Provides a development environment for Algorand sm... | 🟢 |

### containers/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `longhorn-storage` | This NixOS module configures and deploys Longhorn ... | 🟢 |
| `docker-hub` | Provides shell aliases and a smart CLI wrapper for... | 🟢 |
| `k3s-cluster` | Configures a K3s Kubernetes cluster with options f... | 🟡 |
| `nixos-containers` | Configures NixOS containers with network and firew... | 🟡 |
| `podman` | This NixOS module configures Podman container supp... | 🟡 |
| `docker` | Enables Docker container support in NixOS | 🟢 |
| `default` | Imports all container runtime configurations for D... | 🟢 |

### debug/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `debug-init` | Provides utilities for debugging configuration iss... | 🟢 |
| `test-init` | Provides utilities for safely testing NixOS config... | 🟢 |
| `io-monitor` | Provides IO monitoring tools and periodic collecti... | 🟢 |
| `tools-integration` | Integrates Swissknife Debug Tools into NixOS for p... | 🟢 |
| `default` | Aggregates various debug-related NixOS modules. | 🟢 |

### default.nix/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `default` | A central module aggregator for NixOS, importing v... | 🟢 |

### desktop/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `default` | This NixOS module configures the Hyprland Modular ... | 🟡 |
| `i3-lightweight` | Configures a lightweight desktop environment using... | 🟡 |
| `default` | Provides utility functions and window rule builder... | 🟢 |
| `default` | Defines window rules for various applications in a... | 🟢 |
| `default` | Defines a system for creating and managing themes ... | 🟢 |
| `default` | Defines usage profiles for Hyprland, a Wayland com... | 🟢 |
| `default` | Defines keybindings for the Hyprland modular windo... | 🟢 |
| `hyprland` | Configures a pure Wayland desktop environment usin... | 🟡 |
| `examples` | Provides configuration examples for the Hyprland M... | 🟢 |
| `default` | Manages and configures Hyprland plugins | 🟢 |

### development/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `claude-profiles` | Provides a shell script for managing API profiles ... | 🟢 |
| `cicd` | This NixOS module configures CI/CD development too... | 🟢 |
| `jupyter` | This NixOS module configures and enables a Jupyter... | 🟢 |
| `environments` | This NixOS module configures development environme... | 🟢 |
| `default` | Aggregates development-related NixOS modules | 🟢 |

### hardware/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `flake` | A script to collect thermal forensic data from a l... | 🟢 |
| `thermal-profiles` | Manages thermal profiles for hardware components i... | 🟡 |
| `rebuild-hooks` | Integrates thermal safety checks and evidence coll... | 🟡 |
| `intel` | This NixOS module configures various Intel hardwar... | 🟡 |
| `lenovo-throttled` | Configures thermal management settings for Lenovo ... | 🟡 |
| `nvidia` | Configures NVIDIA hardware and services on NixOS | 🟡 |
| `mcp-integration` | Integrates thermal forensics and safety checks int... | 🟡 |
| `wifi-optimization` | Optimizes WiFi performance on NixOS systems by con... | 🟡 |
| `trezor` | Configures Trezor hardware wallet support, includi... | 🟢 |
| `bluetooth` | Enables Bluetooth support with GUI management on N... | 🟢 |

### machine-learning/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `llama-cpp-turbo` | Configures a high-performance inference server for... | 🟢 |
| `vllm` | Configures and enables the vLLM Inference Server f... | 🟢 |
| `monitoring` | This NixOS module configures a VRAM Intelligence S... | 🟡 |
| `config` | Configures MCP (Model Context Protocol) for NixOS ... | 🟡 |
| `storage` | This NixOS module configures a standardized storag... | 🟡 |
| `default` | This NixOS module aggregates various machine learn... | 🟢 |
| `default` | Imports configuration files for storage, VRAM moni... | 🟢 |
| `default` | This NixOS module imports configuration for infere... | 🟢 |
| `default` | Manages GPU VRAM allocation and monitoring for mac... | 🟢 |
| `default` | Imports configuration for Model Context Protocol s... | 🟢 |

### ml/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `flake` | This NixOS module defines a service for an ML Offl... | 🟢 |

### network/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `tailscale-monitor` | A script to monitor Tailscale connectivity, measur... | 🟡 |
| `tailscale` | This NixOS module configures Tailscale VPN setting... | 🟢 |
| `firewall-zones` | Define and configure firewall zones using nftables... | 🟡 |
| `cilium-cni` | This NixOS module configures Cilium CNI with eBPF ... | 🟢 |
| `nginx-tailscale` | Configures an NGINX reverse proxy for Tailscale se... | 🟡 |
| `nordvpn` | Configures NordVPN with NordLynx (WireGuard) integ... | 🟡 |
| `dns-resolver` | Configures DNS resolver settings, including DNSSEC... | 🟡 |
| `tailscale-desktop` | Configures Tailscale for a desktop device to act a... | 🟡 |
| `default` | This NixOS module configures and installs a DNS pr... | 🟢 |
| `tailscale-services` | Configures Tailscale and NGINX for service exposur... | 🟡 |

### packages/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `js-packages` | This NixOS module defines a declarative way to man... | 🟢 |
| `tuning-fixed` | High-performance Electron configuration for Antigr... | 🟡 |
| `fhs` | Provides a FHS environment for the Gemini CLI, ens... | 🟡 |
| `tuning` | Provides performance tuning for Antigravity using ... | 🟢 |
| `default` | This NixOS module defines a derivation for the App... | 🟢 |
| `builder` | This NixOS module defines a function to build and ... | 🟡 |
| `gemini-cli` | Configures the installation and sandboxing of the ... | 🟢 |
| `security` | Provides security hardening for Antigravity using ... | 🟡 |
| `default` | Provides the Claude Code CLI as a system package w... | 🟢 |
| `default` | Installs and configures the Lynis security auditin... | 🟢 |

### programs/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `phantom` | This NixOS module integrates Phantom as a flake in... | 🟢 |
| `vmctl` | Provides configuration for the vmctl package, a li... | 🟢 |
| `cognitive-vault` | A NixOS module to manage the CognitiveVault packag... | 🟢 |
| `default` | Enables XWayland support for Sway and imports conf... | 🟢 |

### root/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `waybar` | Configures Waybar, a status bar for Wayland and Xo... | 🟡 |
| `niri` | Configures the Niri window manager with input, out... | 🟢 |
| `configuration` | This NixOS module configures various system settin... | 🟠 |
| `yazi` | Configures Yazi file manager with advanced setting... | 🟢 |
| `fix-sudo3` | This NixOS module configures various system settin... | 🟢 |
| `desktop-config-backup` | This NixOS module provides a configuration templat... | 🟢 |
| `cypher-host` | This NixOS module configures a system with various... | 🟢 |
| `fix-sudo2` | This NixOS module configures various system settin... | 🟢 |
| `fix-sudo` | This NixOS module configures various system settin... | 🟢 |
| `desktop-cfg` | Provides a base configuration for a desktop enviro... | 🟢 |

### secrets/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `sops-config` | Configures SOPS secrets management in NixOS | 🟢 |
| `api-keys` | Manages and loads API keys from encrypted files in... | 🟢 |
| `aws-bedrock` | Manages AWS Bedrock credentials and environment va... | 🟢 |
| `tailscale` | Manages Tailscale secrets using SOPS and ensures t... | 🟢 |
| `k8s` | Enables and configures Kubernetes secrets decrypti... | 🟢 |
| `default` | Aggregates various secrets management modules for ... | 🟢 |

### security/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `dev-directory-hardening` | Provides security hardening for a development dire... | 🟡 |
| `aide` | Configures AIDE (Advanced Intrusion Detection Envi... | 🟢 |
| `ssh` | This NixOS module configures SSH security hardenin... | 🟡 |
| `keyring` | Configures keyring support with GNOME Keyring, Kee... | 🟡 |
| `nix-daemon` | This NixOS module configures security settings for... | 🟢 |
| `kernel` | This NixOS module configures kernel security harde... | 🟢 |
| `compiler-hardening` | Enables compiler hardening flags to enhance securi... | 🟢 |
| `clamav` | Configures ClamAV antivirus scanning on a NixOS sy... | 🟡 |
| `audit` | Configures security auditing, logging, and related... | 🟡 |
| `packages` | Installs security and audit tools on a NixOS syste... | 🟢 |

### services/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `gitea-showcase` | Configures and manages a Gitea service with automa... | 🟡 |
| `laptop-offload-client` | Configures a NixOS laptop to offload builds to a d... | 🟢 |
| `mobile-workspace` | This NixOS module configures an isolated mobile wo... | 🟢 |
| `offload-server` | Configures an NixOS system as an offload build ser... | 🟡 |
| `mcp-server` | This NixOS module configures and manages the Secur... | 🟢 |
| `mosh` | This NixOS module configures and enables the Mosh ... | 🟢 |
| `gpu-orchestration` | Manages GPU resource orchestration for systemd ser... | 🟡 |
| `config-auditor` | This NixOS module configures a service to audit an... | 🟢 |
| `laptop-builder-client` | Configures a laptop as a remote build client for N... | 🟢 |
| `default` | Imports and configures various services for a NixO... | 🟢 |

### shell/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `rebuild-advanced` | This NixOS module defines a script for advanced re... | 🟢 |
| `training-logger` | Provides utilities for logging training sessions i... | 🟢 |
| `service-control` | Provides shell aliases for controlling GPU/ML serv... | 🟢 |
| `cli-helpers` | Provides colored wrappers for NixOS administration... | 🟢 |
| `rebuild-helpers` | Provides a colorized and enhanced script for rebui... | 🟢 |
| `analytics` | Provides a shell script for analyzing NixOS build ... | 🟢 |
| `default` | Manages shell configuration, including aliases, sc... | 🟡 |
| `nixos-explorer` | Provides an interactive tool for exploring NixOS c... | 🟢 |
| `navigation` | Provides advanced shell aliases for navigating and... | 🟢 |
| `laptop-defense` | Provides a set of shell aliases for thermal forens... | 🟢 |

### soc/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `suricata` | Configure Suricata IDS/IPS with performance and lo... | 🟡 |
| `tools` | Provides tools for monitoring and threat hunting i... | 🟢 |
| `log-aggregator` | Configures a log aggregation system using Vector f... | 🟡 |
| `fim` | Configures File Integrity Monitoring (FIM) for a s... | 🟡 |
| `opensearch` | This NixOS module configures and deploys OpenSearc... | 🟡 |
| `edr` | Configures Endpoint Detection & Response (EDR) fea... | 🟡 |
| `threat-intel` | This NixOS module configures threat intelligence g... | 🟢 |
| `grafana` | This NixOS module configures Grafana for SOC (Secu... | 🟡 |
| `wazuh` | This NixOS module configures and deploys a Wazuh S... | 🟡 |
| `alerting` | This NixOS module configures a service to dispatch... | 🟡 |

### system/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `ssh-config` | Manages SSH client configuration for multiple iden... | 🟢 |
| `memory` | Configures memory management and optimization sett... | 🟡 |
| `emergency-monitor` | Monitors system resources and performs automatic i... | 🟡 |
| `binary-cache` | Configures NixOS to use custom binary caches, incl... | 🟢 |
| `nix` | Configures Nix daemon settings for performance and... | 🟡 |
| `io-scheduler` | Optimizes I/O performance and latency on NixOS sys... | 🟢 |
| `services` | Defines a systemd service to pre-pull Docker image... | 🟢 |
| `ml-gpu-users` | Manages centralized ML/GPU user and group manageme... | 🟢 |
| `aliases` | Installs necessary packages and configures user se... | 🟢 |
| `default` | Aggregates various system-related NixOS modules in... | 🟢 |

### tools/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `intel` | Provides a command-line tool for auditing and anal... | 🟡 |
| `default` | This NixOS module aggregates various tools and uti... | 🟡 |
| `nix-utils` | Provides a script for managing NixOS system utilit... | 🟢 |
| `secrets` | Provides a command-line tool for managing secrets ... | 🟢 |
| `default` | Provides a tool for running architecture analysis ... | 🟢 |
| `llm` | Provides a command-line interface for interacting ... | 🟢 |
| `dev` | Provides a script for managing development tools s... | 🟢 |
| `secops` | Provides a script for security operations includin... | 🟢 |
| `mcp` | Provides a script for managing MCP server tools in... | 🟢 |
| `diagnostics` | Provides a command-line interface for various syst... | 🟢 |

### virtualization/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `vmctl` | Provides a command-line interface (CLI) for managi... | 🟡 |
| `vms` | This NixOS module configures virtualization settin... | 🟡 |
| `macos-kvm` | This NixOS module provides a declarative way to ma... | 🟡 |
| `default` | Imports all virtualization configurations for VM m... | 🟢 |
