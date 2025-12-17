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
    ./electron-tuning.nix

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
