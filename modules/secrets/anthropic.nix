{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.anthropic;
in
{
  options.kernelcore.secrets.anthropic = {
    enable = mkEnableOption "Enable Anthropic secret from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt Anthropic API Key
    sops.secrets = {
      # Anthropic API Key
      "anthropic_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };
}
