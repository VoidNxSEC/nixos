{ ... }:

# ═══════════════════════════════════════════════════════════════
# BLOCKCHAIN MODULE AGGREGATOR
# ═══════════════════════════════════════════════════════════════
# Purpose: Crypto development tools and intelligence pipelines
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    ./algorand # Algorand / AlgoKit / PyTeal dev environment
    ./chainscope.nix # CHAINSCOPE — Crypto intelligence pipeline (B300)
  ];
}
