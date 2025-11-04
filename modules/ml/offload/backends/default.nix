{
  config,
  lib,
  pkgs,
  ...
}:

# Backend Drivers Aggregator
#
# This module aggregates all ML backend drivers.
# Each driver implements a standard interface:
#   - load(model_path) → success/failure
#   - unload() → release VRAM
#   - switch(model_path) → hot-reload model
#   - status() → current state, loaded model, VRAM usage
#   - health() → service health check
#
# Supported backends:
#   - Ollama (ollama-driver.nix)
#   - llama.cpp (llamacpp-driver.nix)
#   - vLLM (vllm-driver.nix)
#   - Text Generation Inference (tgi-driver.nix)
#
# Future backend drivers will be added here as imports.

{
  imports = [
    # ./ollama-driver.nix      # TODO: Phase 2
    # ./llamacpp-driver.nix    # TODO: Phase 2
    # ./vllm-driver.nix        # TODO: Phase 2
    # ./tgi-driver.nix         # TODO: Phase 2
  ];

  options.kernelcore.ml.offload.backends = {
    enable = lib.mkEnableOption "ML backend drivers";

    availableBackends = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of enabled backend names (populated by individual drivers)";
      readOnly = true;
    };
  };

  config =
    lib.mkIf (config.kernelcore.ml.offload.enable && config.kernelcore.ml.offload.backends.enable)
      {
        # Backend driver configurations will be added here
        # Each driver module will register itself in availableBackends
      };
}
