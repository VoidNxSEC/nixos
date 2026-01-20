{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.kernelcore.shell.llamaSwapControl = {
    enable = mkEnableOption "Enable LlamaSwap control aliases and scripts";
  };

  config = mkIf config.kernelcore.shell.llamaSwapControl.enable {
    environment.systemPackages = [
      # ============================================================
      # LLAMA SWAP - CORE SWAPPING
      # ============================================================
      (pkgs.writeShellScriptBin "llama-swap" ''
        #!/usr/bin/env bash
        set -euo pipefail

        SWAP_DIR="/var/lib/llamacpp-swap"
        PROFILES_JSON="$SWAP_DIR/profiles.json"
        CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"
        CURRENT_MODEL_LINK="$SWAP_DIR/current-model"
        SERVICE="llamacpp-swap.service"
        PORT="8081"

        # Usage
        if [ $# -eq 0 ]; then
          echo "Usage: llama-swap <profile-name>"
          echo ""
          echo "Available profiles:"
          llama-swap-list
          exit 1
        fi

        TARGET_PROFILE="$1"

        echo "🔄 LlamaSwap: Switching to profile '$TARGET_PROFILE'"
        echo ""

        # Validate profiles.json exists
        if [ ! -f "$PROFILES_JSON" ]; then
          echo "❌ Error: Profiles configuration not found"
          echo "   Expected: $PROFILES_JSON"
          echo "   Run 'sudo nixos-rebuild switch' to initialize"
          exit 1
        fi

        # Parse profiles.json and validate target profile exists
        if ! ${pkgs.jq}/bin/jq -e --arg profile "$TARGET_PROFILE" '.[$profile]' "$PROFILES_JSON" > /dev/null 2>&1; then
          echo "❌ Error: Profile '$TARGET_PROFILE' not found"
          echo ""
          echo "Available profiles:"
          llama-swap-list
          exit 1
        fi

        # Get model path from profiles.json
        MODEL_PATH=$(${pkgs.jq}/bin/jq -r --arg profile "$TARGET_PROFILE" '.[$profile].modelPath' "$PROFILES_JSON")

        if [ -z "$MODEL_PATH" ] || [ "$MODEL_PATH" = "null" ]; then
          echo "❌ Error: Model path not found for profile '$TARGET_PROFILE'"
          exit 1
        fi

        echo "📁 Model path: $MODEL_PATH"

        # Validate model file exists
        if [ ! -e "$MODEL_PATH" ] && [ ! -L "$MODEL_PATH" ]; then
          echo "❌ Error: Model file not found: $MODEL_PATH"
          echo "   Please verify the model file exists"
          exit 1
        fi

        # Check current profile
        CURRENT_PROFILE=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "none")

        if [ "$CURRENT_PROFILE" = "$TARGET_PROFILE" ]; then
          echo "ℹ️  Already using profile: $TARGET_PROFILE"
          echo "   Use 'llama-swap-status' to check service status"
          exit 0
        fi

        echo "🔄 Current profile: $CURRENT_PROFILE → $TARGET_PROFILE"
        echo ""

        # Record start time
        START_TIME=$(date +%s)

        # Stop service
        echo "⏹️  Stopping llamacpp-swap service..."
        if sudo ${pkgs.systemd}/bin/systemctl is-active "$SERVICE" >/dev/null 2>&1; then
          sudo ${pkgs.systemd}/bin/systemctl stop "$SERVICE"
          sleep 2
        fi

        # Wait for GPU to be released
        echo "⏳ Waiting for VRAM to be released..."
        sleep 1

        # Check VRAM (optional)
        if command -v nvidia-smi &> /dev/null; then
          VRAM_USED=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
          echo "   VRAM used: ''${VRAM_USED} MiB"
        fi

        # Update symlink atomically
        echo "🔗 Updating model symlink..."
        sudo -u llamacpp-swap ln -sfn "$MODEL_PATH" "$CURRENT_MODEL_LINK"

        # Update current profile file
        echo "$TARGET_PROFILE" | sudo -u llamacpp-swap tee "$CURRENT_PROFILE_FILE" > /dev/null

        # Start service
        echo "▶️  Starting llamacpp-swap service..."
        sudo ${pkgs.systemd}/bin/systemctl start "$SERVICE"

        # Wait for service to be ready
        echo "⏳ Waiting for service to be ready..."
        MAX_WAIT=30
        WAIT_COUNT=0

        while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
          if sudo ${pkgs.systemd}/bin/systemctl is-active "$SERVICE" >/dev/null 2>&1; then
            # Service is active, now check health endpoint
            if ${pkgs.curl}/bin/curl -s -f "http://localhost:$PORT/health" >/dev/null 2>&1; then
              break
            fi
          fi
          sleep 1
          WAIT_COUNT=$((WAIT_COUNT + 1))
          echo -n "."
        done
        echo ""

        # Calculate swap time
        END_TIME=$(date +%s)
        SWAP_TIME=$((END_TIME - START_TIME))

        # Check if successful
        if sudo ${pkgs.systemd}/bin/systemctl is-active "$SERVICE" >/dev/null 2>&1; then
          echo ""
          echo "✅ Swap complete! Time: ''${SWAP_TIME}s"
          echo ""
          echo "📊 Status:"
          echo "   Profile: $TARGET_PROFILE"
          echo "   Model: $MODEL_PATH"

          if command -v nvidia-smi &> /dev/null; then
            VRAM_USED=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1)
            VRAM_TOTAL=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
            echo "   VRAM: ''${VRAM_USED}/''${VRAM_TOTAL} MiB"
          fi

          # Try to get model info from API
          if MODEL_INFO=$(${pkgs.curl}/bin/curl -s -f "http://localhost:$PORT/props" 2>/dev/null); then
            MODEL_NAME=$(echo "$MODEL_INFO" | ${pkgs.jq}/bin/jq -r '.default_generation_settings.model // "unknown"' 2>/dev/null || echo "unknown")
            echo "   API Status: ✓ Ready"
          fi

          echo ""
          echo "🔗 Access: http://localhost:$PORT"
          echo ""
        else
          echo ""
          echo "⚠️  Warning: Service started but may not be healthy"
          echo "   Check status with: llama-swap-status"
          echo "   Check logs with: journalctl -u llamacpp-swap.service -n 50"
        fi
      '')

      # ============================================================
      # LLAMA SWAP - LIST PROFILES
      # ============================================================
      (pkgs.writeShellScriptBin "llama-swap-list" ''
        #!/usr/bin/env bash
        set -euo pipefail

        SWAP_DIR="/var/lib/llamacpp-swap"
        PROFILES_JSON="$SWAP_DIR/profiles.json"
        CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"

        if [ ! -f "$PROFILES_JSON" ]; then
          echo "❌ Error: Profiles configuration not found"
          echo "   Run 'sudo nixos-rebuild switch' to initialize"
          exit 1
        fi

        CURRENT_PROFILE=$(cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "none")

        echo "════════════════════════════════════════════════════════════"
        echo "  LlamaSwap - Available Profiles"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        ${pkgs.jq}/bin/jq -r 'to_entries[] | "[\(.key)]\n  Name: \(.value.displayName)\n  Path: \(.value.modelPath)\n  GPU Layers: \(.value.gpuLayers // "default")\n  Context: \(.value.contextSize // "default")\n"' "$PROFILES_JSON" | \
        while IFS= read -r line; do
          # Highlight current profile
          if [[ "$line" =~ ^\[([^\]]+)\]$ ]]; then
            PROFILE_NAME="''${BASH_REMATCH[1]}"
            if [ "$PROFILE_NAME" = "$CURRENT_PROFILE" ]; then
              echo "✓ [$PROFILE_NAME] (ACTIVE)"
            else
              echo "  [$PROFILE_NAME]"
            fi
          else
            echo "$line"
          fi
        done

        echo ""
        echo "Current: $CURRENT_PROFILE"
        echo ""
        echo "Usage: llama-swap <profile-name>"
        echo "════════════════════════════════════════════════════════════"
      '')

      # ============================================================
      # LLAMA SWAP - STATUS
      # ============================================================
      (pkgs.writeShellScriptBin "llama-swap-status" ''
        #!/usr/bin/env bash
        set -euo pipefail

        SWAP_DIR="/var/lib/llamacpp-swap"
        CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"
        CURRENT_MODEL_LINK="$SWAP_DIR/current-model"
        SERVICE="llamacpp-swap.service"
        PORT="8081"

        echo "════════════════════════════════════════════════════════════"
        echo "  LlamaSwap Status"
        echo "════════════════════════════════════════════════════════════"
        echo ""

        # Current profile
        if [ -f "$CURRENT_PROFILE_FILE" ]; then
          CURRENT_PROFILE=$(cat "$CURRENT_PROFILE_FILE")
          echo "Profile: $CURRENT_PROFILE"
        else
          echo "Profile: not set"
        fi

        # Current model
        if [ -L "$CURRENT_MODEL_LINK" ]; then
          MODEL_PATH=$(readlink "$CURRENT_MODEL_LINK")
          echo "Model: $MODEL_PATH"

          if [ -e "$MODEL_PATH" ]; then
            MODEL_SIZE=$(du -h "$MODEL_PATH" 2>/dev/null | cut -f1 || echo "unknown")
            echo "Size: $MODEL_SIZE"
          else
            echo "⚠️  Warning: Model file not found!"
          fi
        else
          echo "Model: symlink not set"
        fi

        echo ""
        echo "────────────────────────────────────────────────────────────"
        echo "Service Status:"
        echo ""

        # Service status
        if sudo ${pkgs.systemd}/bin/systemctl is-active "$SERVICE" >/dev/null 2>&1; then
          echo "  ✓ Service: Active"

          # Health check
          if ${pkgs.curl}/bin/curl -s -f "http://localhost:$PORT/health" >/dev/null 2>&1; then
            echo "  ✓ Health: OK"

            # Get model info
            if MODEL_INFO=$(${pkgs.curl}/bin/curl -s -f "http://localhost:$PORT/props" 2>/dev/null); then
              N_CTX=$(echo "$MODEL_INFO" | ${pkgs.jq}/bin/jq -r '.default_generation_settings.n_ctx // "unknown"')
              N_GPU_LAYERS=$(echo "$MODEL_INFO" | ${pkgs.jq}/bin/jq -r '.default_generation_settings.n_gpu_layers // "unknown"')

              echo "  ✓ API: Ready"
              echo ""
              echo "  Context: $N_CTX tokens"
              echo "  GPU Layers: $N_GPU_LAYERS"
            fi
          else
            echo "  ⚠️  Health: Service active but not responding"
          fi
        else
          echo "  ✗ Service: Inactive"
          echo "  Run: sudo systemctl start llamacpp-swap.service"
        fi

        echo ""
        echo "────────────────────────────────────────────────────────────"
        echo "GPU Status:"
        echo ""

        # GPU info
        if command -v nvidia-smi &> /dev/null; then
          VRAM_INFO=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | head -1)
          VRAM_USED=$(echo "$VRAM_INFO" | cut -d',' -f1 | tr -d ' ')
          VRAM_TOTAL=$(echo "$VRAM_INFO" | cut -d',' -f2 | tr -d ' ')
          VRAM_PERCENT=$((VRAM_USED * 100 / VRAM_TOTAL))

          echo "  VRAM: ''${VRAM_USED}/''${VRAM_TOTAL} MiB (''${VRAM_PERCENT}%)"

          # GPU processes
          if GPU_PROCS=$(${pkgs.linuxPackages.nvidia_x11}/bin/nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null); then
            if [ -n "$GPU_PROCS" ]; then
              echo ""
              echo "  GPU Processes:"
              echo "$GPU_PROCS" | while IFS=',' read -r pid name mem; do
                echo "    PID $pid: $name ($mem MiB)"
              done
            fi
          fi
        else
          echo "  nvidia-smi not available"
        fi

        echo ""
        echo "────────────────────────────────────────────────────────────"
        echo "Commands:"
        echo "  llama-swap-list      - List all profiles"
        echo "  llama-swap <profile> - Switch to profile"
        echo "  llama-swap-status    - Show this status"
        echo ""
        echo "API Endpoint: http://localhost:$PORT"
        echo "════════════════════════════════════════════════════════════"
      '')

      # ============================================================
      # LLAMA SWAP - ADD PROFILE (BONUS)
      # ============================================================
      (pkgs.writeShellScriptBin "llama-swap-add" ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [ $# -lt 2 ]; then
          echo "Usage: llama-swap-add <profile-name> <model-path> [display-name]"
          echo ""
          echo "Example:"
          echo "  llama-swap-add mythos /var/lib/ml-models/llamacpp/models/mythos.gguf \"Mythos 13B\""
          exit 1
        fi

        PROFILE_NAME="$1"
        MODEL_PATH="$2"
        DISPLAY_NAME="''${3:-$PROFILE_NAME}"

        echo "🔧 Adding profile: $PROFILE_NAME"
        echo ""

        # Validate model file
        if [ ! -e "$MODEL_PATH" ] && [ ! -L "$MODEL_PATH" ]; then
          echo "❌ Error: Model file not found: $MODEL_PATH"
          exit 1
        fi

        if [[ ! "$MODEL_PATH" =~ \.gguf$ ]]; then
          echo "⚠️  Warning: File doesn't have .gguf extension"
          read -p "Continue anyway? (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
          fi
        fi

        # Get model size
        MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)

        echo "📊 Profile Details:"
        echo "   Name: $PROFILE_NAME"
        echo "   Display: $DISPLAY_NAME"
        echo "   Path: $MODEL_PATH"
        echo "   Size: $MODEL_SIZE"
        echo ""

        # Add to profiles.json (temporary)
        SWAP_DIR="/var/lib/llamacpp-swap"
        PROFILES_JSON="$SWAP_DIR/profiles.json"

        if [ -f "$PROFILES_JSON" ]; then
          echo "📝 Adding to profiles.json (temporary)..."

          # Backup current profiles.json
          sudo cp "$PROFILES_JSON" "$PROFILES_JSON.backup"

          # Add new profile
          NEW_PROFILE=$(${pkgs.jq}/bin/jq -n \
            --arg name "$PROFILE_NAME" \
            --arg displayName "$DISPLAY_NAME" \
            --arg modelPath "$MODEL_PATH" \
            '{name: $name, displayName: $displayName, modelPath: $modelPath, gpuLayers: null, contextSize: null, modelExists: true}')

          ${pkgs.jq}/bin/jq --argjson new "$NEW_PROFILE" --arg key "$PROFILE_NAME" \
            '.[$key] = $new' "$PROFILES_JSON" | \
            sudo -u llamacpp-swap tee "$PROFILES_JSON.new" > /dev/null

          sudo mv "$PROFILES_JSON.new" "$PROFILES_JSON"

          echo "✅ Profile added temporarily"
          echo ""
          echo "⚠️  To make this profile permanent, add it to configuration.nix:"
          echo ""
          echo "  kernelcore.llama-swap.profiles.$PROFILE_NAME = {"
          echo "    modelPath = \"$MODEL_PATH\";"
          echo "    displayName = \"$DISPLAY_NAME\";"
          echo "    gpuLayers = 35; # Adjust as needed"
          echo "    contextSize = 8192; # Optional"
          echo "  };"
          echo ""
          echo "Then run: sudo nixos-rebuild switch"
          echo ""
          echo "You can now use: llama-swap $PROFILE_NAME"
        else
          echo "❌ Error: profiles.json not found. Run nixos-rebuild switch first."
          exit 1
        fi
      '')

      # ============================================================
      # LLAMA SWAP - BENCHMARK (BONUS)
      # ============================================================
      (pkgs.writeShellScriptBin "llama-swap-bench" ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [ $# -eq 0 ]; then
          echo "Usage: llama-swap-bench <profile-name>"
          echo "   or: llama-swap-bench --all"
          exit 1
        fi

        PORT="8081"

        if [ "$1" = "--all" ]; then
          echo "🔥 Benchmarking all profiles..."
          echo ""

          # Get all profiles
          PROFILES=$(${pkgs.jq}/bin/jq -r 'keys[]' /var/lib/llamacpp-swap/profiles.json)
          CURRENT_PROFILE=$(cat /var/lib/llamacpp-swap/current-profile)

          for profile in $PROFILES; do
            echo "════════════════════════════════════════════════════════════"
            echo "Benchmarking: $profile"
            echo "════════════════════════════════════════════════════════════"

            llama-swap "$profile"
            sleep 3

            echo ""
            echo "Running test query..."
            START_TIME=$(date +%s%N)

            RESPONSE=$(${pkgs.curl}/bin/curl -s -X POST "http://localhost:$PORT/v1/chat/completions" \
              -H "Content-Type: application/json" \
              -d '{"model":"default","messages":[{"role":"user","content":"Count from 1 to 10."}],"max_tokens":50}' 2>/dev/null)

            END_TIME=$(date +%s%N)
            ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

            if [ -n "$RESPONSE" ]; then
              TOKENS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.usage.completion_tokens // 0')
              echo "  Time: ''${ELAPSED_MS}ms"
              echo "  Tokens: $TOKENS"
              if [ "$TOKENS" -gt 0 ]; then
                TOKENS_PER_SEC=$((TOKENS * 1000 / ELAPSED_MS))
                echo "  Speed: ''${TOKENS_PER_SEC} tokens/s"
              fi
            fi

            echo ""
          done

          # Restore original profile
          echo "Restoring original profile: $CURRENT_PROFILE"
          llama-swap "$CURRENT_PROFILE"

        else
          TARGET_PROFILE="$1"
          CURRENT_PROFILE=$(cat /var/lib/llamacpp-swap/current-profile 2>/dev/null || echo "none")

          echo "🔥 Benchmarking profile: $TARGET_PROFILE"
          echo ""

          # Swap if needed
          if [ "$CURRENT_PROFILE" != "$TARGET_PROFILE" ]; then
            llama-swap "$TARGET_PROFILE"
            sleep 3
          fi

          echo "════════════════════════════════════════════════════════════"
          echo "  Quick Generation Test"
          echo "════════════════════════════════════════════════════════════"
          echo ""

          START_TIME=$(date +%s%N)

          RESPONSE=$(${pkgs.curl}/bin/curl -s -X POST "http://localhost:$PORT/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d '{"model":"default","messages":[{"role":"user","content":"Count from 1 to 10."}],"max_tokens":50}')

          END_TIME=$(date +%s%N)
          ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

          echo "Response:"
          echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.choices[0].message.content // "No response"'
          echo ""
          echo "────────────────────────────────────────────────────────────"
          echo "Stats:"
          echo "  Time: ''${ELAPSED_MS}ms"

          if [ -n "$RESPONSE" ]; then
            PROMPT_TOKENS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.usage.prompt_tokens // 0')
            COMPLETION_TOKENS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.usage.completion_tokens // 0')
            TOTAL_TOKENS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.usage.total_tokens // 0')

            echo "  Prompt tokens: $PROMPT_TOKENS"
            echo "  Completion tokens: $COMPLETION_TOKENS"
            echo "  Total tokens: $TOTAL_TOKENS"

            if [ "$COMPLETION_TOKENS" -gt 0 ]; then
              TOKENS_PER_SEC=$((COMPLETION_TOKENS * 1000 / ELAPSED_MS))
              echo "  Speed: ''${TOKENS_PER_SEC} tokens/s"
            fi
          fi
          echo "════════════════════════════════════════════════════════════"
        fi
      '')
    ];

    # Shell aliases for quick access
    programs.zsh.shellAliases = {
      "swap" = "llama-swap";
      "swapls" = "llama-swap-list";
      "swapst" = "llama-swap-status";
      "swapbench" = "llama-swap-bench";
    };

    programs.bash.shellAliases = {
      "swap" = "llama-swap";
      "swapls" = "llama-swap-list";
      "swapst" = "llama-swap-status";
      "swapbench" = "llama-swap-bench";
    };
  };
}
