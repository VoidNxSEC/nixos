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
  # ARGV.JSON - NATIVE ELECTRON CONFIGURATION
  # ═══════════════════════════════════════════════════════════════
  # Chromium/Electron reads argv.json directly (no command-line parsing)
  # Syntax: "flag-name": value (NO -- prefix)
  # ═══════════════════════════════════════════════════════════════

  home-manager.users.kernelcore = {
    xdg.configFile."Antigravity/argv.json".text = builtins.toJSON {
      # ═══════════════════════════════════════════════════════════
      # MEMORY & PROCESS OPTIMIZATIONS
      # ═══════════════════════════════════════════════════════════
      #renderer-process-limit = 4; # Max 4 renderer processes
      process-per-site = true; # Share processes per domain
      #disable-dev-shm-usage = true; # Avoid /dev/shm tmpfs usage

      # ═══════════════════════════════════════════════════════════
      # CACHE & I/O OPTIMIZATIONS
      # ═══════════════════════════════════════════════════════════
      disk-cache-size = 104857600; # 100MB disk cache limit
      media-cache-size = 52428800; # 50MB media cache limit

      # ═══════════════════════════════════════════════════════════
      # GPU ACCELERATION (Intel iGPU Optimized)
      # ═══════════════════════════════════════════════════════════
      disable-gpu = false; # Keep GPU enabled
      #disable-software-rasterizer = true; # Force GPU rasterization
      #enable-gpu-rasterization = true; # Use GPU for rendering

      # Hardware video acceleration (VA-API)
      enable-features = lib.concatStringsSep "," [
        "VaapiVideoDecodeLinuxGL" # Intel VA-API decode
        "VaapiVideoEncoder" # Intel VA-API encode
        "WaylandWindowDecorations" # Native Wayland decorations
      ];

      disable-features = lib.concatStringsSep "," [
        "UseChromeOSDirectVideoDecoder" # ChromeOS-specific, not needed
      ];

      # ═══════════════════════════════════════════════════════════
      # NETWORK & BACKGROUND OPTIMIZATIONS
      # ═══════════════════════════════════════════════════════════
      disable-backgrounding-occluded-windows = true; # Don't throttle background tabs
      disable-background-timer-throttling = true; # Keep timers running

      # ═══════════════════════════════════════════════════════════
      # STABILITY FLAGS (Commented - Uncomment if needed)
      # ═══════════════════════════════════════════════════════════
      # enable-zero-copy = true;                  # Zero-copy video decode (experimental)
      # enable-hardware-overlays = true;          # Hardware overlays (may cause artifacts)
      # ignore-gpu-blocklist = true;              # Force GPU even if blocklisted
    };
  };

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
