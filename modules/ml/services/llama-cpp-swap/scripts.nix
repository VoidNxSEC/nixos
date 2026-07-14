# llamacpp-swap — runtime shell scripts (part of the llama-cpp-swap/ split;
# see ./default.nix). Returns the scripts as an attribute set:
# - memoryEquilibrium → pre-start VRAM/RAM balancing (ExecStartPre)
# - launch            → llama-server launcher honoring the active profile
{
  lib,
  pkgs,
  cfg,
}:

let
  boolToShell = value: if value then "true" else "false";
in
{
  memoryEquilibrium = pkgs.writeShellScript "llamacpp-swap-memory-equilibrium" ''
    set -euo pipefail

    mem_available_kb=$(${pkgs.gawk}/bin/awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    swap_total_kb=$(${pkgs.gawk}/bin/awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    swap_free_kb=$(${pkgs.gawk}/bin/awk '/^SwapFree:/ {print $2}' /proc/meminfo)
    swap_used_kb=$((swap_total_kb - swap_free_kb))
    reserve_kb=$((${toString cfg.memoryEquilibrium.reserveMemoryMiB} * 1024))

    echo "llamacpp-swap memory equilibrium: available=$((mem_available_kb / 1024))MiB swap_used=$((swap_used_kb / 1024))MiB reserve=${toString cfg.memoryEquilibrium.reserveMemoryMiB}MiB"

    if [ "$swap_used_kb" -gt 0 ]; then
      required_kb=$((swap_used_kb + reserve_kb))

      if [ "$mem_available_kb" -gt "$required_kb" ]; then
        echo "llamacpp-swap memory equilibrium: flushing swap back to RAM before inference"
        if ${pkgs.util-linux}/bin/swapoff -a; then
          ${pkgs.util-linux}/bin/swapon -a
          echo "llamacpp-swap memory equilibrium: swap flush complete"
        else
          echo "llamacpp-swap memory equilibrium: swapoff failed, restoring swap and continuing" >&2
          ${pkgs.util-linux}/bin/swapon -a || true
        fi
      else
        echo "llamacpp-swap memory equilibrium: keeping swap online; RAM cannot safely absorb used swap plus reserve" >&2
      fi
    fi

    ${lib.optionalString cfg.memoryEquilibrium.compactMemory ''
      echo 1 > /proc/sys/vm/compact_memory || true
    ''}

    ${lib.optionalString cfg.memoryEquilibrium.dropCaches ''
      echo 3 > /proc/sys/vm/drop_caches || true
    ''}
  '';

  launch = pkgs.writeShellScript "llamacpp-swap-launch" ''
    set -euo pipefail

    SWAP_DIR="/var/lib/llamacpp-swap"
    PROFILES_JSON="$SWAP_DIR/profiles.json"
    CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"
    CURRENT_PROFILE="$(${pkgs.coreutils}/bin/cat "$CURRENT_PROFILE_FILE" 2>/dev/null || true)"

    profile_value() {
      local key="$1"
      if [ -z "$CURRENT_PROFILE" ] || [ ! -f "$PROFILES_JSON" ]; then
        return 0
      fi

      ${pkgs.jq}/bin/jq -r --arg profile "$CURRENT_PROFILE" --arg key "$key" '.[$profile][$key] // empty' "$PROFILES_JSON" 2>/dev/null || true
    }

    profile_int() {
      local key="$1"
      local default="$2"
      local value
      value="$(profile_value "$key")"

      if [[ "$value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$value"
      else
        printf '%s\n' "$default"
      fi
    }

    profile_bool() {
      local key="$1"
      local default="$2"
      local value
      value="$(profile_value "$key")"

      case "$value" in
        true|false) printf '%s\n' "$value" ;;
        *) printf '%s\n' "$default" ;;
      esac
    }

    MODEL_PATH="$(profile_value modelPath)"
    if [ -z "$MODEL_PATH" ]; then
      MODEL_PATH="${cfg.model}"
    fi

    if [ ! -e "$MODEL_PATH" ] && [ ! -L "$MODEL_PATH" ]; then
      echo "llamacpp-swap: model path is missing: $MODEL_PATH" >&2
      exit 1
    fi

    GPU_LAYERS="$(profile_int gpuLayers "${toString cfg.n_gpu_layers}")"
    CTX_SIZE="$(profile_int contextSize "${toString cfg.n_ctx}")"
    BATCH_SIZE="$(profile_int batchSize "${toString cfg.n_batch}")"
    UBATCH_SIZE="$(profile_int ubatchSize "${toString cfg.n_ubatch}")"
    PARALLEL="$(profile_int parallel "${toString cfg.n_parallel}")"
    THREADS="$(profile_int threads "${toString cfg.n_threads}")"
    THREADS_BATCH="$(profile_int threadsBatch "${toString cfg.n_threads_batch}")"
    NO_KV_OFFLOAD="$(profile_bool noKvOffload "${boolToShell cfg.noKvOffload}")"
    MLOCK="$(profile_bool mlock "${boolToShell cfg.mlock}")"

    echo "llamacpp-swap: launching profile=''${CURRENT_PROFILE:-none} model=$MODEL_PATH gpu_layers=$GPU_LAYERS ctx=$CTX_SIZE batch=$BATCH_SIZE ubatch=$UBATCH_SIZE parallel=$PARALLEL"

    args=(
      --host "${cfg.host}"
      --port "${toString cfg.port}"
      --model "$MODEL_PATH"
      --threads "$THREADS"
      --threads-batch "$THREADS_BATCH"
      --gpu-layers "$GPU_LAYERS"
      --main-gpu "${toString cfg.mainGpu}"
      --parallel "$PARALLEL"
      --ctx-size "$CTX_SIZE"
      --batch-size "$BATCH_SIZE"
      --ubatch-size "$UBATCH_SIZE"
    )

    ${lib.optionalString cfg.flashAttention ''
      args+=(--flash-attn on)
    ''}
    ${lib.optionalString (!cfg.mmap) ''
      args+=(--no-mmap)
    ''}

    if [ "$MLOCK" = "true" ]; then
      args+=(--mlock)
    fi

    if [ "$NO_KV_OFFLOAD" = "true" ]; then
      args+=(--no-kv-offload)
    fi

    ${lib.optionalString (cfg.speculativeDecoding.enable && cfg.speculativeDecoding.draftModel != null)
      ''
        args+=(
          --model-draft "${cfg.speculativeDecoding.draftModel}"
          --gpu-layers-draft "${toString cfg.speculativeDecoding.draftGpuLayers}"
          --draft-max "${toString cfg.speculativeDecoding.draftMax}"
          --draft-min "${toString cfg.speculativeDecoding.draftMin}"
          --draft-p-min "${toString cfg.speculativeDecoding.draftPMin}"
        )
      ''
    }
    ${lib.optionalString cfg.continuousBatching ''
      args+=(--cont-batching)
    ''}
    ${lib.optionalString (cfg.chatTemplate != null) ''
      args+=(--chat-template ${lib.escapeShellArg cfg.chatTemplate})
    ''}
    ${lib.optionalString (cfg.apiKey != null) ''
      args+=(--api-key ${lib.escapeShellArg cfg.apiKey})
    ''}
    ${lib.optionalString cfg.metricsEndpoint ''
      args+=(--metrics)
    ''}
    ${lib.optionalString cfg.embeddings ''
      args+=(--embeddings)
    ''}
    ${lib.optionalString (cfg.extraFlags != [ ]) ''
      args+=(${lib.escapeShellArgs cfg.extraFlags})
    ''}

    exec ${lib.getExe' cfg.package "llama-server"} "''${args[@]}"
  '';
}
