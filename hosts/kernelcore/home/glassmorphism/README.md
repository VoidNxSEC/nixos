# 🌟 Glassmorphism Design System

A premium dark glassmorphism theme for NixOS/Hyprland with frosted glass effects, electric neon accents, and 144Hz optimizations.

## 📦 Components

| Component | File | Description |
|-----------|------|-------------|
| **Colors** | `colors.nix` | Design tokens, color palette, transparency values |
| **Kitty** | `kitty.nix` | GPU-accelerated terminal with blur & graphics protocol |
| **Zellij** | `zellij.nix` | Terminal multiplexer with transparent panes |
| **Wallpaper** | `wallpaper.nix` | Wallpaper management with systemd service |
| **Waybar** | `waybar.nix` | Frosted glass status bar with GPU/SSH modules |
| **Mako** | `mako.nix` | Glass notification daemon |
| **Wofi** | `wofi.nix` | Glass application launcher |
| **Hyprlock** | `hyprlock.nix` | Glass lock screen |
| **Wlogout** | `wlogout.nix` | Glass logout menu |
| **Swappy** | `swappy.nix` | Screenshot editor |

## 🎨 Color Palette

```
┌─────────────────────────────────────────────────────────────┐
│  GLASSMORPHISM PALETTE                                      │
├─────────────────────────────────────────────────────────────┤
│  PRIMARY ACCENTS                                            │
│  ┌──────┐ #00d4ff  Electric Cyan (primary)                 │
│  ├──────┤ #7c3aed  Soft Violet (secondary)                 │
│  └──────┘ #ff00aa  Neon Magenta (danger/alert)             │
├─────────────────────────────────────────────────────────────┤
│  BASE SURFACES                                              │
│  #0a0a0f  Deepest background                               │
│  #12121a  Primary surface                                  │
│  #1a1a24  Elevated surface                                 │
│  #22222e  Highest elevation                                │
├─────────────────────────────────────────────────────────────┤
│  SEMANTIC                                                   │
│  #22c55e  Success/Green                                    │
│  #eab308  Warning/Yellow                                   │
│  #ef4444  Error/Red                                        │
│  #3b82f6  Info/Blue                                        │
└─────────────────────────────────────────────────────────────┘
```

## ⌨️ Keybindings

### Terminal Launchers
| Keybind | Action |
|---------|--------|
| `SUPER + Return` | Kitty + Zellij (primary - GPU, graphics protocol) |
| `SUPER + SHIFT + Return` | Alacritty + Zellij (fallback - lightweight) |
| `SUPER + CTRL + Return` | Kitty standalone |
| `SUPER + CTRL + SHIFT + Return` | Alacritty standalone |

### Zellij Navigation (inside terminal)
| Keybind | Action |
|---------|--------|
| `Alt + h/j/k/l` | Move focus between panes |
| `Alt + H/J/K/L` | Resize panes |
| `Alt + 1-9` | Switch to tab number |
| `Alt + n` | New pane (horizontal) |
| `Alt + v` | New pane (vertical) |
| `Alt + t` | New tab |
| `Alt + x` | Close focused pane |
| `Alt + f` | Toggle fullscreen |
| `Alt + z` | Toggle pane frames |
| `Alt + s` | Toggle floating panes |
| `Ctrl + g` | Lock mode (passthrough to app) |

## 🖼️ Wallpaper Setup

The wallpaper module provides three methods:

### 1. Generate a Wallpaper (Recommended)
```bash
generate-glassmorphism-wallpaper 1920 1080
```
Creates a procedural dark abstract wallpaper with cyan/violet luminescent orbs.

### 2. Download Curated Wallpaper
```bash
download-glassmorphism-wallpaper
```
Downloads from curated sources (requires internet).

### 3. Manual Setup
Place your wallpaper at:
```
~/Pictures/wallpapers/glassmorphism-default.png
```

The systemd service will automatically use this file on login.

### Change Wallpaper
```bash
set-wallpaper ~/Pictures/wallpapers/your-image.png
```

## 🖥️ Terminal Stack

### Kitty (Primary)
- **GPU-accelerated** with NVIDIA optimizations
- **Background blur** enabled (compositor-dependent)
- **Graphics protocol** for images in terminal
- **144Hz optimized** - 6ms repaint delay (~166fps cap)
- **JetBrainsMono Nerd Font** at 13.5px
- **92% opacity** with glassmorphism colors

### Zellij (Multiplexer)
- **Transparent theme** matching glassmorphism palette
- **Rounded pane frames**
- **Custom layouts**: `default`, `dev`, `minimal`, `monitor`, `pair`
- **Vim-style keybindings**
- **Session persistence**

### Alacritty (Fallback)
- Lightweight alternative
- Same color scheme
- 94% opacity

## 📂 Zellij Layouts

```bash
# Default - simple single pane with tab/status bars
zellij --layout default

# Development - editor + terminal + watch panes
zellij --layout dev

# Minimal - no bars, borderless
zellij --layout minimal

# Monitoring - btop + logs grid
zellij --layout monitor

# Pair Programming - side-by-side terminals
zellij --layout pair
```

## 🔧 Configuration Options

### Transparency Levels
Defined in `colors.nix`:
```nix
alpha = {
  solid = "ff";     # 100%
  high = "e6";      # 90%
  medium = "cc";    # 80%
  low = "66";       # 40%
  veryLow = "33";   # 20%
};
```

### Blur Settings
```nix
blur = {
  size = 10;
  passes = 3;
  noise = 0.02;
  contrast = 0.9;
  brightness = 0.8;
};
```

### Window Opacity
- **Active windows**: 92%
- **Inactive windows**: 88%
- **Terminals**: 90-92%
- **Browsers**: 98%

## 🚀 Quick Start

1. **Rebuild NixOS**:
   ```bash
   sudo nixos-rebuild switch --flake .#kernelcore
   ```

2. **Generate wallpaper**:
   ```bash
   generate-glassmorphism-wallpaper
   ```

3. **Test terminals**:
   - Press `SUPER + Return` for Kitty + Zellij
   - Press `SUPER + SHIFT + Return` for Alacritty + Zellij

4. **Test notifications**:
   ```bash
   ~/.config/mako/scripts/test-notifications.sh
   ```

## 🎯 Performance Notes

### 144Hz Optimizations
- VRR (Variable Refresh Rate) enabled
- Custom bezier curves for smooth animations
- Hardware cursor disabled for NVIDIA compatibility
- Direct scanout where possible

### NVIDIA Considerations
- `WLR_NO_HARDWARE_CURSORS=1` - Required for cursor visibility
- `GBM_BACKEND=nvidia-drm` - Native DRM backend
- `__GLX_VENDOR_LIBRARY_NAME=nvidia` - GLX compatibility
- Blur may impact performance on older GPUs

## 📁 File Structure

```
hosts/kernelcore/home/glassmorphism/
├── README.md           # This file
├── default.nix         # Module entry point
├── colors.nix          # Design tokens
├── kitty.nix           # Kitty terminal config
├── zellij.nix          # Zellij multiplexer config
├── wallpaper.nix       # Wallpaper management
├── waybar.nix          # Status bar
├── mako.nix            # Notifications
├── wofi.nix            # App launcher
├── hyprlock.nix        # Lock screen
├── wlogout.nix         # Logout menu
├── swappy.nix          # Screenshot editor
└── agent-hub.nix       # AI agent integration (placeholder)
```

## 🔗 Related Files

- `hosts/kernelcore/home/hyprland.nix` - Hyprland window manager config
- `hosts/kernelcore/home/alacritty.nix` - Alacritty terminal config (fallback)
- `hosts/kernelcore/home/home.nix` - Home Manager entry point

## 📝 Changelog

### v2.0.0 (2024)
- ✨ Added Kitty terminal with glassmorphism theme
- ✨ Added Zellij configuration with KDL theme
- ✨ Added wallpaper management module
- ✨ Added wallpaper generator script
- 🔄 Updated keybindings for dual terminal support
- 🔄 Updated Waybar with Kitty icon mapping
- 🔄 Updated Mako with Kitty notification styling

### v1.0.0 (Initial)
- Glassmorphism design system foundation
- Waybar, Mako, Wofi, Hyprlock, Wlogout styling