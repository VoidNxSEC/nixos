{
  config,
  lib,
  pkgs,
  ...
}:

# ML Orchestration Layer
# Offload manager, model registry, backends, API

{
  imports = [
    ./manager.nix
    ./registry
    ./backends
    # ./api is a separate flake project, not imported here
  ];
}
