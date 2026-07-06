# Mapa de Componentes do Sistema NixOS

**Gerado em:** 2025-11-23
**Host:** kernelcore
**Sistema:** NixOS com configuração modular

---

## Índice Rápido

- [Shell](#shell-zsh--bash)
- [Desktop Environment](#desktop-environment-hyprland)
- [Terminal Multiplexer](#terminal-multiplexer-zellij)
- [Aplicações](#aplicações)
- [Segurança](#segurança)
- [Hardware](#hardware)
- [Serviços](#serviços)
- [Machine Learning](#machine-learning)

---

## Shell (Zsh & Bash)

### Configuração Principal (Zsh)
**Arquivo:** `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix` (353 linhas)

**Componentes:**
- **Tema:** Powerlevel10k
- **Arquivo P10k:** `/etc/nixos/hosts/kernelcore/home/shell/p10k.zsh`
- **Plugins Oh-my-zsh:** git, docker, kubectl, aws, sudo, extract, colored-man-pages, command-not-found, history-substring-search
- **Integrações:**
  - zoxide (smarter cd)
  - fzf (fuzzy finder)
  - zsh-autosuggestions
  - zsh-syntax-highlighting

**Sistema de Completion:**
- Configuração avançada (linhas 44-98)
- Fuzzy matching para typos
- Case-insensitive
- Cache habilitado
- Cores para arquivos
- Completion especial para: SSH, Docker, Git, Kill, AWS

**Funções Customizadas:**
- `up()` - Navegar múltiplos diretórios acima
- `extract()` - Extrair qualquer tipo de arquivo
- `backup()` - Backup rápido com timestamp
- `note()` - Anotações rápidas
- `mkcd()` - Criar diretório e entrar

**History:**
- Size: 10000
- Save: 20000
- Path: `~/.zsh_history`
- Extended: true
- Share: true

**Arquivos Gerados:**
- `~/.zshrc` (242 linhas) - Gerado automaticamente pelo NixOS
- `~/.p10k.zsh` - Configuração do Powerlevel10k

### Configuração Bash
**Arquivo:** `/etc/nixos/hosts/kernelcore/home/shell/bash.nix`

### Opções do Shell
**Arquivo:** `/etc/nixos/hosts/kernelcore/home/shell/options.nix`

### Aliases do Sistema
**Estrutura modular em:** `/etc/nixos/modules/shell/aliases/`

```
aliases/
├── ai/
│   ├── default.nix
│   └── ollama.nix
├── amazon/
│   ├── aws.nix
│   └── default.nix
├── desktop/
│   ├── default.nix
│   └── hyprland.nix
├── docker/
│   ├── build.nix
│   ├── compose.nix
│   ├── default.nix
│   └── run.nix
├── gcloud/
│   ├── default.nix
│   └── gcloud.nix
├── kubernetes/
│   ├── default.nix
│   └── kubectl.nix
├── nix/
│   ├── default.nix
│   └── system.nix
├── security/
│   ├── default.nix
│   └── secrets.nix
├── system/
│   ├── default.nix
│   └── utils.nix
├── emergency.nix
├── laptop-defense.nix
└── mcp.nix
```

**Aliases principais definidos em zsh.nix:**
- Navigation: `ll`, `la`, `lt`, `ls` (usando eza)
- Git: `gs`, `ga`, `gaa`, `gc`, `gp`, `gl`, `gd`, `gco`
- Docker: `dps`, `dimg`, `dstop`, `dclean`
- NixOS: `clean`, `cleanold`
- Quick access: `dots`, `neo`, `dev`, `nx`
- Hyprland: `reland`, `hypredit`, `hyprconf`
- Waybar: `wayreload`, `wayedit`, `waystyle`
- Tools: `cat=bat`, `grep=rg`

---

## Desktop Environment (Hyprland)

### Módulo do Sistema
**Arquivo:** `/etc/nixos/modules/desktop/hyprland.nix` (98 linhas)

**Opção de ativação:**
```nix
services.hyprland-desktop.enable = true;
```

**Pacotes instalados:**
- **Core:** waybar, wofi, dunst, swaylock, swayidle
- **Screenshot:** grim, slurp, wl-clipboard, wf-recorder
- **Utilities:** nemo, pavucontrol, networkmanagerapplet
- **Terminals:** alacritty (primary), kitty (backup)
- **Monitoring:** btop
- **Media:** playerctl
- **Qt:** qt5.qtwayland, qt6.qtwayland, adwaita-qt

**XDG Portal:**
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk

**Polkit:**
- Serviço systemd: `polkit-gnome-authentication-agent-1`
- Auto-start com graphical-session.target

**Variáveis de Ambiente (NVIDIA):**
```bash
LIBVA_DRIVER_NAME=nvidia
XDG_SESSION_TYPE=wayland
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
NIXOS_OZONE_WL=1
```

### Configuração do Usuário
**Arquivo:** `~/.config/hypr/hyprland.conf` (248 linhas)

**Configurações principais:**
- **Monitor:** preferred, auto, scale 1
- **Input:** Keyboard layout BR
- **Layout:** dwindle (similar ao bspwm)
- **Gaps:** in=5, out=10
- **Border:** 2px, cores azul/cyan para ativo
- **Decorations:**
  - Rounding: 8
  - Blur: enabled, size 5, passes 2
  - Opacity: 0.96 ativo, 0.88 inativo, 1.0 fullscreen
  - Alacritty/Kitty: 0.94
- **Animations:** Enabled com bezier curves
- **Modifier:** SUPER

**Keybindings principais:**
- `SUPER+Return` - Terminal (alacritty)
- `SUPER+E` - File manager (nemo)
- `SUPER+D` - App launcher (wofi)
- `SUPER+Q` - Fechar janela
- `SUPER+F` - Fullscreen
- `SUPER+V` - Toggle floating
- `SUPER+h/j/k/l` - Navegação vim-style
- `SUPER+SHIFT+h/j/k/l` - Mover janelas
- `SUPER+CTRL+h/j/k/l` - Resize janelas
- `SUPER+1-9` - Workspaces
- `SUPER+L` - Lock screen

**Autostart:**
- waybar
- dunst
- polkit-gnome
- nm-applet
- swayidle (lock após 300s, dpms off após 600s)

**Guia rápido:** `~/.config/hypr/GUIA-RAPIDO.md`

---

## Terminal Multiplexer (Zellij)

### Módulo de Pacote
**Arquivo:** `/etc/nixos/modules/packages/tar-packages/packages/zellij.nix` (41 linhas)

**Detalhes:**
- **Versão:** 0.43.1
- **Build method:** native (binário Rust pré-compilado)
- **Source:** `/etc/nixos/modules/packages/tar-packages/storage/zellij-v0.43.1-x86_64-unknown-linux-musl.tar.gz`
- **SHA256:** 541d98efef5558293ef85ad9acd29e4d920b6e881513b9e77255d8207020d75a
- **Sandbox:** Desabilitado (precisa acesso completo ao sistema)
- **Wrapper env:** `ZELLIJ_CONFIG_DIR=$HOME/.config/zellij`

### Configuração do Usuário
**Arquivo:** `~/.config/zellij/config.kdl` (98 linhas)

**Configurações:**
- **Tema:** gruvbox-dark
- **Default shell:** bash
- **UI:** simplified, sem frames
- **Mouse:** enabled
- **Copy on select:** true
- **Scrollback editor:** nvim

**Keybindings principais:**
- `Alt+t` - Nova tab
- `Alt+w` - Fechar tab
- `Alt+n/p` - Próxima/anterior tab
- `Alt+1-9` - Ir para tab específica
- `Alt+h/j/k/l` - Criar panes (esquerda/baixo/cima/direita)
- `Alt+arrows` - Navegar entre panes
- `Alt++/-` - Resize panes
- `Alt+x` - Fechar pane
- `Alt+f` - Fullscreen do pane
- `Alt+s` - Modo scroll
- `Alt+r` - Renomear tab
- `Ctrl+Q` - DESABILITADO (evitar fechar acidental)

**Modo Scroll:**
- `Esc/q` - Voltar ao normal
- `j/k/Down/Up` - Scroll
- `d/u` - Half page
- `PageDown/Up` - Full page

**Tema Gruvbox:**
```
fg: #ebdbb2
bg: #282828
black: #3c3836
red: #cc241d
green: #98971a
yellow: #d79921
blue: #458588
magenta: #b16286
cyan: #689d6a
white: #a89984
orange: #d65d0e
```

**Guia rápido:** `~/.config/zellij/GUIA-RAPIDO.md`

---

## Aplicações

### Navegadores
**Localização:** `/etc/nixos/modules/applications/`

- `brave-secure.nix` - Brave com hardening de segurança
- `firefox-privacy.nix` - Firefox focado em privacidade
- `chromium.nix` - Chromium

### Editores
- `vscode-secure.nix` - VS Code com configurações de segurança
- `vscodium-secure.nix` - VSCodium (versão open-source)

### Pacotes Customizados

#### DEB Packages
**Localização:** `/etc/nixos/modules/packages/deb-packages/`

```
deb-packages/
├── builder.nix      - Builder para converter .deb
├── sandbox.nix      - Sandbox de segurança
├── audit.nix        - Sistema de auditoria
├── default.nix      - Configuração principal
└── packages/
    ├── cursor.nix       - Cursor IDE
    ├── protonvpn.nix    - ProtonVPN
    └── example.nix      - Template
```

#### TAR Packages
**Localização:** `/etc/nixos/modules/packages/tar-packages/`

```
tar-packages/
├── builder.nix      - Builder para tarballs
├── default.nix      - Configuração principal
├── storage/         - Arquivos .tar.gz
└── packages/
    ├── zellij.nix   - Zellij multiplexer
    ├── codex.nix    - Codex agent
    └── lynis.nix    - Lynis security
```

#### JS Packages
**Localização:** `/etc/nixos/modules/packages/js-packages/`

```
js-packages/
├── default.nix
├── js-packages.nix
└── gemini-cli.nix   - Gemini CLI tool
```

---

## Segurança

**Localização:** `/etc/nixos/modules/security/`

```
security/
├── default.nix              - Configuração principal
├── hardening.nix            - Hardening geral do sistema
├── kernel.nix               - Hardening do kernel
├── network.nix              - Firewall e segurança de rede
├── ssh.nix                  - Configuração SSH hardened
├── pam.nix                  - PAM configuration
├── boot.nix                 - Segurança de boot
├── audit.nix                - Auditd
├── aide.nix                 - AIDE (File integrity)
├── clamav.nix               - Antivírus
├── auto-upgrade.nix         - Updates automáticos
├── compiler-hardening.nix   - Hardening de compilação
├── dev-directory-hardening.nix
├── keyring.nix              - Gestão de chaves
├── nix-daemon.nix           - Segurança do daemon
├── packages.nix             - Pacotes de segurança
└── hardening-template.nix   - Template
```

### Secrets Management
**Localização:** `/etc/nixos/modules/secrets/`

- `sops-config.nix` - Configuração SOPS
- `api-keys.nix` - API keys management

**Storage:** `/etc/nixos/secrets/`

---

## Hardware

**Localização:** `/etc/nixos/modules/hardware/`

```
hardware/
├── default.nix          - Configuração base
├── nvidia.nix           - Drivers NVIDIA
├── intel.nix            - Drivers Intel
├── bluetooth.nix        - Bluetooth
├── trezor.nix           - Suporte Trezor wallet
├── wifi-optimization.nix
├── thermal-profiles.nix
├── lenovo-throttled.nix - Throttle management (Lenovo)
└── laptop-defense/      - Sistema de defesa laptop
    ├── flake.nix
    ├── mcp-integration.nix
    └── rebuild-hooks.nix
```

---

## Serviços

**Localização:** `/etc/nixos/modules/services/`

```
services/
├── default.nix
├── scripts.nix
├── gpu-orchestration.nix
├── laptop-builder-client.nix
├── laptop-offload-client.nix
├── offload-server.nix
└── users/                    - Serviços de usuários
    ├── default.nix
    ├── actions.nix
    ├── claude-code.nix       - Claude Code service
    ├── codex-agent.nix       - Codex agent
    ├── gemini-agent.nix      - Gemini agent
    └── gitlab-runner.nix     - GitLab CI runner
```

---

## Machine Learning

**Localização:** `/etc/nixos/modules/ml/`

```
ml/
├── llama.nix                 - Llama models
├── models-storage.nix        - Storage management (3.8G)
├── ollama-gpu-manager.nix    - Ollama GPU orchestration
├── mcp-config/
│   └── default.nix
├── offload/                  - Offload system
│   ├── default.nix
│   ├── manager.nix
│   ├── model-registry.nix
│   ├── vram-intelligence.nix
│   └── backends/
│       └── default.nix
└── unified-llm/
    └── nix/
        └── flake.nix
```

---

## Desenvolvimento

**Localização:** `/etc/nixos/modules/development/`

- `environments.nix` - Ambientes de desenvolvimento
- `jupyter.nix` - Jupyter notebooks
- `cicd.nix` - CI/CD tools

---

## Network

**Localização:** `/etc/nixos/modules/network/`

```
network/
├── bridge.nix           - Network bridging
├── dns-resolver.nix     - DNS configuration
├── dns/
│   └── default.nix
└── vpn/
    └── nordvpn.nix     - NordVPN
```

---

## Containers

**Localização:** `/etc/nixos/modules/containers/`

- `docker.nix` - Docker
- `podman.nix` - Podman
- `nixos-containers.nix` - NixOS containers
- `default.nix` - Configuração principal

---

## Virtualização

**Localização:** `/etc/nixos/modules/virtualization/`

- `vms.nix` - Definições de VMs
- `vmctl.nix` - Controle de VMs
- `default.nix` - Configuração principal

---

## Sistema

**Localização:** `/etc/nixos/modules/system/`

```
system/
├── aliases.nix              - System-wide aliases
├── binary-cache.nix         - Nix binary cache
├── emergency-monitor.nix    - Emergency monitoring
├── memory.nix               - Memory management
├── ml-gpu-users.nix         - GPU users management
├── nix.nix                  - Nix daemon config
├── services.nix             - System services
├── ssh-config.nix           - SSH configuration
└── sudo-claude-code.nix     - Sudo para Claude Code
```

---

## Host-Specific (kernelcore)

**Localização:** `/etc/nixos/hosts/kernelcore/`

```
kernelcore/
├── configuration.nix        - Configuração principal do host
├── default.nix              - Export do host
├── hardware-configuration.nix - Hardware auto-detectado
├── configurations-template.nix
└── home/
    ├── home.nix             - Home Manager config
    ├── aliases/
    │   └── nixos-aliases.nix
    └── shell/
        ├── default.nix
        ├── options.nix
        ├── bash.nix
        ├── zsh.nix          - ZSH CONFIG PRINCIPAL ★★★
        └── p10k.zsh         - Powerlevel10k config
```

---

## Estrutura de Diretórios Completa

```
/etc/nixos/
├── flake.nix               - Flake principal
├── configuration.nix       - Config global (deprecated, use hosts/)
├── hosts/                  - Configurações por host
│   └── kernelcore/         - Este host
├── modules/                - Módulos reutilizáveis
│   ├── applications/
│   ├── audio/
│   ├── containers/
│   ├── debug/
│   ├── desktop/            ← HYPRLAND
│   ├── development/
│   ├── hardware/
│   ├── ml/
│   ├── network/
│   ├── packages/           ← ZELLIJ
│   ├── programs/
│   ├── secrets/
│   ├── security/
│   ├── services/
│   ├── shell/              ← ALIASES
│   ├── system/
│   └── virtualization/
├── overlays/               - Nix overlays
├── lib/                    - Library functions
├── scripts/                - Scripts utilitários
├── docs/                   - Documentação
│   ├── architecture/       ← VOCÊ ESTÁ AQUI
│   ├── guides/
│   └── reports/
├── dev/                    - Desenvolvimento
├── tests/                  - Testes
├── secrets/                - Secrets (SOPS)
├── sec/                    - Security files
├── evidences/              - Build evidences
└── archive/                - Arquivos antigos
```

---

## Pontos de Entrada Principais

### Para Rebuilds do Sistema
```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Para Home Manager (usuário)
```bash
home-manager switch --flake /etc/nixos#kernelcore@kernelcore
```

### Arquivos Chave
1. `/etc/nixos/flake.nix` - Entry point
2. `/etc/nixos/hosts/kernelcore/configuration.nix` - System config
3. `/etc/nixos/hosts/kernelcore/home/home.nix` - Home Manager
4. `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix` - ZSH ★
5. `/etc/nixos/modules/desktop/hyprland.nix` - Hyprland ★
6. `/etc/nixos/modules/packages/tar-packages/packages/zellij.nix` - Zellij ★

---

## Arquivos de Configuração do Usuário

Estes são **gerados automaticamente** pelo NixOS:

- `~/.zshrc` - Gerado de `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix`
- `~/.p10k.zsh` - Copiado de `/etc/nixos/hosts/kernelcore/home/shell/p10k.zsh`
- `~/.config/hypr/hyprland.conf` - Configuração manual do usuário
- `~/.config/zellij/config.kdl` - Configuração manual do usuário

**IMPORTANTE:** Modificações em `~/.zshrc` serão sobrescritas no próximo rebuild!
Sempre edite os arquivos em `/etc/nixos/` para mudanças permanentes.

---

## Guias Rápidos

- Hyprland: `~/.config/hypr/GUIA-RAPIDO.md`
- Zellij: `~/.config/zellij/GUIA-RAPIDO.md`
- Setup multi-host: `/etc/nixos/docs/guides/MULTI-HOST-SETUP.md`
- Secrets: `/etc/nixos/docs/guides/SECRETS.md`
- SSH: `/etc/nixos/docs/guides/SSH-CONFIGURATION.md`

---

## Estatísticas do Sistema

- **Total de arquivos .nix:** 198
- **Total de módulos:** ~130
- **ML models size:** 3.8G
- **Repository size:** 6.9G
- **Total directories:** 647
- **Total files:** 924

---

**Última atualização:** 2025-11-23
