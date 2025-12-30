# ============================================
# Hyprland Configuration - Glassmorphism Edition
# ============================================
# Premium 144Hz GPU-accelerated config with:
# - Frosted glass blur effects
# - Electric cyan/magenta/violet accents
# - Optimized animations for 144fps
# - NVIDIA-specific optimizations
# ============================================

{
  lib,
  pkgs,
  config,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      # ============================================
      # MONITOR - 1920x1080 @ 144Hz with VRR
      # ============================================
      monitor = [
        ",1920x1080@144,auto,1"
        # Fallback for any other monitor
        ",preferred,auto,1"
      ];

      # ============================================
      # AUTOSTART - Glassmorphism components
      # ============================================
      exec-once = [
        "waybar"
        "mako"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "nm-applet --indicator"
        # Idle management is now handled by services.hypridle (see below)
        # Wallpaper is managed by systemd user service (wallpaper.nix)
        # Run 'generate-glassmorphism-wallpaper' or 'download-glassmorphism-wallpaper' to set up
        # Clipboard manager
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      # ============================================
      # ENVIRONMENT VARIABLES
      # ============================================
      # NOTE: Core Wayland/NVIDIA env vars are set at system-level
      # (modules/desktop/hyprland.nix) to avoid duplication.
      # Only application-specific overrides should be here.
      env = [ ];

      # ============================================
      # INPUT CONFIGURATION
      # ============================================
      input = {
        kb_layout = "br";
        follow_mouse = 1;
        sensitivity = 1.2;
        accel_profile = "flat";
        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
          tap-to-click = true;
        };
      };

      # ============================================
      # GENERAL - Glassmorphism borders
      # ============================================
      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 1;

        # Glassmorphism gradient border - cyan to violet
        "col.active_border" = "rgba(00d4ffff) rgba(7c3aedff) 45deg";
        "col.inactive_border" = "rgba(22222e88)";

        layout = "dwindle";
        allow_tearing = false;
        resize_on_border = true;
      };

      # ============================================
      # DECORATIONS - Premium glassmorphism blur
      # ============================================
      decoration = {
        rounding = 12;

        # Enhanced blur for frosted glass effect
        blur = {
          enabled = true;
          size = 10;
          passes = 3;
          new_optimizations = true;
          xray = true;
          ignore_opacity = false;
          noise = 0.02;
          contrast = 0.9;
          brightness = 0.8;
          vibrancy = 0.2;
          vibrancy_darkness = 0.5;
          special = true;
          popups = true;
        };

        # Window opacity for glass effect
        active_opacity = 0.92;
        inactive_opacity = 0.88;
        fullscreen_opacity = 1.0;

        # Shadow settings (using new shadow section)
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          offset = "0 4";
          color = "rgba(00000066)";
          color_inactive = "rgba(00000044)";
        };

        # Dim inactive windows slightly
        dim_inactive = true;
        dim_strength = 0.15;
      };

      # ============================================
      # ANIMATIONS - Smooth 144fps bezier curves
      # ============================================
      animations = {
        enabled = true;

        # Custom bezier curves optimized for 144Hz
        bezier = [
          # Smooth ease-out for general movement
          "smoothOut, 0.4, 0, 0.2, 1"
          # Quick start for snappy feel
          "snappy, 0.2, 0.8, 0.2, 1"
          # Bounce for playful elements
          "bounce, 0.68, -0.55, 0.265, 1.55"
          # Gentle for subtle transitions
          "gentle, 0.4, 0.14, 0.3, 1"
          # Linear for fade effects
          "linear, 0, 0, 1, 1"
          # Fast for quick actions
          "fast, 0.2, 1, 0.3, 1"
          # Workspace slide
          "slide, 0.3, 0, 0.2, 1"
        ];

        animation = [
          # Window open/close
          "windowsIn, 1, 4, snappy, slide"
          "windowsOut, 1, 3, smoothOut, slide"
          "windowsMove, 1, 4, snappy"

          # Fade effects
          "fadeIn, 1, 3, gentle"
          "fadeOut, 1, 3, gentle"
          "fadeSwitch, 1, 4, smoothOut"
          "fadeShadow, 1, 4, smoothOut"
          "fadeDim, 1, 4, smoothOut"

          # Border color animation
          "border, 1, 8, gentle"
          "borderangle, 1, 50, linear, loop"

          # Workspace transitions - NEW in 0.52: separate in/out
          "workspaces, 1, 5, slide, slide"
          "workspacesIn, 1, 4, snappy, slide" # 0.52: entering workspace
          "workspacesOut, 1, 3, smoothOut, slide" # 0.52: leaving workspace
          "specialWorkspace, 1, 4, snappy, slidevert"

          # Layers (waybar, notifications)
          "layers, 1, 3, snappy, fade"
          "layersIn, 1, 3, snappy, fade"
          "layersOut, 1, 3, gentle, fade"
        ];
      };

      # ============================================
      # LAYOUTS
      # ============================================
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
        smart_split = true;
        smart_resizing = true;
      };

      master = {
        new_status = "master";
        mfact = 0.55;
      };

      # ============================================
      # LAYER RULES - Blur for glassmorphism
      # ============================================
      layerrule = [
        # Waybar - full blur + privacy
        "blur, waybar"
        "blurpopups, waybar"
        "ignorezero, waybar"
        "ignorealpha 0.3, waybar"
        "noscreenshare, waybar" # 0.52: exclude from screenshare

        # Mako notifications - blur + privacy
        "blur, notifications"
        "ignorezero, notifications"
        "ignorealpha 0.3, notifications"
        "noscreenshare, notifications" # 0.52: exclude from screenshare

        # Wofi launcher - blur
        "blur, wofi"
        "ignorezero, wofi"
        "ignorealpha 0.3, wofi"

        # Swappy screenshot editor - blur
        "blur, swappy"
        "ignorezero, swappy"

        # Wlogout - blur
        "blur, logout_dialog"
        "ignorezero, logout_dialog"

        # Hyprlock - blur
        "blur, hyprlock"
        "ignorezero, hyprlock"

        # GTK layer shell
        "blur, gtk-layer-shell"
        "ignorezero, gtk-layer-shell"
      ];

      # ============================================
      # WINDOW RULES - Glassmorphism styling
      # ============================================
      # Opacity Hierarchy (least to most opaque):
      # - Terminals: 0.90-0.92 (most transparent)
      # - File Managers: 0.92
      # - Editors/Communication: 0.95
      # - Browsers: 0.98 (least transparent for readability)
      # ============================================
      windowrulev2 = [
        # ==========================================
        # CATEGORY: Development Tools
        # ==========================================
        # Terminals - High transparency for background visibility
        "opacity 0.92 0.88, class:^(kitty)$"
        "animation slide, class:^(kitty)$"
        "opacity 0.90 0.85, class:^(Alacritty)$"
        "opacity 0.90 0.85, class:^(foot)$"

        # Code Editors - Slightly less transparent than terminals
        "opacity 0.95 0.90, class:^(code-oss)$"
        "opacity 0.95 0.90, class:^(Code)$"
        "opacity 0.95 0.90, class:^(VSCodium)$"
        "opacity 0.95 0.90, class:^(codium)$"
        "opacity 0.95 0.90, class:^(neovide)$"

        # ==========================================
        # CATEGORY: Web Browsers
        # ==========================================
        # Near opaque for readability (text-heavy content)
        "opacity 0.98 0.95, class:^(firefox)$"
        "opacity 0.98 0.95, class:^(Firefox)$"
        "opacity 0.98 0.95, class:^(brave-browser)$"
        "opacity 0.98 0.95, class:^(chromium)$"
        "opacity 0.98 0.95, class:^(Google-chrome)$"

        # ==========================================
        # CATEGORY: File Managers
        # ==========================================
        "float, class:^(nemo)$"
        "size 1200 700, class:^(nemo)$"
        "center, class:^(nemo)$"
        "opacity 0.92 0.88, class:^(nemo)$"

        "float, class:^(thunar)$"
        "size 1200 700, class:^(thunar)$"
        "center, class:^(thunar)$"
        "opacity 0.92 0.88, class:^(thunar)$"

        # ==========================================
        # CATEGORY: System Utilities
        # ==========================================
        # Audio Control
        "float, class:^(pavucontrol)$"
        "size 800 500, class:^(pavucontrol)$"
        "center, class:^(pavucontrol)$"

        # Network Manager
        "float, class:^(nm-connection-editor)$"
        "size 600 400, class:^(nm-connection-editor)$"
        "center, class:^(nm-connection-editor)$"

        # Bluetooth Manager
        "float, class:^(blueman-manager)$"
        "size 600 400, class:^(blueman-manager)$"
        "center, class:^(blueman-manager)$"

        # System Monitor
        "float, class:^(gnome-system-monitor)$"
        "size 1000 700, class:^(gnome-system-monitor)$"
        "center, class:^(gnome-system-monitor)$"

        # ==========================================
        # CATEGORY: Media Applications
        # ==========================================
        # Image Viewers
        "float, class:^(imv)$"
        "size 1400 900, class:^(imv)$"
        "center, class:^(imv)$"

        "float, class:^(feh)$"
        "size 1400 900, class:^(feh)$"
        "center, class:^(feh)$"

        # Video Players
        "float, class:^(mpv)$"
        "size 1280 720, class:^(mpv)$"
        "center, class:^(mpv)$"

        # Picture-in-Picture (stay on top, bottom-right corner)
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "size 400 225, title:^(Picture-in-Picture)$"
        "move 100%-420 100%-245, title:^(Picture-in-Picture)$"

        # ==========================================
        # CATEGORY: Productivity
        # ==========================================
        # Password Manager
        "float, class:^(org.keepassxc.KeePassXC)$"
        "size 1000 700, class:^(org.keepassxc.KeePassXC)$"
        "center, class:^(org.keepassxc.KeePassXC)$"

        # Note-taking
        "opacity 0.95 0.92, class:^(obsidian)$"
        "opacity 0.95 0.92, class:^(logseq)$"

        # PDF Viewers
        "opacity 0.98 0.95, class:^(org.pwmt.zathura)$"
        "opacity 0.98 0.95, class:^(evince)$"

        # ==========================================
        # CATEGORY: Communication
        # ==========================================
        "opacity 0.95 0.92, class:^(discord)$"
        "opacity 0.95 0.92, class:^(slack)$"
        "opacity 0.95 0.92, class:^(teams)$"

        # ==========================================
        # CATEGORY: Screenshot & Graphics Tools
        # ==========================================
        "float, class:^(swappy)$"
        "size 1000 700, class:^(swappy)$"
        "center, class:^(swappy)$"
        "opacity 0.95 0.90, class:^(swappy)$"

        # ==========================================
        # CATEGORY: Dialogs & Popups
        # ==========================================
        "float, title:^(Open File)$"
        "float, title:^(Save File)$"
        "float, title:^(Save As)$"
        "float, title:^(Choose Files)$"
        "float, title:^(Confirm)$"

        # ==========================================
        # CATEGORY: Modal Dialogs & Authentication (0.52+ feature)
        # ==========================================
        # Polkit authentication dialog - modern syntax
        "float, class:^(polkit-gnome-authentication-agent-1)$"
        "pin, class:^(polkit-gnome-authentication-agent-1)$"
        "stayfocused, class:^(polkit-gnome-authentication-agent-1)$"
        "size 450 200, class:^(polkit-gnome-authentication-agent-1)$"
        "center, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"

        # Confirmation dialogs - modern window rule syntax
        "float, title:^(Confirm)$"
        "pin, title:^(Confirm)$"
        "stayfocused, title:^(Confirm)$"
        "center, title:^(Confirm)$"
        "dimaround, title:^(Confirm)$"

        "float, title:^(Delete)$"
        "pin, title:^(Delete)$"
        "stayfocused, title:^(Delete)$"
        "center, title:^(Delete)$"
        "dimaround, title:^(Delete)$"

        "float, title:^(Warning)$"
        "pin, title:^(Warning)$"
        "stayfocused, title:^(Warning)$"
        "center, title:^(Warning)$"
        "dimaround, title:^(Warning)$"

        # File operation dialogs
        "float, title:^(File Operation Progress)$"
        "pin, title:^(File Operation Progress)$"
        "center, title:^(File Operation Progress)$"

        # ==========================================
        # CATEGORY: Performance Optimizations
        # ==========================================
        # Disable animations for some windows (better performance)
        "noanim, class:^(wofi)$" # Launcher feels snappier without anim
        "noanim, title:^(wlogout)$"

        # Immediate rendering for terminals (reduce input latency)
        "immediate, class:^(kitty)$"
        "immediate, class:^(Alacritty)$"

        # Tearing allowed for games (reduce input lag)
        "immediate, class:^(steam_app_).*$"
        "immediate, class:^(gamescope)$"

        # ==========================================
        # CATEGORY: Agent Hub Windows
        # ==========================================
        "float, class:^(agent-hub-chat)$"
        "size 1000 700, class:^(agent-hub-chat)$"
        "center, class:^(agent-hub-chat)$"
        "opacity 0.95 0.90, class:^(agent-hub-chat)$"

        "float, class:^(agent-hub-codex)$"
        "size 1200 800, class:^(agent-hub-codex)$"
        "center, class:^(agent-hub-codex)$"

        "float, class:^(agent-hub-gemini)$"
        "size 1200 800, class:^(agent-hub-gemini)$"
        "center, class:^(agent-hub-gemini)$"

        # ==========================================
        # CATEGORY: Workspace Auto-assignment (Optional)
        # ==========================================
        # Uncomment to enable automatic workspace assignment
        # "workspace 1 silent, class:^(kitty)$"
        # "workspace 3 silent, class:^(firefox)$"
        # "workspace 4 silent, class:^(discord)$"
      ];

      # ============================================
      # WORKSPACE ASSIGNMENTS
      # ============================================
      # Workspace Purpose Guide:
      # 1 = Primary Development (Terminals, Code Editors)
      # 2 = Secondary Development (Documentation, Testing)
      # 3 = Web Browsing (Firefox, Brave, Chromium)
      # 4 = Communication (Discord, Slack, Email)
      # 5 = Media/Entertainment (MPV, Spotify, YouTube)
      # 6 = System Monitoring (btop, system tools)
      # 7 = Research/Notes (Obsidian, PDF viewers)
      # 8 = Graphics/Design (GIMP, Inkscape, Image viewers)
      # 9 = Virtual Machines (VMs, Containers)
      # 10 = Miscellaneous (Temporary workspace)
      # ============================================
      # Note: Workspace assignments are optional - windows can be moved manually.
      # Uncomment the rules below to enable automatic workspace assignments.
      # ============================================
      # workspace = [
      #   # Development Tools → Workspace 1
      #   "1, class:^(kitty)$"
      #   "1, class:^(Alacritty)$"
      #   "1, class:^(VSCodium)$"
      #   "1, class:^(code-oss)$"
      #
      #   # Browsers → Workspace 3
      #   "3, class:^(firefox)$"
      #   "3, class:^(brave-browser)$"
      #   "3, class:^(chromium)$"
      #
      #   # Communication → Workspace 4
      #   "4, class:^(discord)$"
      #   "4, class:^(slack)$"
      #   "4, class:^(teams)$"
      #
      #   # Media → Workspace 5
      #   "5, class:^(mpv)$"
      #   "5, class:^(spotify)$"
      #
      #   # Research/Notes → Workspace 7
      #   "7, class:^(obsidian)$"
      #   "7, class:^(org.pwmt.zathura)$"
      # ];

      # ============================================
      # MISC SETTINGS - 144Hz optimizations
      # ============================================
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;

        # Power management
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;

        # VRR (Variable Refresh Rate) for 144Hz
        vrr = 1;

        # Performance - VFR saves power
        vfr = true;

        # Focus
        focus_on_activate = true;

        # Animation
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;

        # New window behavior
        new_window_takes_over_fullscreen = 2;

        # Rendering optimizations
        render_ahead_of_time = false; # Better for VRR
        render_ahead_safezone = 1; # Minimal safezone for 144Hz

        # Window swallowing (terminal opens GUI app, terminal hides)
        enable_swallow = true;
        swallow_regex = "^(kitty|Alacritty)$";

        # Background apps (allow while unfocused)
        background_color = "0x000000";

        # Layer positioning
        layers_hog_keyboard_focus = true;

        # Initial workspace tracking
        initial_workspace_tracking = 2;

        # Middle click paste
        middle_click_paste = false; # Disable for better clipboard control
      };

      # ============================================
      # CURSOR - Smooth movement
      # ============================================
      cursor = {
        no_hardware_cursors = true;
        enable_hyprcursor = true;
        hide_on_key_press = true;
        inactive_timeout = 5;
        zoom_disable_aa = false; # 0.52: false=smooth zoom, true=pixelated
      };

      # ============================================
      # RENDER - NVIDIA optimizations
      # ============================================
      # Note: explicit_sync and direct_scanout options removed
      # as they don't exist in current Hyprland version

      # ============================================
      # DEBUG - Disable for production
      # ============================================
      debug = {
        disable_logs = true;
        disable_time = true;
      };

      # ============================================
      # KEYBINDINGS
      # ============================================
      # Comprehensive keybinding reference:
      # See: /home/user/nixos/docs/HYPRLAND-KEYBINDINGS.md
      # Quick reference: Super = main modifier
      # ============================================
      "$mainMod" = "SUPER";

      bind = [
        # ==========================================
        # TERMINAL LAUNCHERS
        # ==========================================
        # Primary: Kitty + Zellij (GPU-accelerated, graphics protocol)
        # Using PATH-resolved commands for better compatibility
        "$mainMod, Return, exec, kitty -e zellij attach --create main"
        # Secondary: Alacritty + Zellij (lightweight fallback)
        "$mainMod SHIFT, Return, exec, alacritty -e zellij attach --create alt"
        # Plain terminals without multiplexer
        "$mainMod CTRL, Return, exec, kitty"
        "$mainMod CTRL SHIFT, Return, exec, alacritty"
        # Minimal emergency terminal (Foot with plain bash)
        "$mainMod ALT, Return, exec, foot"

        # ==========================================
        # APPLICATIONS
        # ==========================================
        "$mainMod, E, exec, nemo"
        "$mainMod, D, exec, wofi --show drun"
        "$mainMod SHIFT, D, exec, wofi --show run"

        # Window management
        "$mainMod, Q, killactive"
        "$mainMod, M, exit"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, F, fullscreen, 1"
        "$mainMod, V, togglefloating"
        "$mainMod, P, pseudo"
        "$mainMod, J, togglesplit"
        "$mainMod, G, togglegroup"
        "$mainMod, Tab, changegroupactive, f"
        "$mainMod SHIFT, Tab, changegroupactive, b"

        # Move focus with arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move focus with vim keys (hjkl)
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, semicolon, movefocus, d"

        # Move windows with arrow keys
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        # Move windows with vim keys
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, l, movewindow, r"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, j, movewindow, d"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Scroll workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Screenshot with swappy - region select
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        # Screenshot - fullscreen to swappy
        "SHIFT, Print, exec, grim - | swappy -f -"
        # Screenshot - region to file
        "CTRL, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        # Screenshot - fullscreen to file
        "CTRL SHIFT, Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        # Screenshot - copy region to clipboard
        "$mainMod, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Color picker
        "$mainMod SHIFT, C, exec, hyprpicker -a"

        # Media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

        # Lock screen
        "$mainMod CTRL, L, exec, hyprlock"

        # Force idle (0.52) - trigger idle immediately
        "$mainMod CTRL ALT, L, exec, hyprctl dispatch forceidle"

        # Logout menu
        "$mainMod, Escape, exec, wlogout -p layer-shell"

        # Notification center
        "$mainMod, N, exec, makoctl dismiss"
        "$mainMod SHIFT, N, exec, makoctl dismiss --all"

        # Reload waybar
        "$mainMod SHIFT, W, exec, killall waybar; waybar &"

        # Agent Hub integration
        "$mainMod, A, exec, $HOME/.config/agent-hub/agent-launcher.sh"
        "$mainMod SHIFT, A, exec, $HOME/.config/agent-hub/quick-prompt.sh"

        # Clipboard history
        "$mainMod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        # Calculator (if bc installed)
        "$mainMod, EQUAL, exec, wofi --dmenu --prompt=Calculator | bc -l | wl-copy"

        # Power management
        "$mainMod SHIFT, Escape, exec, systemctl suspend"
        "$mainMod CTRL SHIFT, Escape, exec, systemctl reboot"
        "$mainMod ALT SHIFT, Escape, exec, systemctl poweroff"

        # Window management enhancements
        "$mainMod, Z, togglesplit" # Toggle split direction
        "$mainMod, X, pin" # Pin window (keep on all workspaces)
        "$mainMod, C, centerwindow" # Center floating window

        # Quick workspace switching
        "$mainMod ALT, left, workspace, e-1"
        "$mainMod ALT, right, workspace, e+1"

        # Move window to workspace and follow
        "$mainMod CTRL SHIFT, 1, movetoworkspace, 1"
        "$mainMod CTRL SHIFT, 2, movetoworkspace, 2"
        "$mainMod CTRL SHIFT, 3, movetoworkspace, 3"
        "$mainMod CTRL SHIFT, 4, movetoworkspace, 4"
        "$mainMod CTRL SHIFT, 5, movetoworkspace, 5"

        # Emergency kill (force kill active window)
        "$mainMod SHIFT CTRL, Q, exec, hyprctl kill"

        # Focus urgent window
        "$mainMod, U, focusurgentorlast"
      ];

      # Repeating binds
      binde = [
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

        # Volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        # Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

  # ============================================
  # HYPRIDLE - Idle daemon (replaces swayidle)
  # ============================================
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Ensure single instance
        before_sleep_cmd = "loginctl lock-session"; # Lock before sleep
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn screen on after wake
        ignore_dbus_inhibit = false; # Respect apps preventing idle (media playback)
      };

      listener = [
        # Screen lock after 5 minutes of inactivity
        {
          timeout = 300; # 5 minutes
          on-timeout = "hyprlock"; # Lock screen
        }

        # Turn off display after 10 minutes
        {
          timeout = 600; # 10 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Screen off
          on-resume = "hyprctl dispatch dpms on"; # Screen on
        }

        # Suspend system after 30 minutes (optional - disabled by default)
        # Uncomment to enable system suspend
        # {
        #   timeout = 1800; # 30 minutes
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };
}
