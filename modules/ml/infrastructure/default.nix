{
  config,
  lib,
  pkgs,
  ...
}:

# ML Infrastructure Layer
# Base infrastructure for ML: storage, VRAM monitoring, hardware configs

{
  imports = [
    ./storage.nix
    ./vram
    ./hardware
  ];
}
