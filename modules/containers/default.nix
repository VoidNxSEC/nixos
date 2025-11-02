{ ... }:

# ============================================================
# Container Module Aggregator
# ============================================================
# Purpose: Import all container runtime configurations
# Categories: Docker, Podman, NixOS containers
# ============================================================

{
  imports = [
    ./docker.nix
    ./podman.nix
    ./nixos-containers.nix
  ];
}
