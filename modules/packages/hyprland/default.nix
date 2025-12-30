# ⚠️  DEPRECATED - DO NOT USE ⚠️
#
# This module is DEPRECATED. Hyprland is now provided via official flake input.
#
# CURRENT APPROACH:
# - Hyprland comes from: inputs.hyprland (flake.nix)
# - Overlay: inputs.hyprland.overlays.default
# - Module: inputs.hyprland.nixosModules.default
# - Config: modules/desktop/hyprland.nix
#
# DO NOT ENABLE: kernelcore.packages.hyprland.enable
# (Already commented in hosts/kernelcore/configuration.nix)
#
# ══════════════════════════════════════════════════════════════════════
# LEGACY DOCUMENTATION
# ══════════════════════════════════════════════════════════════════════
#
# Hyprland v0.53.0 - Package Availability Module (LEGACY)
#
# This module made Hyprland v0.53.0 available system-wide via custom overlay.
# The actual package build was done via overlay in /etc/nixos/overlays/hyprland.nix
# The compositor configuration is in /etc/nixos/modules/desktop/hyprland.nix
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
