# Diagnostics Module
#
# System diagnostics and troubleshooting
#
# Commands:
#   diag dns       DNS diagnostics
#   diag ssh       SSH diagnostics
#   diag wifi      WiFi diagnostics
#   diag disk      Disk diagnostics
#   diag hm        Home-manager diagnostics

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.diagnostics;

  diagCmd = pkgs.writeScriptBin "diag" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🔍 System Diagnostics v1.0''${NC}"
      echo ""
      echo "Usage: diag <system>"
      echo ""
      echo "Systems:"
      echo "  dns      DNS resolution diagnostics"
      echo "  ssh      SSH connection diagnostics"
      echo "  wifi     WiFi/network diagnostics"
      echo "  disk     Disk usage and health"
      echo "  hm       Home-manager diagnostics"
      echo "  vscode   VSCode/SSH diagnostics"
      echo "  all      Run all diagnostics"
    }

    diag_dns() {
      echo -e "''${CYAN}=== DNS Diagnostics ===''${NC}"
      if [[ -f "$SCRIPTS_DIR/dns-diagnostics.sh" ]]; then
        bash "$SCRIPTS_DIR/dns-diagnostics.sh"
      else
        echo "DNS servers:"
        cat /etc/resolv.conf
        echo ""
        echo "Testing resolution:"
        nslookup google.com || echo "DNS resolution failed"
      fi
    }

    diag_ssh() {
      echo -e "''${CYAN}=== SSH Diagnostics ===''${NC}"
      if [[ -f "$SCRIPTS_DIR/ssh-diagnostics.sh" ]]; then
        bash "$SCRIPTS_DIR/ssh-diagnostics.sh"
      else
        echo "SSH agent:"
        ssh-add -l 2>/dev/null || echo "No keys loaded"
        echo ""
        echo "SSH config:"
        cat ~/.ssh/config 2>/dev/null | head -20 || echo "No config"
      fi
    }

    diag_wifi() {
      echo -e "''${CYAN}=== WiFi Diagnostics ===''${NC}"
      if [[ -f "$SCRIPTS_DIR/wifi-diagnostics.sh" ]]; then
        bash "$SCRIPTS_DIR/wifi-diagnostics.sh"
      else
        nmcli device wifi list
        nmcli connection show --active
      fi
    }

    diag_disk() {
      echo -e "''${CYAN}=== Disk Diagnostics ===''${NC}"
      if [[ -f "$SCRIPTS_DIR/diagnostico-disco.sh" ]]; then
        bash "$SCRIPTS_DIR/diagnostico-disco.sh"
      else
        df -h
        echo ""
        du -sh /nix/store 2>/dev/null || true
      fi
    }

    diag_hm() {
      echo -e "''${CYAN}=== Home-Manager Diagnostics ===''${NC}"
      if [[ -f "$SCRIPTS_DIR/diagnose-home-manager.sh" ]]; then
        bash "$SCRIPTS_DIR/diagnose-home-manager.sh"
      else
        home-manager generations | head -5
      fi
    }

    CMD="''${1:-}"

    case "$CMD" in
      dns)     diag_dns ;;
      ssh)     diag_ssh ;;
      wifi)    diag_wifi ;;
      disk)    diag_disk ;;
      hm)      diag_hm ;;
      vscode)
        if [[ -f "$SCRIPTS_DIR/vscode-ssh-diagnostic.sh" ]]; then
          bash "$SCRIPTS_DIR/vscode-ssh-diagnostic.sh"
        fi
        ;;
      all)
        diag_dns
        diag_ssh
        diag_wifi
        diag_disk
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
  options.kernelcore.tools.diagnostics = {
    enable = mkEnableOption "System Diagnostics";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ diagCmd ];
  };
}
