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
  };

  config = mkIf cfg.enable {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Essential Wayland and Hyprland packages
    environment.systemPackages = with pkgs; [
      # Core Hyprland tools
      waybar # Status bar
      wofi # Application launcher
      dunst # Notification daemon
      swaylock # Screen locker
      swayidle # Idle management

      # Screenshot and screen recording
      grim # Screenshot utility
      slurp # Screen area selection
      wl-clipboard # Clipboard utilities
      wf-recorder # Screen recorder

      # File manager and utilities
      nemo # File manager (Cinnamon)
      pavucontrol # Audio control
      networkmanagerapplet # Network manager applet

      # Terminal (already have alacritty)
      kitty # Backup terminal

      # System monitoring
      btop # System monitor

      # Media
      playerctl # Media player control

      # Appearance
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qtstyleplugins
      adwaita-qt
      adwaita-qt6
    ];

    # XDG portal for screen sharing and file pickers
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };

    # Polkit authentication agent
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

    # NVIDIA-specific settings for Hyprland
    environment.sessionVariables = mkIf config.kernelcore.nvidia.enable {
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
