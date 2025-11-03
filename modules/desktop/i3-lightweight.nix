{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# i3 Window Manager - Lightweight Desktop
# ============================================================
# Minimal tiling WM for desktop workstation
# Memory footprint: ~500MB (vs GNOME ~2GB)
# ============================================================

with lib;

{
  options.kernelcore.desktop.i3 = {
    enable = mkEnableOption "Enable i3 tiling window manager";

    terminal = mkOption {
      type = types.str;
      default = "alacritty";
      description = "Default terminal emulator";
    };

    launcher = mkOption {
      type = types.str;
      default = "rofi";
      description = "Application launcher (rofi or dmenu)";
    };

    statusBar = mkOption {
      type = types.str;
      default = "i3status";
      description = "Status bar (i3status, i3blocks, or polybar)";
    };

    enableCompositor = mkOption {
      type = types.bool;
      default = true;
      description = "Enable picom compositor for transparency/shadows";
    };

    screenLockCommand = mkOption {
      type = types.str;
      default = "i3lock -c 000000";
      description = "Screen lock command";
    };
  };

  config = mkIf config.kernelcore.desktop.i3.enable {

    # ============================================================
    # X11 Server Configuration
    # ============================================================

    services.xserver = {
      enable = true;

      # Display Manager (lightweight)
      displayManager = {
        lightdm = {
          enable = true;
          greeters.gtk = {
            enable = true;
            theme.name = "Arc-Dark";
            iconTheme.name = "Papirus-Dark";
          };
        };
        defaultSession = "none+i3";
      };

      # i3 Window Manager
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3; # Use i3-gaps if you want gaps between windows

        extraPackages = with pkgs; [
          # Core i3 tools
          dmenu # Basic launcher
          i3status # Default status bar
          i3lock # Screen locker
          i3blocks # Alternative status bar

          # Better alternatives
          rofi # Modern launcher (better than dmenu)
          polybar # Modern status bar (optional)

          # Utilities
          xdotool # X11 automation
          xorg.xev # Key event viewer
          xorg.xprop # Window properties
          xorg.xwininfo # Window info
        ];
      };

      # Keyboard layout
      xkb = {
        layout = "br";
        variant = "";
      };
    };

    # ============================================================
    # Audio
    # ============================================================

    sound.enable = true;
    hardware.pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull; # Bluetooth support
    };

    # Alternative: PipeWire (modern, better for pro audio)
    # services.pipewire = {
    #   enable = true;
    #   alsa.enable = true;
    #   pulse.enable = true;
    # };

    # ============================================================
    # Compositor (transparency, shadows, animations)
    # ============================================================

    services.picom = mkIf config.kernelcore.desktop.i3.enableCompositor {
      enable = true;
      fade = true;
      shadow = true;
      fadeDelta = 4;
      vSync = true;
      backend = "glx"; # GPU-accelerated

      settings = {
        # Transparency
        inactive-opacity = 0.95;
        active-opacity = 1.0;

        # Shadows
        shadow-radius = 12;
        shadow-offset-x = -7;
        shadow-offset-y = -7;
        shadow-opacity = 0.5;

        # Fading
        fade-in-step = 0.03;
        fade-out-step = 0.03;
      };
    };

    # ============================================================
    # Essential GUI Applications (Lightweight)
    # ============================================================

    environment.systemPackages = with pkgs; [
      # ──────────────────────────────────────────────────────
      # Terminal
      # ──────────────────────────────────────────────────────
      alacritty # GPU-accelerated, fast
      # kitty         # Alternative: feature-rich
      # st            # Alternative: minimal (suckless)

      # ──────────────────────────────────────────────────────
      # Launcher
      # ──────────────────────────────────────────────────────
      rofi # Modern, customizable
      rofi-calc # Calculator plugin
      rofi-emoji # Emoji picker

      # ──────────────────────────────────────────────────────
      # File Manager
      # ──────────────────────────────────────────────────────
      pcmanfm # Lightweight GUI
      lxappearance # GTK theme switcher
      # thunar        # Alternative: XFCE file manager

      # ──────────────────────────────────────────────────────
      # Web Browser
      # ──────────────────────────────────────────────────────
      # firefox      # Already in applications/firefox-privacy.nix

      # ──────────────────────────────────────────────────────
      # Image Viewer
      # ──────────────────────────────────────────────────────
      feh # Minimal, fast
      sxiv # Alternative: suckless image viewer

      # ──────────────────────────────────────────────────────
      # PDF Viewer
      # ──────────────────────────────────────────────────────
      zathura # Vim-like keybindings
      # evince        # Alternative: GNOME PDF viewer

      # ──────────────────────────────────────────────────────
      # Screenshot
      # ──────────────────────────────────────────────────────
      scrot # Simple screenshot tool
      maim # Modern screenshot tool
      flameshot # Feature-rich (GUI)

      # ──────────────────────────────────────────────────────
      # Screen Recorder
      # ──────────────────────────────────────────────────────
      simplescreenrecorder
      # obs-studio    # Professional (heavy)

      # ──────────────────────────────────────────────────────
      # Clipboard Manager
      # ──────────────────────────────────────────────────────
      xclip # CLI clipboard
      xsel # Alternative
      clipmenu # Clipboard history

      # ──────────────────────────────────────────────────────
      # System Monitor
      # ──────────────────────────────────────────────────────
      htop # Terminal
      btop # Modern terminal monitor
      # gnome.gnome-system-monitor  # GUI

      # ──────────────────────────────────────────────────────
      # Network Manager
      # ──────────────────────────────────────────────────────
      networkmanagerapplet # nm-applet (system tray)

      # ──────────────────────────────────────────────────────
      # Volume Control
      # ──────────────────────────────────────────────────────
      pavucontrol # PulseAudio GUI
      volumeicon # System tray icon

      # ──────────────────────────────────────────────────────
      # Notification Daemon
      # ──────────────────────────────────────────────────────
      dunst # Lightweight notifications
      libnotify # notify-send command

      # ──────────────────────────────────────────────────────
      # Themes & Icons
      # ──────────────────────────────────────────────────────
      arc-theme # Popular GTK theme
      papirus-icon-theme

      # ──────────────────────────────────────────────────────
      # Fonts
      # ──────────────────────────────────────────────────────
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
      font-awesome # Icon fonts
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
        ];
      })

      # ──────────────────────────────────────────────────────
      # Utilities
      # ──────────────────────────────────────────────────────
      arandr # GUI for xrandr (monitor setup)
      autorandr # Auto-configure monitors
      nitrogen # Wallpaper setter
      redshift # Blue light filter
    ];

    # ============================================================
    # i3 Configuration
    # ============================================================

    environment.etc."i3/config".text = ''
      # ════════════════════════════════════════════════════════
      # i3 Configuration
      # ════════════════════════════════════════════════════════

      # Mod key (Mod4 = Super/Windows key)
      set $mod Mod4

      # Font
      font pango:DejaVu Sans Mono 10

      # ════════════════════════════════════════════════════════
      # Basic Keybindings
      # ════════════════════════════════════════════════════════

      # Terminal
      bindsym $mod+Return exec ${config.kernelcore.desktop.i3.terminal}

      # Kill window
      bindsym $mod+Shift+q kill

      # Application launcher
      bindsym $mod+d exec ${config.kernelcore.desktop.i3.launcher} -show drun
      bindsym $mod+Shift+d exec ${config.kernelcore.desktop.i3.launcher} -show run

      # Lock screen
      bindsym $mod+Shift+x exec ${config.kernelcore.desktop.i3.screenLockCommand}

      # Screenshot
      bindsym Print exec maim -s | xclip -selection clipboard -t image/png
      bindsym Shift+Print exec maim | xclip -selection clipboard -t image/png

      # ════════════════════════════════════════════════════════
      # Window Management
      # ════════════════════════════════════════════════════════

      # Change focus (vim keys)
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right

      # Move windows (vim keys)
      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+j move down
      bindsym $mod+Shift+k move up
      bindsym $mod+Shift+l move right

      # Split orientation
      bindsym $mod+b split h
      bindsym $mod+v split v

      # Fullscreen
      bindsym $mod+f fullscreen toggle

      # Toggle floating
      bindsym $mod+Shift+space floating toggle

      # Change focus between tiling/floating
      bindsym $mod+space focus mode_toggle

      # ════════════════════════════════════════════════════════
      # Layouts
      # ════════════════════════════════════════════════════════

      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split

      # ════════════════════════════════════════════════════════
      # Workspaces
      # ════════════════════════════════════════════════════════

      set $ws1 "1"
      set $ws2 "2"
      set $ws3 "3"
      set $ws4 "4"
      set $ws5 "5"
      set $ws6 "6"
      set $ws7 "7"
      set $ws8 "8"
      set $ws9 "9"
      set $ws10 "10"

      # Switch to workspace
      bindsym $mod+1 workspace $ws1
      bindsym $mod+2 workspace $ws2
      bindsym $mod+3 workspace $ws3
      bindsym $mod+4 workspace $ws4
      bindsym $mod+5 workspace $ws5
      bindsym $mod+6 workspace $ws6
      bindsym $mod+7 workspace $ws7
      bindsym $mod+8 workspace $ws8
      bindsym $mod+9 workspace $ws9
      bindsym $mod+0 workspace $ws10

      # Move window to workspace
      bindsym $mod+Shift+1 move container to workspace $ws1
      bindsym $mod+Shift+2 move container to workspace $ws2
      bindsym $mod+Shift+3 move container to workspace $ws3
      bindsym $mod+Shift+4 move container to workspace $ws4
      bindsym $mod+Shift+5 move container to workspace $ws5
      bindsym $mod+Shift+6 move container to workspace $ws6
      bindsym $mod+Shift+7 move container to workspace $ws7
      bindsym $mod+Shift+8 move container to workspace $ws8
      bindsym $mod+Shift+9 move container to workspace $ws9
      bindsym $mod+Shift+0 move container to workspace $ws10

      # ════════════════════════════════════════════════════════
      # Reload / Restart / Exit
      # ════════════════════════════════════════════════════════

      # Reload config
      bindsym $mod+Shift+c reload

      # Restart i3
      bindsym $mod+Shift+r restart

      # Exit i3
      bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

      # ════════════════════════════════════════════════════════
      # Resize Mode
      # ════════════════════════════════════════════════════════

      mode "resize" {
          bindsym h resize shrink width 10 px or 10 ppt
          bindsym j resize grow height 10 px or 10 ppt
          bindsym k resize shrink height 10 px or 10 ppt
          bindsym l resize grow width 10 px or 10 ppt

          bindsym Return mode "default"
          bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"

      # ════════════════════════════════════════════════════════
      # Status Bar
      # ════════════════════════════════════════════════════════

      bar {
          status_command ${config.kernelcore.desktop.i3.statusBar}
          position top

          colors {
              background #000000
              statusline #ffffff
              separator #666666

              focused_workspace  #4c7899 #285577 #ffffff
              active_workspace   #333333 #222222 #ffffff
              inactive_workspace #333333 #222222 #888888
              urgent_workspace   #2f343a #900000 #ffffff
          }
      }

      # ════════════════════════════════════════════════════════
      # Autostart
      # ════════════════════════════════════════════════════════

      # Compositor
      exec_always --no-startup-id picom

      # Network manager applet
      exec --no-startup-id nm-applet

      # Volume icon
      exec --no-startup-id volumeicon

      # Wallpaper
      exec --no-startup-id nitrogen --restore

      # Clipboard manager
      exec --no-startup-id clipmenud

      # Notification daemon
      exec --no-startup-id dunst
    '';

    # ============================================================
    # Notification Daemon (dunst)
    # ============================================================

    services.dunst = {
      enable = true;
      settings = {
        global = {
          font = "DejaVu Sans Mono 10";
          geometry = "300x5-30+20";
          transparency = 10;
          frame_width = 2;
          frame_color = "#4c7899";
        };
        urgency_low = {
          background = "#222222";
          foreground = "#888888";
          timeout = 5;
        };
        urgency_normal = {
          background = "#285577";
          foreground = "#ffffff";
          timeout = 10;
        };
        urgency_critical = {
          background = "#900000";
          foreground = "#ffffff";
          timeout = 0;
        };
      };
    };

    # ============================================================
    # Auto-lock on idle (optional)
    # ============================================================

    # services.xserver.xautolock = {
    #   enable = true;
    #   time = 10;  # Lock after 10 minutes
    #   locker = config.kernelcore.desktop.i3.screenLockCommand;
    # };

    # ============================================================
    # Redshift (blue light filter)
    # ============================================================

    services.redshift = {
      enable = true;
      temperature = {
        day = 5500;
        night = 3700;
      };
    };
    location.provider = "manual";
    location.latitude = -23.5505; # São Paulo (ajuste para sua localização)
    location.longitude = -46.6333;

    # ============================================================
    # Documentation
    # ============================================================

    environment.etc."i3/README.md".text = ''
      # i3 Window Manager - Quick Reference

      ## Essential Keybindings

      ### Window Management
      - `Super + Enter` - Open terminal
      - `Super + d` - Application launcher
      - `Super + Shift + q` - Close window
      - `Super + h/j/k/l` - Focus window (vim keys)
      - `Super + Shift + h/j/k/l` - Move window
      - `Super + f` - Fullscreen toggle

      ### Workspaces
      - `Super + 1-9` - Switch workspace
      - `Super + Shift + 1-9` - Move window to workspace

      ### Layouts
      - `Super + s` - Stacking layout
      - `Super + w` - Tabbed layout
      - `Super + e` - Toggle split layout
      - `Super + b` - Split horizontal
      - `Super + v` - Split vertical

      ### System
      - `Super + Shift + c` - Reload config
      - `Super + Shift + r` - Restart i3
      - `Super + Shift + e` - Exit i3
      - `Super + Shift + x` - Lock screen
      - `Print` - Screenshot (selection)
      - `Shift + Print` - Screenshot (full)

      ### Resize Mode
      - `Super + r` - Enter resize mode
      - `h/j/k/l` - Resize (vim keys)
      - `Escape` - Exit resize mode

      ## Configuration

      Config file: `/etc/i3/config`
      User config: `~/.config/i3/config` (optional override)

      ## Customization

      Edit module options in:
      `/etc/nixos/modules/desktop/i3-lightweight.nix`

      Available options:
      - kernelcore.desktop.i3.enable
      - kernelcore.desktop.i3.terminal
      - kernelcore.desktop.i3.launcher
      - kernelcore.desktop.i3.statusBar
      - kernelcore.desktop.i3.enableCompositor

      ## Memory Usage

      - i3 + basic apps: ~500MB RAM
      - GNOME equivalent: ~2GB RAM
      - **Savings: ~1.5GB RAM**

      ## Installed Applications

      - Terminal: alacritty
      - Launcher: rofi
      - File Manager: pcmanfm
      - Image Viewer: feh
      - PDF Viewer: zathura
      - Screenshot: maim
      - Clipboard: clipmenu
      - Monitor: btop

      ## Tips

      1. **Multi-monitor**: Use `arandr` GUI or `xrandr` CLI
      2. **Wallpaper**: `nitrogen --restore` or set with `feh --bg-scale`
      3. **Theme**: `lxappearance` to customize GTK theme
      4. **Compositor**: Toggle with `picom --config ~/.config/picom.conf`
    '';
  };
}
