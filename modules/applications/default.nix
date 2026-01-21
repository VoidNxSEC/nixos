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
    # ./cache-optimization.nix
    ./electron-tuning-v2.nix # Per-app Electron tuning
    ./chromium-log-suppression.nix # Suppress verbose GPU/Wayland logging

    # Browsers
    ./firefox-privacy.nix
    ./brave-secure.nix
    ./chromium.nix

    # Editors
    ./vscodium-secure.nix
    ./vscode-secure.nix
    ./vscode-remote-ssh.nix # Remote SSH extension for all VSCode-like editors

    # Terminal
    ./zellij.nix
    ./nemo-full.nix
  ];
}
