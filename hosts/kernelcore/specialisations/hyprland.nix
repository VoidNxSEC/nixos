{
  config,
  pkgs,
  lib,
  ...
}:

{
  specialisation = {
    hyprland.configuration = {
      system.nixos.tags = [ "Hyprland" ];
      programs.niri.enable = lib.mkForce false;
      services.hyprland-desktop.enable = true;
      services.displayManager.defaultSession = "hyprland";
    };
  };
}
