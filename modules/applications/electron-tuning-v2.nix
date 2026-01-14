{
  config,
  lib,
  pkgs,
  ...
}:

# ═══════════════════════════════════════════════════════════════
# ELECTRON TUNING V2 - Per-App Isolation Architecture
# ═══════════════════════════════════════════════════════════════
# Problem: Generic tuning causes flag conflicts across multiple Electron apps
# Solution: Isolate tuning per application with proper flag delivery methods
#
# Key Principles:
# 1. NO global ELECTRON_* or CHROMIUM_FLAGS environment variables
# 2. Use app-specific config files (argv.json, *.conf) ONLY
# 3. Environment variables ONLY for Wayland/platform detection
# 4. Separate performance tuning from platform compatibility
# ═══════════════════════════════════════════════════════════════

with lib;

let
  cfg = config.kernelcore.electron;

  # ═══════════════════════════════════════════════════════════════
  # TUNING PROFILES - Reusable performance configurations
  # ═══════════════════════════════════════════════════════════════

  profiles = {
    # Balanced: Good performance + stability
    balanced = {
      renderer-process-limit = 4;
      process-per-site = true;
      disk-cache-size = 104857600; # 100MB
      enable-gpu-rasterization = true;
      disable-software-rasterizer = true;
    };

    # Performance: Maximum speed, higher resource usage
    performance = {
      renderer-process-limit = 8;
      process-per-site = false; # Isolate processes
      disk-cache-size = 209715200; # 200MB
      enable-gpu-rasterization = true;
      enable-zero-copy = true;
      ignore-gpu-blocklist = true;
    };

    # Low Resource: Minimal memory/CPU usage
    low-resource = {
      renderer-process-limit = 2;
      process-per-site = true;
      disk-cache-size = 52428800; # 50MB
      disable-gpu = false; # Still use GPU, just limit processes
    };
  };

  # Helper: Generate argv.json content for an app
  mkArgvJson =
    profile: features:
    builtins.toJSON (
      profile
      // {
        # Add Wayland-specific features if enabled
        enable-features = concatStringsSep "," (features.enable or [ ]);
        disable-features = concatStringsSep "," (features.disable or [ ]);
      }
    );

in
{
  options.kernelcore.electron = {
    enable = mkEnableOption "Per-app Electron tuning system";

    # Per-app configuration
    apps = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            profile = mkOption {
              type = types.enum [
                "balanced"
                "performance"
                "low-resource"
                "custom"
              ];
              default = "balanced";
              description = "Performance profile to use";
            };

            customProfile = mkOption {
              type = types.attrs;
              default = { };
              description = "Custom profile settings (when profile = custom)";
            };

            features = mkOption {
              type = types.submodule {
                options = {
                  enable = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "Features to enable";
                  };
                  disable = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "Features to disable";
                  };
                };
              };
              default = { };
              description = "Chromium features configuration";
            };

            configDir = mkOption {
              type = types.str;
              description = "XDG config directory for the app";
              example = "Antigravity";
            };
          };
        }
      );
      default = { };
      description = "Per-application Electron configurations";
    };
  };

  config = mkIf cfg.enable {
    # ═══════════════════════════════════════════════════════════════
    # WAYLAND PLATFORM DETECTION ONLY
    # ═══════════════════════════════════════════════════════════════
    # These are NOT performance tuning - only platform compatibility
    # Managed by hyprland.nix, NOT here

    # NO ELECTRON_* or CHROMIUM_FLAGS variables defined here
    # Applications receive tuning via argv.json ONLY

    # ═══════════════════════════════════════════════════════════════
    # PER-APP CONFIGURATION GENERATION
    # ═══════════════════════════════════════════════════════════════
    # Generate argv.json for each configured app

    # This will be used by home-manager module
    # See: hosts/kernelcore/home/electron-apps.nix
  };
}
