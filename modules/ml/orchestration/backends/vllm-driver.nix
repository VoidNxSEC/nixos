{
  config,
  lib,
  pkgs,
  ...
}:

# vLLM Backend Driver
#
# Driver for vLLM integration with ML Offload orchestration.
# Implements standard backend interface:
#   - load(model_path) → success/failure
#   - unload() → release VRAM
#   - switch(model_path) → hot-reload model
#   - status() → current state, loaded model, VRAM usage
#   - health() → service health check

with lib;

let
  cfg = config.kernelcore.ml.offload.backends.vllm;
  offloadCfg = config.kernelcore.ml.offload;
  vllmService = config.services.vllm;
in
{
  options.kernelcore.ml.offload.backends.vllm = {
    enable = mkEnableOption "vLLM backend driver for ML Offload";

    endpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8000";
      description = "vLLM API endpoint URL";
    };

    healthCheckInterval = mkOption {
      type = types.int;
      default = 30;
      description = "Health check interval in seconds";
    };

    loadTimeout = mkOption {
      type = types.int;
      default = 300;
      description = "Model load timeout in seconds";
    };

    capabilities = mkOption {
      type = types.listOf types.str;
      default = [
        "chat"
        "completion"
        "embeddings"
      ];
      readOnly = true;
      description = "Supported capabilities";
    };
  };

  config = mkIf (offloadCfg.enable && cfg.enable) {
    # Ensure vLLM service is available
    assertions = [
      {
        assertion = vllmService.enable or false;
        message = "vLLM backend driver requires services.vllm.enable = true";
      }
    ];

    # Register backend with offload system
    kernelcore.ml.offload.backends.availableBackends = [ "vllm" ];

    # vLLM driver control scripts
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "ml-vllm-status" ''
        #!/usr/bin/env bash
        # Get vLLM backend status

        ENDPOINT="${cfg.endpoint}"

        echo "=== vLLM Backend Status ==="

        # Check service status
        if systemctl is-active --quiet vllm; then
          echo "Service: RUNNING"
        else
          echo "Service: STOPPED"
          exit 1
        fi

        # Check API health
        if ${pkgs.curl}/bin/curl -s "$ENDPOINT/health" | ${pkgs.jq}/bin/jq -e '.status == "ok"' > /dev/null 2>&1; then
          echo "API: HEALTHY"
        else
          echo "API: UNHEALTHY"
        fi

        # Get model info
        MODEL_INFO=$(${pkgs.curl}/bin/curl -s "$ENDPOINT/v1/models" 2>/dev/null)
        if [ $? -eq 0 ]; then
          echo "Models:"
          echo "$MODEL_INFO" | ${pkgs.jq}/bin/jq -r '.data[].id // "none"' 2>/dev/null
        fi

        # VRAM usage (if nvidia-smi available)
        if command -v nvidia-smi &> /dev/null; then
          echo ""
          echo "=== GPU Memory ==="
          nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader
        fi
      '')

      (pkgs.writeShellScriptBin "ml-vllm-health" ''
        #!/usr/bin/env bash
        # Health check for vLLM backend

        ENDPOINT="${cfg.endpoint}"
        TIMEOUT=5

        if ${pkgs.curl}/bin/curl -sf --max-time $TIMEOUT "$ENDPOINT/health" > /dev/null 2>&1; then
          echo "HEALTHY"
          exit 0
        else
          echo "UNHEALTHY"
          exit 1
        fi
      '')

      (pkgs.writeShellScriptBin "ml-vllm-models" ''
        #!/usr/bin/env bash
        # List loaded models in vLLM

        ENDPOINT="${cfg.endpoint}"

        ${pkgs.curl}/bin/curl -s "$ENDPOINT/v1/models" | ${pkgs.jq}/bin/jq '.data[] | {id, created, owned_by}'
      '')
    ];

    # Shell aliases for vLLM management
    programs.bash.shellAliases = {
      vllm-status = "ml-vllm-status";
      vllm-health = "ml-vllm-health";
      vllm-models = "ml-vllm-models";
      vllm-logs = "sudo journalctl -u vllm -n 100 -f";
      vllm-restart = "sudo systemctl restart vllm";
    };
  };
}
