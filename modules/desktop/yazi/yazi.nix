{ config, pkgs, lib, ... }:

# Este módulo apenas garante que o Yazi esteja instalado no sistema.
# A configuração detalhada (keymap, settings) está no home-manager.
#
# Veja: hosts/kernelcore/home/yazi.nix para a configuração completa.

{
  # Instala o Yazi no nível do sistema
  environment.systemPackages = with pkgs; [
    yazi
  ];
}
