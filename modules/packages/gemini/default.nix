{ lib, ... }:

# ═══════════════════════════════════════════════════════════════
# GEMINI CLI - MODULAR JS PACKAGE (Engineering Gold)
# ═══════════════════════════════════════════════════════════════
# Uses js-packages architecture: packaging + security + performance
# Pragmatic build: stdenv.mkDerivation with network (resolves ENOTCACHED)
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    ./js-packages.nix # Modular architecture (sandbox + wrapper)
    ./gemini-cli.nix # Gemini-specific configuration
  ];
}
