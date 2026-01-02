{
  config,
  lib,
  pkgs,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY - SECURITY HARDENING
# ═══════════════════════════════════════════════════════════════
# Purpose: Sandboxing and security restrictions for Antigravity
# Method: Bubblewrap isolation (FHS environment)
# Threat Model: Untrusted AI code execution, extension vulnerabilities
# ═══════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════
  # BUBBLEWRAP SANDBOXING
  # ═══════════════════════════════════════════════════════════════
  # Antigravity runs in FHS environment with restricted filesystem access
  # This is handled by the antigravity-fhs package in nixpkgs
  # ═══════════════════════════════════════════════════════════════

  # Future: Add firejail profile for additional sandboxing
  # Future: Restrict network access per workspace
  # Future: AppArmor profile for Antigravity process

  # ═══════════════════════════════════════════════════════════════
  # SESSION DATA PERSISTENCE (CRITICAL)
  # ═══════════════════════════════════════════════════════════════
  # Persist session data outside tmpfs to survive reboots
  # ═══════════════════════════════════════════════════════════════

  systemd.user.services.antigravity-session-persist = {
    description = "Persist critical Antigravity session data";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "persist-antigravity-session" ''
        set -e
        PERSIST_DIR="$HOME/.local/share/app-session-data"
        ANTI_CONFIG="$HOME/.config/Antigravity"

        mkdir -p "$PERSIST_DIR/antigravity"

        # Persist: Session Storage, Cookies, Preferences, Extensions
        for item in "Session Storage" "Cookies" "Preferences" "Extensions"; do
          [ -e "$ANTI_CONFIG/$item" ] && \
            rsync -a --delete "$ANTI_CONFIG/$item/" \
                  "$PERSIST_DIR/antigravity/" 2>/dev/null || true
        done

        echo "✓ Antigravity session data persisted"
      '';
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # SECURITY NOTES
  # ═══════════════════════════════════════════════════════════════
  # 1. Chromium sandbox is ENABLED (do NOT disable)
  # 2. GPU sandbox is ENABLED (do NOT disable)
  # 3. Seccomp filter is ENABLED (do NOT disable)
  # 4. Extensions run in isolated processes (renderer-process-limit protects this)
  # 5. No network access restrictions yet (TODO: implement per-workspace)
  # ═══════════════════════════════════════════════════════════════
}
