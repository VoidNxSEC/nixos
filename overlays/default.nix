# Overlays collection
# Each overlay is imported from a separate file for better organization
[
  # Python package fixes (test failures, resource issues)
  (import ./python-packages.nix)
  (import ./python-tests-fix.nix) # Disable flaky pytest-xdist tests

  # Hyprland: Now using OFFICIAL flake overlay (see flake.nix inputs)
  # Custom overlay disabled to avoid build issues
  # (import ./hyprland.nix)

  # Add more overlays here as needed:
  # (import ./custom-packages.nix)
  # (import ./version-overrides.nix)

  # Note: swissknife-tools comes from inputs.swissknife flake (see flake.nix)
]
