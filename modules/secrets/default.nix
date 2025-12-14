# Secrets Module Aggregator
{ ... }:
{
  imports = [
    ./api-keys.nix
    ./aws-bedrock.nix
    ./sops-config.nix
    ./tailscale.nix
  ];
}
