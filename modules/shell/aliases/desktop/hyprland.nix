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
  # Gate da Fase 4: config era incondicional; default true preserva o
  # sistema como está e permite desligar por host/specialisation.
  options.kernelcore.shell.aliases.hyprland.enable = lib.mkEnableOption "Hyprland aliases" // {
    default = true;
  };

  config = lib.mkIf config.kernelcore.shell.aliases.hyprland.enable {
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
      "aliases" = "sudo $EDITOR /etc/nixos/modules/shell/aliases/desktop/hyprland.nix";
    };
  };
}
