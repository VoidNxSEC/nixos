{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.tailscale;
in
{
  options.kernelcore.secrets.tailscale = {
    enable = mkEnableOption "Enable Tailscale secrets management via SOPS";

    secretsFile = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets/tailscale.yaml";
      description = "Path to SOPS-encrypted Tailscale secrets file";
    };
  };

  config = mkIf cfg.enable {
    # SOPS secrets for Tailscale - only if file exists
    sops.secrets = mkIf (pathExists cfg.secretsFile) {
      "tailscale-authkey" = {
        sopsFile = cfg.secretsFile;
        key = "authkey";
        mode = "0400";
        owner = "root";
        group = "root";
        restartUnits = [ "tailscaled.service" ];
      };

      "tailscale-preauthkey" = {
        sopsFile = cfg.secretsFile;
        key = "preauthkey";
        mode = "0400";
        owner = "root";
        group = "root";
      };

      "tailscale-api-token" = {
        sopsFile = cfg.secretsFile;
        key = "api_token";
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };

    # Ensure secrets directory exists
    systemd.tmpfiles.rules = [
      "d /etc/nixos/secrets 0750 root root -"
      "d /run/secrets 0750 root root -"
    ];
  };
}