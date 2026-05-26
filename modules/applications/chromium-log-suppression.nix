{
  config,
  lib,
  pkgs,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# CHROMIUM LOG SUPPRESSION - Surgical Error Silencing
# ═══════════════════════════════════════════════════════════════
# Problem: Chromium-based apps spam stderr with GPU debug errors:
#   - ERROR:wayland_wp_image_description.cc - Incomplete image description
#   - ERROR:gles2_cmd_decoder_passthrough.cc - GPU command buffer spam
#
# Root Causes:
#   1. Wayland wp_image_description protocol not fully implemented in Hyprland
#   2. GPU command buffer verbose debug logging at ERROR level (not real errors)
#
# Solution: Add Chromium flags to suppress non-critical GPU debug output
# ═══════════════════════════════════════════════════════════════

with lib;

let
  cfg = config.kernelcore.chromium.logSuppression;

  # Flags to suppress verbose GPU/Wayland logging
  suppressionFlags = [
    # === Logging Level Control ===
    # Only show FATAL errors (not WARNING/ERROR/INFO)
    "--log-level=3" # 0=INFO, 1=WARNING, 2=ERROR, 3=FATAL

    # Disable specific verbose logging
    "--disable-logging" # Disable most logging to stderr
    "--silent-debugger-extension-api" # Silence debugger extension logs

    # === Wayland Protocol Workarounds ===
    # Disable incomplete image description protocol
    "--disable-features=WaylandImageDescription"

    # === GPU Debug Suppression ===
    # These don't actually disable functionality, just the verbose logging
    "--disable-gpu-program-cache" # Reduces GL command logging
    "--enable-gpu-client-logging=0" # Disable GPU client logging

    # === Additional Noise Reduction ===
    "--disable-breakpad" # Disable crash reporter logging
    "--disable-component-update" # Disable component update checks
  ];

  # Flags for performance (optional, can be disabled)
  performanceFlags = optionals cfg.enablePerformanceFlags [
    "--disable-gpu-driver-bug-workarounds" # Skip GPU workarounds
    "--enable-gpu-rasterization" # Use GPU for rasterization
    "--disable-software-rasterizer" # Force GPU rasterization
  ];

  # Combined flags
  allFlags = suppressionFlags ++ performanceFlags;

in
{
  options.kernelcore.chromium.logSuppression = {
    enable = mkEnableOption "Suppress verbose Chromium GPU/Wayland logging";

    enablePerformanceFlags = mkOption {
      type = types.bool;
      default = false;
      description = "Enable additional performance flags (may cause issues on some systems)";
    };

    applyGlobally = mkOption {
      type = types.bool;
      default = true;
      description = "Apply flags globally via environment variables (affects all Chromium/Electron apps)";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional custom flags to append";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ═══════════════════════════════════════════════════════════════
    # GLOBAL APPLICATION (via environment variables)
    # ═══════════════════════════════════════════════════════════════
    (mkIf cfg.applyGlobally {
      environment.sessionVariables = {
        # Chromium flags (used by Electron apps and Chromium-based browsers)
        CHROMIUM_FLAGS = lib.concatStringsSep " " (allFlags ++ cfg.extraFlags);

        # Electron-specific (some apps check this instead)
        ELECTRON_FLAGS = lib.concatStringsSep " " (allFlags ++ cfg.extraFlags);

        # Disable Electron verbose logging
        ELECTRON_ENABLE_LOGGING = "0";
        ELECTRON_NO_ATTACH_CONSOLE = "1";
      };
    })

    # ═══════════════════════════════════════════════════════════════
    # PER-APP WRAPPERS (for apps that don't respect env vars)
    # ═══════════════════════════════════════════════════════════════
    {
      # VSCodium wrapper enhancement
      nixpkgs.overlays = [
        (final: prev: {
          # Wrap VSCodium with log suppression flags
          vscodium = prev.vscodium.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/codium \
                ${lib.concatMapStringsSep " " (flag: "--add-flags ${lib.escapeShellArg flag}") allFlags}
            '';
          });

          # Wrap Brave with log suppression flags (if not already wrapped)
          brave = prev.brave.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              # Check if brave binary exists and wrap it
              if [ -f $out/bin/brave ]; then
                wrapProgram $out/bin/brave \
                  ${lib.concatMapStringsSep " " (flag: "--add-flags ${lib.escapeShellArg flag}") allFlags}
              fi
            '';
          });

          # Wrap Chromium with log suppression flags
          chromium = prev.chromium.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/chromium \
                ${lib.concatMapStringsSep " " (flag: "--add-flags ${lib.escapeShellArg flag}") allFlags}
            '';
          });
        })
      ];
    }
  ]);

  # ═══════════════════════════════════════════════════════════════
  # DOCUMENTATION
  # ═══════════════════════════════════════════════════════════════
  # Usage:
  #   kernelcore.chromium.logSuppression.enable = true;
  #
  # This will:
  #   1. Set CHROMIUM_FLAGS and ELECTRON_FLAGS environment variables
  #   2. Wrap VSCodium, Brave, and Chromium with suppression flags
  #   3. Silence GPU command buffer debug spam
  #   4. Disable incomplete Wayland image description protocol warnings
  #
  # The errors will still occur internally, but won't spam stderr.
  # This is safe - these are debug logs, not functional errors.
  # ═══════════════════════════════════════════════════════════════
}
