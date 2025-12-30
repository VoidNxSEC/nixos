{
  config,
  lib,
  pkgs,
  ...
}:

# ML Orchestration Layer
#
# Unified architecture for ML model offloading with:
# - Multi-backend support (llama.cpp, vLLM, TGI)
# - Intelligent VRAM management (monitoring, scheduling, budget planning)
# - Model registry with auto-discovery
# - RESTful API for unified control
#
# Usage:
#   kernelcore.ml.offload.enable = true;
#   kernelcore.ml.offload.api.port = 9000;

{
  imports = [
    ./manager.nix
    ./registry
    ./backends
    # ./api is a separate flake project, not imported here
  ];

  options.kernelcore.ml.offload = {
    enable = lib.mkEnableOption "ML Offload unified system";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ml-offload";
      description = "Base directory for ML Offload data (registry DB, logs, etc.)";
    };

    modelsPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/ml-models";
      description = "Path to models directory";
    };
  };

  config = lib.mkIf config.kernelcore.ml.offload.enable {
    # Ensure models storage is enabled
    kernelcore.ml.models-storage.enable = lib.mkDefault true;

    # Create offload data directory
    systemd.tmpfiles.rules = [
      "d '${config.kernelcore.ml.offload.dataDir}' 0755 ml-offload ml-offload -"
      "d '${config.kernelcore.ml.offload.dataDir}/logs' 0755 ml-offload ml-offload -"
    ];

    # Enable ml-offload user (via ml-gpu-users.nix)
    kernelcore.system.ml-gpu-users.enable = true;

    # Add Python environment to system packages
    environment.systemPackages = with pkgs; [
      (python313.withPackages (
        ps: with ps; [
          fastapi
          uvicorn
          pydantic
          aiohttp
          psutil
          nvidia-ml-py
        ]
      ))
    ];
  };
}
