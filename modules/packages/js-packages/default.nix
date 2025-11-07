{ lib, ... }:

with lib;

{
  imports = [
    # gemini-cli.nix removed - conflicts with js-packages.nix module structure
    # When needed, it should be refactored to work with the packageType defined in js-packages.nix
    ./js-packages.nix
  ];
}
