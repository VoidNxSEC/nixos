{
  config,
  lib,
  pkgs,
  ...
}:

# LLaMA.cpp SWAP - Hot Model Reloading System
#
# Based on llama-cpp-turbo with hot swap capability.
# Allows quick model switching via symlink with ~5-10s downtime.
#
# Optimizations enabled (same as turbo):
# - CUDA Graphs: Reduces kernel launch overhead (~1.2x speedup)
# - Flash Attention: Memory-efficient attention (lower VRAM, faster long context)
# - Speculative Decoding: Draft model acceleration (1.5-3x speedup)
# - Continuous Batching: Dynamic batch processing for concurrent requests
# - Memory-mapped I/O: Fast model loading with mmap/mlock
#
# Model swapping:
# - Model path points to symlink: /var/lib/llamacpp-swap/current-model
# - Scripts update symlink and restart service gracefully
# - Swap time: ~5-10s total downtime
#
# Phase 5 split:
# - default.nix → implementation (user, tmpfiles, systemd service, firewall)
# - options.nix → kernelcore.ml.inference.llamacpp-swap option declarations
# - scripts.nix → launcher + memory-equilibrium shell scripts

let
  cfg = config.kernelcore.ml.inference.llamacpp-swap;

  scripts = import ./scripts.nix { inherit lib pkgs cfg; };
  memoryEquilibriumScript = scripts.memoryEquilibrium;
  launchScript = scripts.launch;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    # Create dedicated user for llamacpp-swap
    users.users.llamacpp-swap = {
      isSystemUser = true;
      group = "llamacpp-swap";
      home = "/var/lib/llamacpp-swap";
      description = "LlamaSwap service user";
    };

    users.groups.llamacpp-swap = { };

    # Create swap directory structure
    systemd.tmpfiles.rules = [
      "d /var/lib/llamacpp-swap 0755 llamacpp-swap llamacpp-swap -"
      "d /var/lib/llamacpp-swap/profiles 0755 llamacpp-swap llamacpp-swap -"
    ];

    systemd.services.llamacpp-swap = {
      description = "LLaMA.cpp SWAP - Hot Model Reloading Inference Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        # CUDA optimizations
        CUDA_VISIBLE_DEVICES = "0";
        GGML_CUDA_NO_PEER_COPY = "1";
        # Enable CUDA Graphs (default in recent llama.cpp)
        GGML_CUDA_ENABLE_UNIFIED_MEMORY = "0";
        # Reduce CPU overhead
        OMP_NUM_THREADS = toString cfg.n_threads;
      };

      serviceConfig = {
        Type = "exec";
        ExecStart = "${launchScript}";

        Restart = "always";
        RestartSec = 5;
        MemoryHigh = "7G";
        MemoryMax = "10G";
        MemoryAccounting = true;
        OOMScoreAdjust = -500;
        ManagedOOMPreference = "avoid";
        Slice = "ml.slice";
        LimitMEMLOCK = "infinity";

        # Use dedicated user
        DynamicUser = lib.mkForce false;
        User = "llamacpp-swap";
        Group = "llamacpp-swap";

        # Graceful shutdown with GPU memory release
        TimeoutStopSec = "30s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";

        # GPU device access
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
        ];

        # Required for GPU
        PrivateDevices = false;

        # Security hardening
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
        MemoryDenyWriteExecute = false;
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

        # Read-only bindings for model storage
        ReadOnlyPaths = [
          "/var/lib/llamacpp-swap"
          "/var/lib/ml-models"
        ];

        # Writable for symlink management (needed for service startup)
        ReadWritePaths = [ ];
      }
      // lib.optionalAttrs (cfg.memoryLow != null) {
        MemoryLow = cfg.memoryLow;
      }
      // lib.optionalAttrs (cfg.memoryHigh != null) {
        MemoryHigh = cfg.memoryHigh;
      }
      // lib.optionalAttrs (cfg.memoryMax != null) {
        MemoryMax = cfg.memoryMax;
      }
      // lib.optionalAttrs cfg.memoryEquilibrium.enable {
        ExecStartPre = "+${memoryEquilibriumScript}";
      }
      // lib.optionalAttrs cfg.memoryEquilibrium.disableServiceSwap {
        MemorySwapMax = "0";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };

  meta.maintainers = with lib.maintainers; [ marcosfpina ];
}
