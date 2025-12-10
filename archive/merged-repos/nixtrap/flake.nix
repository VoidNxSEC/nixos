{
  description = "NixTrap - Unified NixOS Cache Server & Desktop Infrastructure with Distributed Build Support";

  inputs = {
    # Use nixos-25.05 as primary (from nixtrap2)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager integration
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Utilities
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-unstable,
      home-manager,
      flake-utils,
      ...
    }:
    let
      version = "2.0.0"; # Unified version
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Clean source filter
      cleanSrc = nixpkgs.lib.cleanSourceWith {
        src = ./.;
        filter =
          path: _:
          let
            base = builtins.baseNameOf path;
          in
          !(base == ".git" || base == "result" || base == "nixtrap1" || base == "nixtrap2");
      };

      # Helper to import modules from legacy dirs
      mkModulePath = subdir: module: ./${subdir}/${module};
    in
    {
      # =========================================================================
      # NixOS Modules (Unified)
      # =========================================================================
      nixosModules = {
        # Core modules (from unified modules/ directory)
        cache-server = import ./modules/cache-server.nix;
        api-server = import ./modules/api-server.nix;
        monitoring = import ./modules/monitoring.nix;

        # Desktop and offload modules
        cache-bucket = import ./modules/cache-bucket-setup.nix;
        nginx-proxy = import ./modules/nginx-module.nix;
        offload-server = import ./modules/offload-server.nix;
        offload-client = import ./modules/laptop-offload-client.nix;
        mcp-automation = import ./modules/mcp-offload-automation.nix;
        nar-server = import ./modules/nar-server.nix;

        # Preset combinations
        cache-full =
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

        desktop-full =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              self.nixosModules.cache-bucket
              self.nixosModules.nginx-proxy
              self.nixosModules.offload-client
              self.nixosModules.mcp-automation
            ];
          };

        # Ultimate hybrid setup
        hybrid-full =
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
              self.nixosModules.cache-bucket
              self.nixosModules.nginx-proxy
              self.nixosModules.offload-server
              self.nixosModules.mcp-automation
            ];
          };

        default = self.nixosModules.cache-full;
      };

      # =========================================================================
      # NixOS Configurations
      # =========================================================================
      nixosConfigurations = {
        # From nixtrap1: Minimal cache server
        cache-server-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.cache-server
            {
              services.nixos-cache-server = {
                enable = true;
                hostName = "cache.local";
                priority = 40;
              };

              boot.loader.grub.device = "/dev/sda";
              fileSystems."/" = {
                device = "/dev/sda1";
                fsType = "ext4";
              };
              system.stateVersion = "24.11";
            }
          ];
        };

        # From nixtrap1: Full cache server with monitoring
        cache-server-full = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.cache-full
            {
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

        # From nixtrap2: Production desktop with i3
        # NOTE: This config requires nixtrap2/ directory to be present
        # For new installs, use the 'hybrid' configuration instead
        voidnx = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self; };
          modules = [
            ./configurations/desktop/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.voidnx =
                { config, pkgs, ... }:
                {
                  home.stateVersion = "25.05";
                  programs.git = {
                    enable = true;
                    userName = "voidnxlab";
                    userEmail = "pina@voidnx.com";
                  };
                };
            }
          ];
        };

        # NEW: Hybrid configuration (desktop + cache server + offload)
        hybrid = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self; };
          modules = [
            self.nixosModules.hybrid-full
            ./configurations/hybrid/configuration.nix
            home-manager.nixosModules.home-manager
            {
              # Enable cache server features
              services.nixos-cache-server = {
                enable = true;
                hostName = "cache.local";
                enableTLS = true;
                priority = 40;
              };

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.voidnx =
                { config, pkgs, ... }:
                {
                  home.stateVersion = "25.05";
                  programs.git = {
                    enable = true;
                    userName = "voidnxlab";
                    userEmail = "pina@voidnx.com";
                  };
                };
            }
          ];
        };
      };

      # =========================================================================
      # Packages
      # =========================================================================
      packages =
        let
          mkPackagesForSystem =
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
              # Helper scripts (create simple versions if originals don't exist)
              cacheApiScript =
                if builtins.pathExists (mkModulePath "nixtrap1" "cache-api-server.sh") then
                  builtins.readFile (mkModulePath "nixtrap1" "cache-api-server.sh")
                else
                  ''
                    #!/usr/bin/env bash
                    echo "Cache API server placeholder"
                  '';

              bootstrapScript =
                if builtins.pathExists (mkModulePath "nixtrap1" "nixos-cache-bootstrap.sh") then
                  builtins.readFile (mkModulePath "nixtrap1" "nixos-cache-bootstrap.sh")
                else
                  ''
                    #!/usr/bin/env bash
                    echo "Bootstrap script placeholder"
                  '';
              cacheBootstrapPkg = pkgs.writeShellScriptBin "nixos-cache-bootstrap" bootstrapScript;
            in
            {
              # From nixtrap1
              cache-api-server = pkgs.writeShellScriptBin "cache-api-server" cacheApiScript;
              cache-bootstrap = cacheBootstrapPkg;

              default = cacheBootstrapPkg;
            };
        in
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = mkPackagesForSystem system;
          }) supportedSystems
        );

      # =========================================================================
      # Development Shells
      # =========================================================================
      devShells =
        let
          mkDevShellsForSystem =
            system:
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
            in
            {
              # Combined dev shell
              default = pkgs.mkShell {
                name = "nixtrap-unified-dev";

                buildInputs = with pkgs; [
                  # Nix tools
                  nixos-rebuild
                  nix-serve
                  nixfmt-rfc-style

                  # Development tools
                  git
                  curl
                  jq
                  wget

                  # Node.js for dashboard
                  nodejs_20
                  nodePackages.npm

                  # Monitoring
                  prometheus
                  grafana

                  # Utilities
                  netcat
                  openssl
                  rsync

                  # Terraform (essential for CI/CD)
                  terraform
                  terraform-ls
                ];

                shellHook = ''
                  echo "🚀 NixTrap Unified Development Environment"
                  echo "Version: ${version}"
                  echo ""
                  echo "Available configurations:"
                  echo "  - cache-server-minimal: Minimal binary cache"
                  echo "  - cache-server-full: Full cache with monitoring"
                  echo "  - voidnx: Desktop environment (i3 + offload)"
                  echo "  - hybrid: Desktop + cache + offload (best of both)"
                  echo ""
                  echo "Quick commands:"
                  echo "  - nix flake show: Show all outputs"
                  echo "  - nix flake check: Validate configuration"
                  echo "  - sudo nixos-rebuild switch --flake .#<config>: Deploy"
                  echo "  - nix fmt: Format Nix files"
                  echo ""
                '';
              };

              # CI shell
              ci = pkgs.mkShell {
                name = "nixtrap-ci";
                buildInputs = with pkgs; [
                  nixos-rebuild
                  git
                  curl
                  jq
                  terraform
                  shellcheck
                ];
              };
            };
        in
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = mkDevShellsForSystem system;
          }) supportedSystems
        );

      # =========================================================================
      # Formatter
      # =========================================================================
      formatter = builtins.listToAttrs (
        map (system: {
          name = system;
          value =
            let
              pkgs = import nixpkgs { inherit system; };
            in
            pkgs.nixfmt-rfc-style;
        }) supportedSystems
      );

      # =========================================================================
      # Checks
      # =========================================================================
      checks =
        let
          mkChecksForSystem =
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              # Format check
              nixfmt-tree =
                pkgs.runCommand "nixfmt-tree-check"
                  {
                    nativeBuildInputs = [
                      pkgs.nixfmt-rfc-style
                      pkgs.findutils
                      pkgs.diffutils
                      pkgs.coreutils
                    ];
                    src = cleanSrc;
                  }
                  ''
                    set -euo pipefail
                    cp -r "$src" source
                    chmod -R +w source
                    find source -name '*.nix' -print0 | xargs -0 -r nixfmt
                    diff -ru "$src" source > diff.log || diff_status=$?
                    if [ "''${diff_status:-0}" -ne 0 ]; then
                      if [ "''${diff_status:-0}" -eq 1 ]; then
                        echo 'nixfmt-tree detected formatting differences. Please run nixfmt-tree.' >&2
                        cat diff.log >&2
                        exit 1
                      else
                        cat diff.log >&2
                        exit "''${diff_status:-0}"
                      fi
                    fi
                    rm -f diff.log
                    mkdir -p "$out"
                    touch "$out"/check
                  '';
            };
        in
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = mkChecksForSystem system;
          }) supportedSystems
        );

      # =========================================================================
      # Templates
      # =========================================================================
      templates = {
        minimal = {
          path = ./templates/minimal-cache;
          description = "Minimal NixOS cache server configuration";
        };

        desktop = {
          path = ./templates/desktop;
          description = "Lightweight i3 desktop with distributed build support";
        };

        hybrid = {
          path = ./templates/hybrid;
          description = "Ultimate setup: desktop + cache server + distributed builds";
        };

        default = self.templates.minimal;
      };

      # =========================================================================
      # Hydra Jobs (only for x86_64-linux for now)
      # =========================================================================
      hydraJobs = {
        packages = {
          x86_64-linux = self.packages.x86_64-linux or { };
        };
        checks = {
          x86_64-linux = self.checks.x86_64-linux or { };
        };
      };
    };
}
