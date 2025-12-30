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
    # HYPRLAND - Official Flake (replaces custom overlay)
    # ═══════════════════════════════════════════════════════════════
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    # ═══════════════════════════════════════════════════════════════
    # PROJECTS - Independent flakes (local development) - Development Tools & Infrastructure
    # ═══════════════════════════════════════════════════════════════
    # ML Offload API - Multi-backend ML orchestration
    ml-offload-api = {
      url = "git+file:///home/kernelcore/dev/projects/ml-offload-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    docker-hub = {
      url = "git+file:///home/kernelcore/dev/projects/docker-hub";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Notion → Markdown/JSON exporter for platform migration
    notion-exporter = {
      url = "git+file:///home/kernelcore/dev/projects/notion-exporter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Declarative mini-datacenter with Docker+Nix synergy
    nixos-hyperlab = {
      url = "git+file:///home/kernelcore/dev/projects/nixos-hyperlab";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TUI debug pipeline with semantic filtering & LLM analysis
    shadow-debug-pipeline = {
      url = "git+file:///home/kernelcore/dev/projects/shadow-debug-pipeline";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native OS-level monitoring agent in Rust with Hyprland integration
    ai-agent-os = {
      url = "git+file:///home/kernelcore/dev/projects/ai-agent-os";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ═══════════════════════════════════════════════════════════════
    # PHANTOM - AI Forensic Intelligence Enterprise Grade Dynamic Pipeline (AI Forensics)
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

      # Fast checks for CI/CD (heavy builds moved to packages)
      # Run with: nix flake check
      # For full builds use: nix build .#iso or .#vm-image
      checks.${system} = {
        # Format check (fast)
        fmt = pkgs.runCommand "fmt-check" { buildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
          nixfmt --check ${self}
          touch $out
        '';

        # Package builds (relatively fast)
        mcp-server = self.packages.${system}.securellm-mcp;
        llm-bridge = self.packages.${system}.securellm-bridge;

        # NOTE: Heavy builds (iso, vm, docker-app) removed from checks for performance
        # These are still available via packages: nix build .#iso, .#vm-image, .#image-app
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
                inputs.hyprland.overlays.default # Official Hyprland overlay
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
            # HYPRLAND - Official Module (provides programs.hyprland)
            # ═══════════════════════════════════════════════════════════
            inputs.hyprland.nixosModules.default

            # TODO: Isolate imports with default.nix file calling just ./hosts/kernelcore, and add the hosts/kernelcore/configuration.nix and hardware-configuration.nix files in default.nix imports, and remove the ./hosts/kernelcore/hardware-configuration.nix and ./hosts/kernelcore files from here
            # ═══════════════════════════════════════════════════════════
            # HOST-SPECIFIC CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            ./hosts/kernelcore/hardware-configuration.nix
            ./hosts/kernelcore
            ./hosts/kernelcore/configuration.nix

            # ═══════════════════════════════════════════════════════════
            # ALL SYSTEM MODULES (auto-imported via modules/default.nix)
            # ═══════════════════════════════════════════════════════════
            ./modules

            # NOTE: Feature flags and service configuration moved to:
            #       ./hosts/kernelcore/configuration.nix (lines 400-427)

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
            # Add sops-nix module for user configurations that depend on it
            sops-nix.nixosModules.sops
            {
              sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            }
            ./hosts/kernelcore
          ];
        };
      };

    };
}
