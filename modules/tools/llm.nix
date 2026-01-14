# LLM/AI Tools Module
#
# Local LLM interaction tools
#
# Commands:
#   llm-tool query <prompt>    Query local LLM
#   llm-tool preprocess        Preprocess data for LLM
#   llm-tool vram              Check VRAM usage

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.tools.llm;

  llmToolCmd = pkgs.writeScriptBin "llm-tool" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPTS_DIR="/etc/nixos/scripts"
    LLM_URL="''${LLM_API_URL:-http://localhost:8080}"
    CYAN="\033[0;36m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    NC="\033[0m"

    show_help() {
      echo -e "''${CYAN}🤖 LLM Tools v1.0''${NC}"
      echo ""
      echo "Usage: llm-tool <command>"
      echo ""
      echo "Commands:"
      echo "  query <prompt>    Send prompt to local LLM"
      echo "  preprocess        Preprocess data for LLM"
      echo "  vram              Check GPU VRAM usage"
      echo "  health            Check LLM server health"
      echo "  models            List available models"
    }

    CMD="''${1:-}"
    shift || true

    case "$CMD" in
      query)
        PROMPT="$*"
        if [[ -z "$PROMPT" ]]; then
          echo "Usage: llm-tool query <prompt>"
          exit 1
        fi
        
        echo -e "''${CYAN}Querying LLM...''${NC}"
        curl -s -X POST "$LLM_URL/completion" \
          -H "Content-Type: application/json" \
          -d "{\"prompt\": \"$PROMPT\", \"n_predict\": 512}" | \
          ${pkgs.jq}/bin/jq -r '.content // .error // "No response"'
        ;;
      preprocess)
        if [[ -f "$SCRIPTS_DIR/pre_processa_dados_llm.sh" ]]; then
          exec bash "$SCRIPTS_DIR/pre_processa_dados_llm.sh" "$@"
        else
          echo "Preprocess script not found"
          exit 1
        fi
        ;;
      vram)
        if [[ -f "$SCRIPTS_DIR/vram_examples.sh" ]]; then
          bash "$SCRIPTS_DIR/vram_examples.sh"
        else
          nvidia-smi --query-gpu=memory.used,memory.total --format=csv 2>/dev/null || \
            echo "NVIDIA GPU not found or nvidia-smi not available"
        fi
        ;;
      health)
        echo -e "''${CYAN}Checking LLM server at $LLM_URL...''${NC}"
        if curl -s "$LLM_URL/health" >/dev/null 2>&1; then
          echo -e "''${GREEN}✓ LLM server is running''${NC}"
        else
          echo -e "''${RED}✗ LLM server not responding''${NC}"
          exit 1
        fi
        ;;
      models)
        echo -e "''${CYAN}Available models:''${NC}"
        curl -s "$LLM_URL/v1/models" 2>/dev/null | ${pkgs.jq}/bin/jq -r '.data[]?.id // "No models found"' || \
          echo "Could not retrieve models"
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
  options.kernelcore.tools.llm = {
    enable = mkEnableOption "LLM/AI Tools";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      llmToolCmd
      pkgs.jq
      pkgs.curl
    ];
  };
}
