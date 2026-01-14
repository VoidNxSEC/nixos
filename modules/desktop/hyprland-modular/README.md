# 🌊 Hyprland Modular Framework

> A **production-grade**, extensible configuration system for Hyprland with declarative theming, profiles, and plugin support.

## ✨ Features

- **🎨 Theme Engine** - 7 built-in themes (Glassmorphism, Nord, Dracula, Catppuccin, Gruvbox, TokyoNight, Minimal)
- **👤 Profile System** - Gaming, Work, Development, Streaming, Presentation, Minimal
- **🔌 Plugin Architecture** - First-class support for Hyprland plugins
- **⌨️ Modular Keybindings** - Composable keybinding modules
- **🪟 Declarative Window Rules** - Category-based rule system
- **🔧 Feature Flags** - Toggle individual features on/off
- **📐 Type-Safe Options** - Full NixOS module type checking

## 📁 Structure

```
hyprland-modular/
├── default.nix          # Main module with options
├── lib/
│   └── default.nix      # Helper functions (colors, rules, bindings)
├── themes/
│   └── default.nix      # Theme definitions
├── profiles/
│   └── default.nix      # Usage profiles
├── bindings/
│   └── default.nix      # Keybinding modules
├── rules/
│   └── default.nix      # Window rule categories
├── plugins/
│   └── default.nix      # Plugin system
└── examples.nix         # Usage examples
```

## 🚀 Quick Start

### 1. Import the module

```nix
# In your home-manager configuration
{ config, pkgs, ... }:

{
  imports = [ ./path/to/hyprland-modular ];
  
  programs.hyprland-modular = {
    enable = true;
    theme = "glassmorphism";
    profile = "default";
  };
}
```

### 2. Basic Configuration

```nix
programs.hyprland-modular = {
  enable = true;
  
  # Visual theme
  theme = "catppuccin";  # or "nord", "dracula", "gruvbox", etc.
  
  # Usage profile
  profile = "development";  # or "gaming", "work", "minimal"
  
  # Monitor setup
  monitors = [{
    resolution = "1920x1080@144";
    position = "auto";
    scale = 1.0;
  }];
  
  # Input
  input.keyboard.layout = "br";
  input.mouse.accelProfile = "flat";
  
  # Terminal
  terminal.primary = "kitty";
  terminal.multiplexer = "zellij";
};
```

## 🎨 Themes

| Theme | Description |
|-------|-------------|
| `glassmorphism` | Frosted glass with cyan/violet gradients |
| `nord` | Arctic, bluish clean aesthetic |
| `dracula` | Dark with vibrant purple/pink |
| `catppuccin` | Soothing pastel colors |
| `gruvbox` | Retro warm colors |
| `tokyonight` | Clean dark blue theme |
| `minimal` | No effects, maximum performance |

### Custom Theme

```nix
programs.hyprland-modular = {
  theme = "custom";
  customTheme = {
    name = "my-theme";
    colors = {
      primary = "#ff6b6b";
      secondary = "#4ecdc4";
      background = "#1a1a2e";
      surface = "#16213e";
    };
    opacity = { active = 0.95; inactive = 0.90; };
    blur = { size = 12; passes = 3; };
    rounding = 16;
  };
};
```

## 👤 Profiles

| Profile | Use Case | Animations | Blur | VRR |
|---------|----------|------------|------|-----|
| `default` | Everyday use | Full | Full | On |
| `gaming` | Maximum FPS | Minimal | Off | Fullscreen |
| `work` | Productivity | Moderate | Light | On |
| `minimal` | Battery/low-end | Off | Off | Off |
| `presentation` | Demos | Elegant | Heavy | On |
| `development` | Coding | Balanced | Light | On |
| `streaming` | OBS capture | Smooth | Light | Off |

## 🔧 Feature Flags

```nix
programs.hyprland-modular.features = {
  blur = true;           # Window blur effects
  animations = true;     # Window animations
  shadows = true;        # Drop shadows
  rounding = true;       # Rounded corners
  vrr = true;            # Variable Refresh Rate
  dimInactive = true;    # Dim unfocused windows
  windowSwallowing = true; # Terminal swallowing
  clipboard = true;      # Clipboard manager (cliphist)
  screenshotTools = true; # grim, slurp, swappy
  idleManagement = true;  # hypridle
  notifications = true;   # mako
};
```

## ⌨️ Keybinding Modules

```nix
programs.hyprland-modular.keybindings = {
  modules = [ 
    "core"       # Terminal, launcher, kill, exit
    "window"     # Fullscreen, float, focus, move
    "workspace"  # Switch, move to workspace
    "media"      # Volume, brightness, playerctl
    "screenshot" # Print screen variants
    "power"      # Lock, suspend, shutdown
  ];
  
  # Add custom bindings
  extraBinds = [
    "$mainMod, B, exec, firefox"
    "$mainMod SHIFT, B, exec, brave"
  ];
};
```

### Default Keybindings

| Keys | Action |
|------|--------|
| `Super + Return` | Terminal (with multiplexer) |
| `Super + D` | App launcher |
| `Super + E` | File manager |
| `Super + Q` | Kill window |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move to workspace |
| `Print` | Screenshot region to editor |
| `Super + Ctrl + L` | Lock screen |

## 🪟 Window Rule Categories

```nix
programs.hyprland-modular.windowRules = {
  categories = [
    "development"     # IDEs, terminals, editors
    "browsers"        # Web browsers
    "fileManagers"    # File managers
    "systemUtilities" # pavucontrol, nm-applet, etc.
    "media"           # mpv, vlc, image viewers
    "productivity"    # Obsidian, PDFs, office
    "communication"   # Discord, Slack, Teams
    "dialogs"         # Modal dialogs, auth prompts
    "performance"     # noanim, immediate render
    "gaming"          # Steam, Lutris, games
  ];
  
  # Add custom rules
  extra = [
    "float, class:^(my-app)$"
    "opacity 0.9 0.85, class:^(my-app)$"
  ];
};
```

## 🔌 Plugins

```nix
programs.hyprland-modular.plugins = {
  enable = true;
  list = [
    "hyprexpo"         # Workspace overview
    "hyprbars"         # Window title bars
    "borders-plus-plus" # Enhanced borders
  ];
};
```

### Available Plugins

| Plugin | Description |
|--------|-------------|
| `hyprexpo` | macOS-like workspace overview |
| `hyprspace` | Alternative workspace overview |
| `hyprbars` | Window title bars with buttons |
| `hyprtrails` | Cursor trail effects |
| `borders-plus-plus` | Multi-layer borders |
| `csgo-vulkan-fix` | CS2 Vulkan rendering fix |

## 🖥️ Multi-Monitor Setup

```nix
programs.hyprland-modular.monitors = [
  {
    name = "DP-1";
    resolution = "2560x1440@165";
    position = "0x0";
    scale = 1.0;
    vrr = true;
  }
  {
    name = "HDMI-A-1";
    resolution = "1920x1080@60";
    position = "2560x0";
    scale = 1.0;
    transform = 0;  # 0=normal, 1=90°, 2=180°, 3=270°
  }
];
```

## 🔒 Idle & Lock

```nix
programs.hyprland-modular.idle = {
  lockTimeout = 300;     # Lock after 5 minutes
  dpmsTimeout = 600;     # Screen off after 10 minutes
  suspendTimeout = 1800; # Suspend after 30 minutes (null = disabled)
};
```

## 🛠️ Advanced: Using the Library

The `lib/` module exposes helper functions:

```nix
# In your own modules
let
  hyprLib = import ./lib { inherit lib pkgs; };
in {
  # Color utilities
  hyprLib.hexToRgba "#00d4ff" 0.9  # => "rgba(00d4ffe6)"
  hyprLib.gradient [ "#00d4ff" "#7c3aed" ] 45  # => gradient string
  
  # Rule builders
  hyprLib.appRule { class = "firefox"; opacity = 0.98; }
  hyprLib.floatingApp "pavucontrol" 800 500
  hyprLib.dialogRule "Confirm"
  
  # Binding helpers
  hyprLib.mkWorkspaceBinds "$mainMod" 10
  hyprLib.mkDirectionalBinds "$mainMod" "movefocus"
}
```

## 📝 Migration from Monolithic Config

1. **Identify your settings**: Theme colors, opacity, animations
2. **Choose a base theme**: Pick the closest built-in theme
3. **Select a profile**: Match your primary use case
4. **Enable/disable features**: Use feature flags
5. **Add custom rules**: Use `windowRules.extra`
6. **Add custom binds**: Use `keybindings.extraBinds`

## 🔄 Escape Hatches

For settings not covered by the options:

```nix
programs.hyprland-modular = {
  # Merge into settings
  extraSettings = {
    general.some_option = "value";
  };
  
  # Raw config lines
  extraConfig = ''
    # Raw Hyprland config syntax
    exec-once = my-custom-script
  '';
};
```

## 📜 License

MIT - Feel free to use and modify!

## 🤝 Contributing

PRs welcome! Areas that could use expansion:
- More themes
- More plugins
- Workspace management options
- Animation presets
