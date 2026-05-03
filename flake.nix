{
  description = "Platform-agnostic NixOS orchestrator. One config, every machine.";

  # You can disable any flake by commenting it out in your way, feel free to do so...

  inputs = {
    # ═══════════════════════════════════════════════════════════════
    # CORE SYSTEM
    # ═══════════════════════════════════════════════════════════════
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
    # WINDOW MANAGER
    # ═══════════════════════════════════════════════════════════════
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri - Scrollable Tiling Window Manager (niri-flake with NixOS module)
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # AI TOOLS
    # ═══════════════════════════════════════════════════════════════

    # ML Offload API - Multi-backend ML orchestration
    ml-ops-api = {
      url = "git+http://localhost:3002/voidnxlabs/ml-ops-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SecureLLM MCP - AI Agent Hub
    securellm-mcp = {
      url = "git+http://localhost:3002/voidnxlabs/securellm-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.spider-nix.follows = "spider-nix";
    };

    # SecureLLM Bridge
    securellm-bridge = {
      url = "git+http://localhost:3002/voidnxlabs/securellm-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swissknife = {
      url = "github:VoidNxSEC/swissknife";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spider-Nix
    spider-nix = {
      url = "git+http://localhost:3002/voidnxlabs/spider-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Arch-Analyzer
    arch-analyzer = {
      url = "git+http://localhost:3002/voidnxlabs/arch-analyzer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # neoland and adr-ledger use local paths — add to flakes/personal.nix for your setup
    neoland.url = "git+http://localhost:3002/voidnxlabs/neoland";
    neoland.inputs.nixpkgs.follows = "nixpkgs";

    adr-ledger.url = "git+http://localhost:3002/voidnxlabs/adr-ledger";
    adr-ledger.inputs.nixpkgs.follows = "nixpkgs";

    # SpookNix
    spooknix = {
      url = "git+http://localhost:3002/voidnxlabs/spooknix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Actions-TV (pendente migração para Forgejo)
    actions-tv = {
      url = "github:VoidNxSEC/actions-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native OS-level monitoring agent in Rust with Hyprland integration
    ai-agent-os = {
      url = "git+http://localhost:3002/voidnxlabs/ai-agent-os";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # PHANTOM - AI Forensic Intelligence Enterprise Grade Dynamic Pipeline (AI Forensics)
    # ═══════════════════════════════════════════════════════════════
    phantom = {
      url = "git+http://localhost:3002/voidnxlabs/phantom";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # SECURITY & SIEM TOOLS
    # ═══════════════════════════════════════════════════════════════
    owasaka = {
      url = "git+http://localhost:3002/voidnxlabs/owasaka";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        inherit overlays;
      };

      # coleção de shells (definido abaixo em lib/shells.nix)
      shells = import ./lib/shells.nix { inherit pkgs; };
    in
    {
      # Export modules for other flakes to use
      nixosModules.default = {
        imports = [ ./modules ];
        nixpkgs.overlays = overlays;
        nixpkgs.config.allowUnfree = true;
      };

      templates = {
        minimal = {
          path = ./templates/minimal;
          description = "Minimal NixOS configuration using this framework";
        };
        default = self.templates.minimal;
      };

      formatter.${system} = pkgs.nixfmt;

      # nix develop .#python, .#cuda, .#infra, etc.
      devShells.${system} = shells;

      # imagens Docker e utilidades de build (definido abaixo em lib/packages.nix)
      packages.${system} = import ./lib/packages.nix { inherit pkgs self inputs; };

      # nix run .#securellm-mcp
      apps.${system} = {
        securellm-mcp = {
          type = "app";
          meta = {
            description = "SecureLLM MCP Server";
            mainProgram = "securellm-mcp";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/securellm-mcp";
            source = "https://github.com/VoidNxSEC/securellm-mcp/archive/refs/tags/2.1.0.tar.gz";
            version = "2.1.0";
            broken = false;
          };
          program = "${inputs.securellm-mcp.packages.${system}.default}/bin/securellm-mcp";
        };
        securellm-bridge = {
          type = "app";
          meta = {
            description = "SecureLLM Bridge";
            mainProgram = "securellm-bridge";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/securellm-bridge";
            source = "https://github.com/VoidNxSEC/securellm-bridge/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.securellm-bridge.packages.${system}.default}/bin/securellm-bridge";
        };

        # SPIDER MCP
        spider-nix = {
          type = "app";
          meta = {
            description = "Spider-Nix";
            mainProgram = "spider-nix";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/spider-nix";
            source = "https://github.com/VoidNxSEC/spider-nix/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.spider-nix.packages.${system}.default}/bin/spider-nix";
        };

        # ARCH-ANALYZER
        arch-analyzer = {
          type = "app";
          meta = {
            description = "Arch-Analyzer";
            mainProgram = "arch-analyzer";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/arch-analyzer";
            source = "https://github.com/VoidNxSEC/arch-analyzer/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.arch-analyzer.packages.${system}.default}/bin/arch-analyzer";
        };

        # PHANTOM
        phantom = {
          type = "app";
          meta = {
            description = "Phantom";
            mainProgram = "phantom";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/phantom";
            source = "https://github.com/VoidNxSEC/phantom/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.phantom.packages.${system}.default}/bin/phantom";
        };

        # ACTIONS-TV
        actions-tv = {
          type = "app";
          meta = {
            description = "Actions-TV";
            mainProgram = "actions-tv";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/actions-tv";
            source = "https://github.com/VoidNxSEC/actions-tv/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.actions-tv.packages.${system}.default}/bin/actions-tv";
        };

        # AI-AGENT-OS
        ai-agent-os = {
          type = "app";
          meta = {
            description = "AI Agent OS";
            mainProgram = "ai-agent-os";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/ai-agent-os";
            source = "https://github.com/VoidNxSEC/ai-agent-os/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.ai-agent-os.packages.${system}.default}/bin/ai-agent-os";
        };

        # SPOOKNIX
        spooknix = {
          type = "app";
          meta = {
            description = "SpookNix";
            mainProgram = "spooknix";
            platforms = [ "x86_64-linux" ];
            maintainers = [ pkgs.lib.maintainers.kernelcore ];
            license = pkgs.lib.licenses.mit;
            homepage = "https://github.com/VoidNxSEC/spooknix";
            source = "https://github.com/VoidNxSEC/spooknix/archive/refs/tags/0.1.0.tar.gz";
            version = "0.1.0";
            broken = false;
          };
          program = "${inputs.spooknix.packages.${system}.default}/bin/spooknix";
        };
      };

      # Fast checks for CI/CD (heavy builds moved to packages)
      # Run with: nix flake check
      # For full builds use: nix build .#iso or .#vm-image
      checks.${system} = {
        # Format check (fast)
        fmt = pkgs.runCommand "fmt-check" { buildInputs = [ pkgs.nixfmt ]; } ''
          nixfmt --check ${self}
          touch $out
        '';
        # Package builds (relatively fast)
        mcp-server = self.packages.${system}.securellm-mcp;

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
              nixpkgs.overlays = overlays;
              nixpkgs.config.allowUnfree = true;
            }

            # ═══════════════════════════════════════════════════════════
            # HYPRLAND - Official Module (provides programs.hyprland)
            # ═══════════════════════════════════════════════════════════
            inputs.hyprland.nixosModules.default

            # ═══════════════════════════════════════════════════════════
            # NIRI - Official Module (provides programs.niri)
            # nixosModule disabled - testing if homeModule alone is sufficient
            # ═══════════════════════════════════════════════════════════
            # inputs.niri.nixosModules.niri

            # TODO: Isolate imports with default.nix file calling just ./hosts/kernelcore, and add the hosts/kernelcore/configuration.nix and hardware-configuration.nix files in default.nix imports, and remove the ./hosts/kernelcore/hardware-configuration.nix and ./hosts/kernelcore files from here
            # ═══════════════════════════════════════════════════════════
            # HOST-SPECIFIC CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            ./hosts/kernelcore/hardware-configuration.nix
            ./hosts/kernelcore
            ./hosts/kernelcore/configuration.nix

            # Kubernetes Orquestration # GEMINI: Here is the complete stack,
            #./modules/system/base.nix
            ./modules/containers/k3s-cluster.nix
            ./modules/network/cilium-cni.nix
            ./modules/containers/longhorn-storage.nix

            # ═══════════════════════════════════════════════════════════
            # ALL SYSTEM MODULES (auto-imported via modules/default.nix)
            # ═══════════════════════════════════════════════════════════
            self.nixosModules.default

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
              home-manager.sharedModules = [
                inputs.spooknix.homeManagerModules.default
                inputs.actions-tv.homeManagerModules.github-actions-waybar
              ];
              home-manager.users.kernelcore = import ./hosts/kernelcore/home/home.nix; # kernelcore is the actual user on this machine
              home-manager.backupFileExtension = null;
              home-manager.backupCommand = "${pkgs.coreutils}/bin/cp -a $1 $1.backup-$(date +%Y%m%d-%H%M%S)";
            }

            # ═══════════════════════════════════════════════════════════
            # SPOOKNIX - Privacy-first STT backend (Docker container)
            # ═══════════════════════════════════════════════════════════
            inputs.spooknix.nixosModules.default

            # ═══════════════════════════════════════════════════════════
            # SECURITY FINAL OVERRIDE (highest priority)
            # ═══════════════════════════════════════════════════════════
            ./sec/hardening.nix
            ./profiles/k8s-lab.nix
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

        k8s-node = nixpkgs.lib.nixosSystem {
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
              nixpkgs.overlays = overlays;
              nixpkgs.config.allowUnfree = true;
            }

            # ═══════════════════════════════════════════════════════════
            # HOST CONFIGURATION
            # ═══════════════════════════════════════════════════════════
            ./hosts/k8s-node/configuration.nix

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
              # home-manager.users.kernelcore = import ./hosts/kernelcore/home/home.nix; # TODO: Add home manager for k8s node
            }
          ];
        };
      };
    };
}
