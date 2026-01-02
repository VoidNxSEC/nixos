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
  # ANTIGRAVITY - Performance Profile
  # ═══════════════════════════════════════════════════════════════

  xdg.configFile."Antigravity/argv.json".text = builtins.toJSON {
    # Performance profile: balanced
    renderer-process-limit = 4;
    process-per-site = true;
    disk-cache-size = 104857600; # 100MB

    # GPU acceleration
    disable-gpu = false;
    disable-software-rasterizer = true;
    enable-gpu-rasterization = true;

    # Wayland features (ONLY what Electron actually supports)
    enable-features = lib.concatStringsSep "," [
      "VaapiVideoDecodeLinuxGL" # Hardware video decode
      "VaapiVideoEncoder" # Hardware video encode
      "WaylandWindowDecorations" # Native Wayland decorations
    ];

    disable-features = lib.concatStringsSep "," [
      "UseChromeOSDirectVideoDecoder" # ChromeOS-specific, not needed
    ];
  };

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
