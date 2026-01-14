{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  alertCfg = cfg.alerting;
in
{
  # Alerting options already defined in options.nix

  config = mkIf (cfg.enable && alertCfg.enable) {
    # Alert dispatch service
    systemd.services.soc-alerter = {
      description = "SOC Alert Dispatcher";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        curl
        jq
        coreutils
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "soc-alerter" ''
          #!/usr/bin/env bash
          set -euo pipefail

          ALERT_FILE="/var/log/soc/alerts-$(date +%Y-%m-%d).json"
          SENT_FILE="/var/lib/soc/alerter/sent.txt"
          mkdir -p /var/lib/soc/alerter

          send_slack() {
            local message=$1
            local severity=$2
            local emoji=""
            
            case "$severity" in
              critical) emoji="🚨" ;;
              high) emoji="⚠️" ;;
              medium) emoji="📢" ;;
              *) emoji="ℹ️" ;;
            esac

            ${optionalString alertCfg.slack.enable ''
              if [ -f "${toString alertCfg.slack.webhookFile}" ]; then
                webhook=$(cat "${toString alertCfg.slack.webhookFile}")
                curl -s -X POST "$webhook" \
                  -H "Content-Type: application/json" \
                  -d "{\"channel\":\"${alertCfg.slack.channel}\",\"text\":\"$emoji *SOC Alert [$severity]*\n$message\"}" || true
              fi
            ''}
          }

          send_telegram() {
            local message=$1
            ${optionalString alertCfg.telegram.enable ''
              if [ -f "${toString alertCfg.telegram.botTokenFile}" ]; then
                token=$(cat "${toString alertCfg.telegram.botTokenFile}")
                curl -s "https://api.telegram.org/bot$token/sendMessage" \
                  -d "chat_id=${alertCfg.telegram.chatId}" \
                  -d "text=$message" \
                  -d "parse_mode=HTML" || true
              fi
            ''}
          }

          send_discord() {
            local message=$1
            local severity=$2
            ${optionalString alertCfg.discord.enable ''
              if [ -f "${toString alertCfg.discord.webhookFile}" ]; then
                webhook=$(cat "${toString alertCfg.discord.webhookFile}")
                curl -s -X POST "$webhook" \
                  -H "Content-Type: application/json" \
                  -d "{\"content\":\"**SOC Alert [$severity]**\n$message\"}" || true
              fi
            ''}
          }

          severity_level() {
            case "$1" in
              critical) echo 4 ;;
              high) echo 3 ;;
              medium) echo 2 ;;
              *) echo 1 ;;
            esac
          }

          min_level=$(severity_level "${alertCfg.minSeverity}")

          echo "SOC Alerter started. Minimum severity: ${alertCfg.minSeverity}"

          # Watch for new alerts
          tail -F "$ALERT_FILE" 2>/dev/null | while read -r line; do
            # Parse alert
            timestamp=$(echo "$line" | jq -r '.timestamp // empty')
            severity=$(echo "$line" | jq -r '.severity // .event.severity // "low"')
            message=$(echo "$line" | jq -r '.message // .event.message // .category // "Unknown alert"')
            details=$(echo "$line" | jq -r '.details // .path // .process // "{}"')

            # Create unique ID for dedup
            alert_id=$(echo "$line" | md5sum | cut -d' ' -f1)

            # Check if already sent
            if grep -q "^$alert_id$" "$SENT_FILE" 2>/dev/null; then
              continue
            fi

            # Check severity threshold
            alert_level=$(severity_level "$severity")
            if [ "$alert_level" -lt "$min_level" ]; then
              continue
            fi

            # Format message
            full_message="[$timestamp] $message\nDetails: $details"

            echo "Dispatching alert: $severity - $message"

            # Send to all configured channels
            send_slack "$full_message" "$severity"
            send_telegram "$full_message"
            send_discord "$full_message" "$severity"

            # Mark as sent
            echo "$alert_id" >> "$SENT_FILE"

            # Cleanup old sent records
            tail -10000 "$SENT_FILE" > "$SENT_FILE.tmp" && mv "$SENT_FILE.tmp" "$SENT_FILE"
          done
        ''}";
        Restart = "always";
        RestartSec = "10";
      };
    };

    # Test alert command
    environment.etc."soc/scripts/test-alert.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        SEVERITY=''${1:-medium}
        MESSAGE=''${2:-"Test alert from SOC"}

        echo "{\"timestamp\":\"$(date -Iseconds)\",\"severity\":\"$SEVERITY\",\"message\":\"$MESSAGE\",\"details\":{\"test\":true}}" \
          >> /var/log/soc/alerts-$(date +%Y-%m-%d).json

        echo "Test alert sent: $SEVERITY - $MESSAGE"
      '';
    };

    # Email alerting via msmtp
    programs.msmtp = mkIf alertCfg.email.enable {
      enable = true;
      accounts.default = {
        host = alertCfg.email.smtpServer;
        from = "soc@${config.networking.hostName}";
        auth = true;
        tls = true;
      };
    };

    # CLI aliases
    environment.shellAliases = {
      alert-test = "/etc/soc/scripts/test-alert.sh";
      alert-test-critical = "/etc/soc/scripts/test-alert.sh critical 'Critical test alert'";
    };
  };
}
