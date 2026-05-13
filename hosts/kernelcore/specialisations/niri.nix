{
  config,
  pkgs,
  lib,
  ...
}:

{
  specialisation = {
    niri.configuration = {
      system.nixos.tags = [ "Niri" ];

      # Desabilitar Hyprland
      services.hyprland-desktop.enable = lib.mkForce false;

      # Habilitar Niri (mkForce para sobrescrever o false do main config)
      programs.niri.enable = lib.mkForce true;

      # Mudar sessão padrão
      services.displayManager.defaultSession = "niri";

      # Desabilitar performance optimizations do Hyprland
      kernelcore.hyprland.performance.enable = lib.mkForce false;
    };
  };
}
