# ============================================
# Example: Using Hyprland Modular Framework
# ============================================
# This file shows various configuration examples.
# Import this module in your home-manager config.
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./default.nix ];

  # ==========================================
  # EXAMPLE 1: Minimal Gaming Setup
  # ==========================================
  # programs.hyprland-modular = {
  #   enable = true;
  #   theme = "minimal";
  #   profile = "gaming";
  #
  #   features = {
  #     blur = false;
  #     animations = false;
  #     shadows = false;
  #   };
  #
  #   monitors = [{
  #     resolution = "2560x1440@165";
  #     position = "auto";
  #     scale = 1.0;
  #   }];
  # };

  # ==========================================
  # EXAMPLE 2: Developer Workstation
  # ==========================================
  # programs.hyprland-modular = {
  #   enable = true;
  #   theme = "tokyonight";
  #   profile = "development";
  #
  #   terminal = {
  #     primary = "kitty";
  #     secondary = "alacritty";
  #     multiplexer = "zellij";
  #   };
  #
  #   input.keyboard = {
  #     layout = "us";
  #     options = "caps:escape";
  #   };
  #
  #   keybindings.modules = [
  #     "core" "window" "workspace" "media" "screenshot" "power"
  #   ];
  #
  #   windowRules.categories = [
  #     "development" "browsers" "productivity" "dialogs" "performance"
  #   ];
  # };

  # ==========================================
  # EXAMPLE 3: Streaming Setup
  # ==========================================
  # programs.hyprland-modular = {
  #   enable = true;
  #   theme = "dracula";
  #   profile = "streaming";
  #
  #   monitors = [
  #     { name = "DP-1"; resolution = "2560x1440@144"; position = "0x0"; }
  #     { name = "HDMI-A-1"; resolution = "1920x1080@60"; position = "2560x0"; }
  #   ];
  #
  #   features = {
  #     vrr = false;  # Consistent capture
  #   };
  #
  #   autostart = [
  #     "obs --startreplaybuffer"
  #   ];
  # };

  # ==========================================
  # EXAMPLE 4: Full Featured (Your Config)
  # ==========================================
  programs.hyprland-modular = {
    enable = true;

    # Visual styling
    theme = "glassmorphism";
    profile = "default";

    # All features enabled
    features = {
      blur = true;
      animations = true;
      shadows = true;
      rounding = true;
      vrr = true;
      dimInactive = true;
      windowSwallowing = true;
      clipboard = true;
      screenshotTools = true;
      idleManagement = true;
      notifications = true;
    };

    # 144Hz monitor
    monitors = [
      {
        resolution = "1920x1080@144";
        position = "auto";
        scale = 1.0;
      }
    ];

    # Brazilian keyboard
    input = {
      keyboard.layout = "br";
      mouse = {
        sensitivity = 0.0;
        accelProfile = "flat";
      };
      touchpad = {
        naturalScroll = false;
        tapToClick = true;
      };
    };

    # Terminal setup with Zellij
    terminal = {
      primary = "kitty";
      secondary = "alacritty";
      multiplexer = "zellij";
    };

    # Wofi launcher
    launcher = "wofi";
    fileManager = "nemo";

    # Keybindings
    mainMod = "SUPER";
    keybindings = {
      enable = true;
      modules = [
        "core"
        "window"
        "workspace"
        "media"
        "screenshot"
        "power"
      ];

      # Custom bindings
      extraBinds = [
        # Agent Hub integration
        "$mainMod, A, exec, $HOME/.config/agent-hub/agent-launcher.sh"
        "$mainMod SHIFT, A, exec, $HOME/.config/agent-hub/quick-prompt.sh"

        # Calculator
        "$mainMod, EQUAL, exec, wofi --dmenu --prompt=Calculator | bc -l | wl-copy"
      ];
    };

    # Window rules
    windowRules = {
      enable = true;
      categories = [
        "development"
        "browsers"
        "fileManagers"
        "systemUtilities"
        "media"
        "productivity"
        "communication"
        "dialogs"
        "performance"
      ];

      # Custom rules
      extra = [
        # Agent Hub windows
        "float, class:^(agent-hub-chat)$"
        "size 1000 700, class:^(agent-hub-chat)$"
        "center, class:^(agent-hub-chat)$"
        "opacity 0.95 0.90, class:^(agent-hub-chat)$"
      ];
    };

    # Workspaces
    workspaces = {
      count = 10;
      specialWorkspaces = [
        {
          name = "magic";
          key = "S";
        }
      ];
    };

    # Idle management
    idle = {
      lockTimeout = 300; # 5 minutes
      dpmsTimeout = 600; # 10 minutes
      suspendTimeout = null; # Disabled
    };

    # Autostart
    autostart = [
      # Add any custom autostart commands
    ];
  };
}
