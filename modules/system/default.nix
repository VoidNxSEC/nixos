# System Module Aggregator
{ ... }:
{
  imports = [
    ./aliases.nix
    ./binary-cache.nix
    ./emergency-monitor.nix
    ./memory.nix
    ./ml-gpu-users.nix
    ./nix.nix
    ./services.nix
    ./ssh-config.nix
  ];
}
