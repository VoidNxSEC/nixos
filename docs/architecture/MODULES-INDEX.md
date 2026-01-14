# Índice Completo de Módulos NixOS

**Gerado em:** 2025-11-23
**Total de módulos:** ~130 arquivos .nix

---

## 📋 Sumário

- [Aplicações](#aplicações)
- [Áudio](#áudio)
- [Containers](#containers)
- [Debug](#debug)
- [Desktop](#desktop)
- [Desenvolvimento](#desenvolvimento)
- [Hardware](#hardware)
- [Machine Learning](#machine-learning)
- [Network](#network)
- [Pacotes Customizados](#pacotes-customizados)
- [Programas](#programas)
- [Secrets](#secrets)
- [Segurança](#segurança)
- [Serviços](#serviços)
- [Shell](#shell)
- [Sistema](#sistema)
- [Virtualização](#virtualização)

---

## Aplicações

**Localização:** `/etc/nixos/modules/applications/`

### `default.nix`
- **Descrição:** Configuração principal do módulo de aplicações
- **Função:** Agregador de todas as aplicações

### `brave-secure.nix`
- **Descrição:** Navegador Brave com configurações de segurança
- **Features:**
  - Hardening de privacidade
  - Flags de segurança
  - Extensions recomendadas

### `firefox-privacy.nix`
- **Descrição:** Firefox focado em privacidade
- **Features:**
  - user.js com hardening
  - Configurações anti-tracking
  - Extensions de privacidade

### `chromium.nix`
- **Descrição:** Navegador Chromium
- **Features:**
  - Configurações básicas
  - Flags de performance

### `vscode-secure.nix`
- **Descrição:** Visual Studio Code com segurança
- **Features:**
  - Telemetria desabilitada
  - Extensions recomendadas
  - Configurações de workspace

### `vscodium-secure.nix`
- **Descrição:** VSCodium (VS Code sem telemetria)
- **Features:**
  - Versão 100% open-source
  - Sem Microsoft tracking

---

## Áudio

**Localização:** `/etc/nixos/modules/audio/`

### `production.nix`
- **Descrição:** Setup de produção de áudio
- **Features:**
  - JACK/PipeWire
  - Baixa latência
  - Ferramentas de produção

---

## Containers

**Localização:** `/etc/nixos/modules/containers/`

### `default.nix`
- **Descrição:** Configuração principal de containers
- **Função:** Habilita/desabilita container runtimes

### `docker.nix`
- **Descrição:** Docker runtime
- **Features:**
  - Docker daemon
  - Docker Compose
  - Configurações de rede
  - Registry configuration

### `podman.nix`
- **Descrição:** Podman runtime (rootless)
- **Features:**
  - Podman daemon
  - Podman Compose
  - Compatibilidade Docker

### `nixos-containers.nix`
- **Descrição:** Containers nativos do NixOS
- **Features:**
  - Containers declarativos
  - Isolamento system-level

---

## Debug

**Localização:** `/etc/nixos/modules/debug/`

### `debug-init.nix`
- **Descrição:** Ferramentas de debug do sistema
- **Features:**
  - strace, ltrace
  - gdb, lldb
  - Performance profilers

### `test-init.nix`
- **Descrição:** Ambiente de testes
- **Features:**
  - Test frameworks
  - Mock tools

---

## Desktop

**Localização:** `/etc/nixos/modules/desktop/`

### `default.nix`
- **Descrição:** Configuração principal desktop
- **Função:** Agregador de DEs/WMs

### `hyprland.nix` ⭐
- **Descrição:** Hyprland Wayland compositor
- **Features:**
  - Configuração do sistema
  - Pacotes essenciais (waybar, wofi, dunst, etc)
  - XDG portal
  - Polkit
  - Variáveis NVIDIA
- **Enable option:** `services.hyprland-desktop.enable`
- **Pacotes incluídos:**
  - waybar (status bar)
  - wofi (launcher)
  - dunst (notificações)
  - swaylock/swayidle (lock/idle)
  - grim/slurp (screenshots)
  - wl-clipboard
  - nemo (file manager)
  - pavucontrol
  - networkmanagerapplet
  - playerctl

### `i3-lightweight.nix`
- **Descrição:** i3 window manager (X11)
- **Features:**
  - Setup minimalista
  - Configuração leve

---

## Desenvolvimento

**Localização:** `/etc/nixos/modules/development/`

### `environments.nix`
- **Descrição:** Ambientes de desenvolvimento
- **Features:**
  - Python, Node, Rust, Go
  - Language servers
  - Build tools

### `jupyter.nix`
- **Descrição:** Jupyter notebooks
- **Features:**
  - JupyterLab
  - Kernels (Python, Julia, etc)
  - Extensions

### `cicd.nix`
- **Descrição:** CI/CD tools
- **Features:**
  - GitHub Actions runners
  - GitLab CI
  - Build automation

---

## Hardware

**Localização:** `/etc/nixos/modules/hardware/`

### `default.nix`
- **Descrição:** Configuração base de hardware
- **Função:** Importa configs específicas

### `nvidia.nix` ⭐
- **Descrição:** Drivers NVIDIA
- **Features:**
  - Drivers proprietários
  - CUDA support
  - Configuração Wayland
  - VRAM management
- **Enable option:** `kernelcore.nvidia.enable`

### `intel.nix`
- **Descrição:** Drivers Intel (CPU + iGPU)
- **Features:**
  - Intel graphics
  - VA-API
  - Microcode updates

### `bluetooth.nix`
- **Descrição:** Bluetooth support
- **Features:**
  - bluez
  - blueman
  - Auto-connect

### `trezor.nix`
- **Descrição:** Suporte para Trezor hardware wallet
- **Features:**
  - udev rules
  - Trezor Bridge

### `wifi-optimization.nix`
- **Descrição:** Otimizações de WiFi
- **Features:**
  - Power saving
  - Performance tweaks

### `thermal-profiles.nix`
- **Descrição:** Perfis térmicos
- **Features:**
  - thermald
  - Fan control
  - CPU throttling

### `lenovo-throttled.nix`
- **Descrição:** Fix throttling em laptops Lenovo
- **Features:**
  - lenovo-throttled service
  - Undervolting

### `laptop-defense/`
- **Descrição:** Sistema de defesa para laptop
- **Arquivos:**
  - `flake.nix` - Flake do sistema
  - `mcp-integration.nix` - Integração MCP
  - `rebuild-hooks.nix` - Hooks de rebuild

---

## Machine Learning

**Localização:** `/etc/nixos/modules/ml/`

### `llama.nix`
- **Descrição:** Llama models
- **Features:**
  - Model definitions
  - Runtime config

### `models-storage.nix`
- **Descrição:** Gestão de storage de modelos
- **Features:**
  - Path management
  - Size tracking (3.8G)
  - Cleanup automation

### `ollama-gpu-manager.nix` ⭐
- **Descrição:** Ollama com orquestração de GPU
- **Features:**
  - GPU detection
  - VRAM management
  - Model loading/unloading
  - Auto-scaling

### `mcp-config/default.nix`
- **Descrição:** Configuração MCP para ML
- **Features:**
  - MCP servers
  - Model registry

### `offload/`
- **Descrição:** Sistema de offload de inferência
- **Arquivos:**
  - `default.nix` - Config principal
  - `manager.nix` - Manager de offload
  - `model-registry.nix` - Registry de modelos
  - `vram-intelligence.nix` - VRAM intelligence
  - `backends/default.nix` - Backends de inferência

### `unified-llm/nix/flake.nix`
- **Descrição:** Sistema unificado de LLMs
- **Features:**
  - Abstração multi-backend
  - API unificada

---

## Network

**Localização:** `/etc/nixos/modules/network/`

### `bridge.nix`
- **Descrição:** Network bridging
- **Features:**
  - Virtual bridges
  - Container networking

### `dns-resolver.nix`
- **Descrição:** Configuração DNS
- **Features:**
  - systemd-resolved
  - DNS over TLS
  - Fallback servers

### `dns/default.nix`
- **Descrição:** DNS avançado
- **Features:**
  - DNS caching
  - Custom resolvers

### `vpn/nordvpn.nix`
- **Descrição:** NordVPN client
- **Features:**
  - NordVPN daemon
  - Auto-connect
  - Kill switch

---

## Pacotes Customizados

### DEB Packages

**Localização:** `/etc/nixos/modules/packages/deb-packages/`

#### `default.nix`
- **Descrição:** Sistema principal de conversão .deb
- **Função:** Framework para converter pacotes Debian

#### `builder.nix`
- **Descrição:** Builder de pacotes .deb
- **Features:**
  - Extract .deb
  - Convert to Nix
  - Dependency resolution

#### `sandbox.nix`
- **Descrição:** Sandbox para pacotes .deb
- **Features:**
  - Isolamento de filesystem
  - Namespace isolation
  - Security restrictions

#### `audit.nix`
- **Descrição:** Auditoria de pacotes .deb
- **Features:**
  - Binary analysis
  - Dependency tracking
  - Security scanning

#### `packages/cursor.nix`
- **Descrição:** Cursor IDE (via .deb)
- **Source:** .deb file

#### `packages/protonvpn.nix`
- **Descrição:** ProtonVPN (via .deb)
- **Source:** .deb file

#### `packages/example.nix`
- **Descrição:** Template para novos pacotes .deb

---

### TAR Packages

**Localização:** `/etc/nixos/modules/packages/tar-packages/`

#### `default.nix`
- **Descrição:** Sistema de tar packages
- **Função:** Framework para tarballs

#### `builder.nix`
- **Descrição:** Builder para .tar.gz
- **Features:**
  - Extract tarball
  - Wrapper creation
  - Binary validation

#### `packages/zellij.nix` ⭐
- **Descrição:** Zellij terminal multiplexer
- **Versão:** 0.43.1
- **Source:** Pre-built Rust binary
- **Method:** native
- **Features:**
  - Environment wrapper
  - Config dir setup
  - No sandbox (needs system access)

#### `packages/codex.nix`
- **Descrição:** Codex AI agent
- **Source:** tarball

#### `packages/lynis.nix`
- **Descrição:** Lynis security scanner
- **Source:** tarball

---

### JS Packages

**Localização:** `/etc/nixos/modules/packages/js-packages/`

#### `default.nix`
- **Descrição:** Sistema de JS packages
- **Função:** Framework para pacotes JavaScript/Node

#### `js-packages.nix`
- **Descrição:** Builder de pacotes JS
- **Features:**
  - npm/yarn support
  - Build process

#### `gemini-cli.nix`
- **Descrição:** Gemini CLI tool
- **Source:** npm package

---

## Programas

**Localização:** `/etc/nixos/modules/programs/`

### `default.nix`
- **Descrição:** Programas gerais do sistema
- **Features:**
  - CLI tools
  - System utilities

---

## Secrets

**Localização:** `/etc/nixos/modules/secrets/`

### `sops-config.nix`
- **Descrição:** Configuração SOPS (Secrets OPerationS)
- **Features:**
  - Age encryption
  - GPG support
  - Secret files management
  - Auto-decryption

### `api-keys.nix`
- **Descrição:** Gestão de API keys
- **Features:**
  - Encrypted storage
  - Environment variables
  - Service integration

---

## Segurança

**Localização:** `/etc/nixos/modules/security/`

### `default.nix`
- **Descrição:** Configuração principal de segurança
- **Função:** Agregador de todos módulos de segurança

### `hardening.nix` ⭐
- **Descrição:** Hardening geral do sistema
- **Features:**
  - System hardening
  - User restrictions
  - File permissions
  - umask configuration

### `kernel.nix`
- **Descrição:** Hardening do kernel
- **Features:**
  - Kernel parameters (sysctl)
  - Security modules
  - Address space randomization
  - Stack protection

### `network.nix`
- **Descrição:** Segurança de rede
- **Features:**
  - nftables firewall
  - Port restrictions
  - Rate limiting
  - DDoS protection

### `ssh.nix`
- **Descrição:** SSH hardening
- **Features:**
  - Key-only authentication
  - Disabled password auth
  - Rate limiting
  - Allowed users

### `pam.nix`
- **Descrição:** PAM configuration
- **Features:**
  - Authentication policies
  - Password requirements
  - Session limits

### `boot.nix`
- **Descrição:** Segurança de boot
- **Features:**
  - GRUB password
  - Secure boot prep
  - Boot parameters

### `audit.nix`
- **Descrição:** Auditd configuration
- **Features:**
  - System call auditing
  - File access tracking
  - Log management

### `aide.nix`
- **Descrição:** AIDE (File integrity)
- **Features:**
  - Baseline creation
  - Change detection
  - Automated checks

### `clamav.nix`
- **Descrição:** ClamAV antivírus
- **Features:**
  - Daemon
  - Scheduled scans
  - Update automation

### `auto-upgrade.nix`
- **Descrição:** Updates automáticos
- **Features:**
  - Scheduled updates
  - Security patches
  - Reboot policies

### `compiler-hardening.nix`
- **Descrição:** Hardening de compilação
- **Features:**
  - PIE (Position Independent Executables)
  - Stack canaries
  - FORTIFY_SOURCE
  - RELRO

### `dev-directory-hardening.nix`
- **Descrição:** Hardening do /dev
- **Features:**
  - noexec on /tmp
  - Restricted /dev/shm

### `keyring.nix`
- **Descrição:** Gestão de chaves
- **Features:**
  - GPG agent
  - SSH agent
  - Keyring integration

### `nix-daemon.nix`
- **Descrição:** Segurança do Nix daemon
- **Features:**
  - Sandboxed builds
  - Restricted users
  - Binary cache verification

### `packages.nix`
- **Descrição:** Pacotes de segurança
- **Features:**
  - Security tools
  - Scanning utilities

### `hardening-template.nix`
- **Descrição:** Template para novos hardenings

---

## Serviços

**Localização:** `/etc/nixos/modules/services/`

### `default.nix`
- **Descrição:** Configuração principal de serviços
- **Função:** Agregador de serviços

### `scripts.nix`
- **Descrição:** Scripts de serviço
- **Features:**
  - Helper scripts
  - Automation

### `gpu-orchestration.nix`
- **Descrição:** Orquestração de GPU
- **Features:**
  - GPU allocation
  - Multi-GPU support
  - Workload distribution

### `laptop-builder-client.nix`
- **Descrição:** Cliente de build distribuído (laptop)
- **Features:**
  - Offload builds
  - Remote building

### `laptop-offload-client.nix`
- **Descrição:** Cliente de offload (laptop)
- **Features:**
  - ML inference offload
  - Network optimization

### `offload-server.nix`
- **Descrição:** Servidor de offload
- **Features:**
  - Accept offload requests
  - GPU sharing

---

### User Services

**Localização:** `/etc/nixos/modules/services/users/`

#### `default.nix`
- **Descrição:** Serviços de usuários
- **Função:** Agregador

#### `actions.nix`
- **Descrição:** GitHub Actions runner
- **Features:**
  - Self-hosted runner
  - CI/CD automation

#### `claude-code.nix` ⭐
- **Descrição:** Claude Code service
- **Features:**
  - Systemd service
  - Auto-start
  - Logging

#### `codex-agent.nix`
- **Descrição:** Codex agent service
- **Features:**
  - AI coding assistant
  - Background service

#### `gemini-agent.nix`
- **Descrição:** Gemini agent service
- **Features:**
  - AI service
  - API integration

#### `gitlab-runner.nix`
- **Descrição:** GitLab CI runner
- **Features:**
  - Self-hosted runner
  - Docker executor

---

## Shell

**Localização:** `/etc/nixos/modules/shell/`

### `default.nix`
- **Descrição:** Configuração principal shell
- **Função:** Agregador de shell configs

### `gpu-flags.nix`
- **Descrição:** Flags de GPU para shell
- **Features:**
  - Environment variables
  - CUDA paths

### `training-logger.nix`
- **Descrição:** Logger para treinos ML
- **Features:**
  - Training metrics
  - Log formatting

---

### Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/`

#### `default.nix`
- **Descrição:** Agregador de todos aliases
- **Função:** Importa todos submódulos

#### `emergency.nix`
- **Descrição:** Aliases de emergência
- **Aliases:**
  - Recovery tools
  - System rescue

#### `laptop-defense.nix`
- **Descrição:** Aliases do laptop-defense
- **Aliases:**
  - Defense commands
  - Monitoring

#### `mcp.nix`
- **Descrição:** Aliases MCP
- **Aliases:**
  - MCP server management
  - Debug tools

---

#### AI Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/ai/`

##### `default.nix`
- **Descrição:** Agregador AI aliases

##### `ollama.nix`
- **Descrição:** Aliases Ollama
- **Aliases:**
  - `ollama-start`, `ollama-stop`
  - Model management
  - GPU control

---

#### Amazon/AWS Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/amazon/`

##### `default.nix`
- **Descrição:** Agregador AWS aliases

##### `aws.nix`
- **Descrição:** Aliases AWS CLI
- **Aliases:**
  - S3, EC2, Lambda shortcuts
  - Profile management

---

#### Desktop Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/desktop/`

##### `default.nix`
- **Descrição:** Agregador desktop aliases

##### `hyprland.nix` ⭐
- **Descrição:** Aliases Hyprland
- **Aliases:**
  - `reland` - Reload Hyprland
  - `hypredit` - Edit config
  - `hyprconf` - Cd to config dir
  - `wayreload` - Reload Waybar
  - `wayedit` - Edit Waybar config

---

#### Docker Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/docker/`

##### `default.nix`
- **Descrição:** Agregador Docker aliases

##### `build.nix`
- **Descrição:** Docker build aliases
- **Aliases:**
  - Build shortcuts
  - Multi-stage builds

##### `compose.nix`
- **Descrição:** Docker Compose aliases
- **Aliases:**
  - `dcup`, `dcdown`
  - Service management

##### `run.nix`
- **Descrição:** Docker run aliases
- **Aliases:**
  - Common containers
  - Quick runs

---

#### GCloud Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/gcloud/`

##### `default.nix`
- **Descrição:** Agregador GCloud aliases

##### `gcloud.nix`
- **Descrição:** Google Cloud aliases
- **Aliases:**
  - GCE, GKE shortcuts
  - Project switching

---

#### Kubernetes Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/kubernetes/`

##### `default.nix`
- **Descrição:** Agregador K8s aliases

##### `kubectl.nix`
- **Descrição:** kubectl aliases
- **Aliases:**
  - `k` = kubectl
  - `kg` = kubectl get
  - `kd` = kubectl describe
  - Context switching

---

#### Nix Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/nix/`

##### `default.nix`
- **Descrição:** Agregador Nix aliases

##### `system.nix`
- **Descrição:** NixOS system aliases
- **Aliases:**
  - `clean` - Garbage collection
  - `cleanold` - Remove old generations
  - Build shortcuts

---

#### Security Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/security/`

##### `default.nix`
- **Descrição:** Agregador security aliases

##### `secrets.nix`
- **Descrição:** Secrets management aliases
- **Aliases:**
  - SOPS commands
  - Key management

---

#### System Aliases

**Localização:** `/etc/nixos/modules/shell/aliases/system/`

##### `default.nix`
- **Descrição:** Agregador system aliases

##### `utils.nix`
- **Descrição:** Utilitários do sistema
- **Aliases:**
  - System monitoring
  - Process management
  - Disk usage

---

## Sistema

**Localização:** `/etc/nixos/modules/system/`

### `aliases.nix`
- **Descrição:** System-wide aliases (deprecated, use shell/aliases)

### `binary-cache.nix`
- **Descrição:** Configuração de binary cache
- **Features:**
  - Cache servers
  - Public keys
  - Substituters

### `emergency-monitor.nix`
- **Descrição:** Monitoramento de emergência
- **Features:**
  - System health checks
  - Auto-recovery
  - Alertas

### `memory.nix`
- **Descrição:** Gestão de memória
- **Features:**
  - Swap config
  - OOM killer tuning
  - Cache management

### `ml-gpu-users.nix`
- **Descrição:** Usuários com acesso GPU para ML
- **Features:**
  - Group management
  - GPU permissions

### `nix.nix`
- **Descrição:** Configuração Nix daemon
- **Features:**
  - Nix settings
  - Experimental features
  - Flakes

### `services.nix`
- **Descrição:** Serviços do sistema
- **Features:**
  - Systemd services
  - Timers

### `ssh-config.nix`
- **Descrição:** SSH configuration (system-wide)
- **Features:**
  - SSH daemon config
  - Host keys

### `sudo-claude-code.nix`
- **Descrição:** Sudo rules para Claude Code
- **Features:**
  - Passwordless sudo (specific commands)
  - nixos-rebuild allowed

---

## Virtualização

**Localização:** `/etc/nixos/modules/virtualization/`

### `default.nix`
- **Descrição:** Configuração principal virtualização
- **Função:** Agregador

### `vms.nix`
- **Descrição:** Definições de VMs
- **Features:**
  - QEMU/KVM VMs
  - Network config
  - Resource allocation

### `vmctl.nix`
- **Descrição:** Controle de VMs
- **Features:**
  - Start/stop scripts
  - VM management

---

## Configuração por Host (kernelcore)

**Localização:** `/etc/nixos/hosts/kernelcore/`

### `configuration.nix` ⭐
- **Descrição:** Configuração principal do host
- **Features:**
  - System-level config
  - Hardware imports
  - Module imports
  - Users
  - Boot config

### `default.nix`
- **Descrição:** Export do host para flake
- **Função:** Entry point do host

### `hardware-configuration.nix`
- **Descrição:** Hardware detectado automaticamente
- **Features:**
  - Filesystems
  - Boot loader
  - Kernel modules
  - **NÃO EDITAR MANUALMENTE**

### `configurations-template.nix`
- **Descrição:** Template de configuração

---

### Home Manager (kernelcore)

**Localização:** `/etc/nixos/hosts/kernelcore/home/`

#### `home.nix` ⭐
- **Descrição:** Home Manager configuration principal
- **Features:**
  - User packages
  - User services
  - Dotfiles
  - Imports shell/

---

#### Aliases (Home)

**Localização:** `/etc/nixos/hosts/kernelcore/home/aliases/`

##### `nixos-aliases.nix`
- **Descrição:** Aliases específicos do host
- **Aliases:**
  - Host-specific shortcuts

---

#### Shell (Home)

**Localização:** `/etc/nixos/hosts/kernelcore/home/shell/`

##### `default.nix`
- **Descrição:** Agregador shell config
- **Função:** Importa zsh, bash, options

##### `options.nix`
- **Descrição:** Opções do módulo shell customizado
- **Options:**
  - `myShell.enable`
  - `myShell.defaultShell` (zsh/bash)
  - `myShell.enablePowerlevel10k`

##### `bash.nix`
- **Descrição:** Configuração Bash
- **Features:**
  - Bash config
  - Bashrc generation

##### `zsh.nix` ⭐⭐⭐
- **Descrição:** CONFIGURAÇÃO PRINCIPAL ZSH
- **Linhas:** 353
- **Features:**
  - Oh-my-zsh integration
  - Powerlevel10k theme
  - Advanced completion system
  - History configuration
  - Plugins (9): git, docker, kubectl, aws, sudo, extract, colored-man-pages, command-not-found, history-substring-search
  - Autosuggestions & syntax highlighting
  - Zoxide integration
  - FZF integration
  - Shell aliases (inline)
  - Custom functions: up(), extract(), backup(), note(), mkcd()
  - Environment variables
  - Keybindings

##### `p10k.zsh`
- **Descrição:** Powerlevel10k configuration
- **Features:**
  - Prompt customization
  - Segments config
  - Colors & icons

---

## Resumo por Categoria

| Categoria | Módulos | Descrição |
|-----------|---------|-----------|
| **Aplicações** | 6 | Navegadores, editores |
| **Áudio** | 1 | Produção de áudio |
| **Containers** | 4 | Docker, Podman, NixOS containers |
| **Debug** | 2 | Ferramentas de debug |
| **Desktop** | 3 | Hyprland, i3 |
| **Desenvolvimento** | 3 | Ambientes, Jupyter, CI/CD |
| **Hardware** | 10+ | NVIDIA, Intel, Bluetooth, etc |
| **ML** | 8+ | Ollama, Llama, offload, VRAM |
| **Network** | 4+ | DNS, bridge, VPN |
| **Pacotes** | 15+ | deb, tar, js packages |
| **Segurança** | 15+ | Hardening, audit, firewall |
| **Serviços** | 10+ | GPU, offload, user services |
| **Shell** | 30+ | Aliases modulares, configs |
| **Sistema** | 9 | Nix, memory, monitoring |
| **Virtualização** | 3 | VMs, QEMU/KVM |

---

## Módulos Mais Importantes

### ⭐⭐⭐ Críticos
1. `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix` - **ZSH CONFIG**
2. `/etc/nixos/modules/desktop/hyprland.nix` - **HYPRLAND**
3. `/etc/nixos/modules/packages/tar-packages/packages/zellij.nix` - **ZELLIJ**
4. `/etc/nixos/modules/security/hardening.nix` - **SECURITY**
5. `/etc/nixos/modules/hardware/nvidia.nix` - **GPU**

### ⭐⭐ Importantes
6. `/etc/nixos/modules/ml/ollama-gpu-manager.nix` - **ML/AI**
7. `/etc/nixos/modules/security/kernel.nix` - **KERNEL HARDENING**
8. `/etc/nixos/modules/secrets/sops-config.nix` - **SECRETS**
9. `/etc/nixos/modules/containers/docker.nix` - **DOCKER**
10. `/etc/nixos/hosts/kernelcore/configuration.nix` - **SYSTEM CONFIG**

---

## Navegação Rápida

```bash
# Ver todos módulos
ls /etc/nixos/modules/

# Buscar módulo específico
find /etc/nixos/modules -name "*hyprland*"

# Grep em todos módulos
grep -r "enable" /etc/nixos/modules/

# Listar por categoria
ls /etc/nixos/modules/desktop/
ls /etc/nixos/modules/security/
ls /etc/nixos/modules/shell/aliases/
```

---

**Última atualização:** 2025-11-23
**Total de arquivos documentados:** ~130 módulos .nix
