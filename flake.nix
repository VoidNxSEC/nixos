{
  description = "home sweet home";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-colors.url = "github:misterio77/nix-colors";

    # ═══════════════════════════════════════════════════════════════
    # PROJECTS - Independent flakes on GitHub
    # ═══════════════════════════════════════════════════════════════
    securellm-mcp = {
      url = "git+file:///home/kernelcore/dev/projects/securellm-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    securellm-bridge = {
      url = "git+file:///home/kernelcore/dev/projects/securellm-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cognitive-vault = {
      url = "git+file:///home/kernelcore/dev/projects/cognitive-vault";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vmctl = {
      url = "git+file:///home/kernelcore/dev/projects/vmctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spider-nix = {
      url = "git+file:///home/kernelcore/dev/projects/spider-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    i915-governor = {
      url = "git+file:///home/kernelcore/dev/projects/i915-governor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    swissknife = {
      url = "git+file:///home/kernelcore/dev/projects/swissknife";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arch-analyzer = {
      url = "git+file:///home/kernelcore/dev/projects/arch-analyzer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # PHANTOM - AI Document Intelligence Toolkit
    # ═══════════════════════════════════════════════════════════════
    phantom = {
      url = "git+file:///home/kernelcore/dev/projects/phantom";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # SECURITY & SIEM TOOLS
    # ═══════════════════════════════════════════════════════════════
    owasaka = {
      url = "git+file:///home/kernelcore/dev/projects/O.W.A.S.A.K.A.";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Note: mlx-mcp uses rust-overlay which conflicts with nixpkgs.follows
    # Commented for now, can be enabled when needed for Apple Silicon development
    # mlx-mcp = {
    #   url = "git+file:///home/kernelcore/dev/projects/mlx-mcp";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # Import overlays from organized modules
      overlays = import ./overlays;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = overlays ++ [
          (final: prev: {
            securellm-mcp = inputs.securellm-mcp.packages.${system}.default;
            securellm-bridge = inputs.securellm-bridge.packages.${system}.default;
            swissknife-tools = inputs.swissknife.packages.${system};
            phantom = inputs.phantom.packages.${system}.default;
            arch-analyzer = inputs.arch-analyzer.packages.${system}.default;
          })
        ];
      };

      # coleção de shells (definido abaixo em lib/shells.nix)
      shells = import ./lib/shells.nix { inherit pkgs; };
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;

      # nix develop .#python, .#cuda, .#infra, etc.
      devShells.${system} = shells;

      # imagens Docker e utilidades de build (definido abaixo em lib/packages.nix)
      packages.${system} = import ./lib/packages.nix { inherit pkgs self inputs; };

      # nix run .#securellm-mcp
      apps.${system} = {
        securellm-mcp = {
          type = "app";
          program = "${self.packages.${system}.securellm-mcp}/bin/securellm-mcp";
        };
        securellm-bridge = {
          type = "app";
          program = "${self.packages.${system}.securellm-bridge}/bin/securellm-bridge";
        };
      };

      # checks que o CI pode rodar (fmt, flake check, builds importantes)
      checks.${system} = {
        fmt = pkgs.runCommand "fmt-check" { buildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
          nixfmt --check ${self}
          touch $out
        '';
        iso = self.packages.${system}.iso;
        vm = self.packages.${system}.vm-image;
        docker-app = self.packages.${system}.image-app;
        mcp-server = self.packages.${system}.securellm-mcp;
        llm-bridge = self.packages.${system}.securellm-bridge;

      };

      nixosConfigurations = {
        kernelcore = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            colors = inputs.nix-colors;
          };
          modules = [
            # ═══════════════════════════════════════════════════════════
            # NIXPKGS CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            {
              nixpkgs.overlays = overlays ++ [
                (final: prev: {
                  securellm-mcp = inputs.securellm-mcp.packages.${system}.default;
                  securellm-bridge = inputs.securellm-bridge.packages.${system}.default;
                  swissknife-tools = inputs.swissknife.packages.${system};
                  phantom = inputs.phantom.packages.${system}.default;
                  arch-analyzer = inputs.arch-analyzer.packages.${system}.default;
                })
              ];
              nixpkgs.config.allowUnfree = true;
            }

            # ═══════════════════════════════════════════════════════════
            # HOST-SPECIFIC CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            ./hosts/kernelcore/hardware-configuration.nix
            ./hosts/kernelcore/configuration.nix

            # ═══════════════════════════════════════════════════════════
            # ALL SYSTEM MODULES (auto-imported via modules/default.nix)
            # ═══════════════════════════════════════════════════════════
            ./modules

            # ═══════════════════════════════════════════════════════════
            # FEATURE FLAGS & CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            {
              # SecureLLM MCP Server
              services.securellm-mcp = {
                enable = true;
                daemon.enable = true;
                daemon.logLevel = "INFO";
              };

              # Tools Suite
              kernelcore.tools = {
                enable = true;
                intel.enable = true;
                secops.enable = true;
                nix-utils.enable = true;
                dev.enable = true;
                secrets.enable = true;
                diagnostics.enable = true;
                llm.enable = true;
                mcp.enable = true;
                arch-analyzer.enable = true;
              };

              # Swissknife Debug Tools
              kernelcore.swissknife.enable = true;
            }

            # ═══════════════════════════════════════════════════════════
            # SOPS-NIX SECRETS MANAGEMENT
            # ═══════════════════════════════════════════════════════════
            sops-nix.nixosModules.sops
            {
              sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            }

            # ═══════════════════════════════════════════════════════════
            # HOME-MANAGER
            # ═══════════════════════════════════════════════════════════
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                nix-colors = inputs.nix-colors;
              };
              home-manager.users.kernelcore = import ./hosts/kernelcore/home/home.nix;
              home-manager.backupFileExtension = null;
              home-manager.backupCommand = "${pkgs.coreutils}/bin/cp -a $1 $1.backup-$(date +%Y%m%d-%H%M%S)";
            }

            # ═══════════════════════════════════════════════════════════
            # SECURITY FINAL OVERRIDE (highest priority)
            # ═══════════════════════════════════════════════════════════
            ./sec/hardening.nix
          ];
        };

        kernelcore-iso = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (
              { modulesPath, ... }:
              {
                imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
              }
            )
            ./hosts/kernelcore
          ];
        };
      };

    };
}
