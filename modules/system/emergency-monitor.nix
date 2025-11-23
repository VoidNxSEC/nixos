{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# EMERGENCY MONITORING SERVICE
# ============================================================
# Monitora sistema 24/7 e intervém automaticamente em emergências
# Framework: /etc/nixos/scripts/nix-emergency.sh

with lib;

{
  options.system.emergency = {
    enable = mkEnableOption "Emergency monitoring and auto-intervention";

    swapThreshold = mkOption {
      type = types.int;
      default = 85;
      description = "SWAP usage % that triggers emergency intervention";
    };

    tempThreshold = mkOption {
      type = types.int;
      default = 85;
      description = "CPU temperature (°C) that triggers cooldown";
    };

    loadThreshold = mkOption {
      type = types.int;
      default = 32;
      description = "Load average that triggers build abort";
    };

    autoIntervene = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic intervention (abort builds when critical)";
    };
  };

  config = mkIf config.system.emergency.enable {
    # ========================================
    # EMERGENCY MONITORING SERVICE
    # ========================================

    systemd.services.emergency-monitor = {
      description = "System Emergency Monitor";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "30s";
        User = "root";

        # Script de monitoramento
        ExecStart = pkgs.writeShellScript "emergency-monitor.sh" ''
          #!/usr/bin/env bash
          set -euo pipefail

          SWAP_THRESHOLD=${toString config.system.emergency.swapThreshold}
          TEMP_THRESHOLD=${toString config.system.emergency.tempThreshold}
          LOAD_THRESHOLD=${toString config.system.emergency.loadThreshold}
          AUTO_INTERVENE=${if config.system.emergency.autoIntervene then "true" else "false"}

          log() {
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/emergency-monitor.log
          }

          get_swap_usage() {
            local swap_total=$(free | grep Swap | awk '{print $2}')
            if [[ $swap_total -eq 0 ]]; then
              echo "0"
            else
              free | grep Swap | awk '{printf "%.0f", ($3/$2) * 100}'
            fi
          }

          get_cpu_temp() {
            local temp=0
            if command -v sensors &>/dev/null; then
              temp=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d'.' -f1 || echo 0)
            fi
            if [[ $temp -eq 0 ]] && [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
              temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
            fi
            echo "$temp"
          }

          get_load_avg() {
            uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' | cut -d'.' -f1
          }

          while true; do
            # Verificações
            swap_usage=$(get_swap_usage)
            cpu_temp=$(get_cpu_temp)
            load_avg=$(get_load_avg)

            # Log status periodicamente (a cada 5 minutos)
            if (( $(date +%s) % 300 < 30 )); then
              log "Status: SWAP=$swap_usage% TEMP=$cpu_temp°C LOAD=$load_avg"
            fi

            # ========================================
            # SWAP CRITICAL
            # ========================================
            if [[ $swap_usage -gt $SWAP_THRESHOLD ]]; then
              log "⚠️  SWAP CRITICAL: $swap_usage%"

              if [[ "$AUTO_INTERVENE" == "true" ]]; then
                log "🚨 AUTO-INTERVENTION: Executing swap-emergency..."
                bash /etc/nixos/scripts/nix-emergency.sh swap-emergency >> /var/log/emergency-monitor.log 2>&1
              else
                log "💡 Auto-intervention disabled. Manual action required."
              fi
            fi

            # ========================================
            # TEMPERATURE CRITICAL
            # ========================================
            if [[ $cpu_temp -gt $TEMP_THRESHOLD ]]; then
              log "🔥 OVERHEAT: $cpu_temp°C"

              if [[ "$AUTO_INTERVENE" == "true" ]]; then
                log "🚨 AUTO-INTERVENTION: Executing cooldown..."
                bash /etc/nixos/scripts/nix-emergency.sh cooldown >> /var/log/emergency-monitor.log 2>&1
              else
                log "💡 Auto-intervention disabled. Manual action required."
              fi
            fi

            # ========================================
            # LOAD CRITICAL
            # ========================================
            if [[ $load_avg -gt $LOAD_THRESHOLD ]]; then
              log "⚠️  HIGH LOAD: $load_avg"

              if [[ "$AUTO_INTERVENE" == "true" ]]; then
                # Verificar se há builds NIX ativos
                if pgrep -f "nix.*build\|nixbld" &>/dev/null; then
                  log "🚨 AUTO-INTERVENTION: Aborting NIX builds..."
                  bash /etc/nixos/scripts/nix-emergency.sh abort >> /var/log/emergency-monitor.log 2>&1
                fi
              else
                log "💡 Auto-intervention disabled. Manual action required."
              fi
            fi

            # Intervalo de checagem (30 segundos)
            sleep 30
          done
        '';
      };
    };

    # ========================================
    # LOG ROTATION
    # ========================================

    services.logrotate.settings.emergency-monitor = {
      files = "/var/log/emergency-monitor.log";
      rotate = 7;
      frequency = "daily";
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };

    # ========================================
    # EMERGENCY SCRIPT DISPONÍVEL
    # ========================================

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nix-emergency" ''
        exec bash /etc/nixos/scripts/nix-emergency.sh "$@"
      '')
    ];

    # ========================================
    # SUDO PERMISSIONS
    # ========================================

    security.sudo.extraRules = [
      {
        users = [ "kernelcore" ];
        commands = [
          {
            command = "/etc/nixos/scripts/nix-emergency.sh";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.util-linux}/bin/killall";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.procps}/bin/pkill";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
