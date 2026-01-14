# MCP Server Tools Module
#
# MCP server management and integration
#
# Commands:
#   mcp-tool health    Check MCP server health
#   mcp-tool config    Generate/fix config
#   mcp-tool restart   Restart MCP server

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.mcp;

  mcpToolCmd = pkgs.writeScriptBin "mcp-tool" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    MCP_DIR="/home/kernelcore/dev/Projects/secure-llm-bridge/mcp-server"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🔌 MCP Tools v1.0''${NC}"
      echo ""
      echo "Usage: mcp-tool <command>"
      echo ""
      echo "Commands:"
      echo "  health     Run MCP health check"
      echo "  config     Generate MCP config"
      echo "  fix        Fix MCP configs"
      echo "  build      Build MCP server"
      echo "  test       Test MCP tools"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      health)
        if [[ -f "$SCRIPTS_DIR/mcp-health-check.sh" ]]; then
          exec bash "$SCRIPTS_DIR/mcp-health-check.sh" "$@"
        else
          echo "Health check script not found"
          exit 1
        fi
        ;;
      config)
        if [[ -f "$SCRIPTS_DIR/generate-mcp-config.sh" ]]; then
          exec bash "$SCRIPTS_DIR/generate-mcp-config.sh" "$@"
        else
          echo "Config generator not found"
          exit 1
        fi
        ;;
      fix)
        if [[ -f "$SCRIPTS_DIR/fix-mcp-configs.sh" ]]; then
          exec bash "$SCRIPTS_DIR/fix-mcp-configs.sh" "$@"
        else
          echo "Fix script not found"
          exit 1
        fi
        ;;
      build)
        echo -e "''${CYAN}Building MCP server...''${NC}"
        cd "$MCP_DIR"
        npm run build
        echo -e "''${GREEN}✓ Build complete''${NC}"
        ;;
      test)
        echo -e "''${CYAN}Testing MCP server...''${NC}"
        cd "$MCP_DIR"
        echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node build/index.js | head -50
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
  options.kernelcore.tools.mcp = {
    enable = mkEnableOption "MCP Tools";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ mcpToolCmd ];
  };
}
