{
  description = "NixTrap Desktop Configuration Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixtrap.url = "github:yourusername/nixtrap";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixtrap,
      home-manager,
      ...
    }:
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import your hardware configuration
          ./hardware-configuration.nix

          # Import nixtrap desktop modules
          nixtrap.nixosModules.desktop-full

          # Home manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.youruser = import ./home.nix;
          }

          # Your custom config
          ./configuration.nix
        ];
      };
    };
}
