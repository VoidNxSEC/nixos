{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.k8s;
in
{
  options.kernelcore.secrets.k8s = {
    enable = mkEnableOption "Enable Kubernetes secrets from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt Kubernetes secrets
    sops.secrets = {
      # K3s Cluster Token
      "k3s-token" = {
        sopsFile = ../../secrets/k8s.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
        # Restart k3s if token changes
        restartUnits = [ "k3s.service" ];
      };
    };
  };
}
