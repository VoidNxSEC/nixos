{ ... }:

# ============================================================
# Desktop Environments Aggregator
# ============================================================

{
  imports = [
    ./i3-lightweight.nix
    ./hyprland.nix
    ./hyprland-performance.nix # Performance optimizations for Hyprland
    # NÃO importar ./hyprland-modular aqui: usa options de home-manager
    # (services.hypridle.settings etc.) — pendente adaptação na Fase 5.
    # Add more desktop environments here:
    # ./gnome.nix
    # ./kde.nix
    # ./xfce.nix
  ];

  # XWayland p/ apps X11 (migrado do antigo modules/programs/default.nix)
  programs.sway.xwayland.enable = true;
}
