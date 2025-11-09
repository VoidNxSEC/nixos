{ ... }:

# ============================================================
# Hardware Module Aggregator
# ============================================================
# Purpose: Import all hardware-specific configurations
# Categories: GPU, Intel CPU, Trezor hardware, WiFi optimization
# ============================================================

{
  imports = [
    ./nvidia.nix
    # ./intel.nix  # Commented out in flake.nix
    ./trezor.nix
    ./wifi-optimization.nix
    ./bluetooth.nix
  ];
}
