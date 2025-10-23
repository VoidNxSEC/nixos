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
            ./modules/services/default.nix
            #./modules/services/scripts.nix
            ./modules/services/users/default.nix
            ./modules/services/users/claude-code.nix
            ./modules/services/users/actions.nix

            # Applications
            ./modules/applications/firefox-privacy.nix
            ./modules/applications/brave-secure.nix
            ./modules/applications/vscodium-secure.nix
            ./modules/applications/vscode-secure.nix

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

            # Hardware
            #./modules/hardware/intel.nix
            ./modules/hardware/nvidia.nix
            ./modules/hardware/trezor.nix

            # Development
            ./modules/development/environments.nix
            ./modules/development/jupyter.nix
            ./modules/development/cicd.nix

            # Containers
            ./modules/containers/docker.nix
            ./modules/containers/nixos-containers.nix

            # Virtualization
            ./modules/virtualization/vms.nix

            ./modules/secrets/sops-config.nix

            # Network
            ./modules/network/dns-resolver.nix
            ./modules/network/dns/default.nix
            ./modules/network/vpn/nordvpn.nix

            # Shell
            ./modules/shell/default.nix
            ./modules/shell/gpu-flags.nix
            ./modules/shell/aliases/docker-build.nix

            # Secrets
            ./modules/secrets/sops-config.nix
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
              home-manager.backupFileExtension = "nix";
            }

            # Security modules LAST (highest priority to override other configs)
            ./modules/security/boot.nix
            ./modules/security/compiler-hardening.nix
            ./modules/security/hardening.nix
            ./modules/security/network.nix
            ./modules/security/aide.nix
            ./modules/security/pam.nix
            ./modules/security/ssh.nix
            ./modules/security/clamav.nix
            ./modules/security/nix-daemon.nix
            ./modules/security/kernel.nix
            ./modules/security/packages.nix
            ./modules/security/audit.nix

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
