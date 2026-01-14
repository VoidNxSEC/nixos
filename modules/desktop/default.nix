{ ... }:

# ============================================================
# Desktop Environments Aggregator
# ============================================================

{
  imports = [
    ./i3-lightweight.nix
    ./hyprland.nix
    ./hyprland-performance.nix # Performance optimizations for Hyprland
    # Add more desktop environments here:
    # ./gnome.nix
    # ./kde.nix
    # ./xfce.nix
  ];
}
