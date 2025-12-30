# ============================================
# Hyprland Desktop Environment - Pure Wayland
# ============================================
# 100% Wayland configuration with:
# - xdg-desktop-portal-hyprland (per wiki)
# - NVIDIA optimizations
# - Glassmorphism integration
# - No X11/Plasma/Sway conflicts
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.hyprland-desktop;
in
{
  options.services.hyprland-desktop = {
    enable = mkEnableOption "Hyprland desktop environment";

    # Option to enable NVIDIA optimizations
    nvidia = mkOption {
      type = types.bool;
      default = config.kernelcore.nvidia.enable or false;
      description = "Enable NVIDIA-specific Wayland optimizations";
    };
  };

  config = mkIf cfg.enable {
    # ============================================
    # HYPRLAND COMPOSITOR
    # ============================================
    # Note: programs.hyprland is provided by inputs.hyprland.nixosModules.default
    # We just configure it here
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      # Package comes from inputs.hyprland.overlays.default
      # Don't override it to avoid conflicts
    };

    # ============================================
    # XDG DESKTOP PORTAL
    # ============================================
    # Note: Portal configuration is handled by inputs.hyprland.nixosModules.default
    # We only add GTK portal for file pickers
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # ============================================
    # ESSENTIAL WAYLAND PACKAGES
    # ============================================
    environment.systemPackages = with pkgs; [
      # Core Hyprland Ecosystem
      hyprland # The compositor itself
      hyprlock # Lock screen (glassmorphism compatible)
      hypridle # Idle daemon (replacement for swayidle)
      hyprpicker # Color picker
      hyprpaper # Wallpaper (alternative to swaybg)

      # Status bar and launcher
      waybar # Status bar
      wofi # Application launcher

      # Notifications
      mako # Notification daemon (glassmorphism)
      libnotify # notify-send command

      # Screenshot and recording
      grim # Screenshot utility
      slurp # Screen area selection
      swappy # Screenshot editor (glassmorphism)
      wf-recorder # Screen recorder
      wl-clipboard # Clipboard utilities
      cliphist # Clipboard history

      # Session management
      wlogout # Logout menu (glassmorphism)

      # Wallpaper
      swaybg # Wallpaper utility

      # File manager
      nemo # File manager (Cinnamon)

      # Audio/Bluetooth/Network
      pavucontrol # Audio control
      networkmanagerapplet # Network manager applet
      blueman # Bluetooth manager

      # System monitoring
      btop # System monitor

      # Media control
      playerctl # Media player control
      brightnessctl # Brightness control

      # Qt Wayland support
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qtstyleplugins
      adwaita-qt
      adwaita-qt6

      # GTK theming for portals
      gtk3
      gtk4

      # Cursor theme (bibata-cursors installed via home-manager)
    ];

    # ============================================
    # POLKIT AUTHENTICATION
    # ============================================
    security.polkit.enable = true;

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # ============================================
    # XDG DESKTOP PORTAL GTK
    # ============================================
    # Service is automatically managed by xdg.portal.extraPortals

    # ============================================
    # ENVIRONMENT VARIABLES - Wayland Native
    # ============================================
    environment.sessionVariables = mkMerge [
      # Core Wayland settings (always applied)
      {
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";

        # Qt Wayland
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";

        # GTK
        GDK_BACKEND = "wayland,x11";

        # Electron/Chromium apps
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";

        # SDL
        SDL_VIDEODRIVER = "wayland";

        # Clutter
        CLUTTER_BACKEND = "wayland";

        # Mozilla
        MOZ_ENABLE_WAYLAND = "1";

        # Cursor (theme set at home-manager level)
        XCURSOR_SIZE = "24";
      }

      # NVIDIA-specific environment variables (conditional)
      (mkIf cfg.nvidia {
        # NVIDIA driver settings
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        # Disable hardware cursors (NVIDIA issue)
        WLR_NO_HARDWARE_CURSORS = "1";

        # VRR support
        __GL_GSYNC_ALLOWED = "1";
        __GL_VRR_ALLOWED = "1";

        # Direct rendering
        # WLR_DRM_NO_ATOMIC = "1";
      })
    ];

    # ============================================
    # DBUS & SYSTEMD INTEGRATION
    # ============================================
    # Ensure dbus is available for portals
    services.dbus.enable = true;

    # Enable gvfs for file manager features
    services.gvfs.enable = true;

    # Enable udisks for disk management
    services.udisks2.enable = true;

    # ============================================
    # FONTS FOR WAYLAND
    # ============================================
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji # renamed from noto-fonts-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];

    # ============================================
    # ASSERTIONS - Prevent Conflicts
    # ============================================
    assertions = [
      {
        assertion = !config.services.desktopManager.gnome.enable;
        message = "Hyprland conflicts with GNOME desktop. Please disable services.desktopManager.gnome.enable";
      }
    ];
  };
}
