{ inputs, ... }:

# ═══════════════════════════════════════════════════════════════
# LEDGER MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: ADR Ledger e infraestrutura de governança associada
#
# Os módulos do ledger NÃO são copiados para cá — vêm do flake
# adr-ledger, que já os exporta como nixosModules.
#
# Os quatro módulos locais são adoções de fragmentos que viviam
# órfãos em adr-ledger/nix/iam/ (nada os importava) e por isso
# carregavam defeitos que nunca falharam visivelmente. Ver o
# cabeçalho de cada um.
#
# Decisão: ADR-0090 (adr-ledger).
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    inputs.adr-ledger.nixosModules.adr-ledger # sync + agents + ml (services.adr-ledger*)
    ./facade.nix # superfície kernelcore.blockchain.ledger.*
    ./policy-engine.nix # OPA — adotado, era incondicional
    ./audit.nix # integridade do audit log — adotado, não parseava
    ./secrets.nix # sops-nix — adotado, usava sintaxe NIX_PATH
    ./radicle.nix # git p2p — consolida 3 versões sobre pkgs.radicle
  ];
}
