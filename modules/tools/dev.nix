# Development Tools Module
#
# Git and development workflow tools
#
# Commands:
#   dev-tool commit     AI-powered commit message
#   dev-tool push       Push all projects
#   dev-tool hooks      Setup git hooks
#   dev-tool migrate    Migrate projects

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.dev;

  devToolCmd = pkgs.writeScriptBin "dev-tool" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🛠️ Development Tools v1.0''${NC}"
      echo ""
      echo "Usage: dev-tool <command>"
      echo ""
      echo "Commands:"
      echo "  commit      AI-powered commit (or standard)"
      echo "  push        Push all projects"
      echo "  push-all    Push with force options"
      echo "  hooks       Setup git hooks"
      echo "  pre-commit  Run pre-commit checks"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      commit)
        if [[ -f "$SCRIPTS_DIR/smart-commit.py" ]]; then
          exec python3 "$SCRIPTS_DIR/smart-commit.py" "$@"
        else
          git add -A
          git commit -m "''${1:-Update}"
        fi
        ;;
      push)
        git push origin "$(git branch --show-current)"
        ;;
      push-all)
        if [[ -f "$SCRIPTS_DIR/push-all-projects.sh" ]]; then
          exec bash "$SCRIPTS_DIR/push-all-projects.sh" "$@"
        else
          echo "Push all script not found"
          exit 1
        fi
        ;;
      hooks)
        if [[ -f "$SCRIPTS_DIR/setup-git-hooks.sh" ]]; then
          exec bash "$SCRIPTS_DIR/setup-git-hooks.sh" "$@"
        else
          echo "Setting up basic hooks..."
          git config core.hooksPath .githooks
        fi
        ;;
      pre-commit)
        if [[ -f "$SCRIPTS_DIR/pre-commit.sh" ]]; then
          exec bash "$SCRIPTS_DIR/pre-commit.sh" "$@"
        else
          git diff --cached --check
        fi
        ;;
      -h|--help|"")
        show_help ;;
      *)
        echo -e "''${RED}Unknown: $CMD''${NC}"
        show_help
        exit 1 ;;
    esac
  '';

  # Alias for convenience
  smartCommit = pkgs.writeScriptBin "smart-commit" ''
    #!/usr/bin/env bash
    exec dev-tool commit "$@"
  '';

in
{
  options.kernelcore.tools.dev = {
    enable = mkEnableOption "Development Tools";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      devToolCmd
      smartCommit
    ];
  };
}
