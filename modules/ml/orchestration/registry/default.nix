{
  config,
  lib,
  pkgs,
  ...
}:

# Model Registry
# Database and discovery for ML models

{
  imports = [
    ./database.nix
    # ./discovery.nix  # TODO: Extract from manager.nix if exists
  ];
}
