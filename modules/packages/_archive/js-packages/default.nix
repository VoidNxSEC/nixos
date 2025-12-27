{ lib, ... }:

with lib;

{
  imports = [
    ./js-packages.nix
    ./gemini-cli.nix
  ];
}
