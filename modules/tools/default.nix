# NixOS Tools Modules - Aggregator
#
# modules/tools/default.nix
#
# Usage in configuration.nix:
#   imports = [ ./modules/tools ];
#   kernelcore.tools.enable = true;
# >> THis need to be in default module agreggator.

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools;

  # ═══════════════════════════════════════════════════════════════════════════
  # PYTHON ENVIRONMENT for Python-based tools
  # ═══════════════════════════════════════════════════════════════════════════
  pythonEnv = pkgs.python313.withPackages (
    ps: with ps; [
      pydantic
      rich
      requests
      httpx
      jinja2
      pyyaml
      toml
      psutil
      aiofiles
    ]
  );

  # ═══════════════════════════════════════════════════════════════════════════
  # HELPER: Create wrapped script with dependencies
  # ═══════════════════════════════════════════════════════════════════════════
  mkTool =
    {
      name,
      script,
      deps ? [ ],
      pythonScript ? false,
      description ? "",
    }:
    pkgs.writeScriptBin name (
      if pythonScript then
        ''
          #!${pythonEnv}/bin/python3
          ${script}
        ''
      else
        ''
          #!/usr/bin/env bash
          export PATH="${lib.makeBinPath deps}:$PATH"
          ${script}
        ''
    );

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX-TOOLS: Unified CLI Launcher
  # ═══════════════════════════════════════════════════════════════════════════
  nixToolsCLI = pkgs.writeScriptBin "nix-tools" ''
        #!/usr/bin/env bash
        
        CYAN="\033[0;36m"
        YELLOW="\033[0;33m"
        NC="\033[0m"
        
        show_help() {
          echo -e "''${CYAN}"
          cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════╗
    ║  ███╗   ██╗██╗██╗  ██╗    ████████╗ ██████╗  ██████╗ ██╗     ║
    ║  ████╗  ██║██║╚██╗██╔╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ║
    ║  ██╔██╗ ██║██║ ╚███╔╝        ██║   ██║   ██║██║   ██║██║     ║
    ║  ██║╚██╗██║██║ ██╔██╗        ██║   ██║   ██║██║   ██║██║     ║
    ║  ██║ ╚████║██║██╔╝ ██╗       ██║   ╚██████╔╝╚██████╔╝███████╗║
    ║  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝║
    ║  NixOS Tools Suite v1.0                                       ║
    ╚══════════════════════════════════════════════════════════════╝
    BANNER
          echo -e "''${NC}"
          echo "Usage: nix-tools <module> [command] [options]"
          echo ""
          echo -e "''${YELLOW}Modules:''${NC}"
          echo "  intel       Project intelligence & viability analysis"
          echo "  secops      Security operations & monitoring"
          echo "  nix         NixOS utilities (rebuild, emergency, etc)"
          echo "  dev         Development tools (git, commits)"
          echo "  secrets     Secrets & SOPS management"
          echo "  diag        System diagnostics (e.g., diag log suricata)"
          echo "  llm         LLM/AI interaction tools"
          echo "  mcp         MCP server tools"
          echo "  arch        Architecture analyzer (AI-powered)"
          echo ""
          echo -e "''${YELLOW}Examples:''${NC}"
          echo "  nix-tools intel nix       # Audit NixOS config"
          echo "  nix-tools secops monitor  # Start security monitor"
          echo "  nix-tools nix rebuild     # Smart rebuild with monitoring"
          echo "  nix-tools dev commit      # AI-powered commit"
          echo ""
          echo "Use 'nix-tools <module> --help' for module-specific help."
        }
        
        if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
          show_help
          exit 0
        fi
        
        MODULE="$1"
        shift
        
        case "$MODULE" in
          intel)   exec intel "$@" ;;
          secops)  exec secops "$@" ;;
          nix)     exec nix-util "$@" ;;
          dev)     exec dev-tool "$@" ;;
          secrets) exec secrets-tool "$@" ;;
          diag)    exec diag "$@" ;;
          llm)     exec llm-tool "$@" ;;
          mcp)     exec mcp-tool "$@" ;;
          arch)    exec arch "$@" ;;
          *)
            echo "Unknown module: $MODULE"
            show_help
            exit 1
            ;;
        esac
  '';

in
{
  imports = [
    ./intel.nix
    ./secops.nix
    ./nix-utils.nix
    ./dev.nix
    ./secrets.nix
    ./diagnostics.nix
    ./llm.nix
    ./mcp.nix
    ./arch-analyzer
  ];

  options.kernelcore.tools = {
    enable = mkEnableOption "KernelCore NixOS Tools Suite";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      nixToolsCLI
      pythonEnv
    ];
  };
}
