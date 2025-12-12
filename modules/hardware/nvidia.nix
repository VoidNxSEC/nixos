{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

{
  options = {
    kernelcore.nvidia.enable = mkEnableOption "ativa o módulo NVIDIA";
    kernelcore.nvidia.cudaSupport = mkEnableOption "ativa o suporte CUDA";
    kernelcore.nvidia.prime.enable = mkEnableOption "ativa NVIDIA Prime para laptops híbridos";
    kernelcore.nvidia.prime.sync = mkEnableOption "ativa Prime sync mode";
    kernelcore.nvidia.prime.offload = mkEnableOption "ativa Prime offload mode";
    kernelcore.nvidia.prime.intelBusId = mkOption {
      type = types.str;
      default = "PCI:0:2:0";
      description = "PCI Bus ID do chip Intel/AMD (ex: PCI:0:2:0)";
    };
    kernelcore.nvidia.prime.nvidiaBusId = mkOption {
      type = types.str;
      default = "PCI:1:0:0";
      description = "PCI Bus ID do chip NVIDIA (ex: PCI:1:0:0)";
    };
  };

  config = mkIf config.kernelcore.nvidia.enable {
    # Enable NVIDIA container toolkit for Docker/Podman GPU support
    # Disabled in VM variant since VMs don't have actual NVIDIA hardware
    hardware.nvidia-container-toolkit.enable = mkIf config.kernelcore.nvidia.cudaSupport true;

    # Disable nvidia-container-toolkit in VM variant
    virtualisation.vmVariant = {
      hardware.nvidia-container-toolkit.enable = mkForce false;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      # ⚠️ Finegrained PM DISABLED: causa race condition com NVENC quando OBS fecha
      # GPU tenta D3 suspend antes do encoder terminar cleanup → system hang
      # Sintomas: freeze total ao fechar OBS, só reboot recupera
      # Ticket: https://gitlab.freedesktop.org/drm/nvidia/-/issues/
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = true;

      # NVIDIA Prime configuration for hybrid graphics (Intel Xe + RTX 3050)
      prime = mkIf config.kernelcore.nvidia.prime.enable {
        sync.enable = config.kernelcore.nvidia.prime.sync;
        offload = mkIf config.kernelcore.nvidia.prime.offload {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = mkIf (
          config.kernelcore.nvidia.prime.intelBusId != ""
        ) config.kernelcore.nvidia.prime.intelBusId;
        nvidiaBusId = mkIf (
          config.kernelcore.nvidia.prime.nvidiaBusId != ""
        ) config.kernelcore.nvidia.prime.nvidiaBusId;
      };
    };

    # RTX 3050 6GB Optimizations
    boot.kernelParams = [
      # Enable NVIDIA power management
      "nvidia.NVreg_DynamicPowerManagement=0x02"
      # Preserve video memory allocations
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      # Enable NVIDIA GSP firmware for better power management
      "nvidia.NVreg_EnableGpuFirmware=1"
    ];

    # NVIDIA power management service for RTX 3050
    systemd.services.nvidia-rtx3050-power-management = mkIf config.kernelcore.nvidia.cudaSupport {
      description = "NVIDIA RTX 3050 6GB Power Management";
      wantedBy = [ "multi-user.target" ];
      after = [ "nvidia-persistenced.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Enable persistence mode for better power management
        ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi -pm 1 || true

        # Set power limit based on thermal profile (if exists)
        if [ -f /var/lib/thermal-profile/current ]; then
          PROFILE=$(cat /var/lib/thermal-profile/current)
          case "$PROFILE" in
            silent)
              # 35W power limit for silent operation
              ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi -pl 35 || true
              ;;
            balanced)
              # 60W power limit for balanced performance
              ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi -pl 60 || true
              ;;
            performance)
              # 95W power limit for maximum performance (RTX 3050 laptop max)
              ${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi -pl 95 || true
              ;;
          esac
        fi

        # Enable auto-boost for dynamic clock scaling
        echo 1 > /sys/class/drm/card*/device/power_dpm_force_performance_level 2>/dev/null || true
      '';
    };

    # NVIDIA GPU monitoring service
    systemd.services.nvidia-gpu-monitor = mkIf config.kernelcore.nvidia.cudaSupport {
      description = "NVIDIA GPU monitoring and optimization";
      wantedBy = [ "multi-user.target" ];
      after = [ "nvidia-rtx3050-power-management.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "30s";
      };
      script = ''
        LOG_FILE="/var/log/nvidia-monitor.log"

        while true; do
          # Log GPU stats
          if command -v nvidia-smi >/dev/null 2>&1; then
            echo "$(date +%Y-%m-%d\ %H:%M:%S)" >> "$LOG_FILE"
            nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,utilization.memory,power.draw,clocks.gr,clocks.mem \
              --format=csv,noheader >> "$LOG_FILE" 2>/dev/null || true
          fi
          
          sleep 60
        done
      '';
    };

    # VRAM optimization for 6GB configuration
    boot.kernel.sysctl = mkIf config.kernelcore.nvidia.cudaSupport {
      # Optimize memory allocator for 6GB VRAM
      "vm.min_free_kbytes" = mkDefault 65536;
    };

    hardware.graphics.extraPackages = with pkgs; [
      nvidia-vaapi-driver
      #libvdpau-va-gl
      vulkan-loader
      vulkan-tools
    ];

    # Security: Removed global CUDA environment variables
    # GPU access now controlled via:
    # 1. User group membership (nvidia group)
    # 2. Systemd service DeviceAllow directives
    # 3. Development shells (lib/shells.nix) set CUDA_* vars in isolated contexts

    # Create secure CUDA cache directory
    systemd.tmpfiles.rules = mkIf config.kernelcore.nvidia.cudaSupport [
      "d /var/cache/cuda 0770 root nvidia -"
      "L+ /var/tmp/cuda-cache - - - - /var/cache/cuda"
    ];

    # Restrict GPU device access via udev rules
    services.udev.extraRules = mkIf config.kernelcore.nvidia.cudaSupport ''
      # NVIDIA GPU devices - restrict to nvidia group
      KERNEL=="nvidia[0-9]*", GROUP="nvidia", MODE="0660"
      KERNEL=="nvidiactl", GROUP="nvidia", MODE="0660"
      KERNEL=="nvidia-uvm", GROUP="nvidia", MODE="0660"
      KERNEL=="nvidia-uvm-tools", GROUP="nvidia", MODE="0660"
      KERNEL=="nvidia-modeset", GROUP="nvidia", MODE="0660"
    '';

    # Create nvidia group for GPU access control
    users.groups.nvidia = mkIf config.kernelcore.nvidia.cudaSupport { };

    environment.systemPackages =
      with pkgs;
      [
        nvtopPackages.full # Original TUI monitor
        nvitop # Improved interactive TUI with better process management
        mission-center # Modern GUI system monitor with GPU support
      ]
      ++ lib.optionals config.kernelcore.nvidia.cudaSupport [
        cudaPackages.cudnn
        cudaPackages.cuda_nvcc
        cudaPackages.cudatoolkit
        nvidia-docker
        nvidia-container-toolkit
      ];
  };
}
