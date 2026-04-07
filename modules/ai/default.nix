# AI Ecosystem Modules Aggregator
#
# Importa todos os serviços do ecossistema AI:
#   - ecosystem.nix      — service discovery registry (single source of truth para URLs)
#   - neoland/           — control plane Rust + DSPy pipeline
#   - neotron/           — guardrails + orquestração (stub)
#   - ml-ops-api/        — inference backend (local → k8s GPU fleet)
#   - cerebro/           — semantic reranker para RAG (stub)
#   - phantom/           — security scan / secret detection (stub)

{ ... }:
{
  imports = [
    ./ecosystem.nix
    ./neoland
    ./neotron
    ./ml-ops-api
    ./cerebro
    ./phantom
    # Legacy agent-hub (mantido para compatibilidade)
    ./agent-hub/infra
    ./agent-hub/capabilities
  ];
}
