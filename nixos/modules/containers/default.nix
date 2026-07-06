{ ... }:

# ============================================================
# Container Module Aggregator
# ============================================================
# Purpose: Import container runtime configurations
# Note: Kubernetes modules live in modules/kubernetes/
# ============================================================

{
  imports = [
    # Container runtimes
    ./docker.nix
    ./podman.nix
    ./nixos-containers.nix

    # Docker Hub integration
    ./docker-hub.nix

    # Declarative container kits
    ./ml-containers.nix # AI/ML workloads (Ollama, Jupyter, ComfyUI, vLLM, LocalAI)
    ./dev-containers.nix # Development environments (dev-ml, chat-ui, code-server, postgres)
  ];
}
