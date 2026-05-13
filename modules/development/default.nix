# Development Module Aggregator
{ ... }:
{
  imports = [
    ./cicd.nix
    ./claude-profiles.nix
    ./environments.nix
    ./jupyter.nix
  ];
}
