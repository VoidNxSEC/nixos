# 🤖 AI Architecture Report

> **Generated**: 2025-12-29T17:50:22.411032
> **Model**: `default`
> **Duration**: 112.2s

## Executive Summary

The NixOS repository contains a large number of modules and lines of code, organized into various categories. It includes essential system components, development tools, and a variety of applications, but also has some orphaned or less utilized modules.

**Quality Score: 28/100**

| Metric | Value |
|--------|-------|
| Modules | 268 | (new) |
| Lines | 52,989 | (new) |
| Categories | 22 | - |
| Orphans | 180 | (new) |

## Priority Actions

1. Review orphaned modules to determine if they can be integrated or deprecated.
2. Optimize module categorization for better maintainability and user experience.
3. Conduct a code audit to identify potential security vulnerabilities and inefficiencies.

## Orphan Modules

Found **180** modules not imported anywhere:

### root/ (180 orphans)

- `KERNELCORE-TAILSCALE-CONFIG`
- `TAILSCALE-LAPTOP-CLIENT`
- `TAILSCALE-QUICK-START`
- `TEMPLATE`
- `actions`
- `agent-hub`
- `aide`
- `alacritty`
- `alerting`
- `aliases`
- `analytics`
- `api-keys`
- `audit`
- `auto-upgrade`
- `aws`
- `aws-bedrock`
- `bash`
- `binary-cache`
- `bluetooth`
- `boot`
- `brave`
- `brave-secure`
- `bridge`
- `build`
- `cache-optimization`
- `chromium`
- `cicd`
- `clamav`
- `claude-code`
- `claude-profiles`
- `cli-helpers`
- `codex-agent`
- `cognitive-vault`
- `compiler-hardening`
- `compose`
- `config`
- `config-auditor`
- `configurations-template`
- `cypher-host`
- `dao`
- `database`
- `debug-init`
- `desktop-cfg`
- `desktop-cfg2`
- `desktop-config-backup`
- `desktop-config-clean`
- `dev`
- `dev-directory-hardening`
- `diagnostics`
- `dns-monitor`
- `dns-resolver`
- `docker`
- `docker-hub`
- `edr`
- `electron-config`
- `electron-tuning`
- `emergency`
- `emergency-monitor`
- `environments`
- `fim`
- `firefox`
- `firefox-privacy`
- `firewall-zones`
- `fix-sudo`
- `fix-sudo2`
- `fix-sudo3`
- `flameshot`
- `gcloud`
- `gemini-agent`
- `git`
- `gitlab-runner`
- `gpu-flags`
- `gpu-orchestration`
- `grafana`
- `hardening`
- `hardening-template`
- `hyprland`
- `hyprlock`
- `i3-lightweight`
- `intel`
- `io-monitor`
- `io-scheduler`
- `jupyter`
- `kernel`
- `keyring`
- `kitty`
- `kubectl`
- `laptop-builder-client`
- `laptop-defense`
- `laptop-offload-client`
- `lenovo-throttled`
- `llama-cpp-turbo`
- `llm`
- `log-aggregator`
- `macos-kvm`
- `mako`
- `manager`
- `master`
- `mcp`
- `mcp-integration`
- `mcp-server`
- `memory`
- `ml-gpu-users`
- `mobile-workspace`
- `monitoring`
- `mosh`
- `navigation`
- `nemo-full`
- `netflow`
- `network`
- `nginx-tailscale`
- `nix`
- `nix-daemon`
- `nix-utils`
- `nixos-containers`
- `nixos-explorer`
- `nordvpn`
- `nvidia`
- `offload-server`
- `opensearch`
- `options`
- `pam`
- `phantom`
- `podman`
- `production`
- `projects`
- `python-packages`
- `python-tests-fix`
- `rebuild-advanced`
- `rebuild-helpers`
- `rebuild-hooks`
- `run`
- `scripts`
- `secops`
- `secrets`
- `service-control`
- `services`
- `shell`
- `sops-config`
- `ssh`
- `ssh-config`
- `storage`
- `suricata`
- `swappy`
- `sync`
- `system`
- `tailscale`
- `tailscale-desktop`
- `tailscale-integration-test`
- `tailscale-laptop`
- `tailscale-monitor`
- `tailscale-services`
- `test-init`
- `test-remote-build`
- `theme`
- `thermal-profiles`
- `threat-intel`
- `tmux`
- `tools`
- `tools-integration`
- `training-logger`
- `trezor`
- `utils`
- `video-production`
- `vllm`
- `vllm-driver`
- `vmctl`
- `vms`
- `vscode-secure`
- `vscodium-secure`
- `wallpaper`
- `waybar`
- `wazuh`
- `wifi-optimization`
- `wlogout`
- `wofi`
- `workers`
- `yazi`
- `zellij`
- `zsh`

## Module Analysis

### applications/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `chromium` |  | 🟡 |
| `vscode-secure` |  | 🟡 |
| `vscodium-secure` | Configures VSCodium with Firejail sandboxing and r... | 🟡 |
| `zellij` | This NixOS module configures and optimizes Zellij,... | 🟢 |
| `firefox-privacy` | Configures Firefox for enhanced privacy and perfor... | 🟡 |
| `brave-secure` |  | 🟡 |
| `nemo-full` | This NixOS module configures the Nemo file manager... | 🟢 |
| `cache-optimization` | Optimizes Electron app cache performance by moving... | 🟡 |
| `electron-tuning` | Optimizes Electron and Chromium-based applications... | 🟢 |
| `default` |  | 🟡 |

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
| `docker-hub` |  | 🟡 |
| `nixos-containers` |  | 🟡 |
| `podman` |  | 🟡 |
| `docker` | Enables Docker with specific daemon configuration ... | 🟢 |
| `default` | This module imports and aggregates configurations ... | 🟢 |

### debug/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `debug-init` |  | 🟡 |
| `test-init` |  | 🟡 |
| `io-monitor` |  | 🟡 |
| `tools-integration` | Installs Swissknife debug tools and sets up aliase... | 🟢 |
| `default` | This module aggregates and imports other debug-rel... | 🟢 |

### default.nix/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `default` |  | 🟡 |

### desktop/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `i3-lightweight` | Configures a lightweight desktop environment using... | 🟡 |
| `hyprland` | Configures a pure Wayland desktop environment usin... | 🟡 |
| `yazi` | Installs the Yazi package on the system level. | 🟢 |
| `default` | Aggregates configuration for different desktop env... | 🟢 |

### development/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `claude-profiles` |  | 🟡 |
| `cicd` |  | 🟡 |
| `jupyter` | Configures JupyterLab with various kernels and ext... | 🟡 |
| `environments` |  | 🟡 |
| `default` | This module aggregates and imports multiple develo... | 🟢 |

### hardware/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `flake` | The module is designed to perform thermal forensic... | 🟢 |
| `thermal-profiles` |  | 🟡 |
| `rebuild-hooks` | Integrates thermal safety checks and evidence coll... | 🟡 |
| `intel` |  | 🟡 |
| `lenovo-throttled` |  | 🟡 |
| `nvidia` |  | 🟡 |
| `mcp-integration` | Integrates thermal forensics and safety checks int... | 🟡 |
| `wifi-optimization` |  | 🟡 |
| `trezor` |  | 🟡 |
| `bluetooth` | Configures Bluetooth hardware and enables GUI mana... | 🟡 |

### ml/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `llama-cpp-turbo` | Configures the LLaMA.cpp TURBO high-performance in... | 🟢 |
| `vllm` | Configures and enables the vLLM Inference Server w... | 🟡 |
| `flake` | This NixOS module defines a flake for building and... | 🟡 |
| `monitoring` | This NixOS module configures the VRAM Intelligence... | 🟡 |
| `manager` | Provides a REST API for managing ML model offloadi... | 🟢 |
| `database` | Manages an ML model registry with auto-discovery, ... | 🟡 |
| `vllm-driver` | Provides a NixOS module for configuring and managi... | 🟢 |
| `config` | This NixOS module configures the Model Context Pro... | 🟡 |
| `storage` | Manages the storage structure and environment vari... | 🟡 |
| `default` | Configures an ML orchestration layer with options ... | 🟢 |

### network/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `tailscale-monitor` | Monitors Tailscale connectivity and triggers failo... | 🟡 |
| `tailscale` | This NixOS module configures Tailscale VPN setting... | 🟢 |
| `firewall-zones` | Defines firewall zones and settings for NixOS usin... | 🟡 |
| `nginx-tailscale` | Configures an NGINX reverse proxy for Tailscale se... | 🟡 |
| `nordvpn` | Configures NordVPN with NordLynx (WireGuard) integ... | 🟡 |
| `dns-resolver` |  | 🟡 |
| `tailscale-desktop` | Configures Tailscale for a desktop machine to act ... | 🟡 |
| `default` | This NixOS module configures and installs a DNS pr... | 🟡 |
| `tailscale-services` | Configures Tailscale and NGINX for service exposur... | 🟡 |
| `tailscale-laptop` | Configures Tailscale for a laptop with specific se... | 🟢 |

### packages/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `default` | This NixOS module defines a derivation for the App... | 🟢 |
| `default` | This NixOS module defines a package for the Gemini... | 🟢 |
| `default` | Provides the Claude Code CLI as a system package w... | 🟢 |
| `default` | Installs and configures the Lynis security auditin... | 🟢 |
| `default` | This NixOS module defines a package for Zellij, a ... | 🟢 |
| `default` | Enables the Hyprland v0.53.0 package system-wide b... | 🟢 |
| `default` | This NixOS module imports a set of self-contained ... | 🟢 |

### programs/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `phantom` | This NixOS module integrates Phantom as a flake in... | 🟢 |
| `vmctl` | Provides configuration for the vmctl package, a li... | 🟢 |
| `cognitive-vault` | Provides configuration for installing and enabling... | 🟢 |
| `default` | Enables XWayland support for Sway and imports conf... | 🟢 |

### root/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `waybar` |  | 🟡 |
| `configuration` | This NixOS module configures various system settin... | 🟡 |
| `yazi` | Configures yazi file manager with custom settings,... | 🟠 |
| `fix-sudo3` | This NixOS module configures various system settin... | 🟢 |
| `hyprland` |  | 🟡 |
| `desktop-config-backup` | Provides a base configuration for a desktop enviro... | 🟢 |
| `cypher-host` | This NixOS module configures a system with various... | 🟢 |
| `fix-sudo2` | This NixOS module configures various system settin... | 🟢 |
| `fix-sudo` | This NixOS module configures various system settin... | 🟢 |
| `desktop-cfg` | This NixOS module configures a desktop environment... | 🟢 |

### secrets/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `api-keys` | Manages and loads API keys from encrypted files in... | 🟢 |
| `sops-config` | Configures SOPS secrets management in NixOS, inclu... | 🟢 |
| `aws-bedrock` | Manages AWS Bedrock credentials and environment va... | 🟢 |
| `tailscale` | Manages Tailscale secrets using SOPS and ensures t... | 🟢 |
| `default` | Aggregates various secrets management modules for ... | 🟢 |

### security/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `dev-directory-hardening` | This NixOS module configures security hardening fo... | 🟡 |
| `aide` | Configures AIDE for integrity checking on a NixOS ... | 🟢 |
| `hardening-template` | This NixOS module provides a comprehensive hardeni... | 🟠 |
| `ssh` | This NixOS module configures SSH security hardenin... | 🟡 |
| `keyring` | This NixOS module configures keyring support with ... | 🟢 |
| `nix-daemon` | This NixOS module configures security settings for... | 🟡 |
| `kernel` | This NixOS module configures kernel security harde... | 🟡 |
| `compiler-hardening` | Enables compiler hardening flags to enhance securi... | 🟢 |
| `clamav` | Configures ClamAV antivirus scanning on a NixOS sy... | 🟡 |
| `audit` | Enables security auditing, logging, and related co... | 🟢 |

### services/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `laptop-offload-client` | Configures a NixOS laptop to offload builds to a d... | 🟢 |
| `mobile-workspace` | This NixOS module configures an isolated mobile wo... | 🟢 |
| `offload-server` | Configures an NixOS system to act as an offload bu... | 🟡 |
| `mcp-server` | This NixOS module configures and manages the Secur... | 🟢 |
| `mosh` | This NixOS module configures and enables the Mosh ... | 🟢 |
| `gpu-orchestration` | Manages GPU resource orchestration between systemd... | 🟡 |
| `config-auditor` | This NixOS module provides a configuration auditor... | 🟢 |
| `laptop-builder-client` | Configures a laptop as a remote build client for N... | 🟢 |
| `default` | Imports and configures various services for a NixO... | 🟢 |
| `scripts` | Defines shell aliases for Docker ML containers and... | 🟢 |

### shell/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `rebuild-advanced` | This NixOS module defines a script for advanced re... | 🟢 |
| `training-logger` |  | 🟡 |
| `service-control` | Provides shell aliases for controlling GPU/ML serv... | 🟢 |
| `cli-helpers` |  | 🟡 |
| `rebuild-helpers` | Provides a colorized and enhanced script for rebui... | 🟢 |
| `analytics` | Provides a shell script for analyzing NixOS build ... | 🟢 |
| `default` |  | 🟡 |
| `nixos-explorer` | Provides an interactive tool for exploring NixOS c... | 🟢 |
| `navigation` | Provides advanced shell aliases for navigating and... | 🟢 |
| `laptop-defense` | Provides a set of shell aliases for thermal forens... | 🟢 |

### soc/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `suricata` | Configure Suricata IDS/IPS with performance and lo... | 🟡 |
| `tools` | Provides tools for monitoring and threat hunting i... | 🟢 |
| `log-aggregator` | Configures a log aggregation service using Vector ... | 🟡 |
| `fim` | Configures File Integrity Monitoring (FIM) for a s... | 🟡 |
| `opensearch` | This NixOS module configures and deploys OpenSearc... | 🟡 |
| `edr` | Configures Endpoint Detection & Response (EDR) fea... | 🟡 |
| `threat-intel` | This NixOS module configures threat intelligence f... | 🟢 |
| `grafana` | This NixOS module configures and enables Grafana w... | 🟢 |
| `wazuh` | This NixOS module configures and deploys a Wazuh S... | 🟡 |
| `alerting` | This NixOS module configures a service to dispatch... | 🟡 |

### system/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `ssh-config` | Manages SSH client configuration for multiple iden... | 🟢 |
| `memory` | Configures memory management, cgroup slices, and s... | 🟡 |
| `emergency-monitor` | Monitors system resources and performs automatic i... | 🟡 |
| `binary-cache` | Configures NixOS to use custom binary caches, incl... | 🟢 |
| `nix` | Configures Nix daemon settings for performance opt... | 🟡 |
| `io-scheduler` | Optimize I/O performance and reduce latency by con... | 🟢 |
| `services` | Defines a systemd service to pre-pull Docker image... | 🟢 |
| `ml-gpu-users` | Manages centralized ML/GPU user and group definiti... | 🟢 |
| `aliases` | Installs necessary packages and configures user gr... | 🟢 |
| `default` | Aggregates various system-related NixOS modules in... | 🟢 |

### tools/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `intel` |  | 🟡 |
| `default` |  | 🟡 |
| `nix-utils` |  | 🟡 |
| `secrets` |  | 🟡 |
| `default` | Provides a tool for running architecture analysis ... | 🟢 |
| `llm` |  | 🟡 |
| `dev` | This module provides a unified command-line interf... | 🟢 |
| `secops` |  | 🟡 |
| `mcp` |  | 🟡 |
| `diagnostics` | Provides a unified command-line interface for vari... | 🟢 |

### virtualization/

| Module | Purpose | Complexity |
|--------|---------|------------|
| `vmctl` | Provides a command-line interface (CLI) for managi... | 🟡 |
| `vms` | This NixOS module configures virtualization settin... | 🟡 |
| `macos-kvm` | Provides a declarative way to manage macOS VMs usi... | 🟡 |
| `default` | Imports all virtualization configurations | 🟢 |
