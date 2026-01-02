{ ... }:

# ============================================================
# Container Module Aggregator
# ============================================================
# Purpose: Import all container runtime configurations
# Categories: Docker, Podman, NixOS containers, Kubernetes
# ============================================================

{
  imports = [
    ./docker.nix
    ./podman.nix
    ./nixos-containers.nix

    # Kubernetes Stack
    ./k3s-cluster.nix
    ./longhorn-storage.nix
  ];
}
