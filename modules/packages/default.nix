{ ... }:

# ============================================================
# Packages Module Aggregator
# ============================================================
# Purpose: Import all package management modules
# Categories: .deb packages, flatpak, appimage, etc.
# ============================================================

{
  imports = [
    # Declarative .deb package management
    ./deb-packages

    # Declarative .tar.gz package management
    ./tar-packages

    # Declarative .js package management
    ./js-packages

    # Future: Add other package format integrations here
    # ./flatpak
    # ./appimage
    # ./snap
  ];
}
