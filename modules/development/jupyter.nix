{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.development.jupyter = {
      enable = mkEnableOption "Enable Jupyter notebook environment";

      kernels = {
        python.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Python kernel";
        };

        rust.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Rust kernel (evcxr)";
        };

        nodejs.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Node.js kernel";
        };

        nix.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Nix kernel";
        };
      };

      service.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jupyter-Daemon";
      };

      extensions = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable common Jupyter extensions";
        };
      };
    };
  };

  config = mkIf config.kernelcore.development.jupyter.enable {
    environment.systemPackages =
      with pkgs;
      [
        # Core Jupyter
        jupyter
        jupyter-all
        uv

        # Python kernel (always included if python kernel enabled)
      ]
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.python.enable [
        python313Packages.ipykernel
        python313Packages.ipywidgets
        python313Packages.matplotlib
        python313Packages.numpy
        python313Packages.pandas
        python313Packages.scipy
        python313Packages.seaborn
        python313Packages.plotly
        python313Packages.scikit-learn
        # python313Packages.torchWithCuda  # DISABLED: Use container version for faster rebuilds
        python313Packages.litellm
        python313Packages.anthropic
        python313Packages.jupyter-core
        python313Packages.pip
        python313Packages.virtualenv
        python313Packages.pipx
        python313Packages.pip-tools
        python313Packages.uv
        python313Packages.yt-dlp
        python313Packages.langchain-xai
        python313Packages.langchain-mistralai
        python313Packages.pillow
        python313Packages.google-genai
        #python313Packages.crewai
        python313Packages.transformers
        python313Packages.setuptools
        python313Packages.pandas
        python313Packages.wheel
        python313Packages.build
        python313Packages.twine

        # Package management
        python313Packages.setuptools
        python313Packages.wheel

      ]
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.rust.enable [
        evcxr

      ]
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.nodejs.enable [
        nodePackages.elasticdump

      ]
      ++ lib.optionals config.kernelcore.development.jupyter.extensions.enable [
        python313Packages.jupyterlab-git
        python313Packages.nbconvert
        python313Packages.nbformat
        python313Packages.jupyter-client
        python313Packages.jupyter-sphinx
        python313Packages.jupyter-server-terminals
        python313Packages.jupyter-server
        python313Packages.jupyter-repo2docker
      ];

    systemd.user.services.jupyter = mkIf config.kernelcore.development.jupyter.service.enable {
      description = "JupyterLab Server";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.jupyter}/bin/jupyter-lab --ip=127.0.0.1 --no-browser";
        Restart = "on-failure";
        LoadCredential = "jupyter-token:/etc/credstore/jupyter-token";

        # GPU access (explicit)
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
        ];
        SupplementaryGroups = [ "nvidia" ];

        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
      };
    };

  };
}
