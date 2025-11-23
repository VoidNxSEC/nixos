{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.hardware.thermalProfiles;

  # Profile definitions
  profiles = {
    silent = {
      description = "Silent mode - 35W sustained, minimal noise";
      intel = {
        powerProfile = "silent";
        governor = "powersave";
        minFreq = 20;
        maxFreq = 70;
        turboBoost = false;
        epp = "power";
      };
      throttled = {
        profile = "silent";
      };
      nvidia = {
        powerLimit = 35;
      };
    };

    balanced = {
      description = "Balanced mode - 45W sustained, good balance";
      intel = {
        powerProfile = "balanced";
        governor = "schedutil";
        minFreq = 20;
        maxFreq = 100;
        turboBoost = true;
        epp = "balance_performance";
      };
      throttled = {
        profile = "balanced";
      };
      nvidia = {
        powerLimit = 60;
      };
    };

    performance = {
      description = "Performance mode - 55W sustained, maximum performance";
      intel = {
        powerProfile = "performance";
        governor = "performance";
        minFreq = 50;
        maxFreq = 100;
        turboBoost = true;
        epp = "performance";
      };
      throttled = {
        profile = "performance";
      };
      nvidia = {
        powerLimit = 95;
      };
    };
  };
in
{
  options.kernelcore.hardware.thermalProfiles = {
    enable = mkEnableOption "Enable unified thermal profile management";

    currentProfile = mkOption {
      type = types.enum [
        "silent"
        "balanced"
        "performance"
      ];
      default = "balanced";
      description = "Current active thermal profile";
    };

    autoSwitch = {
      enable = mkEnableOption "Enable automatic profile switching based on load";

      idleThreshold = mkOption {
        type = types.int;
        default = 20;
        description = "CPU usage below this switches to silent (%)";
      };

      highLoadThreshold = mkOption {
        type = types.int;
        default = 70;
        description = "CPU usage above this switches to performance (%)";
      };

      checkInterval = mkOption {
        type = types.int;
        default = 30;
        description = "Profile check interval in seconds";
      };
    };

    temperatureMonitoring = {
      enable = mkEnableOption "Enable temperature-based profile adjustment" // {
        default = true;
      };

      warningTemp = mkOption {
        type = types.int;
        default = 80;
        description = "Temperature warning threshold (°C)";
      };

      criticalTemp = mkOption {
        type = types.int;
        default = 90;
        description = "Temperature critical threshold - force silent mode (°C)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Apply current profile settings to Intel module
    kernelcore.hardware.intel = {
      enable = true;
      powerProfile = profiles.${cfg.currentProfile}.intel.powerProfile;
      governor.default = profiles.${cfg.currentProfile}.intel.governor;
      pstate = {
        minFreqPercent = profiles.${cfg.currentProfile}.intel.minFreq;
        maxFreqPercent = profiles.${cfg.currentProfile}.intel.maxFreq;
        energyPerformancePreference = profiles.${cfg.currentProfile}.intel.epp;
      };
      turboBoost.enable = profiles.${cfg.currentProfile}.intel.turboBoost;
    };

    # Apply current profile to Lenovo throttled
    kernelcore.hardware.lenovoThrottled = {
      enable = true;
      profile = profiles.${cfg.currentProfile}.throttled.profile;
    };

    # Profile switcher service
    systemd.services.thermal-profile-manager = {
      description = "Thermal Profile Manager - Unified control for i5-13420H + RTX 3050";
      wantedBy = [ "multi-user.target" ];
      after = [
        "intel-pstate-config.service"
        "throttled.service"
      ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
      };
      script = ''
        PROFILE_FILE="/var/lib/thermal-profile/current"
        STATS_FILE="/var/lib/thermal-profile/stats.log"

        mkdir -p /var/lib/thermal-profile

        # Initialize with current profile
        echo "${cfg.currentProfile}" > "$PROFILE_FILE"

        log_stats() {
          local profile=$1
          local temp=$2
          local cpu_usage=$3
          local reason=$4
          
          echo "$(date +%Y-%m-%d\ %H:%M:%S) Profile: $profile Temp: ''${temp}C CPU: ''${cpu_usage}% Reason: $reason" \
            >> "$STATS_FILE"
        }

        get_cpu_temp() {
          # Get highest CPU temperature
          if [ -d /sys/class/thermal ]; then
            cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1 | awk '{print int($1/1000)}'
          else
            echo 0
          fi
        }

        get_cpu_usage() {
          # Get average CPU usage
          top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}'
        }

        apply_profile() {
          local new_profile=$1
          local reason=$2
          
          if [ "$new_profile" != "$(cat $PROFILE_FILE 2>/dev/null)" ]; then
            echo "$new_profile" > "$PROFILE_FILE"
            
            # Log profile change
            local temp=$(get_cpu_temp)
            local cpu_usage=$(get_cpu_usage)
            log_stats "$new_profile" "$temp" "$cpu_usage" "$reason"
            
            echo "Thermal profile switched to: $new_profile ($reason)"
          fi
        }

        ${optionalString cfg.autoSwitch.enable ''
          # Automatic profile switching loop
          while true; do
            temp=$(get_cpu_temp)
            cpu_usage=$(get_cpu_usage)
            current_profile=$(cat "$PROFILE_FILE" 2>/dev/null || echo "${cfg.currentProfile}")

            # Temperature-based emergency switching
            ${optionalString cfg.temperatureMonitoring.enable ''
              if [ $temp -ge ${toString cfg.temperatureMonitoring.criticalTemp} ]; then
                apply_profile "silent" "Critical temp: ''${temp}C"
                sleep ${toString cfg.autoSwitch.checkInterval}
                continue
              elif [ $temp -ge ${toString cfg.temperatureMonitoring.warningTemp} ] && [ "$current_profile" = "performance" ]; then
                apply_profile "balanced" "High temp warning: ''${temp}C"
                sleep ${toString cfg.autoSwitch.checkInterval}
                continue
              fi
            ''}

            # Load-based switching (if temp is OK)
            if [ $cpu_usage -ge ${toString cfg.autoSwitch.highLoadThreshold} ] && [ "$current_profile" != "performance" ] && [ $temp -lt ${toString cfg.temperatureMonitoring.warningTemp} ]; then
              apply_profile "performance" "High load: ''${cpu_usage}%"
            elif [ $cpu_usage -le ${toString cfg.autoSwitch.idleThreshold} ] && [ "$current_profile" != "silent" ]; then
              apply_profile "silent" "Low load: ''${cpu_usage}%"
            elif [ $cpu_usage -gt ${toString cfg.autoSwitch.idleThreshold} ] && [ $cpu_usage -lt ${toString cfg.autoSwitch.highLoadThreshold} ] && [ "$current_profile" != "balanced" ]; then
              apply_profile "balanced" "Medium load: ''${cpu_usage}%"
            fi

            sleep ${toString cfg.autoSwitch.checkInterval}
          done
        ''}

        ${optionalString (!cfg.autoSwitch.enable) ''
          # Static profile monitoring (no auto-switching)
          while true; do
            temp=$(get_cpu_temp)
            cpu_usage=$(get_cpu_usage)
            current_profile=$(cat "$PROFILE_FILE" 2>/dev/null || echo "${cfg.currentProfile}")

            # Only temperature-based emergency override
            ${optionalString cfg.temperatureMonitoring.enable ''
              if [ $temp -ge ${toString cfg.temperatureMonitoring.criticalTemp} ]; then
                apply_profile "silent" "EMERGENCY: Critical temp ''${temp}C"
              fi
            ''}

            # Log stats
            log_stats "$current_profile" "$temp" "$cpu_usage" "monitoring"

            sleep 60
          done
        ''}
      '';
    };

    # Profile info service
    systemd.services.thermal-profile-info = {
      description = "Display current thermal profile information";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
                cat > /etc/thermal-profile-info <<EOF
        ╔══════════════════════════════════════════════════════════════╗
        ║          Thermal Profile Manager - i5-13420H + RTX 3050     ║
        ╚══════════════════════════════════════════════════════════════╝

        Current Profile: ${cfg.currentProfile}
        Description: ${profiles.${cfg.currentProfile}.description}

        Intel CPU Settings:
          - Governor: ${profiles.${cfg.currentProfile}.intel.governor}
          - Freq Range: ${toString profiles.${cfg.currentProfile}.intel.minFreq}-${
            toString profiles.${cfg.currentProfile}.intel.maxFreq
          }%
          - Turbo Boost: ${
            if profiles.${cfg.currentProfile}.intel.turboBoost then "Enabled" else "Disabled"
          }
          - EPP: ${profiles.${cfg.currentProfile}.intel.epp}

        Throttled Settings:
          - Profile: ${profiles.${cfg.currentProfile}.throttled.profile}

        Available Profiles:
        ${concatStringsSep "\n" (mapAttrsToList (name: prof: "  - ${name}: ${prof.description}") profiles)}

        Control Commands:
          - View current: cat /var/lib/thermal-profile/current
          - View stats: tail -f /var/lib/thermal-profile/stats.log
          - Profile info: cat /etc/thermal-profile-info

        Auto-switching: ${if cfg.autoSwitch.enable then "Enabled" else "Disabled"}
        Temperature monitoring: ${if cfg.temperatureMonitoring.enable then "Enabled" else "Disabled"}
        EOF
                
                cat /etc/thermal-profile-info
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # Create profile directory and files
    systemd.tmpfiles.rules = [
      "d /var/lib/thermal-profile 0755 root root -"
      "f /var/lib/thermal-profile/current 0644 root root - ${cfg.currentProfile}"
      "f /var/lib/thermal-profile/stats.log 0644 root root -"
    ];

    # Install profile management tools
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "thermal-profile" ''
        #!/usr/bin/env bash
        # Thermal Profile Manager CLI

        PROFILE_FILE="/var/lib/thermal-profile/current"
        STATS_FILE="/var/lib/thermal-profile/stats.log"

        case "$1" in
          status|current)
            echo "Current Profile: $(cat $PROFILE_FILE 2>/dev/null || echo 'unknown')"
            echo ""
            cat /etc/thermal-profile-info 2>/dev/null || echo "Info not available"
            ;;
          stats)
            tail -n 20 "$STATS_FILE" 2>/dev/null || echo "No stats available"
            ;;
          watch)
            watch -n 2 "thermal-profile status"
            ;;
          silent|balanced|performance)
            echo "$1" > "$PROFILE_FILE"
            echo "Profile set to: $1"
            echo "Note: Restart thermal-profile-manager service to apply: sudo systemctl restart thermal-profile-manager"
            ;;
          *)
            echo "Thermal Profile Manager"
            echo "Usage: thermal-profile {status|stats|watch|silent|balanced|performance}"
            echo ""
            echo "Commands:"
            echo "  status       - Show current profile and settings"
            echo "  stats        - Show recent profile changes"
            echo "  watch        - Watch profile status in real-time"
            echo "  silent       - Switch to silent profile"
            echo "  balanced     - Switch to balanced profile"
            echo "  performance  - Switch to performance profile"
            ;;
        esac
      '')
    ];
  };
}
