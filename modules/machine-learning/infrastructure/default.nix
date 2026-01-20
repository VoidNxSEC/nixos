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
    ./model-profiles.nix
    ./vram
    ./hardware
  ];
}
