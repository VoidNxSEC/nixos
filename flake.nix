{
  description = "home sweet home";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
        overlays = overlays;
      };

      # coleção de shells (definido abaixo em lib/shells.nix)
      shells = import ./lib/shells.nix { inherit pkgs; };
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;

      # nix develop .#python, .#cuda, .#infra, etc.
      devShells.${system} = shells;

      # imagens Docker e utilidades de build (definido abaixo em lib/packages.nix)
      packages.${system} = import ./lib/packages.nix { inherit pkgs self; };

      # checks que o CI pode rodar (fmt, flake check, builds importantes)
      checks.${system} = {
        fmt = pkgs.runCommand "fmt-check" { buildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
          nixfmt --check ${self}
          touch $out
        '';
        iso = self.packages.${system}.iso;
        vm = self.packages.${system}.vm-image;
        docker-app = self.packages.${system}.image-app;
      };

      nixosConfigurations = {
        kernelcore = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # Apply overlays to NixOS configuration
            {
              nixpkgs.overlays = overlays;
              nixpkgs.config.allowUnfree = true;
            }

            ./hosts/kernelcore/hardware-configuration.nix
            ./hosts/kernelcore/configuration.nix

            # Services
            ./modules/services/offload-server.nix
            # ./modules/services/laptop-offload-client.nix # DISABLED: Causes remote build failures when desktop offline
            ./modules/services/default.nix
            #./modules/services/scripts.nix
            ./modules/services/users/default.nix
            ./modules/services/users/claude-code.nix
            ./modules/services/users/actions.nix
            ./modules/services/users/gitlab-runner.nix
            ./modules/services/gpu-orchestration.nix

            # Applications (browsers and editors)
            ./modules/applications

            # Packages (declarative .deb, flatpak, etc.)
            ./modules/packages

            # Programs
            #./modules/programs/default.nix

            # ML
            ./modules/ml/llama.nix
            ./modules/ml/models-storage.nix
            ./modules/ml/ollama-gpu-manager.nix

            # System
            ./modules/system/memory.nix
            ./modules/system/nix.nix
            ./modules/system/services.nix
            ./modules/system/aliases.nix
            ./modules/system/ml-gpu-users.nix
            ./modules/system/binary-cache.nix
            ./modules/system/aliases.nix

            # Hardware (GPU, Trezor, WiFi)
            ./modules/hardware

            # Development
            ./modules/development/environments.nix
            ./modules/development/jupyter.nix
            ./modules/development/cicd.nix

            # Containers (Docker, Podman, NixOS containers)
            ./modules/containers

            # Virtualization (VMs, vmctl)
            ./modules/virtualization

            ./modules/secrets/sops-config.nix

            # Network
            ./modules/network/dns-resolver.nix
            ./modules/network/dns/default.nix
            ./modules/network/bridge.nix
            ./modules/network/vpn/nordvpn.nix

            # Shell (includes professional alias structure)
            ./modules/shell/default.nix
            ./modules/shell/gpu-flags.nix
            ./modules/shell/aliases

            # Secrets
            ./modules/secrets/sops-config.nix
            ./modules/secrets/api-keys.nix

            sops-nix.nixosModules.sops
            {
              # SOPS-nix configuration to use SSH host key
              sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            }

            # Debug (optional - comment out if not needed)
            # ./modules/debug/debug-init.nix
            # ./modules/debug/test-init.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.kernelcore = import ./hosts/kernelcore/home/home.nix;
              # Use a dedicated suffix for Home Manager backups to avoid collisions
              # with real dotfiles such as ~/.gtkrc-2.0.nix.
              home-manager.backupFileExtension = "hm-bak";
            }

            # Security modules LAST (highest priority to override other configs)
            ./modules/security

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
