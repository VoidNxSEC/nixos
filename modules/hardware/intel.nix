{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.hardware.intel;
in
{
  options.kernelcore.hardware.intel = {
    enable = mkEnableOption "Enable Intel hardware support for i5-13420H (Raptor Lake)";

    # Power Profile Selection
    powerProfile = mkOption {
      type = types.enum [
        "silent"
        "balanced"
        "performance"
      ];
      default = "balanced";
      description = ''
        Power profile for thermal and performance management:
        - silent: 35W sustained, quiet operation
        - balanced: 45W sustained, good balance (default)
        - performance: 55W sustained, maximum performance
      '';
    };

    # P-State Configuration
    pstate = {
      enable = mkEnableOption "Enable Intel P-State driver" // {
        default = true;
      };

      hwpDynamic = mkEnableOption "Enable Hardware P-States (HWP) dynamic boost" // {
        default = true;
      };

      minFreqPercent = mkOption {
        type = types.int;
        default = 20;
        description = "Minimum CPU frequency percentage (0-100)";
      };

      maxFreqPercent = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum CPU frequency percentage (0-100)";
      };

      energyPerformancePreference = mkOption {
        type = types.enum [
          "performance"
          "balance_performance"
          "balance_power"
          "power"
        ];
        default = "balance_performance";
        description = "Energy Performance Preference (EPP) for 13th gen Intel";
      };
    };

    # CPU Governor Configuration
    governor = {
      default = mkOption {
        type = types.enum [
          "performance"
          "powersave"
          "ondemand"
          "conservative"
          "schedutil"
        ];
        default = "schedutil";
        description = "Default CPU frequency governor";
      };

      pCores = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override governor for P-cores (0-3)";
      };

      eCores = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override governor for E-cores (4-7)";
      };
    };

    # Turbo Boost Control
    turboBoost = {
      enable = mkEnableOption "Enable Intel Turbo Boost" // {
        default = true;
      };

      maxTemp = mkOption {
        type = types.int;
        default = 85;
        description = "Maximum temperature before disabling turbo (°C)";
      };
    };

    # Intel Graphics (Xe iGPU)
    graphics = {
      enable = mkEnableOption "Enable Intel Xe Graphics optimizations" // {
        default = true;
      };

      panelSelfRefresh = mkEnableOption "Enable Panel Self-Refresh (PSR)" // {
        default = true;
      };

      frameBufferCompression = mkEnableOption "Enable Frame Buffer Compression (FBC)" // {
        default = true;
      };

      runtimePM = mkEnableOption "Enable aggressive runtime power management" // {
        default = true;
      };
    };

    # Memory Optimization
    memory = {
      enableTuning = mkEnableOption "Enable memory timing optimizations" // {
        default = true;
      };
    };

    # Cache Optimization
    cache = {
      enableOptimizations = mkEnableOption "Enable Raptor Lake cache optimizations" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    # Intel CPU Microcode Updates
    hardware.cpu.intel.updateMicrocode = mkDefault true;

    # Boot Parameters for Intel Optimization
    boot.kernelParams = [
      # Intel P-State driver
      "intel_pstate=active"
    ]
    ++ optionals cfg.pstate.hwpDynamic [ "intel_pstate=hwp_dynamic_boost" ]
    ++ optionals cfg.graphics.enable [
      # Intel Graphics optimizations
      "i915.enable_fbc=${if cfg.graphics.frameBufferCompression then "1" else "0"}"
      "i915.enable_psr=${if cfg.graphics.panelSelfRefresh then "2" else "0"}"
      "i915.disable_power_well=0"
    ]
    ++ optionals cfg.cache.enableOptimizations [
      # Cache optimizations for Raptor Lake
      "intel_idle.max_cstate=2"
      "processor.max_cstate=2"
    ];

    # Kernel Modules
    boot.kernelModules = [
      "kvm-intel"
      "intel_powerclamp"
    ];

    # Power Management Configuration
    powerManagement = {
      enable = true;
      cpuFreqGovernor = cfg.governor.default;
    };

    # Intel P-State Configuration via systemd
    systemd.services.intel-pstate-config = mkIf cfg.pstate.enable {
      description = "Configure Intel P-State driver for i5-13420H";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Wait for P-State interface
        sleep 2

        # Configure P-State parameters
        if [ -d /sys/devices/system/cpu/intel_pstate ]; then
          echo ${toString cfg.pstate.minFreqPercent} > /sys/devices/system/cpu/intel_pstate/min_perf_pct || true
          echo ${toString cfg.pstate.maxFreqPercent} > /sys/devices/system/cpu/intel_pstate/max_perf_pct || true
          
          # Energy Performance Preference
          for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            if [ -f "$cpu" ]; then
              echo "${cfg.pstate.energyPerformancePreference}" > "$cpu" || true
            fi
          done
        fi

        # Turbo boost control
        if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
          echo "${
            if cfg.turboBoost.enable then "0" else "1"
          }" > /sys/devices/system/cpu/intel_pstate/no_turbo || true
        fi

        # Hybrid core governor optimization (if specified)
        ${optionalString (cfg.governor.pCores != null) ''
          # P-cores (0-3)
          for cpu in 0 1 2 3; do
            if [ -f /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor ]; then
              echo "${cfg.governor.pCores}" > /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor || true
            fi
          done
        ''}

        ${optionalString (cfg.governor.eCores != null) ''
          # E-cores (4-7)
          for cpu in 4 5 6 7; do
            if [ -f /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor ]; then
              echo "${cfg.governor.eCores}" > /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor || true
            fi
          done
        ''}
      '';
    };

    # Thermal monitoring and turbo management
    systemd.services.intel-thermal-monitor = mkIf cfg.turboBoost.enable {
      description = "Intel thermal monitoring for turbo management";
      wantedBy = [ "multi-user.target" ];
      after = [ "intel-pstate-config.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
      };
      script = ''
        while true; do
          # Check CPU temperature
          temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1 || echo 0)
          temp_c=$((temp / 1000))

          # Disable turbo if too hot
          if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
            if [ $temp_c -gt ${toString cfg.turboBoost.maxTemp} ]; then
              echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            elif [ $temp_c -lt $((${toString cfg.turboBoost.maxTemp} - 10)) ]; then
              echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            fi
          fi

          sleep 5
        done
      '';
    };

    # Memory tuning
    boot.kernel.sysctl = mkIf cfg.memory.enableTuning {
      # Memory subsystem tuning for Raptor Lake
      "vm.swappiness" = mkDefault 10;
      "vm.vfs_cache_pressure" = mkDefault 50;
      "vm.dirty_ratio" = mkDefault 10;
      "vm.dirty_background_ratio" = mkDefault 5;
    };

    # Intel Graphics runtime PM
    services.udev.extraRules = mkIf cfg.graphics.runtimePM ''
      # Intel Graphics runtime power management
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
    '';

    # Install monitoring tools
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
      cpufrequtils
      lm_sensors
      turbostat
    ];

    # Profile-based optimization
    systemd.tmpfiles.rules = [
      "d /var/lib/intel-power-profile 0755 root root -"
      "f /var/lib/intel-power-profile/current 0644 root root - ${cfg.powerProfile}"
    ];
  };
}
