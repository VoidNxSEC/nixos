{ lib, ... }:

with lib;

{
  imports = [
    ./gemini-cli.nix
    ./js-packages.nix
  ];
}
