{
  config,
  pkgs,
  lib,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# ELECTRON CONFIGURATION - ENVIRONMENT VARIABLES ONLY
# ═══════════════════════════════════════════════════════════════
# Strategy: Use NIXOS_OZONE_WL=1 for Wayland detection
# Avoid argv.json to prevent "unknown flag" warnings
# All performance tuning moved to environment variables
# ═══════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════
  # ALL ELECTRON APPS CONFIGURATION REMOVED
  # ═══════════════════════════════════════════════════════════════
  # Wayland detection: NIXOS_OZONE_WL=1 (set in hyprland.nix)
  # Performance tuning: Handled by system-level config
  # No argv.json = No warnings about "unknown flags"
  # ═══════════════════════════════════════════════════════════════
}
