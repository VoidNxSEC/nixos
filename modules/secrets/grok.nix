{
  config,
  lib,
  pkgs,
  inputs,
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
      "api_key_grok" = {
        sopsFile = "${inputs.venus}/secrets/grok.yaml";
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
