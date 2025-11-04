{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.development.cicd = {
      enable = mkEnableOption "Enable CI/CD development tools";

      platforms = {
        github = mkEnableOption "Enable GitHub CLI and tools";
        gitlab = mkEnableOption "Enable GitLab CLI and tools";
        gitea = mkEnableOption "Enable Gitea CLI and tools";
      };

      docker = mkEnableOption "Enable Docker for CI/CD testing";

      pre-commit = {
        enable = mkEnableOption "Enable pre-commit hooks";
        checkDirty = mkOption {
          type = types.bool;
          default = true;
          description = "Check for uncommitted changes before push";
        };
        runTests = mkOption {
          type = types.bool;
          default = false;
          description = "Run tests before commit";
        };
        formatCode = mkOption {
          type = types.bool;
          default = true;
          description = "Format code before commit";
        };
      };
    };
  };

  config = mkIf config.kernelcore.development.cicd.enable {
    # ═══════════════════════════════════════════════════════════
    # Core CI/CD Tools
    # ═══════════════════════════════════════════════════════════

    environment.systemPackages =
      with pkgs;
      [
        # Version control
        git
        git-lfs
        git-crypt

        # CI/CD utilities
        act # Run GitHub Actions locally
        gitlab-runner

        # Code quality
        pre-commit
        nixfmt-rfc-style
        statix # Nix linter
        deadnix # Find dead Nix code

        # Security scanning
        trivy
        vulnix

        # Container tools (if docker enabled)
      ]
      ++ optionals config.kernelcore.development.cicd.platforms.github [
        gh # GitHub CLI
        github-runner
      ]
      ++ optionals config.kernelcore.development.cicd.platforms.gitlab [
        glab # GitLab CLI
      ]
      ++ optionals config.kernelcore.development.cicd.platforms.gitea [
        tea # Gitea CLI
      ]
      ++ optionals config.kernelcore.development.cicd.docker [
        docker
        docker-compose
        podman
        buildah
      ];

    # ═══════════════════════════════════════════════════════════
    # Pre-commit Hooks Configuration
    # ═══════════════════════════════════════════════════════════

    environment.etc."nixos-config-hooks/pre-commit" =
      mkIf config.kernelcore.development.cicd.pre-commit.enable
        {
          text = ''
            #!/usr/bin/env bash
            set -e

            echo "Running pre-commit hooks..."

            ${optionalString config.kernelcore.development.cicd.pre-commit.checkDirty ''
              # Check for dirty git tree
              if [[ -n $(git status --porcelain) ]]; then
                echo "⚠️  Warning: You have uncommitted changes"
                git status --short
              fi
            ''}

            ${optionalString config.kernelcore.development.cicd.pre-commit.formatCode ''
              # Format Nix files
              echo "Formatting Nix files..."
              git ls-files -z '*.nix' | xargs -0 -r nixfmt
            ''}

            ${optionalString config.kernelcore.development.cicd.pre-commit.runTests ''
              # Run flake check
              echo "Running flake check..."
              nix flake check --show-trace
            ''}

            echo "✅ Pre-commit hooks passed!"
          '';
          mode = "0755";
        };

    environment.etc."nixos-config-hooks/pre-push" =
      mkIf config.kernelcore.development.cicd.pre-commit.enable
        {
          text = ''
            #!/usr/bin/env bash
            set -e

            echo "Running pre-push hooks..."

            # Always check git status before push
            if [[ -n $(git status --porcelain) ]]; then
              echo "❌ Error: You have uncommitted changes. Commit them before pushing."
              git status --short
              exit 1
            fi

            # Run flake check before push
            echo "Running flake check before push..."
            nix flake check --show-trace || {
              echo "❌ Flake check failed. Fix errors before pushing."
              exit 1
            }

            echo "✅ Pre-push hooks passed!"
          '';
          mode = "0755";
        };

    # ═══════════════════════════════════════════════════════════
    # Git Configuration
    # ═══════════════════════════════════════════════════════════

    programs.git = {
      enable = true;
      lfs.enable = true;

      config = mkIf config.kernelcore.development.cicd.pre-commit.enable {
        core = {
          hooksPath = "/etc/nixos-config-hooks";
        };
      };
    };

    # ═══════════════════════════════════════════════════════════
    # GitHub Runner Service (optional)
    # ═══════════════════════════════════════════════════════════

    # services.github-runner = mkIf config.kernelcore.development.cicd.platforms.github {
    #   enable = false; # Enable manually with token
    #   url = "https://github.com/your-org/your-repo";
    #   tokenFile = "/run/secrets/github-runner-token";
    #   extraLabels = [ "nixos" "self-hosted" ];
    # };

    # ═══════════════════════════════════════════════════════════
    # GitLab Runner Service (optional)
    # ═══════════════════════════════════════════════════════════

    # services.gitlab-runner = mkIf config.kernelcore.development.cicd.platforms.gitlab {
    #   enable = false; # Enable manually with token
    #   services = {
    #     nixos-runner = {
    #       registrationConfigFile = "/run/secrets/gitlab-runner-token";
    #       executor = "docker";
    #       dockerImage = "nixos/nix:latest";
    #     };
    #   };
    # };

    # ═══════════════════════════════════════════════════════════
    # Security Hardening
    # ═══════════════════════════════════════════════════════════

    # Ensure secrets are not committed
    environment.shellAliases = {
      git-scan-secrets = "${pkgs.trivy}/bin/trivy fs --security-checks secret .";
      nix-check = "nix flake check --show-trace";
      nix-fmt-check = "nix fmt -- --check .";
      nix-build-test = "nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel --dry-run";
    };
  };
}
