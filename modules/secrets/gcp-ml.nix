# ============================================
# GCP ML Module - reads from gcp-ml.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.gcp-ml;
in
{
  options.kernelcore.secrets.gcp-ml = {
    enable = mkEnableOption "Enable GCP ML secrets from SOPS (gcp-ml.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt GCP secrets from /etc/nixos/secrets/gcp-ml.yaml
    sops.secrets = {
      # GCP Project Configuration
      "GCP_PROJECT_ID" = {
        sopsFile = ../../secrets/gcp-ml.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "GCP_LOCATION" = {
        sopsFile = ../../secrets/gcp-ml.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Environment loader script
    environment.etc."load-gcp-ml.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Load GCP ML credentials
        # Usage: source /etc/load-gcp-ml.sh

        export GCP_PROJECT_ID="$(cat /run/secrets/GCP_PROJECT_ID 2>/dev/null || echo "")"
        export GCP_LOCATION="$(cat /run/secrets/GCP_LOCATION 2>/dev/null || echo "")"

        echo "✓ GCP ML credentials loaded from gcp-ml.yaml"
        echo "  - GCP_PROJECT_ID: $GCP_PROJECT_ID"
        echo "  - GCP_LOCATION: $GCP_LOCATION"
      '';
      mode = "0755";
    };
  };
}
