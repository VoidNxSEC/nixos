# System Module Aggregator
{ ... }:
{
  imports = [
    ./user-config.nix # Parameterized username + home paths
    ./aliases.nix
    ./binary-cache.nix
    ./emergency-monitor.nix
    ./memory.nix
    ./ml-gpu-users.nix
    ./nix.nix
    ./services.nix
    ./ssh-config.nix
    ./io-scheduler.nix # IO/latency tuning (enable-gated, default false)
  ];
}
