{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

# ═══════════════════════════════════════════════════════════════
# GEMINI CLI & ANTIGRAVITY - CUSTOM PACKAGING
# ═══════════════════════════════════════════════════════════════
# Purpose: Individual customizable packaging for Gemini and Antigravity
# Engine: js-packages.nix (declarative, sandboxed, with FHS support)
# ═══════════════════════════════════════════════════════════════

let
  cfg = config.kernelcore.packages.custom;
in
{
  options.kernelcore.packages.custom = {
    gemini = {
      enable = mkEnableOption "Custom Gemini CLI build";

      sandbox = mkOption {
        type = types.bool;
        default = true;
        description = "Enable bubblewrap sandbox";
      };

      allowedPaths = mkOption {
        type = types.listOf types.str;
        default = [
          "$HOME/.gemini"
          "/etc/nixos"
        ];
        description = "Paths accessible from sandbox";
      };

      blockHardware = mkOption {
        type = types.listOf (
          types.enum [
            "gpu"
            "audio"
            "usb"
            "camera"
            "bluetooth"
          ]
        );
        default = [
          "camera"
          "bluetooth"
        ];
        description = "Hardware devices to block";
      };
    };

    antigravity = {
      enable = mkEnableOption "Custom Antigravity build";

      profile = mkOption {
        type = types.enum [
          "performance"
          "balanced"
          "minimal"
        ];
        default = "performance";
        description = "Performance profile for Electron";
      };

      enableCache = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tmpfs cache optimization";
      };
    };
  };

  config = mkMerge [
    # ═══════════════════════════════════════════════════════════════
    # GEMINI CLI - NPM PACKAGE BUILD
    # ═══════════════════════════════════════════════════════════════
    (mkIf cfg.gemini.enable {
      kernelcore.packages.js = {
        enable = true;

        packages.gemini-cli-custom = {
          enable = true;
          version = "0.24.0-preview.0";

          source = {
            url = "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.24.0-preview.0.tar.gz";
            sha256 = "sha256-7U8pAMmZ2ypddRBAlMolbLghdihEatLAJ46ZqZoESXg=";
          };

          # TODO: Calculate with: prefetch-npm-deps package-lock.json
          # Run in background, will update when ready
          npmDepsHash = "sha256-GDVoH+Tt70UjqqEh6PjVen3hDOXECfbtX+woeCLR2OQ=";

          npmFlags = [ "--legacy-peer-deps" ];
          makeCacheWritable = true;

          nativeBuildInputs = with pkgs; [
            python3
            pkg-config
          ];

          buildInputs = with pkgs; [
            libsecret
          ];

          # Sandboxing configuration
          sandbox = {
            enable = cfg.gemini.sandbox;
            allowedPaths = cfg.gemini.allowedPaths;
            blockHardware = cfg.gemini.blockHardware;
          };

          # Wrapper configuration
          wrapper = {
            name = "gemini-custom";
            executable = "packages/cli/dist/index.js";
            environmentVariables = {
              GEMINI_HOME = "$HOME/.gemini";
              NODE_ENV = "production";
            };
          };
        };
      };

      # Shell alias
      environment.shellAliases = {
        gemini = "gemini-custom";
      };
    })

    # ═══════════════════════════════════════════════════════════════
    # ANTIGRAVITY - PREBUILT ELECTRON APP
    # ═══════════════════════════════════════════════════════════════
    (mkIf cfg.antigravity.enable {
      # Use FHS environment for better compatibility
      environment.systemPackages = [
        (pkgs.buildFHSEnv {
          name = "antigravity-custom";

          targetPkgs =
            pkgs: with pkgs; [
              alsa-lib
              at-spi2-atk
              at-spi2-core
              atk
              cairo
              cups
              dbus
              expat
              fontconfig
              freetype
              gdk-pixbuf
              glib
              gtk3
              libdrm
              libnotify
              libsecret
              libuuid
              libxkbcommon
              mesa
              nspr
              nss
              pango
              systemd
              xorg.libX11
              xorg.libXScrnSaver
              xorg.libXcomposite
              xorg.libXcursor
              xorg.libXdamage
              xorg.libXext
              xorg.libXfixes
              xorg.libXi
              xorg.libXrandr
              xorg.libXrender
              xorg.libXtst
              xorg.libxcb
              xorg.libxshmfence
            ];

          profile = ''
            export ANTIGRAVITY_HOME="$HOME/.config/Antigravity"
            export ELECTRON_TRASH=gio

            # Performance tuning based on profile
            ${
              if cfg.antigravity.profile == "performance" then
                ''
                  export ELECTRON_ENABLE_LOGGING=0
                  export ELECTRON_NO_ATTACH_CONSOLE=1
                ''
              else if cfg.antigravity.profile == "balanced" then
                ''
                  export ELECTRON_ENABLE_LOGGING=1
                ''
              else
                ''
                  export ELECTRON_ENABLE_LOGGING=1
                  export ELECTRON_ENABLE_STACK_DUMPING=1
                ''
            }
          '';

          runScript = pkgs.writeShellScript "antigravity-custom-wrapper" ''
            set -e

            ANTIGRAVITY_VERSION="1.13.3"
            INSTALL_DIR="$HOME/.local/share/antigravity-custom"
            MARKER="$INSTALL_DIR/.installed-$ANTIGRAVITY_VERSION"

            # Auto-install on first run
            if [ ! -f "$MARKER" ]; then
              echo "🔧 Antigravity: First run installation..."
              mkdir -p "$INSTALL_DIR"
              cd "$INSTALL_DIR"

              echo "📦 Downloading Antigravity v$ANTIGRAVITY_VERSION..."
              ${pkgs.curl}/bin/curl -L "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.13.3-4533425205018624/linux-x64/Antigravity.tar.gz" \
                | ${pkgs.gnutar}/bin/tar xz

              touch "$MARKER"
              echo "✅ Antigravity installed at $INSTALL_DIR"
            fi

            # Execute Antigravity
            cd "$INSTALL_DIR/antigravity"
            exec ./antigravity "$@"
          '';

          meta = {
            description = "Antigravity Custom Build (FHS)";
            platforms = lib.platforms.linux;
          };
        })
      ];

      # Cache optimization (if enabled)
      systemd.user.tmpfiles.rules = mkIf cfg.antigravity.enableCache [
        "d %t/app-cache/antigravity-custom 0700 - - -"
      ];

      systemd.user.services.antigravity-custom-cache = mkIf cfg.antigravity.enableCache {
        description = "Setup Antigravity Custom cache in tmpfs";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "setup-antigravity-custom-cache" ''
            CACHE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/app-cache/antigravity-custom"
            CONFIG="$HOME/.config/Antigravity"

            mkdir -p "$CACHE_DIR" "$CONFIG"

            # Backup existing cache
            [ -d "$CONFIG/Cache" ] && [ ! -L "$CONFIG/Cache" ] && mv "$CONFIG/Cache" "$CONFIG/Cache.bak"

            # Create symlinks to tmpfs
            ln -sf "$CACHE_DIR" "$CONFIG/Cache"
            mkdir -p "$CACHE_DIR-code"
            ln -sf "$CACHE_DIR-code" "$CONFIG/Code Cache"

            echo "✓ Antigravity custom cache → tmpfs"
          '';
        };
      };

      # Shell alias
      environment.shellAliases = {
        antigravity = "antigravity-custom";
      };
    })
  ];
}
