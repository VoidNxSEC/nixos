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
    enable = mkEnableOption "Enable Grok secret from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt Grok API Key
    sops.secrets = {
      # Grok API Key
      "grok-api-key" = {
        sopsFile = ../../secrets/grok.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
