{ pkgs, ... }:

{
  # =================================================================
  # ELECTRON APP USER-LEVEL CONFIGURATION
  # Performance flags and settings for Antigravity and other Electron apps
  # =================================================================

  # Electron app preferences (applied to all Electron apps)
  xdg.configFile."electron-flags.conf".text = ''
    # Performance flags for all Electron apps
    --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder
    --disable-features=UseChromeOSDirectVideoDecoder
    --enable-gpu-rasterization
    --enable-zero-copy
    --ignore-gpu-blocklist
  '';

  # Antigravity-specific settings
  xdg.configFile."Antigravity/argv.json".text = builtins.toJSON {
    # GPU acceleration
    "disable-gpu" = false;
    "disable-software-rasterizer" = true;
    "enable-gpu-rasterization" = true;

    # Process limits
    "renderer-process-limit" = 4;
    "process-per-site" = true;

    # Cache settings (100MB max)
    "disk-cache-size" = 104857600;
  };
}
