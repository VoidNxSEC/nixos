# GPU Compute Module - CUDA/ROCm Support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hyperlab.gpu;
in
{
  options.hyperlab.gpu = {
    enable = mkEnableOption "GPU compute support";

    vendor = mkOption {
      type = types.enum [
        "nvidia"
        "amd"
        "intel"
      ];
      default = "nvidia";
      description = "GPU vendor";
    };

    cudaVersion = mkOption {
      type = types.str;
      default = "12";
      description = "CUDA version (for NVIDIA)";
    };

    enablePrime = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NVIDIA Prime for laptops";
    };

    passthrough = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPU passthrough for VMs";
      };

      pciIds = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "10de:1234"
          "10de:5678"
        ];
        description = "PCI IDs for VFIO passthrough";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common GPU settings
    {
      # OpenGL
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Vulkan
      environment.systemPackages = with pkgs; [
        vulkan-tools
        vulkan-loader
        vulkan-validation-layers
        glxinfo
        nvtopPackages.full
      ];
    }

    # NVIDIA specific
    (mkIf (cfg.vendor == "nvidia") {
      # Load NVIDIA drivers
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Modesetting required for Wayland
        modesetting.enable = true;

        # Power management
        powerManagement.enable = false;
        powerManagement.finegrained = false;

        # Use open source kernel module (for newer cards)
        open = mkDefault true;

        # Enable settings app
        nvidiaSettings = true;

        # Driver package
        package = config.boot.kernelPackages.nvidiaPackages.stable;

        # Prime configuration for laptops
        prime = mkIf cfg.enablePrime {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          # These need to be configured per-machine
          # intelBusId = "PCI:0:2:0";
          # nvidiaBusId = "PCI:1:0:0";
        };
      };

      # CUDA packages
      environment.systemPackages = with pkgs; [
        cudaPackages.cudatoolkit
        cudaPackages.cudnn
        cudaPackages.cutensor
        cudaPackages.nccl

        # CUDA utilities
        cudaPackages.cuda_nvcc

        # Monitoring
        nvtopPackages.nvidia
      ];

      # CUDA environment
      environment.sessionVariables = {
        CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
        EXTRA_LDFLAGS = "-L${pkgs.linuxPackages.nvidia_x11}/lib";
        EXTRA_CCFLAGS = "-I${pkgs.cudaPackages.cudatoolkit}/include";
      };

      # LD library path for CUDA
      environment.variables = {
        LD_LIBRARY_PATH = lib.mkForce (
          lib.concatStringsSep ":" [
            "${pkgs.cudaPackages.cudatoolkit}/lib"
            "${pkgs.cudaPackages.cudnn}/lib"
            "${pkgs.linuxPackages.nvidia_x11}/lib"
            "/run/opengl-driver/lib"
          ]
        );
      };
    })

    # AMD specific
    (mkIf (cfg.vendor == "amd") {
      # AMDGPU driver
      services.xserver.videoDrivers = [ "amdgpu" ];

      # ROCm for compute
      hardware.amdgpu = {
        opencl.enable = true;
        amdvlk = {
          enable = true;
          support32Bit.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        rocmPackages.rocm-smi
        rocmPackages.rocminfo
        rocmPackages.clr
      ];

      # HIP environment
      environment.sessionVariables = {
        HIP_PATH = "${pkgs.rocmPackages.clr}";
      };
    })

    # GPU Passthrough for VMs
    (mkIf cfg.passthrough.enable {
      # IOMMU
      boot.kernelParams = [
        (if cfg.vendor == "nvidia" then "intel_iommu=on" else "amd_iommu=on")
        "iommu=pt"
        "vfio-pci.ids=${concatStringsSep "," cfg.passthrough.pciIds}"
        "video=vesafb:off,efifb:off"
      ];

      # VFIO modules
      boot.initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];

      # Blacklist GPU drivers for passthrough
      boot.blacklistedKernelModules =
        if cfg.vendor == "nvidia" then
          [
            "nvidia"
            "nouveau"
            "nvidiafb"
          ]
        else
          [
            "amdgpu"
            "radeon"
          ];

      boot.extraModprobeConfig = ''
        softdep drm pre: vfio-pci
        options vfio-pci ids=${concatStringsSep "," cfg.passthrough.pciIds}
      '';
    })
  ]);
}
