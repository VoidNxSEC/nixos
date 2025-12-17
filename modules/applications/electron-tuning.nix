{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =================================================================
  # ELECTRON/CHROMIUM PERFORMANCE TUNING
  # Apply aggressive optimization flags to reduce resource usage
  # =================================================================

  # Environment variables for all Electron apps
  environment.sessionVariables = {
    # Limit Electron processes
    ELECTRON_MAX_RENDERER_PROCESSES = "4";

    # Disable verbose logging (reduces IO)
    ELECTRON_ENABLE_LOGGING = "0";
    ELECTRON_NO_ATTACH_CONSOLE = "1";

    # Chromium performance flags (used by all Electron apps)
    CHROMIUM_FLAGS = lib.concatStringsSep " " [
      # === Memory & Process Optimizations ===
      "--disable-dev-shm-usage" # Don't use /dev/shm tmpfs
      "--renderer-process-limit=4" # Max 4 renderer processes
      "--process-per-site" # Share processes across same domain

      # === Cache & IO Optimizations ===
      "--disk-cache-size=104857600" # 100MB disk cache limit
      "--media-cache-size=52428800" # 50MB media cache limit
      "--disable-software-rasterizer" # Force GPU rasterization

      # === GPU Acceleration (reduce CPU/IO) ===
      "--enable-gpu-rasterization" # Use GPU for rendering
      "--enable-zero-copy" # Zero-copy video decode
      "--enable-hardware-overlays" # Hardware video overlays
      "--ignore-gpu-blocklist" # Force GPU even if blocklisted

      # === Network & Preloading ===
      "--disable-backgrounding-occluded-windows" # Don't throttle background tabs
      "--disable-background-timer-throttling" # Keep timers running

      # === Stability & Performance ===
      "--no-sandbox" # Disable sandbox (already sandboxed by Firejail)
      "--disable-gpu-sandbox" # Disable GPU sandbox
      "--disable-seccomp-filter-sandbox" # Disable seccomp
    ];
  };

  # Overlay to wrap Antigravity with optimized flags
  nixpkgs.overlays = [
    (final: prev: {
      # Only override if antigravity package exists
      antigravity =
        if prev ? antigravity then
          prev.antigravity.overrideAttrs (old: {
            # Wrap the binary with performance flags
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/antigravity \
                --add-flags "--ozone-platform-hint=auto" \
                --add-flags "--enable-features=WaylandWindowDecorations,VaapiVideoDecodeLinuxGL" \
                --add-flags "--disable-features=UseChromeOSDirectVideoDecoder" \
                --add-flags "$CHROMIUM_FLAGS" \
                --set ELECTRON_OZONE_PLATFORM_HINT "auto"
            '';
          })
        else
          prev.antigravity;

      # Also optimize Brave if present
      brave =
        if prev ? brave then
          prev.brave.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/brave \
                --add-flags "$CHROMIUM_FLAGS"
            '';
          })
        else
          prev.brave;
    })
  ];
}
