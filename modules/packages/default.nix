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

    # Future: Add other package format integrations here
    # ./flatpak
    # ./appimage
    # ./snap
  ];
}
