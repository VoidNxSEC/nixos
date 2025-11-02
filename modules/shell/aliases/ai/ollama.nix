{ config, pkgs, lib, ... }:

# ============================================================
# AI/ML Stack Aliases
# ============================================================

{
  environment.shellAliases = {
    # Ollama
    "ollama-list" = "docker exec ollama-gpu ollama list 2>/dev/null || echo 'Ollama not running'";
    "ollama-pull" = "docker exec ollama-gpu ollama pull";
    "ollama-run" = "docker exec ollama-gpu ollama run";
    "ollama-ps" = "docker exec ollama-gpu ollama ps";

    # AI Stack Management (from nixos-aliases.nix)
    "ai-up" = "docker compose -f ~/Documents/nx/docker/docker-compose.ai.yml up -d";
    "ai-down" = "docker compose -f ~/Documents/nx/docker/docker-compose.ai.yml down";
    "ai-restart" = "docker compose -f ~/Documents/nx/docker/docker-compose.ai.yml restart";
    "ai-logs" = "docker compose -f ~/Documents/nx/docker/docker-compose.ai.yml logs -f";
    "ai-status" = "docker compose -f ~/Documents/nx/docker/docker-compose.ai.yml ps";

    # GPU Stack
    "gpu-up" = "docker compose -f ~/Documents/nx/docker/docker-compose.gpu.yml up -d";
    "gpu-down" = "docker compose -f ~/Documents/nx/docker/docker-compose.gpu.yml down";
    "gpu-logs" = "docker compose -f ~/Documents/nx/docker/docker-compose.gpu.yml logs -f";

    # Jupyter
    "jupyter-gpu" = "docker run --rm -it --gpus all -p 8888:8888 -v $(pwd):/workspace jupyter/tensorflow-notebook";
  };
}
