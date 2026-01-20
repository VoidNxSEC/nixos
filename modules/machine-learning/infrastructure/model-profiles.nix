{
  config,
  lib,
  pkgs,
  ...
}:

# Model Profiles for LlamaSwap
#
# Manages model profiles for hot swapping between different GGUF models.
# Generates profiles.json and manages symlinks for active model.

with lib;

let
  cfg = config.kernelcore.llama-swap;

  # Convert profile attrset to JSON format
  profilesJson = builtins.toJSON (
    mapAttrs (name: profile: {
      inherit name;
      inherit (profile) modelPath displayName;
      gpuLayers = profile.gpuLayers;
      contextSize = profile.contextSize;
      # Add file size if model exists
      modelExists = builtins.pathExists profile.modelPath;
    }) cfg.profiles
  );
in
{
  options.kernelcore.llama-swap = {
    enable = mkEnableOption "LlamaSwap hot model reloading system";

    profiles = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            modelPath = mkOption {
              type = types.path;
              description = "Path to GGUF model file";
              example = "/var/lib/ml-models/llamacpp/models/model.gguf";
            };

            displayName = mkOption {
              type = types.str;
              description = "Human-readable name for the model";
              example = "Qwen 2.5 Coder 7B (Q4)";
            };

            gpuLayers = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Number of GPU layers for this model.
                If null, uses service default.
              '';
            };

            contextSize = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Context window size for this model.
                If null, uses service default.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Model profiles for hot swapping.
        Each profile defines a model with optional per-model settings.
      '';
      example = literalExpression ''
        {
          coder = {
            modelPath = "/var/lib/ml-models/llamacpp/models/Qwen2.5_Coder_7B_Instruct";
            displayName = "Qwen 2.5 Coder 7B (Q4)";
            gpuLayers = 35;
            contextSize = 8192;
          };
          reasoning = {
            modelPath = "/var/lib/ml-models/llamacpp/models/DeepSeek-R1.gguf";
            displayName = "DeepSeek-R1 8B (Q4)";
            gpuLayers = 35;
          };
        }
      '';
    };

    defaultProfile = mkOption {
      type = types.str;
      default = "default";
      description = "Default model profile to use on boot";
    };

    swapStateDir = mkOption {
      type = types.path;
      default = "/var/lib/llamacpp-swap";
      description = "Directory for swap state (symlinks, current profile)";
    };
  };

  config = mkIf cfg.enable {
    # Validate that default profile exists
    assertions = [
      {
        assertion = cfg.profiles != { } -> (hasAttr cfg.defaultProfile cfg.profiles);
        message = ''
          LlamaSwap: defaultProfile "${cfg.defaultProfile}" is not defined in profiles.
          Available profiles: ${concatStringsSep ", " (attrNames cfg.profiles)}
        '';
      }
    ];

    # Create swap directory structure
    systemd.tmpfiles.rules = [
      "d ${cfg.swapStateDir} 0755 llamacpp-swap llamacpp-swap -"
      "d ${cfg.swapStateDir}/profiles 0755 llamacpp-swap llamacpp-swap -"
    ];

    # Generate profiles.json and initialize symlinks
    systemd.services.llamacpp-swap-init = {
      description = "Initialize LlamaSwap profiles and symlinks";
      wantedBy = [ "multi-user.target" ];
      before = [ "llamacpp-swap.service" ];
      after = [ "local-fs.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "llamacpp-swap";
        Group = "llamacpp-swap";
      };

      script = ''
        set -euo pipefail

        SWAP_DIR="${cfg.swapStateDir}"
        PROFILES_JSON="$SWAP_DIR/profiles.json"
        CURRENT_PROFILE_FILE="$SWAP_DIR/current-profile"
        CURRENT_MODEL_LINK="$SWAP_DIR/current-model"

        echo "🔧 Initializing LlamaSwap..."

        # Create directories
        mkdir -p "$SWAP_DIR/profiles"

        # Generate profiles.json
        echo "📝 Generating profiles.json..."
        cat > "$PROFILES_JSON" <<'EOFPROFILES'
        ${profilesJson}
        EOFPROFILES

        echo "✅ Profiles.json generated with ${toString (length (attrNames cfg.profiles))} profiles"

        # Initialize current-profile file if not exists
        if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
          echo "📌 Setting default profile: ${cfg.defaultProfile}"
          echo "${cfg.defaultProfile}" > "$CURRENT_PROFILE_FILE"
        fi

        # Read current profile
        CURRENT_PROFILE=$(cat "$CURRENT_PROFILE_FILE")
        echo "🔍 Current profile: $CURRENT_PROFILE"

        # Get model path for current profile
        ${concatStringsSep "\n" (
          mapAttrsToList (name: profile: ''
            if [ "$CURRENT_PROFILE" = "${name}" ]; then
              MODEL_PATH="${profile.modelPath}"
              echo "🎯 Model path: $MODEL_PATH"
            fi
          '') cfg.profiles
        )}

        # Create or update symlink
        if [ -n "''${MODEL_PATH:-}" ]; then
          if [ -e "$MODEL_PATH" ] || [ -L "$MODEL_PATH" ]; then
            echo "🔗 Creating symlink: $CURRENT_MODEL_LINK -> $MODEL_PATH"
            ln -sfn "$MODEL_PATH" "$CURRENT_MODEL_LINK"
            echo "✅ LlamaSwap initialization complete"
          else
            echo "⚠️  WARNING: Model file not found: $MODEL_PATH"
            echo "⚠️  Symlink not created. Run 'llama-swap <profile>' to set valid model."
            exit 0
          fi
        else
          echo "⚠️  WARNING: Profile '$CURRENT_PROFILE' not found in profiles"
          echo "Available profiles: ${concatStringsSep ", " (attrNames cfg.profiles)}"
          exit 1
        fi
      '';
    };

    # Show swap status on boot (optional, helpful for debugging)
    systemd.services.llamacpp-swap-status = {
      description = "Show LlamaSwap status on boot";
      after = [ "llamacpp-swap-init.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "llamacpp-swap";
        Group = "llamacpp-swap";
      };

      script = ''
        set -euo pipefail

        SWAP_DIR="${cfg.swapStateDir}"
        CURRENT_PROFILE=$(cat "$SWAP_DIR/current-profile" 2>/dev/null || echo "unknown")
        CURRENT_MODEL=$(readlink "$SWAP_DIR/current-model" 2>/dev/null || echo "not set")

        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "  LlamaSwap Status"
        echo "════════════════════════════════════════════════════════════"
        echo "  Active Profile: $CURRENT_PROFILE"
        echo "  Model Path: $CURRENT_MODEL"
        echo "  Available Profiles: ${toString (length (attrNames cfg.profiles))}"
        echo ""
        echo "  Commands:"
        echo "    llama-swap-list     - List all profiles"
        echo "    llama-swap <profile> - Switch to profile"
        echo "    llama-swap-status   - Show current status"
        echo "════════════════════════════════════════════════════════════"
        echo ""
      '';
    };
  };
}
