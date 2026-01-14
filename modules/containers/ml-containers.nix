# ============================================
# ML/AI Container Kits Module
# ============================================
# Purpose: Declarative NixOS containers for AI/ML workloads
# Inspired by: ~/dev/low-level/docker-hub/ml-clusters/kits/
# Containers: Ollama, ComfyUI, Jupyter, vLLM, LocalAI
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.containers.ml;

  # Common network configuration for ML containers
  mlNetworkBase = "192.168.200";
  hostBaseIP = "${mlNetworkBase}.10";

  # Helper to generate sequential IPs
  mkContainerIP = offset: "${mlNetworkBase}.${toString (10 + offset)}";

  # Common GPU passthrough configuration
  gpuBindMounts = {
    "/dev/nvidia0" = {
      hostPath = "/dev/nvidia0";
      isReadOnly = false;
    };
    "/dev/nvidiactl" = {
      hostPath = "/dev/nvidiactl";
      isReadOnly = false;
    };
    "/dev/nvidia-uvm" = {
      hostPath = "/dev/nvidia-uvm";
      isReadOnly = false;
    };
  };

  gpuAllowedDevices = [
    {
      node = "/dev/nvidia0";
      modifier = "rw";
    }
    {
      node = "/dev/nvidiactl";
      modifier = "rw";
    }
    {
      node = "/dev/nvidia-uvm";
      modifier = "rw";
    }
  ];

  # Common packages for ML containers
  mlCommonPackages = with pkgs; [
    python313
    python313Packages.pip
    python313Packages.virtualenv
    python313Packages.uv
    git
    curl
    wget
    htop
    neovim
  ];

  # GPU-enabled packages
  mlGpuPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.nccl
  ];
in
{
  options.kernelcore.containers.ml = {
    enable = mkEnableOption "Enable ML/AI container infrastructure";

    # Individual container enables
    ollama = {
      enable = mkEnableOption "Ollama LLM inference container";
      port = mkOption {
        type = types.port;
        default = 11434;
        description = "Ollama API port";
      };
      modelsPath = mkOption {
        type = types.str;
        default = "/var/lib/ollama/models";
        description = "Host path for Ollama models";
      };
      bindLlamaCpp = mkOption {
        type = types.bool;
        default = false;
        description = "Bind mount llama.cpp from host for local inference";
      };
      llamaCppPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to llama.cpp binary on host (auto-detected if null)";
      };
    };

    jupyter = {
      enable = mkEnableOption "Jupyter Lab container for ML development";
      port = mkOption {
        type = types.port;
        default = 8888;
        description = "Jupyter Lab port";
      };
      notebooksPath = mkOption {
        type = types.str;
        default = "/home/kernelcore/dev/notebooks";
        description = "Host path for notebooks";
      };
    };

    comfyui = {
      enable = mkEnableOption "ComfyUI image generation container";
      port = mkOption {
        type = types.port;
        default = 8188;
        description = "ComfyUI web interface port";
      };
    };

    vllm = {
      enable = mkEnableOption "vLLM high-performance inference container";
      port = mkOption {
        type = types.port;
        default = 8000;
        description = "vLLM API port";
      };
    };

    localai = {
      enable = mkEnableOption "LocalAI multi-modal inference container";
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "LocalAI API port";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure container networking is enabled
    boot.enableContainers = true;

    # Network configuration for ML containers
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-ml-+" ];
      externalInterface = "wlp62s0";
    };

    networking.firewall = {
      trustedInterfaces = [ "ve-ml-+" ];
      allowedTCPPorts =
        [ ]
        ++ optional cfg.ollama.enable cfg.ollama.port
        ++ optional cfg.jupyter.enable cfg.jupyter.port
        ++ optional cfg.comfyui.enable cfg.comfyui.port
        ++ optional cfg.vllm.enable cfg.vllm.port
        ++ optional cfg.localai.enable cfg.localai.port;
    };

    # ═══════════════════════════════════════════════════════════
    # OLLAMA CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.ml-ollama = mkIf cfg.ollama.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 1;

      bindMounts =
        gpuBindMounts
        // {
          "${cfg.ollama.modelsPath}" = {
            hostPath = cfg.ollama.modelsPath;
            isReadOnly = false;
          };
        }
        // optionalAttrs cfg.ollama.bindLlamaCpp {
          "/usr/local/bin/llama-cli" = {
            hostPath =
              if cfg.ollama.llamaCppPath != null then
                cfg.ollama.llamaCppPath
              else
                "${pkgs.llama-cpp}/bin/llama-cli";
            isReadOnly = true;
          };
          "/usr/local/bin/llama-server" = {
            hostPath =
              if cfg.ollama.llamaCppPath != null then
                dirOf cfg.ollama.llamaCppPath + "/llama-server"
              else
                "${pkgs.llama-cpp}/bin/llama-server";
            isReadOnly = true;
          };
        };

      allowedDevices = gpuAllowedDevices;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.ollama.port ];
            };
          };

          hardware.graphics.enable = true;
          nixpkgs.config.allowUnfree = true;

          services.ollama = {
            enable = true;
            package = pkgs.ollama-cuda; # Use CUDA-enabled package
            host = "0.0.0.0";
            port = cfg.ollama.port;
          };

          environment.systemPackages = mlCommonPackages ++ mlGpuPackages;

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # JUPYTER LAB CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.ml-jupyter = mkIf cfg.jupyter.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 2;

      bindMounts = gpuBindMounts // {
        "${cfg.jupyter.notebooksPath}" = {
          hostPath = cfg.jupyter.notebooksPath;
          isReadOnly = false;
        };
      };

      allowedDevices = gpuAllowedDevices;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.jupyter.port ];
            };
          };

          hardware.graphics.enable = true;
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages =
            mlCommonPackages
            ++ mlGpuPackages
            ++ (with pkgs; [
              jupyter-all
              python313Packages.jupyter-core
              python313Packages.jupyterlab
              python313Packages.ipython
              python313Packages.numpy
              python313Packages.pandas
              python313Packages.matplotlib
              python313Packages.scikit-learn
              python313Packages.torch
              python313Packages.torchvision
            ]);

          # Jupyter service configuration
          systemd.services.jupyter = {
            description = "Jupyter Lab Server";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "simple";
              User = "root";
              WorkingDirectory = cfg.jupyter.notebooksPath;
              ExecStart = "${pkgs.python313Packages.jupyterlab}/bin/jupyter-lab --ip=0.0.0.0 --port=${toString cfg.jupyter.port} --no-browser --allow-root";
              Restart = "on-failure";
            };
          };

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # COMFYUI CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.ml-comfyui = mkIf cfg.comfyui.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 3;

      bindMounts = gpuBindMounts;
      allowedDevices = gpuAllowedDevices;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.comfyui.port ];
            };
          };

          hardware.graphics.enable = true;
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages =
            mlCommonPackages
            ++ mlGpuPackages
            ++ (with pkgs; [
              python313Packages.torch
              python313Packages.torchvision
              python313Packages.pillow
              python313Packages.numpy
            ]);

          # ComfyUI will be installed in /opt/comfyui
          systemd.tmpfiles.rules = [ "d /opt/comfyui 0755 root root -" ];

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # vLLM CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.ml-vllm = mkIf cfg.vllm.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 4;

      bindMounts = gpuBindMounts;
      allowedDevices = gpuAllowedDevices;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.vllm.port ];
            };
          };

          hardware.graphics.enable = true;
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages =
            mlCommonPackages
            ++ mlGpuPackages
            ++ (with pkgs; [
              python313Packages.vllm
              python313Packages.transformers
              python313Packages.fastapi
              python313Packages.uvicorn
            ]);

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # LOCALAI CONTAINER
    # ═══════════════════════════════════════════════════════════
    containers.ml-localai = mkIf cfg.localai.enable {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostBaseIP;
      localAddress = mkContainerIP 5;

      bindMounts = gpuBindMounts;
      allowedDevices = gpuAllowedDevices;

      config =
        { config, pkgs, ... }:
        {
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            defaultGateway = {
              address = hostBaseIP;
              interface = "eth0";
            };
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            firewall = {
              enable = true;
              allowedTCPPorts = [ cfg.localai.port ];
            };
          };

          hardware.graphics.enable = true;
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = mlCommonPackages ++ mlGpuPackages;

          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # SHELL ALIASES FOR ML CONTAINERS
    # ═══════════════════════════════════════════════════════════
    environment.shellAliases = {
      # Ollama shortcuts
      ml-ollama-enter = "nixos-container root-login ml-ollama";
      ml-ollama-status = "nixos-container status ml-ollama";
      ml-ollama-start = "nixos-container start ml-ollama";
      ml-ollama-stop = "nixos-container stop ml-ollama";
      ollama-list = "curl -s http://${mkContainerIP 1}:${toString cfg.ollama.port}/api/tags | ${pkgs.jq}/bin/jq";

      # Jupyter shortcuts
      ml-jupyter-enter = "nixos-container root-login ml-jupyter";
      ml-jupyter-status = "nixos-container status ml-jupyter";
      ml-jupyter-start = "nixos-container start ml-jupyter";
      ml-jupyter-stop = "nixos-container stop ml-jupyter";

      # ComfyUI shortcuts
      ml-comfyui-enter = "nixos-container root-login ml-comfyui";
      ml-comfyui-status = "nixos-container status ml-comfyui";
      ml-comfyui-start = "nixos-container start ml-comfyui";
      ml-comfyui-stop = "nixos-container stop ml-comfyui";

      # vLLM shortcuts
      ml-vllm-enter = "nixos-container root-login ml-vllm";
      ml-vllm-status = "nixos-container status ml-vllm";
      ml-vllm-start = "nixos-container start ml-vllm";
      ml-vllm-stop = "nixos-container stop ml-vllm";

      # LocalAI shortcuts
      ml-localai-enter = "nixos-container root-login ml-localai";
      ml-localai-status = "nixos-container status ml-localai";
      ml-localai-start = "nixos-container start ml-localai";
      ml-localai-stop = "nixos-container stop ml-localai";

      # Bulk operations
      ml-status-all = "nixos-container list | grep '^ml-' | xargs -I {} nixos-container status {}";
      ml-stop-all = "nixos-container list | grep '^ml-' | xargs -I {} nixos-container stop {}";
      ml-start-all = "nixos-container list | grep '^ml-' | xargs -I {} nixos-container start {}";
    };
  };
}
