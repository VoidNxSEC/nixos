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
    ./intel.nix
    ./lenovo-throttled.nix
    ./thermal-profiles.nix
    ./trezor.nix
    ./wifi-optimization.nix
    ./bluetooth.nix
  ];
}
