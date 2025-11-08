{ ... }:

# ============================================================
# Desktop Environments Aggregator
# ============================================================

{
  imports = [
    ./i3-lightweight.nix
    ./hyprland.nix
    # Add more desktop environments here:
    # ./gnome.nix
    # ./kde.nix
    # ./xfce.nix
  ];
}
