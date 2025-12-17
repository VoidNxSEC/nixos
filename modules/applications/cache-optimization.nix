{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =================================================================
  # ELECTRON APP CACHE OPTIMIZATION
  # Move Electron app caches to tmpfs (RAM disk) to reduce NVMe wear
  # and improve IO performance dramatically
  # =================================================================

  # Create tmpfs mount point in user runtime directory
  systemd.user.tmpfiles.rules = [
    # Main cache directory (auto-cleaned on logout)
    "d %t/app-cache 0700 - - - 1h"
    "d %t/app-cache/antigravity 0700 - - -"
    "d %t/app-cache/brave 0700 - - -"
  ];

  # Service to setup cache symlinks on login
  systemd.user.services.electron-cache-setup = {
    description = "Setup Electron app caches in tmpfs";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-electron-cache" ''
        CACHE_DIR="$XDG_RUNTIME_DIR/app-cache"

        echo "Setting up Electron caches in tmpfs: $CACHE_DIR"

        # === Antigravity Cache ===
        ANTI_CONFIG="$HOME/.config/Antigravity"
        mkdir -p "$ANTI_CONFIG"

        # Backup existing cache if not a symlink
        if [ -d "$ANTI_CONFIG/Cache" ] && [ ! -L "$ANTI_CONFIG/Cache" ]; then
          echo "Backing up Antigravity cache..."
          mv "$ANTI_CONFIG/Cache" "$ANTI_CONFIG/Cache.bak.$(date +%Y%m%d)" || true
        fi

        # Create symlink to tmpfs
        rm -f "$ANTI_CONFIG/Cache"
        ln -sf "$CACHE_DIR/antigravity" "$ANTI_CONFIG/Cache"
        echo "✓ Antigravity cache -> tmpfs"

        # Also handle Code Cache
        if [ -d "$ANTI_CONFIG/Code Cache" ] && [ ! -L "$ANTI_CONFIG/Code Cache" ]; then
          mv "$ANTI_CONFIG/Code Cache" "$ANTI_CONFIG/Code Cache.bak.$(date +%Y%m%d)" || true
        fi
        mkdir -p "$CACHE_DIR/antigravity-code"
        rm -f "$ANTI_CONFIG/Code Cache"
        ln -sf "$CACHE_DIR/antigravity-code" "$ANTI_CONFIG/Code Cache"

        # === Brave Cache ===
        BRAVE_CONFIG="$HOME/.config/BraveSoftware/Brave-Browser/Default"
        mkdir -p "$BRAVE_CONFIG"

        if [ -d "$BRAVE_CONFIG/Cache" ] && [ ! -L "$BRAVE_CONFIG/Cache" ]; then
          echo "Backing up Brave cache..."
          mv "$BRAVE_CONFIG/Cache" "$BRAVE_CONFIG/Cache.bak.$(date +%Y%m%d)" || true
        fi

        rm -f "$BRAVE_CONFIG/Cache"
        ln -sf "$CACHE_DIR/brave" "$BRAVE_CONFIG/Cache"
        echo "✓ Brave cache -> tmpfs"

        # Brave Code Cache
        if [ -d "$BRAVE_CONFIG/Code Cache" ] && [ ! -L "$BRAVE_CONFIG/Code Cache" ]; then
          mv "$BRAVE_CONFIG/Code Cache" "$BRAVE_CONFIG/Code Cache.bak.$(date +%Y%m%d)" || true
        fi
        mkdir -p "$CACHE_DIR/brave-code"
        rm -f "$BRAVE_CONFIG/Code Cache"
        ln -sf "$CACHE_DIR/brave-code" "$BRAVE_CONFIG/Code Cache"

        echo "Electron cache setup complete"
        du -sh "$CACHE_DIR" 2>/dev/null || true
      '';
    };
  };

  # Periodic sync of critical session data (preserves important state)
  systemd.user.services.cache-persist = {
    description = "Persist critical Electron session data";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cache-persist" ''
        # Only sync session storage, cookies, and preferences
        # Skip actual cache data (it's recreatable)

        PERSIST_DIR="$HOME/.local/share/app-cache-persist"
        mkdir -p "$PERSIST_DIR"/{antigravity,brave}

        echo "Persisting critical session data..."

        # Antigravity: Session Storage, Cookies, Preferences
        ANTI_CONFIG="$HOME/.config/Antigravity"
        if [ -d "$ANTI_CONFIG" ]; then
          for dir in "Local Storage" "Session Storage" "Cookies" "Preferences"; do
            if [ -e "$ANTI_CONFIG/$dir" ]; then
              ${pkgs.rsync}/bin/rsync -a --delete \
                "$ANTI_CONFIG/$dir" \
                "$PERSIST_DIR/antigravity/" 2>/dev/null || true
            fi
          done
        fi

        # Brave: Same critical data
        BRAVE_CONFIG="$HOME/.config/BraveSoftware/Brave-Browser/Default"
        if [ -d "$BRAVE_CONFIG" ]; then
          for dir in "Local Storage" "Session Storage" "Cookies" "Preferences"; do
            if [ -e "$BRAVE_CONFIG/$dir" ]; then
              ${pkgs.rsync}/bin/rsync -a --delete \
                "$BRAVE_CONFIG/$dir" \
                "$PERSIST_DIR/brave/" 2>/dev/null || true
            fi
          done
        fi

        echo "Session data persisted to: $PERSIST_DIR"
        du -sh "$PERSIST_DIR" 2>/dev/null || true
      '';
    };
  };

  systemd.user.timers.cache-persist = {
    description = "Timer for periodic cache persistence";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Unit = "cache-persist.service";
    };
  };
}
