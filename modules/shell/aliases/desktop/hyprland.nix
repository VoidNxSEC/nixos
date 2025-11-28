{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Hyprland & Desktop Aliases
# ============================================================

{
  environment.shellAliases = {
    # Shell reload
    "reload" = "source ~/.bashrc";

    # Hyprland
    "reland" = "hyprctl reload";
    "hypredit" = "$EDITOR ~/.config/hypr/hyprland.conf";
    "hyprconf" = "cd ~/.config/hypr && ls -la";

    # Waybar
    "wayreload" = "killall waybar && waybar &";
    "wayedit" = "$EDITOR ~/.config/waybar/config";
    "waystyle" = "$EDITOR ~/.config/waybar/style.css";

    # Quick edits
    "edit-hypr-aliases" = "sudo $EDITOR /etc/nixos/modules/shell/aliases/desktop/hyprland.nix";
    "edit-hyprland-aliases" = "sudo $EDITOR /etc/nixos/modules/shell/aliases/desktop/hyprland.nix"; # alias longo
  };
}
