{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.grok;
in
{
  options.kernelcore.secrets.grok = {
    enable = mkEnableOption "Enable Grok secret from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt Grok API Key
    sops.secrets = {
      # Grok API Key
      "api-key-grok" = {
        sopsFile = ../../secrets/grok.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
