# ============================================================================
# Hyprland Configuration - nix-hypr Modular Framework
# ============================================================================
# Unified configuration using ~/dev/projects/nix-hypr/
#
# Architecture:
#   - Theme: glassmorphism (built-in)
#   - Profile: development (balanced for dev work)
#   - Features: All enabled (blur, animations, shadows, etc.)
#   - Keybindings: Modular system (7 categories)
#   - Window Rules: Categorized (10 categories)
#
# Benefits:
#   - ~75% less manual config (150 lines vs 780 lines)
#   - Type-safe with NixOS options
#   - Easy theme/profile switching
#   - Organized keybindings and rules
# ============================================================================

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Import hyprland-modular framework (vendorized from nix-hypr)
  # Located at: /etc/nixos/modules/desktop/hyprland-modular/
  imports = [
    ../../../modules/desktop/hyprland-modular
  ];

  # ============================================================================
  # HYPRLAND MODULAR CONFIGURATION
  # ============================================================================
  programs.hyprland-modular = {
    enable = true;

    # ==========================================================================
    # THEME & PROFILE
    # ==========================================================================
    # Using built-in glassmorphism theme
    # (Can be customized later via customTheme or extraSettings if needed)
    theme = "glassmorphism";

    # Development profile: balanced for dev work
    # - Animations: fast (2-3 speed)
    # - Blur: moderate (8px, 2 passes)
    # - Window swallowing: enabled
    # - Good balance between aesthetics and performance
    profile = "development";

    # ==========================================================================
    # FEATURE FLAGS
    # ==========================================================================
    features = {
      blur = true; # Window blur effects (glassmorphism theme requires blur)
      animations = true; # Window animations
      shadows = true; # Drop shadows (Manual in extraSettings)
      rounding = true; # Rounded corners
      vrr = true; # Variable Refresh Rate (144Hz)
      dimInactive = true; # Dim unfocused windows
      windowSwallowing = false; # Terminal swallowing (disabled for now)
      clipboard = true; # cliphist integration
      screenshotTools = true; # grim/slurp/swappy
      idleManagement = true; # hypridle for lock/dpms
      notifications = true; # mako daemon
      xdgPortals = true; # XDG desktop portals
    };

    # ==========================================================================
    # MONITOR CONFIGURATION
    # ==========================================================================
    # Current setup: 1920x1080@144Hz with VRR
    monitors = [
      {
        name = ""; # Auto-detect (empty for default monitor)
        resolution = "1920x1080@144";
        position = "auto";
        scale = 1.0;
        vrr = true; # Per-monitor VRR enable
      }
    ];

    # ==========================================================================
    # INPUT CONFIGURATION
    # ==========================================================================
    input = {
      keyboard = {
        layout = "br"; # Brazilian ABNT2
        variant = "";
        options = "";
      };

      mouse = {
        sensitivity = 1.2; # From current config (line 65)
        accelProfile = "flat"; # No acceleration
        naturalScroll = false;
      };

      touchpad = {
        enable = true;
        naturalScroll = false;
        tapToClick = true;
        disableWhileTyping = true;
      };
    };

    # ==========================================================================
    # TERMINAL & LAUNCHER
    # ==========================================================================
    terminal = {
      primary = "kitty";
      secondary = "alacritty";
      multiplexer = "zellij"; # Auto-attach to zellij sessions
    };

    launcher = "wofi"; # Application launcher (can be wofi/rofi/fuzzel)
    fileManager = "nemo"; # File manager

    # ==========================================================================
    # AUTOSTART APPLICATIONS
    # ==========================================================================
    # NOTE: Core components (waybar, mako, polkit, nm-applet, clipboard) are
    # already started by hyprland-modular framework - no need to duplicate here.
    # Only add custom applications that aren't handled by the framework.
    autostart = [
      # Add custom autostart applications here if needed
    ];

    # ==========================================================================
    # KEYBINDINGS
    # ==========================================================================
    mainMod = "SUPER";

    keybindings = {
      enable = true;

      # Enable all standard keybinding modules
      modules = [
        "core" # Terminal, launcher, kill, exit, clipboard, color picker
        "window" # Fullscreen, float, move, navigate (arrows + hjkl)
        "workspace" # Switch/move workspaces 1-10, prev/next, mouse scroll
        "media" # Play/pause/next/prev/stop
        "screenshot" # Region/fullscreen capture (grim/slurp/swappy)
        "power" # Lock, logout, suspend, reboot, poweroff
      ];

      # Custom keybindings not covered by standard modules
      extraBinds = [
        # ========================================
        # TERMINAL VARIANTS
        # ========================================
        # NOTE: Terminal keybindings already provided by 'core' module:
        #   SUPER+Return          → kitty with zellij (main session)
        #   SUPER+SHIFT+Return    → alacritty with zellij (alt session)
        #   SUPER+CTRL+Return     → kitty (no multiplexer)
        #   SUPER+CTRL+SHIFT+Return → alacritty (no multiplexer)
        #   SUPER+ALT+Return      → foot (emergency)
        # No need to duplicate here!

        # ========================================
        # NOTIFICATIONS
        # ========================================
        "$mainMod, N, exec, makoctl dismiss"
        "$mainMod SHIFT, N, exec, makoctl dismiss --all"

        # ========================================
        # STATUS BAR
        # ========================================
        # NOTE: Waybar reload (SUPER+SHIFT+W) already provided by 'core' module
        # Removed to avoid duplication

        # ========================================
        # AGENT HUB (AI Integration)
        # ========================================
        "$mainMod, A, exec, $HOME/.config/agent-hub/agent-launcher.sh"
        "$mainMod SHIFT, A, exec, $HOME/.config/agent-hub/quick-prompt.sh"

        # ========================================
        # UTILITIES
        # ========================================
        # Calculator (bc + wofi)
        "$mainMod, EQUAL, exec, wofi --dmenu --prompt=Calculator | bc -l | wl-copy"

        # ========================================
        # WINDOW MANAGEMENT ENHANCEMENTS
        # ========================================
        # Toggle split direction
        "$mainMod, Z, togglesplit"
        # Pin window (keep on all workspaces)
        "$mainMod, X, pin"
        # NOTE: centerwindow conflicts with clipboard (SUPER+C)
        # Clipboard is more useful, so centerwindow is omitted

        # ========================================
        # WORKSPACE NAVIGATION
        # ========================================
        # Quick prev/next workspace
        "$mainMod ALT, left, workspace, e-1"
        "$mainMod ALT, right, workspace, e+1"

        # Move to workspace and follow (1-5 only, extend if needed)
        "$mainMod CTRL SHIFT, 1, movetoworkspace, 1"
        "$mainMod CTRL SHIFT, 2, movetoworkspace, 2"
        "$mainMod CTRL SHIFT, 3, movetoworkspace, 3"
        "$mainMod CTRL SHIFT, 4, movetoworkspace, 4"
        "$mainMod CTRL SHIFT, 5, movetoworkspace, 5"

        # ========================================
        # EMERGENCY CONTROLS
        # ========================================
        # Emergency kill (force kill active window)
        "$mainMod SHIFT CTRL, Q, exec, hyprctl kill"

        # Focus urgent window
        "$mainMod, U, focusurgentorlast"
      ];

      # Repeating bindings (binde)
      extraBindE = [
        # ========================================
        # WINDOW RESIZE
        # ========================================
        # Resize with arrow keys
        "$mainMod CTRL, left, resizeactive, -50 0"
        "$mainMod CTRL, right, resizeactive, 50 0"
        "$mainMod CTRL, up, resizeactive, 0 -50"
        "$mainMod CTRL, down, resizeactive, 0 50"

        # Resize with vim keys
        "$mainMod CTRL, h, resizeactive, -50 0"
        "$mainMod CTRL, l, resizeactive, 50 0"
        "$mainMod CTRL, k, resizeactive, 0 -50"
        "$mainMod CTRL, j, resizeactive, 0 50"

        # ========================================
        # AUDIO CONTROLS
        # ========================================
        # Volume (handled by media module, but adding for explicit control)
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        # ========================================
        # BRIGHTNESS CONTROLS
        # ========================================
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
    };

    # ==========================================================================
    # WINDOW RULES
    # ==========================================================================
    windowRules = {
      enable = true;

      # Enable all standard window rule categories
      categories = [
        "development" # Terminals, editors, IDEs
        "browsers" # Firefox, Brave, Chromium
        "fileManagers" # Nautilus, thunar, nemo
        "systemUtilities" # PulseAudio, network tools
        "media" # mpv, imv, Picture-in-Picture
        "productivity" # KeePass, notes, PDFs
        "communication" # Discord, Slack, Teams
        "dialogs" # File dialogs, polkit, confirmations
        "performance" # Launchers noanim, terminals immediate
        "gaming" # Steam, Wine, Gamescope
      ];

      # Layer rules for blur (glassmorphism effect)
      # Note: nix-hypr might have a layers option - if it conflicts, remove this
      # For now adding via extraConfig since it's Hyprland-specific syntax

      # Custom window rules not covered by standard categories
      extra = [
        # ========================================
        # AGENT HUB WINDOWS (AI Integration)
        # ========================================
        # Chat window
        "float 1, match:class ^(agent-hub-chat)$"
        "size 1000 700, match:class ^(agent-hub-chat)$"
        "center 1, match:class ^(agent-hub-chat)$"
        "opacity 0.95 0.90, match:class ^(agent-hub-chat)$"

        # Codex window
        "float 1, match:class ^(agent-hub-codex)$"
        "size 1200 800, match:class ^(agent-hub-codex)$"
        "center 1, match:class ^(agent-hub-codex)$"

        # Gemini window
        "float 1, match:class ^(agent-hub-gemini)$"
        "size 1200 800, match:class ^(agent-hub-gemini)$"
        "center 1, match:class ^(agent-hub-gemini)$"
      ];
    };

    # ==========================================================================
    # WORKSPACE CONFIGURATION
    # ==========================================================================
    workspaces = {
      count = 10; # Standard 1-10 workspaces

      # Special workspace (accessed via SUPER+S)
      specialWorkspaces = [
        {
          name = "magic";
          key = "S";
        }
      ];

      persistentRules = [ ]; # No workspace persistence rules yet
    };

    # ==========================================================================
    # IDLE & LOCK CONFIGURATION
    # ==========================================================================
    idle = {
      lockTimeout = 300; # Lock after 5 minutes
      dpmsTimeout = 600; # Screen off after 10 minutes
      suspendTimeout = null; # No auto-suspend
    };

    # ==========================================================================
    # EXTRA SETTINGS (Cleaned up)
    # ==========================================================================
    # For Hyprland settings not directly supported by nix-hypr options
    extraSettings = {
      # General settings
      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 1;
        "col.active_border" = "rgba(00d4ffff) rgba(7c3aedff) 45deg";
        "col.inactive_border" = "rgba(22222e88)";
        layout = "dwindle";
        allow_tearing = false;
        resize_on_border = true;
      };

      # Decoration - blur moved to extraConfig (raw syntax) to avoid serialization issues
      # See extraConfig section below

      # Misc settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 1; # Always on VRR (0=off, 1=fullscreen only, 2=always)
        vfr = true; # Variable Frame Rate for power saving
        force_default_wallpaper = 0;
        focus_on_activate = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        layers_hog_keyboard_focus = true;
        initial_workspace_tracking = 2;
        middle_click_paste = false;
        background_color = "0x000000";
      };

      # Cursor settings
      cursor = {
        no_hardware_cursors = true; # NVIDIA fix
        enable_hyprcursor = true;
        hide_on_key_press = true;
        inactive_timeout = 5;
      };

      # Debug settings (disable for performance)
      debug = {
        disable_logs = true;
        disable_time = true;
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
        smart_split = true;
        smart_resizing = true;
      };

      # Master layout
      master = {
        new_status = "master";
        mfact = 0.55;
      };

      # Binds behavior
      binds = {
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
      };
    };

    # ==========================================================================
    # RAW HYPRLAND CONFIG - Blur definition (fixes serialization issues)
    # ==========================================================================
    extraConfig = ''
      decoration {
        blur {
          enabled = true
          size = 8
          passes = 2
          new_optimizations = true
          ignore_opacity = false
        }
      }
    '';
  };

  # ============================================================================
  # HYPRIDLE CONFIGURATION (Standalone service)
  # ============================================================================
  # Note: hypridle might be configured by nix-hypr's idleManagement feature
  # This is here for additional customization if needed
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          timeout = 300; # 5 minutes
          on-timeout = "hyprlock";
        }
        {
          timeout = 600; # 10 minutes
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
