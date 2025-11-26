{
  config,
  lib,
  pkgs,
  ...
}:

# ML Modules - Main Aggregator
#
# Modular ML infrastructure for NixOS with:
# - Infrastructure: Storage, VRAM monitoring, hardware configs
# - Services: llama.cpp, Ollama inference services
# - Orchestration: Offload manager, model registry, backends
# - Applications: SecureLLM Bridge (secure LLM proxy)
# - Integrations: MCP servers, Neovim integration
#
# Usage:
#   imports = [ ./modules/ml ];
#
# See modules/ml/README.md for detailed documentation.

{
  imports = [
    ./infrastructure
    ./services
    ./orchestration
    ./applications
    ./integrations
  ];
}
