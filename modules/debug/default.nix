# Debug Module Aggregator
{ ... }:
{
  imports = [
    ./debug-init.nix
    ./test-init.nix
    ./tools-integration.nix
  ];
}
