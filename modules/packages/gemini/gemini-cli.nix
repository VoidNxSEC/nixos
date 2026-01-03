{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

# ═══════════════════════════════════════════════════════════════
# GEMINI CLI - JS-PACKAGES CONFIGURATION
# ═══════════════════════════════════════════════════════════════
# Declarative configuration using js-packages modular architecture
# Combines: packaging + security (sandbox) + performance (wrapper)
# ═══════════════════════════════════════════════════════════════

{
  kernelcore.packages.js = {
    enable = true;

    packages.gemini-cli = {
      enable = true;
      version = "0.24.0-nightly.20251231.05049b5ab";

      # ═══════════════════════════════════════════════════════════
      # PACKAGING - Source from local storage (reproducible)
      # ═══════════════════════════════════════════════════════════
      source = {
        path = ./storage/gemini-cli-0.24.0-nightly.20251231.05049b5ab.tar.gz;
        sha256 = "CZQRDxV8omFWZ+RY7MEFXGohsoN8z1iiW//PxXgOr9E=";
      };

      # Use local valid lockfile to avoid upstream issues
      lockfile = ./package-lock.json;

      # Verified npmDepsHash for offline build
      npmDepsHash = "sha256-zlYWlhIs7R47UngrEBXRckpdKi61DAFOwmCCIEXWV1w=";

      # npm flags for build
      npmFlags = [
        "--legacy-peer-deps"
      ];

      # ═══════════════════════════════════════════════════════════
      # BUILD DEPENDENCIES
      # ═══════════════════════════════════════════════════════════
      nativeBuildInputs = with pkgs; [
        pkg-config
        python3
      ];

      buildInputs = with pkgs; [
        libsecret # Required for keytar (password management)
      ];

      # ═══════════════════════════════════════════════════════════
      # SECURITY - Bubblewrap Sandbox
      # ═══════════════════════════════════════════════════════════
      sandbox = {
        enable = true; # Enable bubblewrap isolation

        allowedPaths = [
          "$HOME/.config/gemini" # Allow Gemini config directory
          "$HOME/.cache/gemini" # Allow cache directory
          "$HOME/.local/share/gemini" # Allow data directory
          "/run/user" # Allow access to user runtime dir (DBus/Keyring)
        ];

        blockHardware = [
          "camera" # Block camera access
          "bluetooth" # Block bluetooth
          # Audio and GPU allowed for potential future features
        ];
      };

      # ═══════════════════════════════════════════════════════════
      # PERFORMANCE - Wrapper Configuration
      # ═══════════════════════════════════════════════════════════
      wrapper = {
        name = "gemini"; # Executable name
        executable = "lib/node_modules/@google/gemini-cli/bundle/gemini.js";

        environmentVariables = {
          # Node.js performance tuning
          NODE_OPTIONS = "--max-old-space-size=4096";

          # Disable telemetry
          DO_NOT_TRACK = "1";
        };

        extraArgs = [
          # Additional args can be added here
        ];
      };
    };
  };
}
