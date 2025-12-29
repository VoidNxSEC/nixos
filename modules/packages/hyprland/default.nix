# Hyprland v0.53.0 - Package Availability Module
#
# This module makes Hyprland v0.53.0 available system-wide.
# The actual package build is done via overlay in /etc/nixos/overlays/hyprland.nix
# The compositor configuration is done in /etc/nixos/modules/desktop/hyprland.nix
#
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages.hyprland;
in
{
  options.kernelcore.packages.hyprland = {
    enable = lib.mkEnableOption "Hyprland v0.53.0 package (built via overlay)";
  };

  config = lib.mkIf cfg.enable {
    # Make hyprland available system-wide
    # The overlay already provides pkgs.hyprland v0.53.0
    # The desktop module (modules/desktop/hyprland.nix) handles programs.hyprland config
    environment.systemPackages = [ pkgs.hyprland ];
  };
}
