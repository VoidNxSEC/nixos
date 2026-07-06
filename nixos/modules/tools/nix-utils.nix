# NixOS Utilities Module
#
# System management and recovery tools
#
# Commands:
#   nix-util rebuild      Smart rebuild with monitoring
#   nix-util update       Quick flake update
#   nix-util emergency    Emergency recovery
#   nix-util reset        Hard reset
#   nix-util store        Store monitoring
#   nix-util validate     Post-rebuild validation

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.nix-utils;

  nixUtilCmd = pkgs.writeScriptBin "nix-util" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}❄️ NixOS Utilities v1.0''${NC}"
      echo ""
      echo "Usage: nix-util <command>"
      echo ""
      echo "Commands:"
      echo "  rebuild     Smart rebuild with monitoring"
      echo "  update      Quick flake update + rebuild"
      echo "  emergency   Emergency recovery mode"
      echo "  reset       Hard reset (dangerous!)"
      echo "  store       Monitor nix store"
      echo "  validate    Post-rebuild validation"
      echo "  gc          Garbage collect"
      echo "  optimize    Optimize store"
      echo "  fix-perms   Fix repository file permissions"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      rebuild)
        if [[ -f "$SCRIPTS_DIR/monitor-rebuild.sh" ]]; then
          exec bash "$SCRIPTS_DIR/monitor-rebuild.sh" "$@"
        else
          sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
        fi
        ;;
      update)
        echo -e "''${CYAN}Updating flake inputs...''${NC}"
        cd /etc/nixos
        nix flake update
        echo -e "''${CYAN}Rebuilding...''${NC}"
        sudo nixos-rebuild switch --flake .#kernelcore
        echo -e "''${GREEN}✓ Update complete''${NC}"
        ;;
      emergency)
        if [[ -f "$SCRIPTS_DIR/nix-emergency.sh" ]]; then
          exec bash "$SCRIPTS_DIR/nix-emergency.sh" "$@"
        else
          echo "Emergency script not found"
          exit 1
        fi
        ;;
      reset)
        if [[ -f "$SCRIPTS_DIR/nix-hard-reset.sh" ]]; then
          exec bash "$SCRIPTS_DIR/nix-hard-reset.sh" "$@"
        else
          echo "Hard reset script not found"
          exit 1
        fi
        ;;
      store)
        if [[ -f "$SCRIPTS_DIR/monitor-nix-store.sh" ]]; then
          exec bash "$SCRIPTS_DIR/monitor-nix-store.sh" "$@"
        else
          nix-store --gc --print-dead | wc -l
          du -sh /nix/store
        fi
        ;;
      validate)
        if [[ -f "$SCRIPTS_DIR/post-rebuild-validate.sh" ]]; then
          exec bash "$SCRIPTS_DIR/post-rebuild-validate.sh" "$@"
        else
          systemctl --failed
        fi
        ;;
      gc)
        echo -e "''${CYAN}Running garbage collection...''${NC}"
        sudo nix-collect-garbage -d
        echo -e "''${GREEN}✓ GC complete''${NC}"
        ;;
      optimize)
        echo -e "''${CYAN}Optimizing store...''${NC}"
        sudo nix-store --optimise
        echo -e "''${GREEN}✓ Optimization complete''${NC}"
        ;;
      fix-perms)
        if [[ -f "$SCRIPTS_DIR/fix-repo-permissions.sh" ]]; then
          exec bash "$SCRIPTS_DIR/fix-repo-permissions.sh" "$@"
        else
          echo "Fix permissions script not found"
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
  options.kernelcore.tools.nix-utils = {
    enable = mkEnableOption "NixOS Utilities";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ nixUtilCmd ];
  };
}
