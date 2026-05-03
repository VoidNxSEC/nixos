{
  description = "Minimal NixOS configuration using VoidNxSEC Framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    void-nixos.url = "github:VoidNxSEC/nixos"; # The main repo
  };

  outputs =
    {
      self,
      nixpkgs,
      void-nixos,
      ...
    }@inputs:
    {
      nixosConfigurations.minimal = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Import the core framework
          void-nixos.nixosModules.default

          # Your machine configuration
          ./configuration.nix

          # Basic hardware config (usually generated)
          ./hardware-configuration.nix
        ];
      };
    };
}
