{
  config,
  lib,
  pkgs,
  ...
}:

# VRAM Management
# Monitoring and scheduling for GPU VRAM allocation

{
  imports = [
    ./monitoring.nix
    # ./scheduler.nix  # TODO: Create central GPU scheduler
  ];
}
