# ============================================
# API Keys Module - reads from api-keys.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.api-keys;
in
{
  options.kernelcore.secrets.api-keys = {
    enable = mkEnableOption "Enable API keys from SOPS (api-keys.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt API keys from /etc/nixos/secrets/api-keys.yaml
    sops.secrets = {
      # Anthropic (Claude)
      "anthropic_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # OpenRouter
      "openrouter_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Google Gemini
      "gemini_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Mistral AI
      "mistralai_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # DeepSeek
      "deepseek_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Replicate
      "replicate_api_key" = {
        sopsFile = ../../secrets/api-keys.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Environment loader script
    environment.etc."load-api-keys.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Load decrypted API keys from /run/secrets
        # Usage: source /etc/load-api-keys.sh

        export ANTHROPIC_API_KEY="$(cat /run/secrets/anthropic_api_key 2>/dev/null || echo "")"
        export OPENROUTER_API_KEY="$(cat /run/secrets/openrouter_api_key 2>/dev/null || echo "")"
        export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key 2>/dev/null || echo "")"
        export MISTRAL_API_KEY="$(cat /run/secrets/mistralai_api_key 2>/dev/null || echo "")"
        export DEEPSEEK_API_KEY="$(cat /run/secrets/deepseek_api_key 2>/dev/null || echo "")"
        export REPLICATE_API_TOKEN="$(cat /run/secrets/replicate_api_key 2>/dev/null || echo "")"

        echo "✓ API keys loaded from api-keys.yaml"
        echo "  - ANTHROPIC_API_KEY: ''${ANTHROPIC_API_KEY:0:15}..."
        echo "  - GEMINI_API_KEY: ''${GEMINI_API_KEY:0:15}..."
        echo "  - MISTRAL_API_KEY: ''${MISTRAL_API_KEY:0:15}..."
      '';
      mode = "0755";
    };
  };
}
