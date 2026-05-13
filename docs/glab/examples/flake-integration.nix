# Example: Integrating GitLab Duo in Your Main Flake
# Este é um exemplo de como integrar a configuração do GitLab Duo no seu flake.nix principal

{
  description = "Example Project with GitLab Duo Integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Integrar GitLab Duo como input
    gitlab-duo.url = "path:./nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gitlab-duo,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      in
      {
        # Development shell com GitLab Duo integrado
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.python313
            pkgs.poetry
            pkgs.git
            pkgs.yq
            pkgs.jq
          ];

          shellHook = ''
            # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            # GitLab Duo Configuration
            # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            export GITLAB_DUO_ENABLED=true
            export GITLAB_DUO_ENDPOINT="https://gitlab.com/api/v4"
            export GITLAB_DUO_FEATURES_CODE_COMPLETION=true
            export GITLAB_DUO_FEATURES_CODE_REVIEW=true
            export GITLAB_DUO_FEATURES_SECURITY_SCANNING=true
            export GITLAB_DUO_FEATURES_DOCUMENTATION=true
            export GITLAB_DUO_MODEL_CODE_GENERATION="claude-3-5-sonnet"
            export GITLAB_DUO_MODEL_CODE_REVIEW="claude-3-5-sonnet"
            export GITLAB_DUO_MODEL_SECURITY="claude-3-5-sonnet"
            export GITLAB_DUO_RATE_LIMIT_RPM=60
            export GITLAB_DUO_RATE_LIMIT_TPM=90000
            export GITLAB_DUO_CACHE_ENABLED=true
            export GITLAB_DUO_CACHE_TTL=3600
            export GITLAB_DUO_LOG_LEVEL="info"
            export GITLAB_DUO_LOG_FORMAT="json"

            # Load API key from secure location
            if [ -f ~/.config/gitlab-duo/api-key ]; then
              export GITLAB_DUO_API_KEY=$(cat ~/.config/gitlab-duo/api-key)
            fi

            # Create necessary directories
            mkdir -p ./logs/gitlab-duo

            # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            # Project-specific Configuration
            # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            export PYTHONPATH="$PWD/src:$PYTHONPATH"
            export POETRY_VIRTUALENVS_IN_PROJECT=true
            export POETRY_VIRTUALENVS_CREATE=true

            echo "✓ Development environment loaded"
            echo "✓ GitLab Duo is configured and ready"
          '';
        };

        # Alternativa: Shell separado apenas para GitLab Duo
        devShells.gitlab-duo = pkgs.mkShell {
          buildInputs = [
            pkgs.yq
            pkgs.jq
            pkgs.git
          ];

          shellHook = ''
            # GitLab Duo Configuration
            export GITLAB_DUO_ENABLED=true
            export GITLAB_DUO_ENDPOINT="https://gitlab.com/api/v4"
            export GITLAB_DUO_FEATURES_CODE_COMPLETION=true
            export GITLAB_DUO_FEATURES_CODE_REVIEW=true
            export GITLAB_DUO_FEATURES_SECURITY_SCANNING=true
            export GITLAB_DUO_FEATURES_DOCUMENTATION=true
            export GITLAB_DUO_MODEL_CODE_GENERATION="claude-3-5-sonnet"
            export GITLAB_DUO_MODEL_CODE_REVIEW="claude-3-5-sonnet"
            export GITLAB_DUO_MODEL_SECURITY="claude-3-5-sonnet"
            export GITLAB_DUO_RATE_LIMIT_RPM=60
            export GITLAB_DUO_RATE_LIMIT_TPM=90000
            export GITLAB_DUO_CACHE_ENABLED=true
            export GITLAB_DUO_CACHE_TTL=3600
            export GITLAB_DUO_LOG_LEVEL="info"
            export GITLAB_DUO_LOG_FORMAT="json"

            if [ -f ~/.config/gitlab-duo/api-key ]; then
              export GITLAB_DUO_API_KEY=$(cat ~/.config/gitlab-duo/api-key)
            fi

            mkdir -p ./logs/gitlab-duo

            echo "✓ GitLab Duo environment loaded"
          '';
        };
      }
    );
}
