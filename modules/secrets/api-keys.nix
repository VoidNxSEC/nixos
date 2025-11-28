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
    enable = mkEnableOption "Enable decrypted API keys from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt secrets from encrypted YAML files
    sops.secrets = {
      # Anthropic (Claude)
      "anthropic_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # OpenAI
      "openai_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        key = "openai_admin_key";
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "openai_project_id" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # DeepSeek
      "deepseek_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Google Gemini
      # TEMPORARILY DISABLED: Key not found in SOPS file
      # To enable: Add gemini_api_key to secrets/api.yaml and uncomment
      # "gemini_api_key" = {
      #   sopsFile = ../../secrets/api.yaml;
      #   mode = "0440";
      #   owner = config.users.users.kernelcore.name;
      #   group = "users";
      # };

      # OpenRouter
      "openrouter_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Replicate
      "replicate_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Mistral
      "mistral_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Groq
      "groq_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "groq_project_id" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # NVIDIA
      "nvidia_api_key" = {
        sopsFile = ../../secrets/api.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # GitHub Personal Access Token (for gh CLI, development)
      "github_token" = {
        sopsFile = ../../secrets/github.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Helper script to load API keys into environment
    environment.etc."load-api-keys.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Load decrypted API keys from /run/secrets into environment
        # Usage: source /etc/load-api-keys.sh

        export ANTHROPIC_API_KEY="$(cat /run/secrets/anthropic_api_key 2>/dev/null || echo "")"
        export OPENAI_API_KEY="$(cat /run/secrets/openai_api_key 2>/dev/null || echo "")"
        export OPENAI_PROJECT_ID="$(cat /run/secrets/openai_project_id 2>/dev/null || echo "")"
        export DEEPSEEK_API_KEY="$(cat /run/secrets/deepseek_api_key 2>/dev/null || echo "")"
        export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key 2>/dev/null || echo "")"
        export OPENROUTER_API_KEY="$(cat /run/secrets/openrouter_api_key 2>/dev/null || echo "")"
        export REPLICATE_API_TOKEN="$(cat /run/secrets/replicate_api_key 2>/dev/null || echo "")"
        export MISTRAL_API_KEY="$(cat /run/secrets/mistral_api_key 2>/dev/null || echo "")"
        export GROQ_API_KEY="$(cat /run/secrets/groq_api_key 2>/dev/null || echo "")"
        export GROQ_PROJECT_ID="$(cat /run/secrets/groq_project_id 2>/dev/null || echo "")"
        export NVIDIA_API_KEY="$(cat /run/secrets/nvidia_api_key 2>/dev/null || echo "")"
        export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || echo "")"

        echo "✓ API keys loaded into environment"
        echo "  - ANTHROPIC_API_KEY: ''${ANTHROPIC_API_KEY:0:15}..."
        echo "  - OPENAI_API_KEY: ''${OPENAI_API_KEY:0:15}..."
        echo "  - GROQ_API_KEY: ''${GROQ_API_KEY:0:15}..."
        echo "  - GITHUB_TOKEN: ''${GITHUB_TOKEN:0:10}..."
      '';
      mode = "0755";
    };

    # Add to user shell profile
    programs.bash.interactiveShellInit = mkDefault ''
      # Auto-load API keys for interactive sessions (optional)
      # Uncomment to automatically load on shell start:
      # source /etc/load-api-keys.sh 2>/dev/null
    '';
  };
}
