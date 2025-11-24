# Arquitetura Visual do Sistema NixOS

**Data:** 2025-11-23
**Host:** kernelcore

---

## Fluxo de Configuração

```
┌─────────────────────────────────────────────────────────────────┐
│                         /etc/nixos/                             │
│                        flake.nix                                │
│                     (Entry Point)                               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├──────────────────┬─────────────────────────┐
                     │                  │                         │
                     ▼                  ▼                         ▼
          ┌──────────────────┐  ┌──────────────┐     ┌──────────────────┐
          │   System Config  │  │   Modules    │     │  Home Manager    │
          │                  │  │              │     │                  │
          │ hosts/kernelcore/│  │  modules/    │     │ hosts/kernelcore/│
          │ configuration.nix│  │              │     │   home/home.nix  │
          └────────┬─────────┘  └──────┬───────┘     └────────┬─────────┘
                   │                   │                      │
                   │                   │                      │
                   └───────────┬───────┴──────────────────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │  nixos-rebuild     │
                    │     switch         │
                    └──────────┬─────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │   Sistema Ativo    │
                    │  (Generation N)    │
                    └────────────────────┘
```

---

## Estrutura de Módulos

```
                           ┌─────────────────┐
                           │  modules/       │
                           │  (Reutilizáveis)│
                           └────────┬────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │           │               │               │           │
        ▼           ▼               ▼               ▼           ▼
    ┌───────┐  ┌────────┐     ┌─────────┐    ┌─────────┐  ┌────────┐
    │Desktop│  │Security│     │ Shell   │    │Hardware │  │   ML   │
    └───┬───┘  └───┬────┘     └────┬────┘    └────┬────┘  └───┬────┘
        │          │               │              │           │
        │          │               │              │           │
    Hyprland   Hardening       Zsh/Bash       NVIDIA     Ollama/Llama
    Waybar     Audit           Aliases        Intel      GPU Manager
    Wofi       AIDE            Functions      Bluetooth  VRAM Intel
    Dunst      ClamAV          P10k           Thermal    Offload
```

---

## Desktop Environment Stack

```
┌──────────────────────────────────────────────────────────────────┐
│                      Camada de Aplicação                         │
│  Brave │ Firefox │ VSCode │ Alacritty │ Nemo │ btop │ ...        │
└────────┬─────────────────────────────────────────────────────────┘
         │
┌────────┴─────────────────────────────────────────────────────────┐
│                  Camada de Desktop Environment                   │
│                                                                   │
│  ┌──────────┐  ┌─────────┐  ┌───────┐  ┌─────────┐  ┌────────┐ │
│  │ Hyprland │  │ Waybar  │  │ Wofi  │  │  Dunst  │  │ Swaylock││
│  │  (WM)    │  │ (Bar)   │  │(Launcher│ │ (Notif) │  │ (Lock) ││
│  └────┬─────┘  └────┬────┘  └───┬───┘  └────┬────┘  └───┬────┘ │
└───────┼─────────────┼───────────┼───────────┼───────────┼───────┘
        │             │           │           │           │
┌───────┴─────────────┴───────────┴───────────┴───────────┴───────┐
│                      Wayland Compositor                          │
│                                                                   │
│  ┌────────────────┐        ┌─────────────────────┐              │
│  │ wlroots        │        │  XDG Desktop Portal │              │
│  │ (Compositor)   │        │  - hyprland         │              │
│  └───────┬────────┘        │  - gtk              │              │
│          │                 └──────────┬──────────┘              │
└──────────┼────────────────────────────┼─────────────────────────┘
           │                            │
┌──────────┴────────────────────────────┴─────────────────────────┐
│                      Kernel & Drivers                            │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Linux   │  │  NVIDIA  │  │  Intel   │  │  Audio   │        │
│  │  Kernel  │  │ Drivers  │  │ Drivers  │  │  (ALSA/  │        │
│  │          │  │          │  │          │  │   Pulse) │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Shell Environment Stack

```
┌──────────────────────────────────────────────────────────────────┐
│                      Terminal Emulator                           │
│                       Alacritty                                  │
│                   (GPU-accelerated)                              │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────┐
│                    Terminal Multiplexer                          │
│                         Zellij                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Tab 1   │  │  Tab 2   │  │  Tab 3   │  │  Tab 4   │        │
│  │ ┌──┬──┐  │  │          │  │          │  │          │        │
│  │ │p1│p2│  │  │          │  │          │  │          │        │
│  │ └──┴──┘  │  │          │  │          │  │          │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────┐
│                           Shell                                  │
│                            ZSH                                   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                  Powerlevel10k                         │     │
│  │              (Prompt personalizado)                    │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Plugins:                                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐       │
│  │ Oh-my-zsh   │  │ Autosuggestions│ │ Syntax Highlight│       │
│  │ - git       │  │                │  │                 │       │
│  │ - docker    │  │  History-based │  │  Real-time      │       │
│  │ - kubectl   │  │  Completion    │  │  Syntax color   │       │
│  │ - aws       │  └────────────────┘  └──────────────────┘       │
│  │ - sudo      │                                                 │
│  └─────────────┘                                                 │
│                                                                   │
│  Integrações:                                                    │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐       │
│  │   Zoxide    │  │     FZF      │  │   Completion     │       │
│  │  (smarter   │  │  (fuzzy      │  │   (advanced      │       │
│  │    cd)      │  │   finder)    │  │    system)       │       │
│  └─────────────┘  └──────────────┘  └──────────────────┘       │
│                                                                   │
│  Aliases & Functions:                                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ ll, la, gs, ga, gc, gp, dps, clean, dots, ...            │   │
│  │ up(), extract(), backup(), note(), mkcd()                │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Fluxo de Configuração do Shell

```
┌──────────────────────────────────────────────────────────────────┐
│         /etc/nixos/hosts/kernelcore/home/shell/zsh.nix           │
│                    (Configuração Nix)                            │
│  - 353 linhas de configuração declarativa                       │
│  - Define plugins, aliases, funções, history                    │
│  - Integra Powerlevel10k, zoxide, fzf                          │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                    home-manager build
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      ~/.zshrc                                    │
│               (Gerado automaticamente)                           │
│  - 242 linhas geradas pelo NixOS                                │
│  - NÃO EDITAR MANUALMENTE!                                      │
│  - Sobrescrito a cada rebuild                                   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Zsh Runtime                                   │
│  1. Carrega Powerlevel10k instant prompt                        │
│  2. Source Oh-my-zsh                                            │
│  3. Ativa plugins                                               │
│  4. Carrega autosuggestions                                     │
│  5. Carrega syntax highlighting                                 │
│  6. Inicializa zoxide                                           │
│  7. Configura FZF                                               │
│  8. Carrega ~/.p10k.zsh                                         │
│  9. Aplica aliases e funções                                    │
│ 10. Ready! ⚡                                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Sistema de Aliases (Modular)

```
                    /etc/nixos/modules/shell/aliases/
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │         │        │      │      │        │         │
        ▼         ▼        ▼      ▼      ▼        ▼         ▼
    ┌────────┐ ┌────┐  ┌──────┐ ┌──┐ ┌────┐  ┌────────┐ ┌──────┐
    │ Docker │ │ AI │  │GCloud│ │K8s│ │Nix │  │Security│ │System│
    └───┬────┘ └─┬──┘  └───┬──┘ └─┬─┘ └──┬─┘  └───┬────┘ └───┬──┘
        │        │         │      │      │        │          │
        ▼        ▼         ▼      ▼      ▼        ▼          ▼
    build.nix  ollama   gcloud  kubectl system  secrets   utils
    compose    .nix     .nix    .nix    .nix    .nix      .nix
    run.nix

    +
    ┌────────────┐  ┌──────────────┐  ┌────────────┐
    │  Desktop   │  │  Emergency   │  │    MCP     │
    │  hyprland  │  │  emergency   │  │    mcp     │
    │  .nix      │  │  .nix        │  │    .nix    │
    └────────────┘  └──────────────┘  └────────────┘

                            │
                            ▼
            Consolidado em ~/.zshrc via home-manager
```

---

## Hyprland Startup Sequence

```
1. Sistema inicia
         │
         ▼
2. Display Manager / TTY login
         │
         ▼
3. Hyprland inicia (exec Hyprland)
         │
         ├─→ Lê ~/.config/hypr/hyprland.conf
         │
         ├─→ Aplica configurações (monitor, input, decorations)
         │
         └─→ exec-once (autostart):
                 │
                 ├─→ waybar        (status bar)
                 ├─→ dunst         (notificações)
                 ├─→ polkit-gnome  (autenticação)
                 ├─→ nm-applet     (network)
                 └─→ swayidle      (idle management)
                          │
                          └─→ timeout 300  → swaylock
                              timeout 600  → dpms off
```

---

## Zellij Workflow

```
Terminal (Alacritty)
         │
         ├─→ Comando: zellij
         │            │
         │            ▼
         │   Zellij inicia
         │            │
         │            ├─→ Lê ~/.config/zellij/config.kdl
         │            │
         │            ├─→ Aplica tema (gruvbox-dark)
         │            │
         │            ├─→ Configura keybindings
         │            │
         │            └─→ Inicia shell padrão (bash)
         │                         │
         │                         ▼
         ├─────────────────────────────────────────┐
         │        Session Layout                   │
         │                                          │
         │  Tab 1          Tab 2         Tab 3     │
         │  ┌──────┐      ┌──────┐      ┌──────┐  │
         │  │      │      │      │      │      │  │
         │  │ Pane │      │ Full │      │ P1|P2│  │
         │  │      │      │      │      │ ──┼──│  │
         │  │      │      │      │      │ P3|P4│  │
         │  └──────┘      └──────┘      └──────┘  │
         │                                          │
         │  [Alt+t] Nova tab                       │
         │  [Alt+h/j/k/l] Criar panes              │
         │  [Alt+arrows] Navegar                   │
         └──────────────────────────────────────────┘
```

---

## Security Layers

```
┌──────────────────────────────────────────────────────────────────┐
│                      Application Layer                           │
│  - Sandboxed packages (deb-packages, tar-packages)              │
│  - Browser hardening (Brave, Firefox)                           │
│  - VSCode security config                                       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────┐
│                      System Hardening                            │
│  ┌───────────┐  ┌──────────┐  ┌────────┐  ┌─────────────┐      │
│  │  Kernel   │  │ Network  │  │  Boot  │  │  Compiler   │      │
│  │ Hardening │  │ Firewall │  │ Secure │  │  Hardening  │      │
│  └───────────┘  └──────────┘  └────────┘  └─────────────┘      │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────┐
│                         Monitoring                               │
│  ┌───────────┐  ┌──────────┐  ┌────────┐  ┌─────────────┐      │
│  │  Auditd   │  │   AIDE   │  │ ClamAV │  │  Emergency  │      │
│  │  (Audit)  │  │  (File   │  │(Anti-  │  │   Monitor   │      │
│  │           │  │ Integrity│  │ virus) │  │             │      │
│  └───────────┘  └──────────┘  └────────┘  └─────────────┘      │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────┐
│                      Secrets Management                          │
│  ┌──────────────────┐              ┌───────────────────┐        │
│  │      SOPS        │              │    GPG Keys       │        │
│  │  (Age-encrypted) │────────────→ │  SSH Keys         │        │
│  │                  │              │  API Keys         │        │
│  └──────────────────┘              └───────────────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Package Management Layers

```
                    ┌──────────────────┐
                    │   Nix Packages   │
                    │  (nixpkgs)       │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌─────────────────┐  ┌────────────────┐
│ Native Nixpkgs│  │  Custom Builders│  │    Overlays    │
│               │  │                 │  │                │
│ - Standard    │  │ - deb-packages  │  │ - Hyprland     │
│   packages    │  │ - tar-packages  │  │ - Custom pkgs  │
│               │  │ - js-packages   │  │                │
└───────┬───────┘  └────────┬────────┘  └───────┬────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  Sistema Final   │
                  │                  │
                  │  All packages    │
                  │  integrated      │
                  └──────────────────┘

Custom Builders Detail:

deb-packages:
  .deb → Extract → Analyze → Audit → Sandbox → Nix Package

tar-packages:
  .tar.gz → Extract → Validate → Wrapper → Nix Package

js-packages:
  npm/source → Build → Package → Nix Package
```

---

## ML/AI Stack

```
┌──────────────────────────────────────────────────────────────────┐
│                      Application Layer                           │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐          │
│  │ Claude Code │  │ Codex Agent  │  │ Gemini Agent  │          │
│  │  Service    │  │   Service    │  │    Service    │          │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘          │
└─────────┼─────────────────┼──────────────────┼──────────────────┘
          │                 │                  │
┌─────────┴─────────────────┴──────────────────┴──────────────────┐
│                      Model Layer                                 │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │              Ollama GPU Manager                        │     │
│  │  - VRAM Intelligence                                   │     │
│  │  - Model Loading/Unloading                            │     │
│  │  - GPU Orchestration                                  │     │
│  └────────────────────────┬───────────────────────────────┘     │
│                           │                                      │
│  ┌────────────┐  ┌────────┴─────┐  ┌──────────────┐           │
│  │   Llama    │  │   Ollama     │  │ Model Registry│           │
│  │   Models   │  │   Runtime    │  │               │           │
│  └────────────┘  └──────────────┘  └──────────────┘           │
│                                                                   │
│  Storage: /mnt/data/ML-Models/ (3.8G)                           │
└─────────────────────────┬─────────────────────────────────────┘
                          │
┌─────────────────────────┴─────────────────────────────────────┐
│                    Hardware Layer                              │
│                                                                 │
│  ┌──────────────┐              ┌──────────────┐              │
│  │    NVIDIA    │              │    Intel     │              │
│  │     GPU      │              │   Graphics   │              │
│  │   (CUDA)     │              │   (Offload)  │              │
│  └──────────────┘              └──────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Rebuild & Testing Flow

```
┌────────────────────────────────────────────────────────────────┐
│                     Developer Edit                             │
│  vim /etc/nixos/modules/desktop/hyprland.nix                  │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                    Pre-Rebuild Checks                          │
│  - Syntax check (nix flake check)                             │
│  - Git status                                                  │
│  - User hooks (if configured)                                 │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│              sudo nixos-rebuild switch                         │
│                                                                 │
│  1. Parse flake.nix                                           │
│  2. Evaluate configuration                                    │
│  3. Build packages (if needed)                                │
│  4. Create new generation                                     │
│  5. Switch to new generation                                  │
│  6. Activate services                                         │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                    Post-Rebuild                                │
│  - Evidence saved to /etc/nixos/evidences/                    │
│  - Systemd services restarted                                 │
│  - User hooks (if configured)                                 │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
                   System Active ✓
```

---

## Data Flow Diagram

```
User Input (Keyboard/Mouse)
         │
         ▼
    Hyprland (Window Manager)
         │
         ├─→ Applications
         │       │
         │       └─→ Alacritty
         │               │
         │               └─→ Zellij
         │                       │
         │                       └─→ Zsh
         │                               │
         │                               └─→ Commands
         │                                       │
         │                                       ├─→ Nix tools
         │                                       ├─→ Docker
         │                                       ├─→ Git
         │                                       ├─→ AI agents
         │                                       └─→ System utils
         │
         ├─→ Waybar (Status)
         │       │
         │       └─→ System info (CPU, RAM, Network)
         │
         └─→ Dunst (Notifications)
                 │
                 └─→ User alerts
```

---

**Última atualização:** 2025-11-23
