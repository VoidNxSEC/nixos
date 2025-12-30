{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.ml.models-storage;
in
{
  options.kernelcore.ml.models-storage = {
    enable = mkEnableOption "Enable standardized ML models storage structure";

    baseDirectory = mkOption {
      type = types.str;
      default = "/var/lib/ml-models";
      description = "Base directory for all ML models";
    };
  };

  config = mkIf cfg.enable {
    # User creation moved to modules/system/ml-gpu-users.nix for centralized management
    # Enable it in configuration.nix: kernelcore.system.ml-gpu-users.enable = true;

    # Create standardized directory structure for ML models
    systemd.tmpfiles.rules = [
      # Base directories
      "d ${cfg.baseDirectory} 0755 root root -"

      # Llama.cpp models (GGUF format)
      "d ${cfg.baseDirectory}/llamacpp 0755 llamacpp llamacpp -"
      "d ${cfg.baseDirectory}/llamacpp/models 0775 llamacpp llamacpp -"
      "L+ /var/lib/llamacpp - - - - ${cfg.baseDirectory}/llamacpp"
      # Recursively fix permissions for llamacpp directories
      "Z ${cfg.baseDirectory}/llamacpp 0775 llamacpp llamacpp -"

      # Hugging Face cache
      "d ${cfg.baseDirectory}/huggingface 0755 root root -"
      "d ${cfg.baseDirectory}/huggingface/hub 0755 root root -"
      "d ${cfg.baseDirectory}/huggingface/datasets 0755 root root -"

      # GGML/GGUF models
      "d ${cfg.baseDirectory}/gguf 0755 root root -"

      # vLLM models
      "d ${cfg.baseDirectory}/vllm 0755 root root -"

      # Text Generation Inference models
      "d ${cfg.baseDirectory}/tgi 0755 root root -"

      # Custom fine-tuned models
      "d ${cfg.baseDirectory}/custom 0755 root root -"

      # Model conversion workspace
      "d ${cfg.baseDirectory}/conversion 0755 root root -"

      # Shared model cache
      "d ${cfg.baseDirectory}/cache 0755 root root -"
    ];

    # Environment variables for model storage
    environment.variables = {
      ML_MODELS_BASE = cfg.baseDirectory;
      LLAMACPP_MODELS_PATH = "${cfg.baseDirectory}/llamacpp";
      HF_HOME = "${cfg.baseDirectory}/huggingface";
      HF_HUB_CACHE = "${cfg.baseDirectory}/huggingface/hub";
      HF_DATASETS_CACHE = "${cfg.baseDirectory}/huggingface/datasets";
      TRANSFORMERS_CACHE = "${cfg.baseDirectory}/huggingface/hub";
    };

    # Convenience aliases for model management
    environment.shellAliases = {
      ml-models = "cd ${cfg.baseDirectory}";
      ml-ls = "${pkgs.eza}/bin/eza -la --tree --level=2 ${cfg.baseDirectory}";
      ml-du = "${pkgs.coreutils}/bin/du -sh ${cfg.baseDirectory}/*";
      ml-clean-cache = "rm -rf ${cfg.baseDirectory}/cache/*";
    };

    # Model storage monitoring service
    systemd.services.ml-storage-monitor = {
      description = "ML Models Storage Monitor";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "ml-storage-check" ''
          #!/bin/sh
          BASE_DIR="${cfg.baseDirectory}"

          # Check available space
          AVAIL=$(df -BG "$BASE_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')

          if [ "$AVAIL" -lt 50 ]; then
            echo "WARNING: ML models storage low: ''${AVAIL}GB remaining"
            logger -t ml-storage "Low disk space: ''${AVAIL}GB remaining"
          fi

          # Log storage usage
          echo "ML Models Storage Usage:"
          ${pkgs.coreutils}/bin/du -sh "$BASE_DIR"/* 2>/dev/null || true
        '';
      };
    };

    # Weekly storage monitoring timer
    systemd.timers.ml-storage-monitor = {
      description = "ML Storage Monitor Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
}
