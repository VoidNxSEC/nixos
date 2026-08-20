{ inputs, ... }:

# ═══════════════════════════════════════════════════════════════
# LEDGER MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: ADR Ledger e infraestrutura de governança associada
#
# Os módulos do ledger NÃO são copiados para cá — vêm do flake
# adr-ledger, que já os exporta como nixosModules. Ver ADR-0090.
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    inputs.adr-ledger.nixosModules.adr-ledger # sync + agents + ml (services.adr-ledger*)
    ./facade.nix # superfície kernelcore.blockchain.ledger.*
  ];
}
