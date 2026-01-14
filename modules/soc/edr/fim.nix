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
  options.kernelcore.soc.edr.fim = {
    enable = mkOption {
      type = types.bool;
      default = cfg.edr.enable;
      description = "Enable File Integrity Monitoring";
    };

    # Paths to monitor
    monitorPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "/etc"
        "/usr/bin"
        "/usr/sbin"
        "/bin"
        "/sbin"
        "/boot"
        "/lib"
        "/lib64"
      ];
      description = "Paths to monitor for changes";
    };

    # Exclude patterns
    excludePatterns = mkOption {
      type = types.listOf types.str;
      default = [
        "*.log"
        "*.tmp"
        "*.cache"
        "/etc/mtab"
        "/etc/resolv.conf"
        "/etc/hosts"
      ];
      description = "Patterns to exclude from monitoring";
    };

    # Scan interval
    scanInterval = mkOption {
      type = types.str;
      default = "hourly";
      description = "How often to perform integrity scans";
    };

    # Real-time monitoring
    realtime = mkOption {
      type = types.bool;
      default = true;
      description = "Enable real-time file monitoring with inotify";
    };
  };

  config = mkIf (cfg.enable && cfg.edr.fim.enable) {
    # Integrate with existing AIDE configuration
    # This extends the security.aide module

    # Real-time file monitoring service using inotify
    systemd.services.soc-fim = mkIf cfg.edr.fim.realtime {
      description = "SOC File Integrity Monitor (Real-time)";
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        inotify-tools
        coreutils
        jq
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "fim-realtime" ''
          #!/usr/bin/env bash
          set -euo pipefail

          ALERT_FILE="/var/log/soc/fim-alerts.json"
          mkdir -p /var/log/soc

          log_change() {
            local action=$1
            local path=$2
            local severity="medium"

            # Elevate severity for critical paths
            case "$path" in
              /etc/passwd*|/etc/shadow*|/etc/sudoers*)
                severity="critical"
                ;;
              /etc/ssh/*|/etc/pam.d/*)
                severity="high"
                ;;
              /usr/bin/*|/usr/sbin/*|/bin/*|/sbin/*)
                severity="high"
                ;;
            esac

            echo "{\"timestamp\":\"$(date -Iseconds)\",\"event\":\"fim\",\"action\":\"$action\",\"path\":\"$path\",\"severity\":\"$severity\"}" >> "$ALERT_FILE"
            logger -t SOC-FIM -p security.warning "FIM: $action on $path"
          }

          WATCH_PATHS="${concatStringsSep " " cfg.edr.fim.monitorPaths}"
          EXCLUDE_ARGS="${concatMapStringsSep " " (p: "--exclude '${p}'") cfg.edr.fim.excludePatterns}"

          echo "Starting real-time FIM on: $WATCH_PATHS"

          ${pkgs.inotify-tools}/bin/inotifywait -m -r \
            --format '%w%f %e' \
            -e modify,attrib,close_write,move,create,delete \
            $EXCLUDE_ARGS \
            $WATCH_PATHS 2>/dev/null | while read -r path events; do
            
            # Skip excluded patterns
            skip=false
            ${concatMapStringsSep "\n" (
              p: "if [[ \"$path\" == ${p} ]]; then skip=true; fi"
            ) cfg.edr.fim.excludePatterns}
            
            if [ "$skip" = "false" ]; then
              log_change "$events" "$path"
            fi
          done
        ''}";
        Restart = "always";
        RestartSec = "5";
      };
    };

    # Scheduled full integrity check
    systemd.services.soc-fim-scan = {
      description = "SOC File Integrity Full Scan";

      path = with pkgs; [
        coreutils
        findutils
        openssl
        jq
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "fim-scan" ''
          #!/usr/bin/env bash
          set -euo pipefail

          BASELINE_FILE="/var/lib/soc/fim/baseline.json"
          CURRENT_FILE="/var/lib/soc/fim/current.json"
          DIFF_FILE="/var/log/soc/fim-diff-$(date +%Y%m%d-%H%M%S).json"

          mkdir -p /var/lib/soc/fim
          mkdir -p /var/log/soc

          echo "Starting FIM full scan at $(date -Iseconds)"

          # Generate current state
          generate_hashes() {
            echo "{"
            echo "  \"timestamp\": \"$(date -Iseconds)\","
            echo "  \"files\": {"
            
            first=true
            for path in ${concatStringsSep " " cfg.edr.fim.monitorPaths}; do
              if [ -d "$path" ]; then
                find "$path" -type f 2>/dev/null | while read -r file; do
                  # Skip excluded
                  skip=false
                  ${concatMapStringsSep "\n" (
                    p: "if [[ \"$file\" == ${p} ]]; then skip=true; fi"
                  ) cfg.edr.fim.excludePatterns}
                  
                  if [ "$skip" = "false" ]; then
                    hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}' || echo "error")
                    perms=$(stat -c '%a' "$file" 2>/dev/null || echo "000")
                    owner=$(stat -c '%u:%g' "$file" 2>/dev/null || echo "0:0")
                    mtime=$(stat -c '%Y' "$file" 2>/dev/null || echo "0")
                    
                    if [ "$first" = "true" ]; then
                      first=false
                    else
                      echo ","
                    fi
                    echo "    \"$file\": {\"hash\":\"$hash\",\"perms\":\"$perms\",\"owner\":\"$owner\",\"mtime\":$mtime}"
                  fi
                done
              fi
            done
            
            echo "  }"
            echo "}"
          }

          # Generate current hashes
          generate_hashes > "$CURRENT_FILE"

          # Compare with baseline if exists
          if [ -f "$BASELINE_FILE" ]; then
            echo "Comparing with baseline..."
            
            {
              echo "{"
              echo "  \"timestamp\": \"$(date -Iseconds)\","
              echo "  \"changes\": []"
              echo "}"
            } > "$DIFF_FILE"

            # Use jq to find differences
            changes=$(${pkgs.jq}/bin/jq -r --slurpfile current "$CURRENT_FILE" --slurpfile baseline "$BASELINE_FILE" -n '
              ($current[0].files | keys) as $current_files |
              ($baseline[0].files | keys) as $baseline_files |
              
              # New files
              (($current_files - $baseline_files) | map({path: ., change: "added"})) +
              
              # Deleted files  
              (($baseline_files - $current_files) | map({path: ., change: "deleted"})) +
              
              # Modified files
              [($current_files | .[] | select(. as $f | $baseline_files | index($f)) | 
                select(. as $f | $current[0].files[$f].hash != $baseline[0].files[$f].hash) |
                {path: ., change: "modified"})]
            ')

            if [ "$(echo "$changes" | ${pkgs.jq}/bin/jq 'length')" -gt 0 ]; then
              echo "Changes detected!"
              echo "$changes" | ${pkgs.jq}/bin/jq '.'
              
              # Log changes
              echo "$changes" | ${pkgs.jq}/bin/jq -c '.[]' | while read -r change; do
                echo "{\"timestamp\":\"$(date -Iseconds)\",\"event\":\"fim_scan\",\"change\":$change}" >> /var/log/soc/fim-alerts.json
              done
            else
              echo "No changes detected"
            fi
          else
            echo "No baseline found, creating initial baseline..."
            cp "$CURRENT_FILE" "$BASELINE_FILE"
          fi

          echo "FIM scan completed at $(date -Iseconds)"
        ''}";
      };
    };

    systemd.timers.soc-fim-scan = {
      description = "SOC FIM Scan Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.edr.fim.scanInterval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/soc/fim 0750 root root -"
    ];

    # CLI aliases
    environment.shellAliases = {
      fim-scan = "sudo systemctl start soc-fim-scan && journalctl -u soc-fim-scan -f";
      fim-alerts = "tail -f /var/log/soc/fim-alerts.json | jq";
      fim-baseline = "sudo rm /var/lib/soc/fim/baseline.json && sudo systemctl start soc-fim-scan";
    };
  };
}
