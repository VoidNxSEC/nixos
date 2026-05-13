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

  # DIAGNOSTIC CLI
  diag = pkgs.writeScriptBin "diag" ''
    #!/usr/bin/env bash

    show_help() {
      echo "Usage: diag <command> [args]"
      echo ""
      echo "Commands:"
      echo "  log         View systemd journal or dmesg with colorized output (e.g., diag log suricata)"
      echo "  ps          Advanced process listing"
      echo "  io          IO and ZRAM diagnostics"
      echo "  net         Network conflict detection"
      echo "  psi         System pressure sentinel"
      echo "  modules     Module catalog - show all modules and their state (active/disabled/orphan)"
      echo ""
      echo "For specific help: diag <command> --help"
    }

    if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
      show_help
      exit 0
    fi

    COMMAND="$1"
    shift

    case "$COMMAND" in
      log)
        exec "${pkgs.writeScriptBin "log-viewer" (builtins.readFile ../../scripts/nix-tools/log-viewer.sh)}/bin/log-viewer" "$@"
        ;;
      ps)
        exec "${pkgs.writeScriptBin "ps-advanced" (builtins.readFile ../../scripts/surgical/ps-advanced.sh)}/bin/ps-advanced" "$@"
        ;;
      io)
        exec "${pkgs.writeScriptBin "io-surgeon" (builtins.readFile ../../scripts/surgical/io-surgeon.sh)}/bin/io-surgeon" "$@"
        ;;
      net)
        exec "${pkgs.writeScriptBin "net-conflict" (builtins.readFile ../../scripts/surgical/net-conflict.sh)}/bin/net-conflict" "$@"
        ;;
      psi)
        exec "${pkgs.writeScriptBin "psi-sentinel" (builtins.readFile ../../scripts/surgical/psi-sentinel.sh)}/bin/psi-sentinel" "$@"
        ;;
      modules)
        exec "${pkgs.writeScriptBin "module-catalog" (builtins.readFile ../../scripts/surgical/module-catalog.sh)}/bin/module-catalog" "$@"
        ;;
      *)
        echo "Unknown diag command: $COMMAND"
        show_help
        exit 1
        ;;
    esac
  '';

in
{
  options.kernelcore.tools.diagnostics = {
    enable = mkEnableOption "System Diagnostics";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ diag ];
  };
}
