{
  description = "A basic NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # Or your preferred stable channel
    home-manager.url = "github:nix-community/home-manager/release-25.05"; # If using Home Manager
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Ensure Home Manager uses the same nixpkgs
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      cleanSrc = nixpkgs.lib.cleanSourceWith {
        src = ./.;
        filter =
          path: _:
          let
            base = builtins.baseNameOf path;
          in
          !(base == ".git" || base == "result");
      };
    in
    {
      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
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
        }
      );

      nixosConfigurations.voidnx = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Or your system architecture
        specialArgs = { inherit self; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.voidnx = import ./home.nix;
          }
        ];
      };
    };
}
