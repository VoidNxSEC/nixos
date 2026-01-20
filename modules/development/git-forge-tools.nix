{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.git-forge-tools;

  # Helper script to create repos across different forges
  forgeCreate = pkgs.writeShellScriptBin "forge-create" ''
    #!/usr/bin/env bash
    # Wrapper to create repositories on different forges

    FORGE=$1
    NAME=$2
    shift 2

    case $FORGE in
      github|gh)
        gh repo create "$NAME" --private --source=. --remote=origin --push
        ;;
      gitlab|gl)
        glab repo create --name="$NAME" --internal --source=. --remote=origin --push
        ;;
      gitea|tea|forgejo)
        tea repo create --name="$NAME" --private --push
        ;;
      *)
        echo "Usage: forge-create <github|gitlab|gitea> <repo-name>"
        exit 1
        ;;
    esac
  '';

in
{
  options.programs.git-forge-tools = {
    enable = lib.mkEnableOption "Enable advanced CLI tools for Git Forges (GitHub, GitLab, Gitea, Azure)";

    enableExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install useful extensions for gh (dash, eco)";
    };
  };

  config = lib.mkIf cfg.enable {

    # ═══════════════════════════════════════════════════════════
    # GITHUB CLI (gh)
    # ═══════════════════════════════════════════════════════════
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
        # Interactive prompts
        prompt = "enabled";
      };

      extensions = lib.optionals cfg.enableExtensions (
        with pkgs;
        [
          gh-dash # Dashboard TUI
          gh-eco # Ecosystem explorer
          # gh-copilot # Often requires manual auth/setup, added here if needed
        ]
      );
    };

    # ═══════════════════════════════════════════════════════════
    # OTHER CLIS
    # ═══════════════════════════════════════════════════════════
    home.packages = with pkgs; [
      # GitLab
      glab

      # Gitea / Forgejo
      tea

      # Azure DevOps
      azure-cli

      # The Helper Script
      forgeCreate
    ];

    # ═══════════════════════════════════════════════════════════
    # ALIASES
    # ═══════════════════════════════════════════════════════════
    home.shellAliases = {
      # Unified
      "repo-new" = "forge-create";

      # GitHub
      "ghw" = "gh repo view --web";
      "ghpr" = "gh pr create";
      "ghrw" = "gh run watch";
      "ghd" = "gh dash";

      # GitLab
      "glw" = "glab repo view --web";
      "glpr" = "glab mr create";
      "glci" = "glab ci status --live";

      # Gitea/Forgejo
      "teaw" = "tea repo open";
      "teapr" = "tea pr create";
      "teals" = "tea repo list";
    };

    # ═══════════════════════════════════════════════════════════
    # CONFIGURATION HINTS
    # ═══════════════════════════════════════════════════════════
    # Gitea/Tea config usually lives in ~/.config/tea/config.yml
    # Azure CLI config lives in ~/.azure

    home.file.".config/tea/config.yml".text = ''
      # Managed by NixOS (Template)
      # Run 'tea login add' to configure interactively
      logins: []
    '';
  };
}
