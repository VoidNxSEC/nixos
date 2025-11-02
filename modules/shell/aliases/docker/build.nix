{ config, pkgs, lib, ... }:

# ============================================================
# Docker Build Aliases
# ============================================================
# Professional Docker build shortcuts with GPU support
# Usage: Add to flake.nix via ./modules/shell/aliases/docker
# ============================================================

let
  # Import GPU flags from centralized config
  gpuFlags = config.shell.gpu.dockerFlags or "--device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g";
in
{
  environment.shellAliases = {
    # ──────────────────────────────────────────────────────
    # BASIC DOCKER BUILD
    # ──────────────────────────────────────────────────────

    # Simple build current directory
    "d-build" = "docker build -t";

    # Build with no cache
    "d-build-fresh" = "docker build --no-cache -t";

    # Build with progress output
    "d-build-verbose" = "docker build --progress=plain -t";

    # Build and tag latest
    "d-build-latest" = ''
      f() { docker build -t "$1:latest" . && echo "✓ Built $1:latest"; }; f
    '';

    # ──────────────────────────────────────────────────────
    # GPU-ENABLED BUILDS
    # ──────────────────────────────────────────────────────

    # Build with GPU support (CUDA base images)
    "d-build-gpu" = ''
      docker build \
        --build-arg CUDA_VERSION=12.6.0 \
        --build-arg PYTHON_VERSION=3.11 \
        -t
    '';

    # Build PyTorch GPU image
    "d-build-pytorch" = ''
      docker build \
        --build-arg BASE_IMAGE=nvcr.io/nvidia/pytorch:25.09-py3 \
        -t
    '';

    # ──────────────────────────────────────────────────────
    # MULTI-STAGE BUILDS
    # ──────────────────────────────────────────────────────

    # Build specific stage
    "d-build-stage" = "docker build --target";

    # Build development stage
    "d-build-dev" = "docker build --target development -t";

    # Build production stage
    "d-build-prod" = "docker build --target production -t";

    # ──────────────────────────────────────────────────────
    # BUILD WITH ARGS
    # ──────────────────────────────────────────────────────

    # Build with build args from file
    "d-build-args" = "docker build --build-arg-file build-args.env -t";

    # Build with secret
    "d-build-secret" = ''
      docker build \
        --secret id=mysecret,src=/path/to/secret \
        -t
    '';

    # ──────────────────────────────────────────────────────
    # BUILDX (MULTI-PLATFORM)
    # ──────────────────────────────────────────────────────

    # Build for multiple platforms
    "d-buildx" = ''
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t
    '';

    # Build and push multi-platform
    "d-buildx-push" = ''
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --push \
        -t
    '';

    # ──────────────────────────────────────────────────────
    # BUILD HELPERS
    # ──────────────────────────────────────────────────────

    # Show build history
    "d-build-history" = "docker history";

    # Show image layers
    "d-build-layers" = "docker image inspect --format='{{range .RootFS.Layers}}{{println .}}{{end}}'";

    # Calculate image size
    "d-build-size" = "docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}'";

    # Clean build cache
    "d-build-clean" = "docker builder prune -f";

    # Clean all build cache (including dangling)
    "d-build-clean-all" = "docker builder prune -af";

    # ──────────────────────────────────────────────────────
    # QUICK BUILD RECIPES
    # ──────────────────────────────────────────────────────

    # Python app quick build
    "d-build-python" = ''
      f() {
        docker build \
          --build-arg PYTHON_VERSION=3.11 \
          --build-arg APP_NAME="$1" \
          -t "$1:latest" .
      }; f
    '';

    # Node.js app quick build
    "d-build-node" = ''
      f() {
        docker build \
          --build-arg NODE_VERSION=20 \
          --build-arg APP_NAME="$1" \
          -t "$1:latest" .
      }; f
    '';
  };
}
