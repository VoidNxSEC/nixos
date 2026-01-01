{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Use official Antigravity package from nixpkgs (version 1.13.3)
  # antigravity-fhs provides better extension compatibility via FHS environment
  environment.systemPackages = with pkgs; [
    antigravity-fhs
  ];
}
