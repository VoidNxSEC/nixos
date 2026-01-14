# ============================================
# Niri Configuration - Glassmorphism Edition
# ============================================
# Scrolling compositor with infinite horizontal canvas
# Premium 144Hz config with glassmorphism accents
#
# Paradigm Shift from Hyprland:
# - No discrete workspaces → infinite horizontal scroll
# - Columns instead of tiles
# - Named workspaces available but optional
# - Focus on keyboard-driven navigation
# ============================================

{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  # Import glassmorphism design tokens
  colors = config.glassmorphism.colors;

  # Helper to convert hex digit to decimal
  hexDigitToInt =
    c:
    let
      hexMap = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "A" = 10;
        "b" = 11;
        "B" = 11;
        "c" = 12;
        "C" = 12;
        "d" = 13;
        "D" = 13;
        "e" = 14;
        "E" = 14;
        "f" = 15;
        "F" = 15;
      };
    in
    hexMap.${c};

  # Convert 2-character hex string to decimal
  hexByteToInt =
    hex:
    let
      high = hexDigitToInt (builtins.substring 0 1 hex);
      low = hexDigitToInt (builtins.substring 1 1 hex);
    in
    high * 16 + low;

  # Helper to convert hex to niri rgba format
  hexToNiriRgba =
    hex: alpha:
    let
      # Remove # prefix
      clean = lib.removePrefix "#" hex;
      r = hexByteToInt (builtins.substring 0 2 clean);
      g = hexByteToInt (builtins.substring 2 2 clean);
      b = hexByteToInt (builtins.substring 4 2 clean);
    in
    {
      r = r;
      g = g;
      b = b;
      a = alpha;
    };

  # Screenshot helper script
  screenshotScript = pkgs.writeShellScriptBin "niri-screenshot" ''
    #!/usr/bin/env bash
    # Niri screenshot helper with swappy integration

    case "$1" in
      region)
        grim -g "$(slurp)" - | swappy -f -
        ;;
      screen)
        grim - | swappy -f -
        ;;
      window)
        # Niri doesn't have window geometry query yet, fallback to region
        grim -g "$(slurp)" - | swappy -f -
        ;;
      clipboard)
        grim -g "$(slurp)" - | wl-copy
        ;;
      *)
        echo "Usage: niri-screenshot [region|screen|window|clipboard]"
        ;;
    esac
  '';

in
{
  # ============================================
  # NIRI WINDOW MANAGER
  # ============================================
  programs.niri = {
    enable = true;

    settings = {
      # ============================================
      # INPUT CONFIGURATION
      # ============================================
      input = {
        keyboard = {
          xkb = {
            layout = "br";
            options = "caps:escape"; # Caps Lock → Escape (vim-friendly)
          };
          repeat-delay = 300;
          repeat-rate = 50;
        };

        mouse = {
          # Disable mouse acceleration for precision
          accel-profile = "flat";
        };

        touchpad = {
          tap = true;
          natural-scroll = false;
          dwt = true; # Disable while typing
          accel-profile = "adaptive";
        };

        # Focus follows mouse (Niri default, feels natural with scroll)
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "25%"; # Limit auto-scroll when focusing
        };

        # Warp mouse to focused window
        warp-mouse-to-focus = true;
      };

      # ============================================
      # OUTPUT (MONITOR) CONFIGURATION
      # ============================================
      outputs = {
        # Primary monitor - 144Hz
        # Niri auto-detects, but you can specify:
        # "DP-1" = {
        #   mode = {
        #     width = 1920;
        #     height = 1080;
        #     refresh = 144.0;
        #   };
        #   scale = 1.0;
        #   position = { x = 0; y = 0; };
        #   variable-refresh-rate = true;
        # };
      };

      # ============================================
      # LAYOUT - The Heart of Niri
      # ============================================
      layout = {
        # Gap between windows (glassmorphism breathing room)
        gaps = 16;

        # Center focused column when possible
        center-focused-column = "on-overflow";

        # Default column width
        default-column-width = {
          proportion = 0.5; # 50% of screen by default
        };

        # Preset column widths (cycle through with keybind)
        preset-column-widths = [
          { proportion = 0.33333; } # 1/3
          { proportion = 0.5; } # 1/2
          { proportion = 0.66667; } # 2/3
          { proportion = 1.0; } # Full
        ];

        # Focus ring - cyan glow (glassmorphism accent)
        focus-ring = {
          enable = true;
          width = 2;
          active-color = hexToNiriRgba colors.accent.cyan 1.0;
          inactive-color = hexToNiriRgba colors.base.bg3 0.6;
        };

        # Border (additional to focus ring)
        border = {
          enable = false; # Using focus-ring only for cleaner look
        };

        # Struts (reserved space for bars)
        struts = {
          left = 0;
          right = 0;
          top = 0; # Waybar handles its own space
          bottom = 0;
        };
      };

      # ============================================
      # SPAWN AT STARTUP
      # ============================================
      spawn-at-startup = [
        # Status bar
        { command = [ "waybar" ]; }
        # Notification daemon
        { command = [ "mako" ]; }
        # Polkit agent
        { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        # Network applet
        {
          command = [
            "nm-applet"
            "--indicator"
          ];
        }
        # Wallpaper (swaybg works with Niri)
        {
          command = [
            "swaybg"
            "-i"
            "${config.home.homeDirectory}/Pictures/wallpapers/glassmorphism-default.png"
            "-m"
            "fill"
          ];
        }
        # Clipboard manager
        {
          command = [
            "sh"
            "-c"
            "wl-paste --type text --watch cliphist store"
          ];
        }
        {
          command = [
            "sh"
            "-c"
            "wl-paste --type image --watch cliphist store"
          ];
        }
        # Idle daemon (using swayidle since hypridle is Hyprland-specific)
        {
          command = [
            "swayidle"
            "-w"
            "timeout"
            "300"
            "swaylock -f"
            "timeout"
            "600"
            "niri msg action power-off-monitors"
            "resume"
            "niri msg action power-on-monitors"
            "before-sleep"
            "swaylock -f"
          ];
        }
      ];

      # ============================================
      # ENVIRONMENT VARIABLES
      # ============================================
      environment = {
        # Wayland native
        "QT_QPA_PLATFORM" = "wayland";
        "SDL_VIDEODRIVER" = "wayland";
        "CLUTTER_BACKEND" = "wayland";
        "GDK_BACKEND" = "wayland,x11";
        "XDG_CURRENT_DESKTOP" = "niri";
        "XDG_SESSION_TYPE" = "wayland";
        "XDG_SESSION_DESKTOP" = "niri";

        # NVIDIA (if applicable)
        "GBM_BACKEND" = "nvidia-drm";
        "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
        "WLR_NO_HARDWARE_CURSORS" = "1";

        # Theming
        "GTK_THEME" = "Adwaita:dark";
        "QT_STYLE_OVERRIDE" = "kvantum";
      };

      # ============================================
      # CURSOR
      # ============================================
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };

      # ============================================
      # PREFER NO CLIENT-SIDE DECORATIONS
      # ============================================
      prefer-no-csd = true;

      # ============================================
      # SCREENSHOT PATH
      # ============================================
      screenshot-path = "~/Pictures/Screenshots/screenshot-%Y%m%d-%H%M%S.png";

      # ============================================
      # HOTKEY OVERLAY (help screen)
      # ============================================
      hotkey-overlay = {
        skip-at-startup = true;
      };

      # ============================================
      # ANIMATIONS - Smooth 144Hz
      # ============================================
      animations = {
        # Enable animations
        enable = true;

        # Slow down for debugging (1.0 = normal)
        slowdown = 1.0;

        # Workspace switch animation
        workspace-switch = {
          spring = {
            damping-ratio = 0.8;
            stiffness = 500;
            epsilon = 0.001;
          };
        };

        # Window open animation
        window-open = {
          duration-ms = 200;
          curve = "ease-out-expo";
        };

        # Window close animation
        window-close = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };

        # Horizontal view movement (scrolling)
        horizontal-view-movement = {
          spring = {
            damping-ratio = 0.9;
            stiffness = 800;
            epsilon = 0.001;
          };
        };

        # Window movement
        window-movement = {
          spring = {
            damping-ratio = 0.85;
            stiffness = 600;
            epsilon = 0.001;
          };
        };

        # Window resize
        window-resize = {
          spring = {
            damping-ratio = 0.85;
            stiffness = 600;
            epsilon = 0.001;
          };
        };

        # Config notification popup
        config-notification-open-close = {
          duration-ms = 200;
          curve = "ease-out-quad";
        };
      };

      # ============================================
      # WINDOW RULES
      # ============================================
      window-rules = [
        # ==========================================
        # FLOATING WINDOWS
        # ==========================================
        {
          matches = [
            { app-id = "^pavucontrol$"; }
            { app-id = "^nm-connection-editor$"; }
            { app-id = "^blueman-manager$"; }
            { app-id = "^nemo$"; }
            { app-id = "^thunar$"; }
            { app-id = "^imv$"; }
            { app-id = "^mpv$"; }
            { app-id = "^swappy$"; }
            { title = "^Picture-in-Picture$"; }
          ];
          open-floating = true;
        }

        # ==========================================
        # OPACITY RULES (Glassmorphism)
        # ==========================================
        # Terminals - most transparent
        {
          matches = [
            { app-id = "^kitty$"; }
            { app-id = "^Alacritty$"; }
            { app-id = "^foot$"; }
          ];
          opacity = 0.92;
        }

        # Code editors - slightly less transparent
        {
          matches = [
            { app-id = "^code-oss$"; }
            { app-id = "^Code$"; }
            { app-id = "^VSCodium$"; }
            { app-id = "^codium$"; }
          ];
          opacity = 0.95;
        }

        # Browsers - near opaque for readability
        {
          matches = [
            { app-id = "^firefox$"; }
            { app-id = "^brave-browser$"; }
            { app-id = "^chromium$"; }
          ];
          opacity = 0.98;
        }

        # ==========================================
        # COLUMN WIDTH OVERRIDES
        # ==========================================
        # Browsers get more space
        {
          matches = [
            { app-id = "^firefox$"; }
            { app-id = "^brave-browser$"; }
          ];
          default-column-width = {
            proportion = 0.66667;
          };
        }

        # Terminals are narrower
        {
          matches = [
            { app-id = "^kitty$"; }
            { app-id = "^Alacritty$"; }
          ];
          default-column-width = {
            proportion = 0.5;
          };
        }

        # ==========================================
        # PIP (Picture-in-Picture)
        # ==========================================
        {
          matches = [
            { title = "^Picture-in-Picture$"; }
          ];
          open-floating = true;
          # Niri doesn't have pin yet, but it stays on top as floating
        }

        # ==========================================
        # AGENT HUB
        # ==========================================
        {
          matches = [
            { app-id = "^agent-hub-.*$"; }
          ];
          open-floating = true;
          opacity = 0.95;
        }
      ];

      # ============================================
      # NAMED WORKSPACES (Optional in Niri)
      # ============================================
      # Niri has infinite scroll, but you can define named workspaces
      # These act as "anchors" you can jump to
      workspaces = {
        "dev" = { }; # Development
        "web" = { }; # Browsers
        "chat" = { }; # Communication
        "media" = { }; # Media/Entertainment
        "sys" = { }; # System monitoring
      };

      # ============================================
      # KEYBINDINGS
      # ============================================
      binds = {
        # ==========================================
        # TERMINAL LAUNCHERS
        # ==========================================
        "Mod+Return" = {
          action.spawn = [
            "kitty"
            "-e"
            "zellij"
            "attach"
            "--create"
            "main"
          ];
        };
        "Mod+Shift+Return" = {
          action.spawn = [
            "alacritty"
            "-e"
            "zellij"
            "attach"
            "--create"
            "alt"
          ];
        };
        "Mod+Ctrl+Return" = {
          action.spawn = [ "kitty" ];
        };
        "Mod+Alt+Return" = {
          action.spawn = [ "foot" ];
        };

        # ==========================================
        # APPLICATION LAUNCHERS
        # ==========================================
        "Mod+D" = {
          action.spawn = [
            "wofi"
            "--show"
            "drun"
          ];
        };
        "Mod+Shift+D" = {
          action.spawn = [
            "wofi"
            "--show"
            "run"
          ];
        };
        "Mod+E" = {
          action.spawn = [ "nemo" ];
        };

        # ==========================================
        # WINDOW MANAGEMENT
        # ==========================================
        "Mod+Q" = {
          action.close-window = { };
        };
        "Mod+Shift+Q" = {
          action.quit = {
            skip-confirmation = true;
          };
        };

        # ==========================================
        # FOCUS NAVIGATION
        # Niri paradigm: columns are horizontal, windows stack vertically in columns
        # ==========================================
        # Focus column (horizontal movement)
        "Mod+H" = {
          action.focus-column-left = { };
        };
        "Mod+L" = {
          action.focus-column-right = { };
        };
        "Mod+Left" = {
          action.focus-column-left = { };
        };
        "Mod+Right" = {
          action.focus-column-right = { };
        };

        # Focus window within column (vertical movement)
        "Mod+K" = {
          action.focus-window-up = { };
        };
        "Mod+J" = {
          action.focus-window-down = { };
        };
        "Mod+Up" = {
          action.focus-window-up = { };
        };
        "Mod+Down" = {
          action.focus-window-down = { };
        };

        # Focus first/last column
        "Mod+Home" = {
          action.focus-column-first = { };
        };
        "Mod+End" = {
          action.focus-column-last = { };
        };

        # ==========================================
        # MOVE WINDOWS
        # ==========================================
        # Move column
        "Mod+Shift+H" = {
          action.move-column-left = { };
        };
        "Mod+Shift+L" = {
          action.move-column-right = { };
        };
        "Mod+Shift+Left" = {
          action.move-column-left = { };
        };
        "Mod+Shift+Right" = {
          action.move-column-right = { };
        };

        # Move window within column
        "Mod+Shift+K" = {
          action.move-window-up = { };
        };
        "Mod+Shift+J" = {
          action.move-window-down = { };
        };
        "Mod+Shift+Up" = {
          action.move-window-up = { };
        };
        "Mod+Shift+Down" = {
          action.move-window-down = { };
        };

        # Move to first/last position
        "Mod+Shift+Home" = {
          action.move-column-to-first = { };
        };
        "Mod+Shift+End" = {
          action.move-column-to-last = { };
        };

        # ==========================================
        # COLUMN OPERATIONS
        # ==========================================
        # Consume window into column (merge)
        "Mod+BracketLeft" = {
          action.consume-window-into-column = { };
        };
        # Expel window from column (split)
        "Mod+BracketRight" = {
          action.expel-window-from-column = { };
        };

        # ==========================================
        # COLUMN WIDTH
        # ==========================================
        # Cycle preset widths
        "Mod+R" = {
          action.switch-preset-column-width = { };
        };
        # Manual resize
        "Mod+Ctrl+H" = {
          action.set-column-width = "-10%";
        };
        "Mod+Ctrl+L" = {
          action.set-column-width = "+10%";
        };
        "Mod+Ctrl+Left" = {
          action.set-column-width = "-10%";
        };
        "Mod+Ctrl+Right" = {
          action.set-column-width = "+10%";
        };

        # Reset to default width
        "Mod+Ctrl+R" = {
          action.reset-window-height = { };
        };

        # ==========================================
        # WINDOW HEIGHT (within column)
        # ==========================================
        "Mod+Ctrl+K" = {
          action.set-window-height = "-10%";
        };
        "Mod+Ctrl+J" = {
          action.set-window-height = "+10%";
        };
        "Mod+Ctrl+Up" = {
          action.set-window-height = "-10%";
        };
        "Mod+Ctrl+Down" = {
          action.set-window-height = "+10%";
        };

        # ==========================================
        # FULLSCREEN & MAXIMIZE
        # ==========================================
        "Mod+F" = {
          action.maximize-column = { };
        };
        "Mod+Shift+F" = {
          action.fullscreen-window = { };
        };

        # ==========================================
        # FLOATING
        # ==========================================
        "Mod+V" = {
          action.toggle-window-floating = { };
        };
        "Mod+Shift+V" = {
          action.switch-focus-between-floating-and-tiling = { };
        };

        # ==========================================
        # NAMED WORKSPACES
        # ==========================================
        "Mod+1" = {
          action.focus-workspace = "dev";
        };
        "Mod+2" = {
          action.focus-workspace = "web";
        };
        "Mod+3" = {
          action.focus-workspace = "chat";
        };
        "Mod+4" = {
          action.focus-workspace = "media";
        };
        "Mod+5" = {
          action.focus-workspace = "sys";
        };

        # Move window to workspace
        "Mod+Shift+1" = {
          action.move-window-to-workspace = "dev";
        };
        "Mod+Shift+2" = {
          action.move-window-to-workspace = "web";
        };
        "Mod+Shift+3" = {
          action.move-window-to-workspace = "chat";
        };
        "Mod+Shift+4" = {
          action.move-window-to-workspace = "media";
        };
        "Mod+Shift+5" = {
          action.move-window-to-workspace = "sys";
        };

        # Workspace navigation (relative)
        "Mod+Page_Up" = {
          action.focus-workspace-up = { };
        };
        "Mod+Page_Down" = {
          action.focus-workspace-down = { };
        };

        # ==========================================
        # MONITOR MANAGEMENT
        # ==========================================
        "Mod+Shift+Ctrl+H" = {
          action.move-column-to-monitor-left = { };
        };
        "Mod+Shift+Ctrl+L" = {
          action.move-column-to-monitor-right = { };
        };
        "Mod+Shift+Ctrl+Left" = {
          action.move-column-to-monitor-left = { };
        };
        "Mod+Shift+Ctrl+Right" = {
          action.move-column-to-monitor-right = { };
        };

        # ==========================================
        # SCREENSHOTS
        # ==========================================
        "Print" = {
          action.screenshot = { }; # Full screen
        };
        "Shift+Print" = {
          action.screenshot-screen = { }; # Active screen
        };
        "Ctrl+Print" = {
          action.screenshot-window = { }; # Active window
        };
        # Custom screenshot with swappy
        "Mod+Print" = {
          action.spawn = [
            "${screenshotScript}/bin/niri-screenshot"
            "region"
          ];
        };

        # ==========================================
        # MEDIA KEYS
        # ==========================================
        "XF86AudioRaiseVolume" = {
          action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "5%+"
          ];
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "5%-"
          ];
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];
          allow-when-locked = true;
        };
        "XF86AudioPlay" = {
          action.spawn = [
            "playerctl"
            "play-pause"
          ];
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action.spawn = [
            "playerctl"
            "next"
          ];
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action.spawn = [
            "playerctl"
            "previous"
          ];
          allow-when-locked = true;
        };
        "XF86MonBrightnessUp" = {
          action.spawn = [
            "brightnessctl"
            "set"
            "5%+"
          ];
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action.spawn = [
            "brightnessctl"
            "set"
            "5%-"
          ];
          allow-when-locked = true;
        };

        # ==========================================
        # LOCK & POWER
        # ==========================================
        "Mod+Ctrl+L" = {
          action.spawn = [
            "swaylock"
            "-f"
          ];
        };
        "Mod+Escape" = {
          action.spawn = [
            "wlogout"
            "-p"
            "layer-shell"
          ];
        };
        "Mod+Shift+Escape" = {
          action.spawn = [
            "systemctl"
            "suspend"
          ];
        };

        # ==========================================
        # POWER MANAGEMENT
        # ==========================================
        "Mod+Shift+P" = {
          action.power-off-monitors = { };
        };

        # ==========================================
        # CLIPBOARD
        # ==========================================
        "Mod+C" = {
          action.spawn = [
            "sh"
            "-c"
            "cliphist list | wofi --dmenu | cliphist decode | wl-copy"
          ];
        };

        # ==========================================
        # COLOR PICKER
        # ==========================================
        "Mod+Shift+C" = {
          action.spawn = [
            "hyprpicker"
            "-a"
          ];
        };

        # ==========================================
        # AGENT HUB
        # ==========================================
        "Mod+A" = {
          action.spawn = [ "${config.home.homeDirectory}/.config/agent-hub/agent-launcher.sh" ];
        };
        "Mod+Shift+A" = {
          action.spawn = [ "${config.home.homeDirectory}/.config/agent-hub/quick-prompt.sh" ];
        };

        # ==========================================
        # NOTIFICATIONS
        # ==========================================
        "Mod+N" = {
          action.spawn = [
            "makoctl"
            "dismiss"
          ];
        };
        "Mod+Shift+N" = {
          action.spawn = [
            "makoctl"
            "dismiss"
            "--all"
          ];
        };

        # ==========================================
        # WAYBAR RELOAD
        # ==========================================
        "Mod+Shift+W" = {
          action.spawn = [
            "sh"
            "-c"
            "killall waybar; waybar &"
          ];
        };

        # ==========================================
        # VIEW SCROLLING (Niri-specific!)
        # ==========================================
        # Scroll the view (move canvas, not focus)
        "Mod+Ctrl+Shift+H" = {
          action.focus-column-left-or-last = { };
        };
        "Mod+Ctrl+Shift+L" = {
          action.focus-column-right-or-first = { };
        };

        # Center focused column
        "Mod+Ctrl+C" = {
          action.center-column = { };
        };

        # ==========================================
        # DEBUG & HELP
        # ==========================================
        "Mod+Shift+Slash" = {
          action.show-hotkey-overlay = { };
        };
      };
    };
  };

  # ============================================
  # REQUIRED PACKAGES
  # ============================================
  home.packages = with pkgs; [
    # Niri ecosystem
    swaylock # Lock screen (swaylock-effects for fancy version)
    swayidle # Idle management
    swaybg # Wallpaper

    # Screenshot tools
    grim
    slurp
    swappy
    screenshotScript

    # Color picker (hyprpicker works on Niri too)
    hyprpicker

    # Media control
    playerctl
    brightnessctl

    # Clipboard
    wl-clipboard
    cliphist

    # Notification
    libnotify
  ];

  # ============================================
  # SWAYLOCK CONFIGURATION
  # ============================================
  programs.swaylock = {
    enable = true;
    settings = {
      # Glassmorphism style
      color = "0a0a0f";
      image = "${config.home.homeDirectory}/Pictures/wallpapers/glassmorphism-default.png";

      # Blur effect
      effect-blur = "10x3";
      effect-vignette = "0.5:0.5";

      # Ring styling
      ring-color = "00d4ff";
      ring-ver-color = "7c3aed";
      ring-wrong-color = "ff00aa";
      ring-clear-color = "22c55e";

      key-hl-color = "00d4ff";
      bs-hl-color = "ff00aa";

      # Inside circle
      inside-color = "12121a";
      inside-ver-color = "12121a";
      inside-wrong-color = "1a0a12";
      inside-clear-color = "12121a";

      # Text
      text-color = "e4e4e7";
      text-ver-color = "00d4ff";
      text-wrong-color = "ff00aa";
      text-clear-color = "22c55e";

      # Layout
      indicator-radius = 120;
      indicator-thickness = 10;

      # Font
      font = "JetBrainsMono Nerd Font";
      font-size = 24;

      # Behavior
      ignore-empty-password = true;
      show-failed-attempts = true;

      # Fade
      fade-in = 0.2;
    };
  };
}
