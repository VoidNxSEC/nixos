# ============================================
# GitHub Module - reads from github.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.github;
in
{
  options.kernelcore.secrets.github = {
    enable = mkEnableOption "Enable GitHub secrets from SOPS (github.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt GitHub secrets from /etc/nixos/secrets/github.yaml
    sops.secrets = {
      # GitHub PAT – readable by kernelcore user and any github-runner service
      # group is the runner group created by services.github-runners.<name>
      "github_token" = {
        sopsFile = "${inputs.venus}/secrets/github.yaml";
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "github-runner-kernelcore-org";
      };

    };

    # Allow kernelcore user to read the token alongside the runner service
    users.users.kernelcore.extraGroups = lib.mkAfter [ "github-runner-kernelcore-org" ];
  };
}
