# Secrets Module Aggregator
# Each module reads from its corresponding SOPS file in /etc/nixos/secrets/
{ ... }:
{
  imports = [
    # SOPS configuration (must be first)
    ./sops-config.nix

    # API Keys and credentials (alphabetical)
    ./api-keys.nix # reads api-keys.yaml
    ./anthropic.nix # reads anthropic.yaml (if exists)
    ./aws-bedrock.nix # reads aws.yaml
    ./gcp-ml.nix # reads gcp-ml.yaml
    ./gitea.nix # reads gitea.yaml
    ./github.nix # reads github.yaml
    ./grok.nix # reads grok.yaml
    ./k8s.nix # reads k8s.yaml
    ./tailscale.nix # reads tailscale.yaml
  ];
}
