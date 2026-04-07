{ ... }:
{
  imports = [
    ./control-plane.nix
    ./dspy-pipeline.nix
    ./agent-config.nix
    ./checkpoint-storage.nix
    ./ledger-subscriber.nix
    # Fase 4 — Observabilidade self-hosted (soberania dos dados de orquestração)
    ./loki.nix
    ./vector.nix
  ];
}
