{
  description = "Minimal NixOS Cache Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixtrap.url = "github:yourusername/nixtrap";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixtrap,
    }:
    {
      nixosConfigurations.cache-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixtrap.nixosModules.cache-server

          {
            # Import your hardware configuration
            imports = [ ./hardware-configuration.nix ];

            # Cache server configuration
            services.nixos-cache-server = {
              enable = true;
              hostName = "cache.local";
              priority = 40;
            };

            # Basic system configuration
            boot.loader.grub.device = "/dev/sda";
            networking.hostName = "nixos-cache";
            time.timeZone = "UTC";

            # User configuration
            users.users.admin = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "changeme";
            };

            # SSH access
            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "no";
            };

            system.stateVersion = "24.11";
          }
        ];
      };
    };
}
