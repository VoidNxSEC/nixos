# All .deb packages configuration
# This file merges all package configurations from the packages/ directory
{
  imports = [
    ./packages/cursor.nix
    ./packages/protonvpn.nix
    ./packages/protonpass.nix
  ];
}
