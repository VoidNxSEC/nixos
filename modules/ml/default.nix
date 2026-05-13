{ ... }:

# ============================================================
# ML / AI Module Aggregator
# ============================================================
# Covers: infrastructure, services, integrations, orchestration,
#         and AI agent ecosystem (agents/).
#
# Enable selectively via options in each submodule, e.g.:
#   kernelcore.ml.llama.enable = true;
#   kernelcore.ml.agents.neoland.enable = true;
# ============================================================

{
  imports = [
    # Core ML infrastructure (storage, VRAM, hardware)
    ./infrastructure

    # Long-running inference services (llama.cpp, vLLM)
    ./services

    # External integrations (MCP servers, Neovim, etc.)
    ./integrations

    # Container/K8s orchestration for ML workloads
    ./orchestration

    # AI agent ecosystem (neoland, neotron, cerebro, phantom, agent-hub)
    ./agents
  ];
}
