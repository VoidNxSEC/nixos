{
  description = "NixOS Cache Server - Complete Enterprise-Grade Binary Cache Solution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
    }:
    let
      # Version info
      version = "1.0.0";

      # Supported systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

    in
    {
      # NixOS Modules
      nixosModules = {
        # Main cache server module
        cache-server = import ./modules/cache-server.nix;

        # API server module
        api-server = import ./modules/api-server.nix;

        # Monitoring module (Prometheus + Node Exporter)
        monitoring = import ./modules/monitoring.nix;

        # Complete setup (all modules combined)
        default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              self.nixosModules.cache-server
              self.nixosModules.api-server
              self.nixosModules.monitoring
            ];
          };
      };

      # NixOS Configuration examples
      nixosConfigurations = {
        # Example minimal cache server
        cache-server-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.cache-server
            {
              # Minimal configuration example
              services.nixos-cache-server = {
                enable = true;
                hostName = "cache.local";
                priority = 40;
              };

              # Basic system config
              boot.loader.grub.device = "/dev/sda";
              fileSystems."/" = {
                device = "/dev/sda1";
                fsType = "ext4";
              };
              system.stateVersion = "24.11";
            }
          ];
        };

        # Example full-featured cache server
        cache-server-full = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            {
              # Full configuration example
              services.nixos-cache-server = {
                enable = true;
                hostName = "cache.example.com";
                enableTLS = true;
                enableMonitoring = true;
                priority = 40;

                storage = {
                  maxSize = "100G";
                  gcKeepOutputs = true;
                  gcKeepDerivations = true;
                };
              };

              services.nixos-cache-api = {
                enable = true;
                port = 8080;
              };

              services.nixos-cache-monitoring = {
                enable = true;
                enablePrometheus = true;
                enableNodeExporter = true;
              };

              # Basic system config (customize for your system)
              boot.loader.grub.device = "/dev/sda";
              fileSystems."/" = {
                device = "/dev/sda1";
                fsType = "ext4";
              };
              networking.hostName = "nixos-cache";
              system.stateVersion = "24.11";
            }
          ];
        };
      };

      # Packages for different systems
      packages = flake-utils.lib.eachSystem supportedSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # API server package
          cache-api-server = pkgs.writeShellScriptBin "cache-api-server" (
            builtins.readFile ./cache-api-server.sh
          );

          # Bootstrap script package
          cache-bootstrap = pkgs.writeShellScriptBin "nixos-cache-bootstrap" (
            builtins.readFile ./nixos-cache-bootstrap.sh
          );

          # Dashboard build
          dashboard = pkgs.buildNpmPackage {
            pname = "nixos-cache-dashboard";
            version = version;

            src = ./.;

            npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update with actual hash

            buildPhase = ''
              npm run build
            '';

            installPhase = ''
              mkdir -p $out
              cp -r dist/* $out/
            '';
          };

          default = self.packages.${system}.cache-bootstrap;
        }
      );

      # Development shells
      devShells = flake-utils.lib.eachSystem supportedSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "nixos-cache-dev";

            buildInputs = with pkgs; [
              # Nix tools
              nixos-rebuild
              nix-serve

              # Development tools
              git
              curl
              jq

              # Node.js for dashboard development
              nodejs_20
              nodePackages.npm

              # Monitoring tools
              prometheus
              grafana

              # Utilities
              netcat
              openssl
            ];

            shellHook = ''
              echo "🚀 NixOS Cache Server Development Environment"
              echo "Version: ${version}"
              echo ""
              echo "Available commands:"
              echo "  - nixos-cache-bootstrap: Run the bootstrap script"
              echo "  - npm run dev: Start dashboard development server"
              echo "  - nix flake check: Validate flake"
              echo "  - nixos-rebuild switch --flake .#cache-server-full: Deploy full setup"
              echo ""
            '';
          };

          # CI/CD shell
          ci = pkgs.mkShell {
            name = "nixos-cache-ci";

            buildInputs = with pkgs; [
              nixos-rebuild
              git
              curl
              jq
            ];
          };
        }
      );

      # Checks for CI/CD
      checks = flake-utils.lib.eachSystem supportedSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Check that modules can be imported
          module-syntax = pkgs.runCommand "check-module-syntax" { } ''
            ${pkgs.nix}/bin/nix-instantiate --eval --strict ${./modules/cache-server.nix} --show-trace
            ${pkgs.nix}/bin/nix-instantiate --eval --strict ${./modules/api-server.nix} --show-trace
            ${pkgs.nix}/bin/nix-instantiate --eval --strict ${./modules/monitoring.nix} --show-trace
            touch $out
          '';
        }
      );

      # Templates for quick setup
      templates = {
        minimal = {
          path = ./templates/minimal;
          description = "Minimal NixOS cache server configuration";
        };

        full = {
          path = ./templates/full;
          description = "Full-featured NixOS cache server with monitoring";
        };

        default = self.templates.minimal;
      };

      # Hydra jobsets (for CI/CD)
      hydraJobs = {
        inherit (self) packages checks;
      };
    };
}
