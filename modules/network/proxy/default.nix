# Network Proxy Module Aggregator
{ ... }:
{
  imports = [
    ./nginx-public.nix
    ./nginx-tailscale.nix
    ./tailscale-services.nix
  ];
}
