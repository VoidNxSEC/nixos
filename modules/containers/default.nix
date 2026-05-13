{ ... }:

# ============================================================
# Container Module Aggregator
# ============================================================
# Purpose: Import all container runtime configurations
# Categories: Docker, Podman, NixOS containers, Kubernetes, ML/AI, Development
# ============================================================

{
  imports = [
    # Container runtimes
    ./docker.nix
    ./podman.nix
    ./nixos-containers.nix

    # Kubernetes Stack
    ./k3s-cluster.nix
    ./longhorn-storage.nix

    # Docker Hub integration
    ./docker-hub.nix

    # Declarative container kits
    ./ml-containers.nix # AI/ML workloads (Ollama, Jupyter, ComfyUI, vLLM, LocalAI)
    ./dev-containers.nix # Development environments (dev-ml, chat-ui, code-server, postgres)
  ];
}
