# Secrets Module Aggregator
{ ... }:
{
  imports = [
    ./api-keys.nix
    ./aws-bedrock.nix
    ./k8s.nix
    ./sops-config.nix
    ./tailscale.nix
    ./grok.nix
    ./anthropic.nix
  ];
}
