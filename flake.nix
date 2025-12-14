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
      url = "github:VoidNxSEC/cognitive-vault";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vmctl = {
      url = "github:VoidNxSEC/vmctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spider-nix = {
      url = "github:VoidNxSEC/spider-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    i915-governor = {
      url = "github:VoidNxSEC/i915-governor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    swissknife = {
      url = "git+file:///home/kernelcore/dev/projects/swissknife";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════
    # PHANTOM - AI Document Intelligence Toolkit
    # ═══════════════════════════════════════════════════════════════
    phantom = {
      url = "git+file:///home/kernelcore/dev/Projects/phantom";
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
        overlays = overlays ++ [
          (final: prev: {
            securellm-mcp = inputs.securellm-mcp.packages.${system}.default;
            securellm-bridge = inputs.securellm-bridge.packages.${system}.default;
            swissknife-tools = inputs.swissknife.packages.${system};
            phantom = inputs.phantom.packages.${system}.default;
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
            # Apply overlays to NixOS configuration
            {
              nixpkgs.overlays = overlays ++ [
                (final: prev: {
                  securellm-mcp = inputs.securellm-mcp.packages.${system}.default;
                  securellm-bridge = inputs.securellm-bridge.packages.${system}.default;
                  swissknife-tools = inputs.swissknife.packages.${system};
                  phantom = inputs.phantom.packages.${system}.default;
                })
              ];
              nixpkgs.config.allowUnfree = true;
            }

            ./hosts/kernelcore/hardware-configuration.nix
            ./hosts/kernelcore/configuration.nix

            # Services
            ./modules/services/offload-server.nix
            ./modules/services/laptop-offload-client.nix
            ./modules/services/config-auditor.nix
            ./modules/services/default.nix
            ./modules/services/scripts.nix # Shell aliases for ML containers (pytorch, tgi, etc)
            ./modules/services/users/default.nix
            ./modules/services/users/claude-code.nix
            ./modules/services/users/actions.nix
            ./modules/services/users/gitlab-runner.nix
            ./modules/services/gpu-orchestration.nix
            ./modules/services/mosh.nix # Mosh server for mobile shell (Blink Shell iOS)
            ./modules/services/mobile-workspace.nix # Isolated workspace for mobile access
            ./modules/services/mcp-server.nix # SecureLLM MCP Server
            #./modules/services/rsync-server.nix # DISABLED: File doesn't exist

            # Enable SecureLLM MCP Server Daemon (runs on boot)
            {
              services.securellm-mcp = {
                enable = true;
                daemon.enable = true;
                daemon.logLevel = "INFO";
              };
            }

            # Desktop environments
            ./modules/desktop

            # Applications (browsers and editors)
            ./modules/applications

            # Audio
            ./modules/audio/video-production.nix

            # Packages (declarative .deb, flatpak, etc.)
            ./modules/packages

            # Programs
            ./modules/programs/default.nix

            ./modules/desktop/yazi/yazi.nix

            # ML - Machine Learning Infrastructure (modular, see modules/ml/README.md)
            ./modules/ml

            # System
            ./modules/system/memory.nix
            ./modules/system/nix.nix
            ./modules/system/services.nix
            ./modules/system/aliases.nix
            ./modules/system/io-scheduler.nix # TICKET #IO-992: Optimized IO & ZRAM
            ./modules/system/ml-gpu-users.nix
            ./modules/system/binary-cache.nix
            ./modules/system/ssh-config.nix # SSH client configuration

            # Modules moved to knowledge/ (archived)
            # ./modules/system/sudo-claude-code.nix

            # Hardware (GPU, Trezor, WiFi)
            ./modules/hardware

            # Development
            ./modules/development/environments.nix
            ./modules/development/claude-profiles.nix # TEMP DISABLED for troubleshooting
            ./modules/development/jupyter.nix
            ./modules/development/cicd.nix

            # Containers (Docker, Podman, NixOS containers)
            ./modules/containers

            # Virtualization (VMs, vmctl)
            ./modules/virtualization

            # Tools Suite (unified CLI)
            ./modules/tools
            {
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
              };
            }

            ./modules/secrets/sops-config.nix

            # Network
            ./modules/network/dns-resolver.nix
            ./modules/network/dns/default.nix
            ./modules/network/bridge.nix
            ./modules/network/vpn/nordvpn.nix
            ./modules/network/monitoring/tailscale-monitor.nix
            ./modules/network/vpn/tailscale.nix
            ./modules/network/vpn/tailscale-laptop.nix
            ./modules/network/vpn/tailscale-desktop.nix
            ./modules/network/proxy/nginx-tailscale.nix # NGINX reverse proxy for Tailscale
            ./modules/network/security/firewall-zones.nix # nftables firewall zones

            # Shell (includes professional alias structure)
            ./modules/shell/default.nix
            ./modules/shell/gpu-flags.nix
            ./modules/shell/aliases

            # Secrets
            ./modules/secrets/sops-config.nix
            ./modules/secrets/api-keys.nix
            ./modules/secrets/aws-bedrock.nix
            ./modules/secrets/tailscale.nix # Tailscale secrets management

            sops-nix.nixosModules.sops
            {
              # SOPS-nix configuration to use SSH host key
              sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            }

            # Debug (optional - comment out if not needed)
            # Debug
            ./modules/debug/default.nix
            {
              kernelcore.swissknife.enable = true;
            }

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                nix-colors = inputs.nix-colors;
              };
              home-manager.users.kernelcore = import ./hosts/kernelcore/home/home.nix;
              # Use custom backup command with timestamp to avoid conflicts
              home-manager.backupFileExtension = null;
              home-manager.backupCommand = "${pkgs.coreutils}/bin/cp -a $1 $1.backup-$(date +%Y%m%d-%H%M%S)";
            }

            # Security modules LAST (highest priority to override other configs)
            ./modules/security
            #./dev/default.nix

            # SOC - Security Operations Center (NSA-level infrastructure)
            ./modules/soc
            {
              kernelcore.soc = {
                enable = true;
                profile = "standard"; # minimal | standard | enterprise
                retention.days = 30;

                # Explicitly disable Suricata for now
                ids.suricata.enable = false;

                # Alert configuration (customize as needed)
                alerting = {
                  enable = true;
                  minSeverity = "medium";
                };
              };
            }

            ./sec/hardening.nix # Final override
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
