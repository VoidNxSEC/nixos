{
  description = "SecureLLM Bridge - Secure communication with LLMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        };

        buildInputs = with pkgs; [
          openssl
          pkg-config
        ];

        nativeBuildInputs = with pkgs; [
          rustToolchain
          cargo
          rustc
        ];

      in
      {
        packages = {
          default = self.packages.${system}.securellm;

          securellm = pkgs.rustPlatform.buildRustPackage {
            pname = "securellm";
            version = "0.1.0";

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            inherit buildInputs nativeBuildInputs;

            meta = with pkgs.lib; {
              description = "Secure bridge for LLM communication";
              homepage = "https://github.com/securellm/bridge";
              license = with licenses; [
                mit
                asl20
              ];
              maintainers = [ ];
            };
          };
        };

        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          nativeBuildInputs =
            nativeBuildInputs
            ++ (with pkgs; [
              # Development tools
              cargo-watch
              cargo-edit
              cargo-audit
              cargo-outdated

              # Testing and debugging
              gdb
              valgrind

              # Documentation
              mdbook

              # Container tools
              docker
              podman
            ]);

          shellHook = ''
            echo "🔒 SecureLLM Bridge Development Environment"
            echo "Rust version: $(rustc --version)"
            echo ""
            echo "Available commands:"
            echo "  cargo build          - Build the project"
            echo "  cargo test           - Run tests"
            echo "  cargo run --bin securellm -- --help"
            echo ""
            echo "For NixOS users: Configuration is in /nix/module.nix"
          '';

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };

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
            cfg = config.services.securellm;
          in
          {
            options.services.securellm = {
              enable = mkEnableOption "SecureLLM Bridge service";

              package = mkOption {
                type = types.package;
                default = self.packages.${system}.securellm;
                description = "The SecureLLM package to use";
              };

              user = mkOption {
                type = types.str;
                default = "securellm";
                description = "User account under which securellm runs";
              };

              group = mkOption {
                type = types.str;
                default = "securellm";
                description = "Group under which securellm runs";
              };

              configFile = mkOption {
                type = types.path;
                description = "Path to the configuration file";
              };

              dataDir = mkOption {
                type = types.path;
                default = "/var/lib/securellm";
                description = "Directory for securellm data";
              };
            };

            config = mkIf cfg.enable {
              users.users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
                home = cfg.dataDir;
                createHome = true;
              };

              users.groups.${cfg.group} = { };

              systemd.services.securellm = {
                description = "SecureLLM Bridge";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];

                serviceConfig = {
                  Type = "simple";
                  User = cfg.user;
                  Group = cfg.group;
                  ExecStart = "${cfg.package}/bin/securellm --config ${cfg.configFile}";
                  Restart = "on-failure";
                  RestartSec = "5s";

                  # Security hardening
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectSystem = "strict";
                  ProtectHome = true;
                  ReadWritePaths = [ cfg.dataDir ];
                  ProtectKernelTunables = true;
                  ProtectKernelModules = true;
                  ProtectControlGroups = true;
                  RestrictAddressFamilies = [
                    "AF_INET"
                    "AF_INET6"
                    "AF_UNIX"
                  ];
                  RestrictNamespaces = true;
                  LockPersonality = true;
                  MemoryDenyWriteExecute = true;
                  RestrictRealtime = true;
                  RestrictSUIDSGID = true;
                  PrivateDevices = true;
                };
              };
            };
          };
      }
    );
}
