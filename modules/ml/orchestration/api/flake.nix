{
  description = "ML Offload Manager - Unified REST API for ML model orchestration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build the Rust API binary
        ml-offload-api = pkgs.rustPlatform.buildRustPackage {
          pname = "ml-offload-api";
          version = "0.1.0";

          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            rustc
            cargo
          ];

          buildInputs = with pkgs; [
            openssl
            sqlite
          ];

          # Skip tests for now (require NVIDIA hardware)
          doCheck = false;

          meta = with pkgs.lib; {
            description = "ML Offload Manager REST API";
            homepage = "https://github.com/VoidNxSEC/nixos";
            license = licenses.mit;
            maintainers = [ "kernelcore" ];
          };
        };

      in
      {
        # Package output
        packages = {
          default = ml-offload-api;
          ml-offload-api = ml-offload-api;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rust-analyzer
            rustc
            cargo
            clippy
            rustfmt
            pkg-config
            openssl
            sqlite
          ];

          shellHook = ''
            echo "ML Offload API - Development Environment"
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo ""
            echo "Available commands:"
            echo "  cargo build --release  # Build release binary"
            echo "  cargo test             # Run tests"
            echo "  cargo clippy           # Run linter"
            echo "  cargo fmt              # Format code"
          '';
        };

        # Apps (for nix run)
        apps.default = {
          type = "app";
          program = "${ml-offload-api}/bin/ml-offload-api";
        };
      }
    )
    // {
      # NixOS module
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        with lib;
        let
          cfg = config.services.ml-offload-api;
        in
        {
          options.services.ml-offload-api = {
            enable = mkEnableOption "ML Offload Manager API";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The ml-offload-api package to use";
            };

            host = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "Host to bind the API server to";
            };

            port = mkOption {
              type = types.port;
              default = 9000;
              description = "Port to bind the API server to";
            };

            dataDir = mkOption {
              type = types.path;
              default = "/var/lib/ml-offload";
              description = "Directory for API data and state";
            };

            modelsPath = mkOption {
              type = types.path;
              default = "/var/lib/ml-models";
              description = "Path to ML models directory";
            };

            dbPath = mkOption {
              type = types.path;
              default = "/var/lib/ml-offload/registry.db";
              description = "Path to SQLite database";
            };

            corsEnabled = mkOption {
              type = types.bool;
              default = false;
              description = "Enable CORS for API requests";
            };

            logLevel = mkOption {
              type = types.enum [
                "error"
                "warn"
                "info"
                "debug"
                "trace"
              ];
              default = "info";
              description = "Logging level for the API";
            };

            openFirewall = mkOption {
              type = types.bool;
              default = false;
              description = "Open firewall port for the API";
            };
          };

          config = mkIf cfg.enable {
            # Create data directory
            systemd.tmpfiles.rules = [
              "d ${cfg.dataDir} 0755 ml-offload ml-offload -"
              "d ${cfg.modelsPath} 0755 ml-offload ml-offload -"
            ];

            # Create ml-offload user/group
            users.users.ml-offload = {
              isSystemUser = true;
              group = "ml-offload";
              description = "ML Offload API service user";
              home = cfg.dataDir;
            };

            users.groups.ml-offload = { };

            # Systemd service
            systemd.services.ml-offload-api = {
              description = "ML Offload Manager API";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              environment = {
                ML_OFFLOAD_HOST = cfg.host;
                ML_OFFLOAD_PORT = toString cfg.port;
                ML_OFFLOAD_DATA_DIR = cfg.dataDir;
                ML_OFFLOAD_MODELS_PATH = cfg.modelsPath;
                ML_OFFLOAD_DB_PATH = cfg.dbPath;
                ML_OFFLOAD_CORS_ENABLED = if cfg.corsEnabled then "true" else "false";
                RUST_LOG = "ml_offload_api=${cfg.logLevel}";
              };

              serviceConfig = {
                Type = "simple";
                User = "ml-offload";
                Group = "ml-offload";
                ExecStart = "${cfg.package}/bin/ml-offload-api";
                Restart = "on-failure";
                RestartSec = "5s";

                # Hardening
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [ cfg.dataDir ];
                ReadOnlyPaths = [ cfg.modelsPath ];

                # Resource limits
                MemoryMax = "2G";
                CPUQuota = "200%";
              };
            };

            # Firewall
            networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
          };
        };
    };
}
