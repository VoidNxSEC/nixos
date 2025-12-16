# Architecture Analyzer - NixOS Module (Simplified)
#
# Uses the arch-analyzer package from flake input.
#
# Usage:
#   kernelcore.tools.arch-analyzer.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.arch-analyzer;

  # Use arch-analyzer from overlay (set by flake.nix)
  archAnalyzerPkg =
    pkgs.arch-analyzer or (pkgs.writeScriptBin "arch-analyze" ''
      #!/usr/bin/env bash
      echo "Error: arch-analyzer not available. Check flake inputs."
      exit 1
    '');

  # nix-tools integration wrapper
  archToolsWrapper = pkgs.writeScriptBin "arch" ''
    #!${pkgs.bash}/bin/bash

    show_help() {
      echo "Architecture Analyzer - AI-Powered Analysis"
      echo ""
      echo "Usage: nix-tools arch <command> [options]"
      echo ""
      echo "Commands:"
      echo "  analyze     Run full architecture analysis"
      echo "  report      View latest report"
      echo ""
      echo "Examples:"
      echo "  nix-tools arch analyze"
      echo "  nix-tools arch analyze --verbose"
    }

    case "''${1:-help}" in
      analyze)
        shift
        exec ${archAnalyzerPkg}/bin/arch-analyze "$@"
        ;;
      report)
        if [[ -f "/etc/nixos/arch/AI-ARCHITECTURE-REPORT.md" ]]; then
          ''${PAGER:-less} "/etc/nixos/arch/AI-ARCHITECTURE-REPORT.md"
        else
          echo "No report found. Run: nix-tools arch analyze"
        fi
        ;;
      help|--help|-h)
        show_help
        ;;
      *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
    esac
  '';

in
{
  options.kernelcore.tools.arch-analyzer = {
    enable = mkEnableOption "Architecture Analyzer with AI integration";

    schedule = mkOption {
      type = types.nullOr (
        types.enum [
          "hourly"
          "daily"
          "weekly"
        ]
      );
      default = null;
      description = "Schedule for automatic analysis";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      archAnalyzerPkg
      archToolsWrapper
    ];

    # Create output directory
    systemd.tmpfiles.rules = [
      "d /etc/nixos/arch 0755 root root -"
      "d /var/lib/arch-analyzer 0755 root root -"
    ];

    # Scheduled analysis service
    systemd.services.arch-analyzer = mkIf (cfg.schedule != null) {
      description = "Architecture Analyzer";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${archAnalyzerPkg}/bin/arch-analyze";
        Nice = 10;
      };
    };

    systemd.timers.arch-analyzer = mkIf (cfg.schedule != null) {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = cfg.schedule;
    };

    environment.shellAliases = {
      arch-analyze = "arch-analyze";
      arch-report = "less /etc/nixos/arch/AI-ARCHITECTURE-REPORT.md";
    };
  };
}
