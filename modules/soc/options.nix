{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
in
{
  options.kernelcore.soc = {
    enable = mkEnableOption "Enable NSA-level Security Operations Center";

    profile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "enterprise"
      ];
      default = "standard";
      description = ''
        SOC deployment profile:
        - minimal: Log aggregation + basic alerting (low resources)
        - standard: + IDS/IPS + SIEM (recommended, ~8GB RAM)
        - enterprise: + Threat intel + Full EDR + Advanced dashboards
      '';
    };

    # Data retention settings
    retention = {
      days = mkOption {
        type = types.int;
        default = 30;
        description = "Number of days to retain security logs";
      };

      maxSizeGB = mkOption {
        type = types.int;
        default = 50;
        description = "Maximum size in GB for log storage";
      };
    };

    # Network settings
    network = {
      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address for SOC services to listen on";
      };

      adminNetwork = mkOption {
        type = types.str;
        default = "100.64.0.0/10";
        description = "CIDR for admin access (default: Tailscale)";
      };
    };

    # Alerting configuration
    alerting = {
      enable = mkEnableOption "Enable SOC alerting";

      slack = {
        enable = mkEnableOption "Enable Slack notifications";
        webhookFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to Slack webhook URL file (SOPS encrypted)";
        };
        channel = mkOption {
          type = types.str;
          default = "#security-alerts";
          description = "Slack channel for alerts";
        };
      };

      email = {
        enable = mkEnableOption "Enable email notifications";
        recipients = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Email addresses for alert notifications";
        };
        smtpServer = mkOption {
          type = types.str;
          default = "";
          description = "SMTP server for sending alerts";
        };
      };

      telegram = {
        enable = mkEnableOption "Enable Telegram notifications";
        botTokenFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to Telegram bot token file";
        };
        chatId = mkOption {
          type = types.str;
          default = "";
          description = "Telegram chat ID for alerts";
        };
      };

      discord = {
        enable = mkEnableOption "Enable Discord notifications";
        webhookFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to Discord webhook URL file";
        };
      };

      # Alert severity levels
      minSeverity = mkOption {
        type = types.enum [
          "low"
          "medium"
          "high"
          "critical"
        ];
        default = "medium";
        description = "Minimum severity level to trigger alerts";
      };
    };

    # Threat intelligence
    threatIntel = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable threat intelligence feed integration";
      };

      feeds = mkOption {
        type = types.listOf (
          types.enum [
            "abuseipdb"
            "misp"
            "otx"
            "emergingthreats"
          ]
        );
        default = [ "emergingthreats" ];
        description = "Threat intelligence feeds to enable";
      };

      updateInterval = mkOption {
        type = types.str;
        default = "6h";
        description = "How often to update threat intel feeds";
      };
    };
  };

  # Profile-based defaults
  config = mkIf cfg.enable {
    # Enable components based on profile
    kernelcore.soc = {
      threatIntel.enable = mkDefault (cfg.profile == "enterprise");
      alerting.enable = mkDefault true;
    };

    # Enable Podman for OCI containers (required by SOC modules)
    kernelcore.containers.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";
  };
}
