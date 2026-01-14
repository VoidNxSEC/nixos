{
  config,
  lib,
  pkgs,
  ...
}:

# Machine Learning Modules - Main Aggregator
#
# Core ML infrastructure for NixOS:
# - Infrastructure: Storage, VRAM monitoring, hardware configs
# - Services: llama.cpp-turbo, vLLM inference services
# - Integrations: MCP servers, Neovim integration
#
# Note: ML Offload API (orchestration) moved to separate repo:
#   https://github.com/VoidNxSEC/ml-offload-api
#
# Usage:
#   imports = [ ./modules/machine-learning ];

{
  imports = [
    ./infrastructure
    ./services
    ./integrations
  ];
}
