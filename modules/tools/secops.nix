# SecOps - Security Operations Module
#
# Security monitoring and anomaly detection
#
# Commands:
#   secops monitor    Start security monitoring
#   secops scan       Scan for anomalies
#   secops logs       Monitor security logs
#   secops network    Network monitoring
#   secops report     Generate security report

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.secops;

  secopsCmd = pkgs.writeScriptBin "secops" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    CYAN="\033[0;36m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🔒 SecOps - Security Operations v1.0''${NC}"
      echo ""
      echo "Usage: secops <command>"
      echo ""
      echo "Commands:"
      echo "  monitor   Start security monitoring daemon"
      echo "  scan      Scan for anomalies"
      echo "  logs      Monitor security logs"
      echo "  network   Network traffic monitoring"
      echo "  procs     Process monitoring"
      echo "  report    Generate Lynis security report"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      monitor|scan)
        if [[ -f "$SCRIPTS_DIR/detecta-anomalias.sh" ]]; then
          exec bash "$SCRIPTS_DIR/detecta-anomalias.sh" "$@"
        else
          echo "Anomaly detector not found"
          exit 1
        fi
        ;;
      logs)
        if [[ -f "$SCRIPTS_DIR/monitora-logs-seguranca.sh" ]]; then
          exec bash "$SCRIPTS_DIR/monitora-logs-seguranca.sh" "$@"
        else
          journalctl -f -p warning
        fi
        ;;
      network)
        if [[ -f "$SCRIPTS_DIR/monitora-rede.sh" ]]; then
          exec bash "$SCRIPTS_DIR/monitora-rede.sh" "$@"
        else
          sudo ss -tuln
        fi
        ;;
      procs)
        if [[ -f "$SCRIPTS_DIR/monitora-processos-detalhado.sh" ]]; then
          exec bash "$SCRIPTS_DIR/monitora-processos-detalhado.sh" "$@"
        else
          ps aux --sort=-%mem | head -20
        fi
        ;;
      report)
        if [[ -f "$SCRIPTS_DIR/lynis-report-generator.py" ]]; then
          exec python3 "$SCRIPTS_DIR/lynis-report-generator.py" "$@"
        else
          sudo lynis audit system
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
  options.kernelcore.tools.secops = {
    enable = mkEnableOption "SecOps - Security Operations";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ secopsCmd ];
  };
}
