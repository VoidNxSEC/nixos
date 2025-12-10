{
  description = "Workflow Terraform com Nix Flakes e cache remoto";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.terraform_1_6;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.terraform_1_6
            pkgs.git
            pkgs.curl
            pkgs.jq
          ];

          shellHook = ''
            echo "🚀 Ambiente Terraform pronto!"
            terraform version
          '';
        };
      }
    );
}
