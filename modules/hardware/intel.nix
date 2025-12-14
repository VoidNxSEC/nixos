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
        Power profile for thermal and performance management.
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
      };

      maxFreqPercent = mkOption {
        type = types.int;
        default = 100;
      };

      energyPerformancePreference = mkOption {
        type = types.enum [
          "performance"
          "balance_performance"
          "balance_power"
          "power"
        ];
        default = "balance_performance";
        description = "EPP hint for HWP.";
      };
    };

    # CPU Governor Configuration
    governor = {
      default = mkOption {
        type = types.enum [
          "performance"
          "powersave"
          "ondemand"
          "schedutil"
        ];
        default = "powersave"; # Intel P-state ativa prefere 'powersave' como base, o HWP gerencia o clock real.
        description = "Default CPU frequency governor. With intel_pstate, 'powersave' implies HWP management.";
      };
      # (Mantive os overrides de P/E-cores mas note que com HWP ativo, o governador de OS tem menos impacto)
      pCores = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      eCores = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };

    # Turbo Boost Control
    turboBoost = {
      enable = mkEnableOption "Enable Intel Turbo Boost" // {
        default = true;
      };
      maxTemp = mkOption {
        type = types.int;
        default = 90;
      };
    };

    # Intel Graphics (Xe iGPU) Tunings
    graphics = {
      enable = mkEnableOption "Enable Intel Xe Graphics optimizations" // {
        default = true;
      };

      # CRÍTICO: PSR causa stutters e crashes em browsers (Chromium/Electron) na Gen12+.
      # Desativar (0) é o fix de estabilidade. Habilitar apenas se tiver certeza que o painel suporta PSR2 sem falhas.
      panelSelfRefresh = mkEnableOption "Enable Panel Self-Refresh (PSR)" // {
        default = false;
      };

      frameBufferCompression = mkEnableOption "Enable Frame Buffer Compression (FBC)" // {
        default = true; # FBC geralmente é seguro, mas se houver glitches visuais, desative.
      };

      # NOVO: GuC/HuC Submission
      # Habilitar o GuC move o agendamento da CPU para o microcontrolador da GPU.
      # Essencial para i5-13420H para evitar sobrecarga de interrupções e melhorar encoding de vídeo.
      enableGuC = mkEnableOption "Enable GuC/HuC Firmware Loading & Submission" // {
        default = true;
      };
    };

    # Memory & Cache (Mantidos iguais, removendo verbosidade para clareza)
    memory.enableTuning = mkEnableOption "Enable memory timing optimizations" // {
      default = true;
    };
    cache.enableOptimizations = mkEnableOption "Enable Raptor Lake cache optimizations" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = mkDefault true;

    # Boot Parameters
    boot.kernelParams = [
      "intel_pstate=active"
    ]
    ++ optionals cfg.pstate.hwpDynamic [ "intel_pstate=hwp_dynamic_boost" ]
    ++ optionals cfg.graphics.enable (
      [
        # Graphics Parameters
        "i915.enable_fbc=${if cfg.graphics.frameBufferCompression then "1" else "0"}"

        # PSR: 0 = Disabled (Estabilidade máxima para Chromium), 1 = PSR1, 2 = PSR2 (Deep sleep)
        "i915.enable_psr=${if cfg.graphics.panelSelfRefresh then "2" else "0"}"
      ]
      ++ optionals cfg.graphics.enableGuC [
        # GuC = 3 (Enable GuC submission + HuC loading)
        # GuC = 2 (Enable GuC submission only)
        # Raptor Lake se beneficia de ambos (3).
        "i915.enable_guc=3"
      ]
    )
    ++ optionals cfg.cache.enableOptimizations [
      # C-States
      "intel_idle.max_cstate=2" # Cuidado: Isso limita a economia de energia drasticamente. Útil se houver freezes totais do sistema.
      "processor.max_cstate=2"
    ];

    boot.kernelModules = [
      "kvm-intel"
      "intel_powerclamp"
      "coretemp"
    ];

    # Instalação de drivers gráficos (Userland)
    # Necessário para o Chromium usar VA-API corretamente via /dev/dri/renderD128
    hardware.graphics = {
      # (NixOS 24.05+) - Antigo hardware.opengl
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # Driver iHD para VA-API (Gen9+) - CRÍTICO para Chromium
        intel-vaapi-driver # Driver legado (i965)
        vpl-gpu-rt # Intel OneVPL
      ];
    };

    # Power Management
    powerManagement = {
      enable = true;
      cpuFreqGovernor = cfg.governor.default;
    };

    # Service P-State (Mantido lógica original, simplificada)
    systemd.services.intel-pstate-config = mkIf cfg.pstate.enable {
      description = "Configure Intel P-State parameters";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Wait for sysfs
        sleep 2

        PSTATE_DIR="/sys/devices/system/cpu/intel_pstate"

        if [ -d "$PSTATE_DIR" ]; then
          echo ${toString cfg.pstate.minFreqPercent} > "$PSTATE_DIR/min_perf_pct" || true
          echo ${toString cfg.pstate.maxFreqPercent} > "$PSTATE_DIR/max_perf_pct" || true

          # EPP Update
          for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [ -f "$cpu" ] && echo "${cfg.pstate.energyPerformancePreference}" > "$cpu" || true
          done

          # Turbo Control
          # 'no_turbo' -> 0 (enabled), 1 (disabled)
          echo "${if cfg.turboBoost.enable then "0" else "1"}" > "$PSTATE_DIR/no_turbo" || true
        fi
      '';
    };

    # Thermal Monitor (Mantido, mas ajustado para não brigar com thermald se instalado)
    systemd.services.intel-thermal-monitor = mkIf cfg.turboBoost.enable {
      description = "Intel thermal monitoring logic";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
      };
      script = ''
        while true; do
          current_temp=$(cat /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
          temp=''${current_temp:-0}
          temp_c=$((temp / 1000))

          if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
            if [ "$temp_c" -gt "${toString cfg.turboBoost.maxTemp}" ]; then
              echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            elif [ "$temp_c" -lt $((${toString cfg.turboBoost.maxTemp} - 15)) ]; then
              # Histerese aumentada para 15C para evitar oscilação rápida (flapping)
              echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
            fi
          fi
          sleep 5
        done
      '';
    };

    # Sysctl tuning
    boot.kernel.sysctl = mkIf cfg.memory.enableTuning {
      "vm.swappiness" = mkDefault 10;
      "vm.vfs_cache_pressure" = mkDefault 50;
    };

    # Packages
    environment.systemPackages = with pkgs; [
      intel-gpu-tools # Use 'sudo intel_gpu_top' para verificar se a GPU está carregando (Render/Video/Blitter)
      lm_sensors
    ];
  };
}
