# AI/LLM Stack Module - Local AI Infrastructure
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hyperlab.ai;
in
{
  options.hyperlab.ai = {
    enable = mkEnableOption "AI/LLM stack";

    ollama = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Ollama LLM server";
      };

      acceleration = mkOption {
        type = types.enum [
          "cuda"
          "rocm"
          "cpu"
        ];
        default = "cuda";
        description = "Hardware acceleration backend";
      };

      models = mkOption {
        type = types.listOf types.str;
        default = [
          "llama3.1"
          "codellama"
          "mistral"
        ];
        description = "Models to pre-pull";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Ollama bind address";
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        description = "Ollama port";
      };
    };

    openWebUI = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Open WebUI for Ollama";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Open WebUI port";
      };
    };

    localAI = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable LocalAI (OpenAI-compatible API)";
      };
    };

    jupyter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable JupyterLab for ML development";
      };

      port = mkOption {
        type = types.port;
        default = 8888;
        description = "JupyterLab port";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ollama service
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      acceleration = cfg.ollama.acceleration;
      host = cfg.ollama.host;
      port = cfg.ollama.port;

      # Environment for models
      environmentVariables = {
        OLLAMA_MODELS = "/var/lib/ollama/models";
        OLLAMA_NUM_PARALLEL = "4";
        OLLAMA_MAX_LOADED_MODELS = "2";
      };

      # Load models on startup
      loadModels = cfg.ollama.models;
    };

    # Open WebUI via OCI container
    virtualisation.oci-containers.containers = mkMerge [
      # Open WebUI
      (mkIf cfg.openWebUI.enable {
        open-webui = {
          image = "ghcr.io/open-webui/open-webui:main";
          ports = [ "${toString cfg.openWebUI.port}:8080" ];
          volumes = [
            "open-webui-data:/app/backend/data"
          ];
          environment = {
            OLLAMA_BASE_URL = "http://host.docker.internal:${toString cfg.ollama.port}";
            WEBUI_SECRET_KEY = "hyperlab-secret-change-me";
            ENABLE_SIGNUP = "true";
          };
          extraOptions = [
            "--add-host=host.docker.internal:host-gateway"
          ];
        };
      })

      # LocalAI
      (mkIf cfg.localAI.enable {
        localai = {
          image = "localai/localai:latest-gpu-nvidia-cuda-12";
          ports = [ "8081:8080" ];
          volumes = [
            "localai-models:/models"
          ];
          environment = {
            MODELS_PATH = "/models";
            DEBUG = "false";
          };
          extraOptions = [
            "--gpus=all"
          ];
        };
      })
    ];

    # JupyterLab service
    systemd.services.jupyter = mkIf cfg.jupyter.enable {
      description = "JupyterLab ML Development Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = config.hyperlab.user or "pina";
        WorkingDirectory = "/home/${config.hyperlab.user or "pina"}/notebooks";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/${config.hyperlab.user or "pina"}/notebooks";
        ExecStart = ''
          ${
            pkgs.python311.withPackages (
              ps: with ps; [
                jupyter
                jupyterlab
                ipykernel
                numpy
                pandas
                matplotlib
                seaborn
                scikit-learn
                torch
                transformers
              ]
            )
          }/bin/jupyter lab \
            --ip=0.0.0.0 \
            --port=${toString cfg.jupyter.port} \
            --no-browser \
            --NotebookApp.token=""
            --NotebookApp.password=""
        '';
        Restart = "always";
        RestartSec = "10";
      };
    };

    # Python ML environment available system-wide
    environment.systemPackages = with pkgs; [
      # Python with ML packages
      (python311.withPackages (
        ps: with ps; [
          # Core ML
          torch
          torchvision
          torchaudio
          transformers
          accelerate
          datasets

          # Data science
          numpy
          pandas
          scipy
          scikit-learn

          # Visualization
          matplotlib
          seaborn
          plotly

          # Deep learning utilities
          einops
          safetensors
          huggingface-hub

          # LLM specific
          langchain
          openai
          tiktoken

          # API development
          fastapi
          uvicorn
          pydantic

          # Notebooks
          jupyter
          jupyterlab
          ipykernel
          ipywidgets
        ]
      ))

      # CLI tools
      ollama

      # Model management
      huggingface-hub
    ];

    # Create model directories
    systemd.tmpfiles.rules = [
      "d /var/lib/ollama/models 0755 root root -"
      "d /var/lib/localai/models 0755 root root -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [
      cfg.ollama.port
      cfg.openWebUI.port
      cfg.jupyter.port
      8081 # LocalAI
    ];

    # Performance tuning for AI workloads
    boot.kernel.sysctl = {
      # More memory for AI models
      "vm.overcommit_memory" = 1;
      "vm.swappiness" = 10;

      # Network optimization
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
    };
  };
}
