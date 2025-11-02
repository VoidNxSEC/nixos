{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Docker Run Aliases
# ============================================================
# Professional Docker run shortcuts with GPU support
# ============================================================

let
  # Import GPU flags from centralized config
  gpuFlags =
    config.shell.gpu.dockerFlags
      or "--device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g";
in
{
  environment.shellAliases = {
    # ──────────────────────────────────────────────────────
    # BASIC DOCKER RUN
    # ──────────────────────────────────────────────────────

    "d-run" = "docker run --rm -it";
    "d-run-bg" = "docker run -d";
    "d-run-clean" = "docker run --rm";

    # ──────────────────────────────────────────────────────
    # GPU-ENABLED RUN
    # ──────────────────────────────────────────────────────

    # Run with full GPU access
    "d-run-gpu" = "docker run --rm -it ${gpuFlags}";

    # Run GPU with workspace mounted
    "d-run-gpu-work" = "docker run --rm -it ${gpuFlags} -v $(pwd):/workspace -w /workspace";

    # Run GPU PyTorch interactive
    "d-run-pytorch" = ''
      docker run --rm -it ${gpuFlags} \
        -v $(pwd):/workspace \
        -w /workspace \
        nvcr.io/nvidia/pytorch:25.09-py3 \
        bash
    '';

    # ──────────────────────────────────────────────────────
    # PORT MAPPING
    # ──────────────────────────────────────────────────────

    # Run with port 8080
    "d-run-web" = "docker run --rm -it -p 8080:8080";

    # Run Jupyter (8888)
    "d-run-jupyter" = "docker run --rm -it -p 8888:8888";

    # Run with custom port
    "d-run-port" = ''
      f() { docker run --rm -it -p "$1:$1"; }; f
    '';

    # ──────────────────────────────────────────────────────
    # VOLUME MOUNTS
    # ──────────────────────────────────────────────────────

    # Run with current directory mounted
    "d-run-here" = "docker run --rm -it -v $(pwd):/app -w /app";

    # Run with home directory mounted
    "d-run-home" = "docker run --rm -it -v $HOME:/home/user";

    # ──────────────────────────────────────────────────────
    # QUICK ENVIRONMENTS
    # ──────────────────────────────────────────────────────

    # Python 3.11 quick shell
    "d-python" = "docker run --rm -it -v $(pwd):/app -w /app python:3.11 bash";

    # Node.js 20 quick shell
    "d-node" = "docker run --rm -it -v $(pwd):/app -w /app node:20 bash";

    # Ubuntu latest quick shell
    "d-ubuntu" = "docker run --rm -it ubuntu:latest bash";

    # Alpine quick shell (minimal)
    "d-alpine" = "docker run --rm -it alpine:latest sh";

    # ──────────────────────────────────────────────────────
    # CONTAINER MANAGEMENT
    # ──────────────────────────────────────────────────────

    # List running containers (pretty)
    "d-ps" = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";

    # List all containers
    "d-ps-all" = "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Image}}'";

    # Stop all running containers
    "d-stop-all" = "docker stop $(docker ps -q)";

    # Remove all stopped containers
    "d-rm-stopped" = "docker container prune -f";

    # Execute bash in running container
    "d-exec" = "docker exec -it";

    # Execute bash in running container
    "d-shell" = ''
      f() { docker exec -it "$1" /bin/bash || docker exec -it "$1" /bin/sh; }; f
    '';

    # View container logs
    "d-logs" = "docker logs -f";

    # Inspect container
    "d-inspect" = "docker inspect";
  };
}
