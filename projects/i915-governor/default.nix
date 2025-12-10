{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.i915-governor;
  # Importa o pacote que definimos acima
  governorPackage = pkgs.callPackage /etc/nixos/projects/i915-governor/nix/package.nix {};
in {
  options.services.i915-governor = {
    enable = mkEnableOption "Intel i915 Memory Governor";

    thresholds = {
      gpuCritical = mkOption {
        type = types.int;
        default = 90;
        description = "Porcentagem de uso da iGPU para iniciar throttling";
      };

      memoryPressure = mkOption {
        type = types.int;
        default = 80;
        description = "Pressão de memória (PSI) para disparar compactação";
      };
    };
  };

  config = mkIf cfg.enable {
    # Disponibiliza o binário no path do sistema
    environment.systemPackages = [ governorPackage ];

    systemd.services.i915-governor = {
      description = "Intel i915 Memory Governor Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];

      serviceConfig = {
        ExecStart = "${governorPackage}/bin/i915-governor";
        Restart = "always";

        # Variáveis de ambiente passadas via módulo Nix
        Environment = [
          "IGPU_CRITICAL_THRESHOLD=${toString cfg.thresholds.gpuCritical}"
          "MEM_PRESSURE_THRESHOLD=${toString cfg.thresholds.memoryPressure}"
        ];

        # Segurança & Capabilities
        # Precisamos de SYS_ADMIN para drop_caches e compact_memory
        CapabilityBoundingSet = "CAP_SYS_ADMIN CAP_SYS_RESOURCE";
        AmbientCapabilities = "CAP_SYS_ADMIN CAP_SYS_RESOURCE";

        # Hardening
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "full"; # Read-only em /usr, /boot, etc
        ProtectKernelTunables = false; # Precisa ser false para escrever em /proc/sys/vm/*
      };
    };
  };
}
