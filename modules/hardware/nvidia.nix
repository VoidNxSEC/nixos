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
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = true;

      # NVIDIA Prime configuration
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
