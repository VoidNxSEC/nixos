# Secrets Management Module
#
# SOPS and secrets management tools
#
# Commands:
#   secrets-tool add      Add new secret
#   secrets-tool edit     Edit secrets with SOPS
#   secrets-tool sync     Sync secrets
#   secrets-tool fix      Fix permissions

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.secrets;

  secretsToolCmd = pkgs.writeScriptBin "secrets-tool" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    SECRETS_DIR="/etc/nixos/secrets"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🔐 Secrets Management v1.0''${NC}"
      echo ""
      echo "Usage: secrets-tool <command>"
      echo ""
      echo "Commands:"
      echo "  add <name> <value>   Add new secret"
      echo "  edit <file>          Edit with SOPS"
      echo "  list                 List secrets"
      echo "  sync                 Sync to GitHub"
      echo "  fix                  Fix permissions"
      echo "  load                 Load API keys to env"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      add)
        if [[ -f "$SCRIPTS_DIR/add-secret.sh" ]]; then
          exec bash "$SCRIPTS_DIR/add-secret.sh" "$@"
        else
          echo "Add secret script not found"
          exit 1
        fi
        ;;
      edit)
        FILE="''${1:-$SECRETS_DIR/api-keys.yaml}"
        if [[ -f "$SCRIPTS_DIR/sops-editor.sh" ]]; then
          exec bash "$SCRIPTS_DIR/sops-editor.sh" "$FILE"
        else
          sops "$FILE"
        fi
        ;;
      list)
        echo -e "''${CYAN}Secrets in $SECRETS_DIR:''${NC}"
        find "$SECRETS_DIR" -name "*.yaml" -o -name "*.json" 2>/dev/null | while read f; do
          echo "  - $(basename "$f")"
        done
        ;;
      sync)
        if [[ -f "$SCRIPTS_DIR/sync-github-secrets.sh" ]]; then
          exec bash "$SCRIPTS_DIR/sync-github-secrets.sh" "$@"
        else
          echo "Sync script not found"
          exit 1
        fi
        ;;
      fix)
        if [[ -f "$SCRIPTS_DIR/fix-secrets-permissions.sh" ]]; then
          exec bash "$SCRIPTS_DIR/fix-secrets-permissions.sh" "$@"
        else
          chmod 600 "$SECRETS_DIR"/*.yaml 2>/dev/null || true
          echo -e "''${GREEN}✓ Permissions fixed''${NC}"
        fi
        ;;
      load)
        if [[ -f "$SCRIPTS_DIR/load-api-keys.sh" ]]; then
          source "$SCRIPTS_DIR/load-api-keys.sh"
          echo -e "''${GREEN}✓ API keys loaded''${NC}"
        else
          echo "Load script not found"
          exit 1
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

in
{
  options.kernelcore.tools.secrets = {
    enable = mkEnableOption "Secrets Management";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      secretsToolCmd
      pkgs.sops
    ];
  };
}
