{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.hardware.lenovoThrottled;

  # Power limits based on profile
  powerLimits = {
    silent = {
      pl1 = 35;
      pl2 = 55;
      duration = 28;
    };
    balanced = {
      pl1 = 45;
      pl2 = 65;
      duration = 28;
    };
    performance = {
      pl1 = 55;
      pl2 = 80;
      duration = 28;
    };
  };

  currentProfile = cfg.profile;
  pl = powerLimits.${currentProfile};
in
{
  options.kernelcore.hardware.lenovoThrottled = {
    enable = mkEnableOption "Enable Lenovo throttled fix for i5-13420H";

    profile = mkOption {
      type = types.enum [
        "silent"
        "balanced"
        "performance"
      ];
      default = "balanced";
      description = ''
        Power profile for thermal management:
        - silent: 35W PL1, low noise
        - balanced: 45W PL1, good balance (default)
        - performance: 55W PL1, maximum performance
      '';
    };

    tripTemp = mkOption {
      type = types.int;
      default = 85;
      description = "Temperature threshold for thermal throttling (°C)";
    };

    unlockVoltage = mkEnableOption "Attempt to unlock voltage controls (requires BIOS support)" // {
      default = true;
    };

    updateRate = mkOption {
      type = types.int;
      default = 5;
      description = "Update rate in seconds for power limit monitoring";
    };
  };

  config = mkIf cfg.enable {
    # Install throttled package
    services.throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        # Enable the fix for clock dropping under load
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC/online

        # Try to unlock undervolt (will fail if BIOS locked, but worth trying)
        Unlock_Voltage: ${if cfg.unlockVoltage then "True" else "False"}

        [BATTERY]
        # Battery power limits (more conservative)
        Update_Rate_s: ${toString cfg.updateRate}
        PL1_Tdp_W: ${toString (pl.pl1 - 10)}
        PL1_Duration_s: ${toString pl.duration}
        PL2_Tdp_W: ${toString (pl.pl2 - 15)}
        PL2_Duration_s: 0.002
        Trip_Temp_C: ${toString (cfg.tripTemp - 5)}

        [AC]
        # AC power limits - THE KEY TO THERMAL CONTROL
        # PL1: Sustained power (long duration). Keep this reasonable for thermals.
        # Lower this to 35-45W prevents laptop from becoming a hotplate.
        Update_Rate_s: ${toString cfg.updateRate}
        PL1_Tdp_W: ${toString pl.pl1}
        PL1_Duration_s: ${toString pl.duration}

        # PL2: Peak power (short burst). Keep high for responsiveness.
        PL2_Tdp_W: ${toString pl.pl2}
        PL2_Duration_s: 0.002

        # Trip temperature - thermal throttling threshold
        # Lowering to 85C prevents excessive heat buildup
        Trip_Temp_C: ${toString cfg.tripTemp}

        # Undervolt offsets (only work if BIOS allows)
        # Negative values = lower voltage = less heat
        # CORE voltage offset (mV) - affects P-cores and E-cores
        CORE: -50
        # GPU voltage offset (mV) - affects iGPU
        GPU: -50
        # Cache voltage offset (mV) - affects L2/L3 cache
        CACHE: -50
        # Uncore voltage offset (mV) - affects memory controller
        UNCORE: -50
        # Analogio voltage offset (mV) - affects analog circuitry
        ANALOGIO: 0
      '';
    };

    # Monitor throttled service
    systemd.services.throttled-monitor = {
      description = "Monitor Lenovo throttled power limits";
      wantedBy = [ "multi-user.target" ];
      after = [ "throttled.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "30s";
      };
      script = ''
        # Log directory
        LOG_DIR="/var/log/throttled"
        mkdir -p "$LOG_DIR"

        while true; do
          # Check if throttled is running
          if systemctl is-active --quiet throttled; then
            # Log current power limits
            if command -v turbostat >/dev/null 2>&1; then
              turbostat --quiet --show PkgWatt,CorWatt,GFXWatt,RAMWatt --interval 60 2>&1 | \
                head -1 >> "$LOG_DIR/power-$(date +%Y%m%d).log" || true
            fi

            # Log temperatures
            if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
              temp=$(cat /sys/class/thermal/thermal_zone0/temp)
              temp_c=$((temp / 1000))
              echo "$(date +%Y-%m-%d\ %H:%M:%S) Temp: ''${temp_c}C Profile: ${currentProfile} PL1: ${toString pl.pl1}W PL2: ${toString pl.pl2}W" \
                >> "$LOG_DIR/thermal-$(date +%Y%m%d).log"
            fi
          fi

          sleep 60
        done
      '';
    };

    # Profile switcher service
    systemd.services.throttled-profile-switcher = {
      description = "Switch throttled power profile dynamically";
      wantedBy = [ "multi-user.target" ];
      after = [ "throttled.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Write current profile
        echo "${currentProfile}" > /var/lib/throttled-profile/current || true

        # Log profile change
        echo "$(date): Throttled profile set to ${currentProfile} (PL1: ${toString pl.pl1}W, PL2: ${toString pl.pl2}W)" \
          >> /var/log/throttled/profile-changes.log || true
      '';
    };

    # Create log directory
    systemd.tmpfiles.rules = [
      "d /var/log/throttled 0755 root root -"
      "d /var/lib/throttled-profile 0755 root root -"
      "f /var/lib/throttled-profile/current 0644 root root - ${currentProfile}"
    ];

    # Install monitoring tools
    environment.systemPackages = with pkgs; [
      linuxPackages.turbostat
      powertop
      stress-ng
    ];

    # Ensure kernel module support
    boot.kernelModules = [
      "msr"
      "coretemp"
    ];
  };
}
