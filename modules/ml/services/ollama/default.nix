{
  config,
  lib,
  pkgs,
  ...
}:

# Ollama Service & Management
# Ollama inference service with GPU memory management

{
  imports = [
    # ./service.nix      # TODO: Extract from configuration.nix if exists
    ./gpu-manager.nix
  ];
}
