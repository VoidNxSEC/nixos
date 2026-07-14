# Laptop Defense — NixOS module for thermal protection / emergency brake.
# Part of the flake.nix split; see ./flake.nix (nixosModules.thermalProtection).
{ defensePackages }:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.kernelcore.hardware.laptop-defense.thermal = {
    enable = mkEnableOption "Thermal protection and emergency brake";

    maxTemp = mkOption {
      type = types.int;
      default = 95;
      description = "Maximum temperature (°C) before emergency brake";
    };
  };

  config = mkIf config.kernelcore.hardware.laptop-defense.thermal.enable {
    # Disable ClamAV durante rebuilds
    systemd.services.clamav-daemon.serviceConfig =
      mkIf (config.services.clamav.daemon.enable or false)
        {
          Nice = 19; # Baixa prioridade
          CPUQuota = "25%"; # Limita CPU
        };

    # Thermal emergency brake
    systemd.services.thermal-emergency = {
      description = "Emergency thermal protection";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "30s";

        ExecStart = pkgs.writeShellScript "thermal-guard" ''
          while true; do
            MAX_TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

            if [ "''${MAX_TEMP:-0}" -gt ${toString config.kernelcore.hardware.laptop-defense.thermal.maxTemp} ]; then
              echo "🚨 THERMAL EMERGENCY: ''${MAX_TEMP}°C" | ${pkgs.systemd}/bin/systemd-cat -t thermal-emergency -p err

              # Kill rebuild if running
              ${pkgs.procps}/bin/pkill -TERM nixos-rebuild || true
              ${pkgs.procps}/bin/pkill -TERM nix || true

              # Force CPU governor to powersave
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                echo powersave > "$cpu" 2>/dev/null || true
              done

              # Disable turbo (Intel)
              echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

              sleep 30
            fi

            sleep 5
          done
        '';
      };
    };

    # Install forensics tools
    environment.systemPackages = with defensePackages; [
      thermalForensics
      thermalMonitor
      mcpLogExtractor
      decisionFramework
      fullInvestigation
    ];
  };
}
