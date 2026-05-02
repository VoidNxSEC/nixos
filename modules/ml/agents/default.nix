# AI Agents & Ecosystem Aggregator
# Formerly modules/ai/ — relocated into modules/ml/agents/
#
#   ecosystem.nix  — service discovery registry
#   neoland/       — control plane (Rust + DSPy pipeline)
#   neotron/       — guardrails + orchestration
#   ml-ops-api/    — inference backend (local → k8s GPU fleet)
#   cerebro/       — semantic reranker for RAG
#   phantom/       — security scan / secret detection
#   agent-hub/     — event-driven automation infrastructure

{ ... }:
{
  imports = [
    ./ecosystem.nix
    ./neoland
    ./neotron
    #./ml-ops-api
    ./cerebro
    ./phantom
    # Legacy agent-hub (mantido para compatibilidade)
    ./agent-hub/infra
    ./agent-hub/capabilities
  ];
}
