# Secrets Module Aggregator
{ ... }:
{
  imports = [
    ./gcp-ml.nix
    ./aws-bedrock.nix
    ./k8s.nix
    ./sops-config.nix
    ./tailscale.nix
    ./grok.nix
  ];
}
