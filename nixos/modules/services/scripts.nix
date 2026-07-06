{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Shell aliases for Docker ML containers and system shortcuts
  environment.shellAliases = {
    # ML Container Shortcuts
    tgi = "docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g ghcr.io/huggingface/text-generation-inference:latest";
    pytorch = "docker run --rm -it --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g nvcr.io/nvidia/pytorch:25.09-py3";
    jup-ml = "docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g";

    # System Shortcuts
    nx = "cd /etc/nixos"; # Quick jump to NixOS config
  };

  # Ensure aliases work in both bash and zsh
  programs.bash.shellAliases = config.environment.shellAliases;
  programs.zsh.shellAliases = config.environment.shellAliases;
}
