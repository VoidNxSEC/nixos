{
  config,
  pkgs,
  lib,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# PER-APP ELECTRON CONFIGURATION (Home Manager)
# ═══════════════════════════════════════════════════════════════
# Replaces generic electron-config.nix with isolated per-app configs
# ═══════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════
  # ANTIGRAVITY - MIGRATED to modules/packages/antigravity/tuning.nix
  # ═══════════════════════════════════════════════════════════════
  # See: modules/packages/antigravity/
  #   - tuning.nix:   Performance optimization (argv.json)
  #   - security.nix: Sandboxing and session persistence
  #   - default.nix:  Package orchestration
  # ═══════════════════════════════════════════════════════════════

  # ═══════════════════════════════════════════════════════════════
  # VSCODE/VSCODIUM - Low Resource Profile
  # ═══════════════════════════════════════════════════════════════

  xdg.configFile."Code/argv.json".text = builtins.toJSON {
    # Low resource profile for editor
    renderer-process-limit = 2;
    process-per-site = true;
    disk-cache-size = 52428800; # 50MB

    # Minimal GPU usage (editor doesn't need heavy acceleration)
    disable-gpu = false;
    enable-gpu-rasterization = false;

    # Wayland compatibility only
    enable-features = lib.concatStringsSep "," [
      "WaylandWindowDecorations"
    ];
  };

  xdg.configFile."VSCodium/argv.json".text = builtins.toJSON {
    # Same as Code
    renderer-process-limit = 2;
    process-per-site = true;
    disk-cache-size = 52428800;
    disable-gpu = false;
    enable-gpu-rasterization = false;
    enable-features = "WaylandWindowDecorations";
  };

  # ═══════════════════════════════════════════════════════════════
  # GLOBAL ELECTRON FLAGS CONF (REMOVED)
  # ═══════════════════════════════════════════════════════════════
  # OLD: xdg.configFile."electron-flags.conf" was causing conflicts
  # NEW: Each app has its own argv.json with isolated configuration
  #
  # electron-flags.conf is NOT used by most apps - they read argv.json instead
  # ═══════════════════════════════════════════════════════════════
}
