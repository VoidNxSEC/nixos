# Nix Flake for GitLab Duo Configuration
# Provides declarative configuration for GitLab Duo at repository root level

{
  description = "GitLab Duo Configuration - Declarative Nix Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # GitLab Duo Configuration
        gitlabDuoConfig = {
          enabled = true;
          apiKey = builtins.getEnv "GITLAB_DUO_API_KEY";
          endpoint = "https://gitlab.com/api/v4";
          features = {
            codeCompletion = true;
            codeReview = true;
            securityScanning = true;
            documentationGeneration = true;
          };
          models = {
            codeGeneration = "claude-3-5-sonnet";
            codeReview = "claude-3-5-sonnet";
            security = "claude-3-5-sonnet";
          };
          rateLimit = {
            requestsPerMinute = 60;
            tokensPerMinute = 90000;
          };
          cache = {
            enabled = true;
            ttl = 3600;
          };
          logging = {
            level = "info";
            format = "json";
          };
        };

      in
      {
        # Development shell with GitLab Duo configuration
        devShells.default = pkgs.mkShell {
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

            # Load API key from secure location if available
            if [ -f ~/.config/gitlab-duo/api-key ]; then
              export GITLAB_DUO_API_KEY=$(cat ~/.config/gitlab-duo/api-key)
            fi

            # Create necessary directories
            mkdir -p ./logs/gitlab-duo

            echo "✓ GitLab Duo environment loaded"
          '';
        };

        # Packages
        packages = {
          gitlabDuo = import ./gitlab-duo { inherit pkgs; };
        };

        # Default package
        defaultPackage = self.packages.${system}.gitlabDuo;
      }
    );
}
