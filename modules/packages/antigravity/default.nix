{
  config,
  lib,
  pkgs,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY - MODULAR PACKAGE CONFIGURATION
# ═══════════════════════════════════════════════════════════════
# Purpose: Orchestrate packaging, tuning, and security for Antigravity
# Architecture: Modular separation of concerns
#   - tuning.nix:   Performance optimization (argv.json, caching)
#   - security.nix: Sandboxing and hardening (bubblewrap, persistence)
#   - default.nix:  Package installation and orchestration (this file)
# ═══════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════
  # MODULE IMPORTS - SEPARATION OF CONCERNS
  # ═══════════════════════════════════════════════════════════════
  imports = [
    ./tuning.nix # Performance: argv.json, cache optimization, GPU tuning
    ./security.nix # Security: sandboxing, session persistence
  ];

  # ═══════════════════════════════════════════════════════════════
  # PACKAGE INSTALLATION
  # ═══════════════════════════════════════════════════════════════
  # Use antigravity-fhs for better extension compatibility
  # FHS environment provides proper filesystem layout for npm/extensions
  # ═══════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    antigravity-fhs # Antigravity with FHS environment (official nixpkgs)
  ];

  # ═══════════════════════════════════════════════════════════════
  # PACKAGE NOTES
  # ═══════════════════════════════════════════════════════════════
  # - NO overlays needed (tuning via argv.json)
  # - NO wrapProgram hacks (native Electron config)
  # - Clean separation: packaging / tuning / security
  # - Scales: Easy to add more packages with same pattern
  # ═══════════════════════════════════════════════════════════════
}
