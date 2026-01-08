{
  config,
  lib,
  pkgs,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY - PERFORMANCE TUNING
# ═══════════════════════════════════════════════════════════════
# Purpose: High-performance Electron configuration for Antigravity
# Method: argv.json (native Electron config, no wrapper hacks)
# Benefits: Reduced I/O, optimized GPU usage, lower memory footprint
# ═══════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════
  # ARGV.JSON REMOVED - USE ENVIRONMENT VARIABLES ONLY
  # ═══════════════════════════════════════════════════════════════
  # All configuration moved to environment variables:
  #   - Wayland detection: NIXOS_OZONE_WL=1 (set in hyprland.nix)
  #   - Performance tuning: System-level configuration
  #
  # Reason: argv.json flags cause "unknown option" warnings
  # Solution: Let Chromium/Electron use native Wayland detection
  # ═══════════════════════════════════════════════════════════════

  # ═══════════════════════════════════════════════════════════════
  # CACHE OPTIMIZATION - TMPFS (from cache-optimization.nix)
  # ═══════════════════════════════════════════════════════════════
  # Moved to antigravity module for better isolation
  # ═══════════════════════════════════════════════════════════════

  systemd.user.tmpfiles.rules = [
    "d %t/app-cache/antigravity 0700 - - -"
  ];

  systemd.user.services.antigravity-cache-setup = {
    description = "Setup Antigravity cache in tmpfs";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-antigravity-cache" ''
        set -e
        CACHE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/app-cache/antigravity"
        ANTI_CONFIG="$HOME/.config/Antigravity"

        echo "Setting up Antigravity cache in tmpfs: $CACHE_DIR"

        # Backup existing cache if present
        if [ -d "$ANTI_CONFIG/Cache" ] && [ ! -L "$ANTI_CONFIG/Cache" ]; then
          echo "Backing up existing Antigravity cache..."
          mv "$ANTI_CONFIG/Cache" "$ANTI_CONFIG/Cache.bak"
        fi

        # Create tmpfs cache and symlink
        mkdir -p "$CACHE_DIR"
        ln -sf "$CACHE_DIR" "$ANTI_CONFIG/Cache"
        echo "✓ Antigravity cache → tmpfs"

        # Code Cache (separate for better isolation)
        mkdir -p "$CACHE_DIR-code"
        [ -L "$ANTI_CONFIG/Code Cache" ] && rm "$ANTI_CONFIG/Code Cache"
        ln -sf "$CACHE_DIR-code" "$ANTI_CONFIG/Code Cache"
        echo "✓ Antigravity code cache → tmpfs"

        echo "Antigravity cache optimization complete"
      '';
    };
  };
}
