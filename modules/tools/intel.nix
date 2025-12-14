# INTEL - Project Intelligence Module
#
# Provides enterprise-level project auditing and viability analysis
#
# Commands:
#   intel <path>              Full project audit
#   intel nix                 Audit /etc/nixos
#   intel dev                 Scan ~/dev/Projects
#   intel scan <dir>          Multi-project scan
#   intel score <path>        Quick viability score
#   intel health <path>       Health check
#   intel deps <path>         Dependency analysis
#   intel quality <path>      Code quality metrics
#   intel compare <p1> <p2>   Compare projects

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.intel;

  phantomDir = "/home/kernelcore/dev/Projects/phantom";

  # Python environment with required deps
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pydantic
      rich
      requests
      httpx
      psutil
      pyyaml
      toml
    ]
  );

  # Main INTEL command
  intelCmd = pkgs.writeScriptBin "intel" ''
    #!/usr/bin/env bash
    set -euo pipefail

    PHANTOM_DIR="${phantomDir}"
    AUDITOR="$PHANTOM_DIR/project_auditor.py"
    PYTHON="${pythonEnv}/bin/python3"

    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🧠 INTEL - Project Intelligence v1.0''${NC}"
      echo ""
      echo "Usage: intel [command] [options] [path]"
      echo ""
      echo "Commands:"
      echo "  <path>             Full audit (default: current dir)"
      echo "  nix                Audit /etc/nixos"
      echo "  dev                Scan ~/dev/Projects"
      echo "  scan <dir>         Multi-project scan"
      echo "  score <path>       Viability score only"
      echo "  health <path>      Quick health check"
      echo "  deps <path>        Dependencies"
      echo "  quality <path>     Code quality"
      echo "  compare <p1> <p2>  Compare projects"
      echo ""
      echo "Options:"
      echo "  -f, --format FMT   table, json, markdown"
      echo "  --ai               Enable AI analysis"
      echo "  -o, --output FILE  Save to file"
    }

    run_auditor() {
      local mode="$1"
      shift
      cd "$PHANTOM_DIR"
      $PYTHON "$AUDITOR" "$mode" "$@"
    }

    run_quick() {
      local target="''${1:-.}"
      cd "$PHANTOM_DIR"
      $PYTHON "$AUDITOR" --path "$target" --format json 2>/dev/null
    }

    # Parse arguments
    CMD=""
    TARGET=""
    FORMAT="table"
    EXTRA_ARGS=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        nix|dev|scan|score|health|deps|quality|compare)
          CMD="$1"; shift ;;
        -f|--format)
          FORMAT="$2"; shift 2 ;;
        --ai)
          EXTRA_ARGS+=("--ai"); shift ;;
        -o|--output)
          EXTRA_ARGS+=("--output" "$2"); shift 2 ;;
        -h|--help)
          show_help; exit 0 ;;
        -*)
          echo "Unknown: $1"; show_help; exit 1 ;;
        *)
          if [[ -z "$TARGET" ]]; then TARGET="$1"; else EXTRA_ARGS+=("$1"); fi
          shift ;;
      esac
    done

    [[ -z "$CMD" ]] && CMD="audit"
    [[ -z "$TARGET" ]] && TARGET="."

    case "$CMD" in
      audit)
        echo -e "''${CYAN}🧠 INTEL: Auditing $TARGET''${NC}"
        run_auditor --path "$TARGET" --format "$FORMAT" "''${EXTRA_ARGS[@]}"
        ;;
      nix)
        echo -e "''${CYAN}🧠 INTEL: Auditing NixOS Config''${NC}"
        run_auditor --path /etc/nixos --format "$FORMAT" "''${EXTRA_ARGS[@]}"
        ;;
      dev)
        echo -e "''${CYAN}🧠 INTEL: Scanning ~/dev/Projects''${NC}"
        run_auditor --scan "$HOME/dev/Projects" --format "$FORMAT" "''${EXTRA_ARGS[@]}"
        ;;
      scan)
        echo -e "''${CYAN}🧠 INTEL: Scanning $TARGET''${NC}"
        run_auditor --scan "$TARGET" --format "$FORMAT" "''${EXTRA_ARGS[@]}"
        ;;
      score)
        echo -e "''${CYAN}🧠 INTEL: Viability Score''${NC}"
        run_quick "$TARGET" | ${pkgs.jq}/bin/jq -r '.[0] | 
          "Project: \(.name)\nScore: \(.viability.score // 0)/100 (\(.viability.grade // "?"))\nStatus: \(.status)\nRecommendation: \(.viability.recommendation // "unknown")"'
        ;;
      health)
        echo -e "''${CYAN}🧠 INTEL: Health Check''${NC}"
        run_quick "$TARGET" | ${pkgs.jq}/bin/jq -r '.[0] | 
          "Project: \(.name)\n" +
          (if .quality.readme_exists then "✅" else "❌" end) + " README\n" +
          (if .quality.has_license then "✅" else "❌" end) + " LICENSE\n" +
          (if .quality.linting_configured then "✅" else "❌" end) + " Linting\n" +
          (if .activity.is_git_repo then "✅" else "❌" end) + " Git\n" +
          "Score: \(.viability.score // 0)/100"'
        ;;
      deps)
        echo -e "''${CYAN}🧠 INTEL: Dependencies''${NC}"
        run_quick "$TARGET" | ${pkgs.jq}/bin/jq -r '.[0].dependencies | 
          "Total: \(.total_dependencies // 0)\nDirect: \(.direct_dependencies // 0)\nOutdated: \(.outdated_dependencies // 0)"'
        ;;
      quality)
        echo -e "''${CYAN}🧠 INTEL: Code Quality''${NC}"
        run_quick "$TARGET" | ${pkgs.jq}/bin/jq -r '.[0] | 
          "Lines: \(.code.total_lines // 0)\nFiles: \(.code.file_count // 0)\nComplexity: \(.complexity.cyclomatic_complexity_avg // 0)\nMaintainability: \(.complexity.maintainability_index // 0)/100"'
        ;;
      compare)
        if [[ ''${#EXTRA_ARGS[@]} -lt 1 ]]; then
          echo "Usage: intel compare <project1> <project2>"; exit 1
        fi
        echo -e "''${CYAN}🧠 INTEL: Comparing''${NC}"
        S1=$(run_quick "$TARGET" | ${pkgs.jq}/bin/jq -r '.[0].viability.score // 0')
        S2=$(run_quick "''${EXTRA_ARGS[0]}" | ${pkgs.jq}/bin/jq -r '.[0].viability.score // 0')
        echo "$TARGET: $S1/100"
        echo "''${EXTRA_ARGS[0]}: $S2/100"
        ;;
    esac
  '';

in
{
  options.kernelcore.tools.intel = {
    enable = mkEnableOption "INTEL - Project Intelligence";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      intelCmd
      pythonEnv
      pkgs.jq
    ];
  };
}
