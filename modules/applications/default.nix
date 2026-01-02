{ ... }:

# ============================================================
# Applications Module Aggregator
# ============================================================
# Purpose: Import all application-specific configurations
# Categories: Browsers, Editors, Privacy-focused applications
# ============================================================

{
  imports = [
    # Performance Optimizations
    ./cache-optimization.nix
    # ./electron-tuning.nix  # MIGRATED: Now using electron-tuning-v2.nix
    ./electron-tuning-v2.nix # Per-app Electron tuning

    # Browsers
    ./firefox-privacy.nix
    ./brave-secure.nix
    ./chromium.nix

    # Editors
    ./vscodium-secure.nix
    ./vscode-secure.nix

    # Terminal
    ./zellij.nix
    ./nemo-full.nix
  ];
}
