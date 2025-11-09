# Overlays collection
# Each overlay is imported from a separate file for better organization
[
  # Python package fixes (test failures, resource issues)
  (import ./python-packages.nix)

  # Hyprland v0.52.0 custom build
  (import ./hyprland.nix)

  # Add more overlays here as needed:
  # (import ./custom-packages.nix)
  # (import ./version-overrides.nix)
]
