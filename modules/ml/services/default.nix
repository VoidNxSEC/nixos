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
    ./vllm.nix
  ];
}
