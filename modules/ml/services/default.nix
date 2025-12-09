{
  config,
  lib,
  pkgs,
  ...
}:

# ML Services Layer
# Systemd services for ML inference (llama.cpp, Ollama, etc.)

{
  imports = [
    ./llama-cpp.nix
    #./llama-cpp-swap.nix
    ./ollama

    # ./vllm.nix  # TODO: Future
  ];
}
