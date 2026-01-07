{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Import centralized Python package library
  pythonLib = import ../../lib/python.nix { inherit pkgs; };
in
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
      ]
      # Python packages organized by category (from lib/python.nix)
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.python.enable (
        pythonLib.core
        ++ pythonLib.datascience
        ++ pythonLib.ml
        ++ pythonLib.development
        ++ pythonLib.utilities
        # Note: Jupyter kernel packages included separately below
        # torchWithCuda DISABLED: Use container version for faster rebuilds
      )
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.rust.enable [
        evcxr

      ]
      ++ lib.optionals config.kernelcore.development.jupyter.kernels.nodejs.enable [
        nodePackages_latest.node2nix
      ]
      # Jupyter extensions and server components (from lib/python.nix)
      ++ lib.optionals config.kernelcore.development.jupyter.extensions.enable pythonLib.jupyter;

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
