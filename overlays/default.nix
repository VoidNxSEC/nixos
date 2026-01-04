# Overlays collection
# Each overlay is imported from a separate file for better organization
[
  # Python package fixes (test failures, resource issues)
  (import ./python-packages.nix)
  # (import ./python-tests-fix.nix) # Merged into python-packages.nix to avoid global rebuilds

  # Add more overlays here as needed:
  # (import ./custom-packages.nix)
  # (import ./version-overrides.nix)

  # Note: swissknife-tools comes from inputs.swissknife flake (see flake.nix)
]
