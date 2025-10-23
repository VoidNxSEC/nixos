{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.services.llamacpp;
in
{
  options.services.llamacpp = {
    enable = lib.mkEnableOption "LLaMA C++ server with CUDA support";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages;
      };
      defaultText = lib.literalExpression ''
        pkgs.llama-cpp.override {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        }
      '';
      description = "The llama-cpp package to use.";
    };

    model = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/llama-cpp/models/mistral-7b.gguf";
      description = "Path to the model file.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "IP address the LLaMA C++ server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Listen port for LLaMA C++ server.";
    };

    n_threads = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Number of threads to use for generation.";
    };

    n_gpu_layers = lib.mkOption {
      type = lib.types.int;
      default = 35;
      description = ''
        Number of model layers to offload to GPU.
        Set to 0 to use CPU only.
        Recommended values: 22-35 for 6GB GPU, 35+ for larger GPUs.
      '';
    };

    n_parallel = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of parallel sequences to process.";
    };

    n_ctx = lib.mkOption {
      type = lib.types.int;
      default = 2048;
      description = "Context window size (in tokens).";
    };

    n_batch = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = "Batch size for prompt processing.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--temp"
        "0.8"
        "--top-p"
        "0.9"
        "--repeat-penalty"
        "1.1"
      ];
      description = ''
        Extra flags passed to llama-server.
        Common options include --temp, --top-p, --repeat-penalty, etc.
        Basic options like --threads, --gpu-layers, --ctx-size are configured via dedicated options.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to open the firewall for LLaMA C++ server.
        This adds {option}`port` to [](#opt-networking.firewall.allowedTCPPorts).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.llamacpp = {
      description = "LLaMA C++ server with CUDA support";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        CUDA_VISIBLE_DEVICES = "0";
        GGML_CUDA_NO_PEER_COPY = "1";
        CUDA_LAUNCH_BLOCKING = "1";
      };

      serviceConfig = {
        Type = "idle";
        ExecStart = lib.concatStringsSep " " (
          [
            "${lib.getExe' cfg.package "llama-server"}"
            "--log-disable"
            "--host ${cfg.host}"
            "--port ${toString cfg.port}"
            "--model ${cfg.model}"
            "--threads ${toString cfg.n_threads}"
            "--gpu-layers ${toString cfg.n_gpu_layers}"
            "--parallel ${toString cfg.n_parallel}"
            "--ctx-size ${toString cfg.n_ctx}"
            "--batch-size ${toString cfg.n_batch}"
          ]
          ++ cfg.extraFlags
        );
        Restart = "always";
        RestartSec = 10;

        # Use declaratively created user instead of DynamicUser
        DynamicUser = lib.mkForce false;
        User = "llamacpp";
        Group = "llamacpp";

        # Graceful shutdown for GPU memory release
        TimeoutStopSec = "30s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";

        # GPU device access
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
        ];

        # for GPU acceleration
        PrivateDevices = false;

        # hardening
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        NoNewPrivileges = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallErrorNumber = "EPERM";
        ProtectProc = "invisible";
        ProtectHostname = true;
        ProcSubset = "pid";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ ];
}
