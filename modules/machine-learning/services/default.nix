{
  config,
  lib,
  pkgs,
  ...
}:

# ML Services Layer
# Inference services: llama.cpp (CUDA), vLLM

{
  imports = [
    ./llama-cpp-turbo.nix
    ./llama-cpp-swap.nix
    ./tabbyapi.nix
    ./vllm.nix
  ];
}
