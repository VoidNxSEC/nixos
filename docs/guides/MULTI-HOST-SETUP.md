# Multi-Host Setup - Laptop + Desktop

## Situação Atual

**1 host**: `kernelcore` (LAPTOP)
- Hardware: Intel mobile, Thunderbolt, WiFi
- Desktop: GNOME + Wayland
- IP: Dinâmico (192.168.15.8)

## Objetivo

**2 hosts**:

### Laptop (atual)
- Nome: `kernelcore-laptop`
- Desktop: GNOME (heavy, feature-rich)
- Uso: Mobile, desenvolvimento, tudo
- IP: 192.168.15.8 (dinâmico)

### Desktop (novo)
- Nome: `kernelcore-desktop`
- Desktop: i3 WM (tiling, lightweight)
- Uso: Builder, cache server, workstation fixa
- IP: 192.168.15.7 (fixo)

---

## Estrutura de Diretórios

```
/etc/nixos/
├── flake.nix                      # Define ambos os hosts
├── hosts/
│   ├── common/                    # ⭐ NOVO - Configs compartilhados
│   │   ├── default.nix           # Imports todos os módulos comuns
│   │   ├── base.nix              # Sistema base (usuários, locale, timezone)
│   │   ├── hardware.nix          # Hardware comum (NVIDIA, etc)
│   │   ├── security.nix          # Security hardening comum
│   │   └── networking.nix        # Network base (não bridge/vpn)
│   │
│   ├── laptop/                    # ⭐ RENOMEAR kernelcore → laptop
│   │   ├── default.nix
│   │   ├── configuration.nix     # Laptop-specific
│   │   ├── hardware-configuration.nix
│   │   └── desktop.nix           # GNOME config
│   │
│   └── desktop/                   # ⭐ NOVO - Desktop config
│       ├── default.nix
│       ├── configuration.nix     # Desktop-specific
│       ├── hardware-configuration.nix
│       └── desktop.nix           # i3 config
│
└── modules/                       # Módulos reutilizáveis (já existem)
```

---

## O que vai onde?

### `hosts/common/` - Compartilhado

**base.nix:**
```nix
- users.users.kernelcore
- time.timeZone
- i18n.defaultLocale
- console.keyMap
- nix.settings
```

**hardware.nix:**
```nix
- kernelcore.nvidia.enable = true
- kernelcore.nvidia.cudaSupport = true
```

**security.nix:**
```nix
- kernelcore.security.hardening.enable
- kernelcore.security.ssh.enable
- kernelcore.security.audit.enable
- kernelcore.security.clamav.enable
```

**networking.nix:**
```nix
- DNS resolver config
- Firewall básico
- NÃO: bridge, VPN (específicos)
```

---

### `hosts/laptop/` - Laptop específico

**configuration.nix:**
```nix
{
  imports = [
    ../common  # Herda tudo do common
    ./hardware-configuration.nix
    ./desktop.nix
  ];

  # LAPTOP SPECIFICS
  networking = {
    hostName = "kernelcore-laptop";
    networkmanager.enable = true;  # WiFi management
  };

  # Bridge para VMs
  kernelcore.network.bridge.enable = true;

  # WiFi optimization
  kernelcore.hardware.wifi-optimization.enable = true;

  # Offload para desktop
  kernelcore.services.laptop-offload.enable = true;
  kernelcore.services.laptop-offload.builderHost = "192.168.15.7";

  # Power management (laptop)
  services.tlp.enable = true;
  powerManagement.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
}
```

**desktop.nix (GNOME):**
```nix
{
  # GNOME Desktop Environment
  services = {
    xserver.enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    gnome.core-shell.enable = true;
    gnome.core-apps.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    # ... GNOME apps
  ];
}
```

---

### `hosts/desktop/` - Desktop específico

**configuration.nix:**
```nix
{
  imports = [
    ../common  # Herda tudo do common
    ./hardware-configuration.nix
    ./desktop.nix
  ];

  # DESKTOP SPECIFICS
  networking = {
    hostName = "kernelcore-desktop";
    # IP fixo
    interfaces.enp0s31f6.ipv4.addresses = [{
      address = "192.168.15.7";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.15.1";
  };

  # Binary cache server
  services.nix-serve = {
    enable = true;
    port = 5000;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  # Build server (aceita builds remotos)
  nix.settings = {
    trusted-users = [ "nix-builder" "@wheel" ];
  };

  # SSH para builds remotos
  users.users.nix-builder = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      # Chave pública do laptop
      "ssh-ed25519 AAAA..."
    ];
  };

  # SEM power management (desktop sempre ligado)
  services.tlp.enable = false;
  powerManagement.enable = false;

  # SEM WiFi optimization (usa ethernet)
  kernelcore.hardware.wifi-optimization.enable = false;
}
```

**desktop.nix (i3 WM):**
```nix
{ config, pkgs, lib, ... }:

{
  # i3 Window Manager (lightweight)
  services.xserver = {
    enable = true;

    # Display Manager (leve)
    displayManager = {
      lightdm.enable = true;
      defaultSession = "none+i3";
    };

    # i3 Tiling Window Manager
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu           # Application launcher
        i3status        # Status bar
        i3lock          # Screen locker
        i3blocks        # Alternative status bar
        rofi            # Better application launcher
        polybar         # Modern status bar (optional)
      ];
    };
  };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Essential GUI apps (lightweight)
  environment.systemPackages = with pkgs; [
    # Terminal
    alacritty       # GPU-accelerated terminal

    # File manager
    pcmanfm         # Lightweight

    # Web browser
    firefox

    # Image viewer
    feh

    # Compositor (transparency, shadows)
    picom

    # Network manager applet
    networkmanagerapplet

    # Screenshot
    scrot
    maim

    # Clipboard
    xclip

    # PDF viewer
    zathura
  ];

  # i3 config (opcional - pode ser no home-manager)
  environment.etc."i3/config".text = ''
    # i3 config
    set $mod Mod4

    # Font
    font pango:DejaVu Sans Mono 10

    # Start terminal
    bindsym $mod+Return exec alacritty

    # Kill focused window
    bindsym $mod+Shift+q kill

    # Start rofi
    bindsym $mod+d exec rofi -show drun

    # Change focus (vim keys)
    bindsym $mod+h focus left
    bindsym $mod+j focus down
    bindsym $mod+k focus up
    bindsym $mod+l focus right

    # Move windows
    bindsym $mod+Shift+h move left
    bindsym $mod+Shift+j move down
    bindsym $mod+Shift+k move up
    bindsym $mod+Shift+l move right

    # Split horizontal/vertical
    bindsym $mod+b split h
    bindsym $mod+v split v

    # Fullscreen
    bindsym $mod+f fullscreen toggle

    # Workspaces
    bindsym $mod+1 workspace 1
    bindsym $mod+2 workspace 2
    # ... etc

    # Status bar
    bar {
        status_command i3status
    }
  '';
}
```

---

## Flake.nix Atualizado

```nix
{
  description = "NixOS configurations - Multi-host";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {

      # ──────────────────────────────────────────────────────
      # LAPTOP - Mobile workstation
      # ──────────────────────────────────────────────────────
      kernelcore-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop
        ];
      };

      # ──────────────────────────────────────────────────────
      # DESKTOP - Builder + Cache server
      # ──────────────────────────────────────────────────────
      kernelcore-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/desktop
        ];
      };

    };
  };
}
```

---

## Migração Passo-a-Passo

### 1. Criar estrutura comum

```bash
cd /etc/nixos
mkdir -p hosts/common
```

### 2. Extrair configs compartilhados

```bash
# Criar hosts/common/default.nix
# Mover configs comuns de configuration.nix para lá
```

### 3. Renomear laptop

```bash
mv hosts/kernelcore hosts/laptop
```

### 4. Criar desktop

```bash
mkdir -p hosts/desktop
# Copiar hardware-configuration.nix do desktop real
# Criar configuration.nix + desktop.nix com i3
```

### 5. Testar builds

```bash
# Laptop
nix build .#nixosConfigurations.kernelcore-laptop.config.system.build.toplevel

# Desktop
nix build .#nixosConfigurations.kernelcore-desktop.config.system.build.toplevel
```

### 6. Deploy

```bash
# No laptop
sudo nixos-rebuild switch --flake .#kernelcore-laptop

# No desktop
sudo nixos-rebuild switch --flake .#kernelcore-desktop
```

---

## Comparação Laptop vs Desktop

| Feature | Laptop | Desktop |
|---------|--------|---------|
| **WM** | GNOME + Wayland | i3 WM + X11 |
| **Display Manager** | GDM | LightDM |
| **IP** | Dinâmico (.8) | Fixo (.7) |
| **WiFi** | ✅ Sim | ❌ Ethernet only |
| **Power Mgmt** | TLP enabled | Disabled |
| **Builder** | Offload para desktop | Host local builds |
| **Cache** | Usa desktop como cache | Serve cache |
| **Bridge** | ✅ Para VMs | ❌ Não precisa |
| **Weight** | Heavy (~2GB RAM) | Light (~500MB RAM) |

---

## Benefícios

✅ **Shared configs** - DRY (Don't Repeat Yourself)
✅ **Easy to maintain** - Mudança comum = 1 lugar
✅ **Clear separation** - Desktop vs Laptop óbvio
✅ **Testable** - Build ambos antes de deploy
✅ **Portable** - Git clone em qualquer máquina

---

## Próximos Passos

1. ⭐ Criar módulo i3 lightweight
2. ⭐ Criar estrutura hosts/common
3. Migrar configs compartilhados
4. Gerar hardware-configuration.nix do desktop
5. Deploy e testar

Quer que eu crie os arquivos agora?
