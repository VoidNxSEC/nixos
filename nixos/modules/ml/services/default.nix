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
    ./llama-model-router.nix
    #./tabbyapi.nix
    ./vllm.nix
  ];
}
