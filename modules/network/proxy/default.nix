# Network Proxy Module Aggregator
{ ... }:
{
  imports = [
    ./nginx-tailscale.nix
    ./tailscale-services.nix
  ];
}
