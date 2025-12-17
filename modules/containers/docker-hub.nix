# ============================================
# Docker Hub Integration Module
# ============================================
# Foundational smart scripts for docker-hub flake
# Provides: AI stack, GPU stack, container orchestration
# ============================================

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.containers.docker-hub;

  # Path to docker-hub project
  dockerHubPath = "/home/kernelcore/dev/projects/docker-hub";

  # Python script wrapper
  orchestrator = "${dockerHubPath}/main.py";
in
{
  options.kernelcore.containers.docker-hub = {
    enable = mkEnableOption "Docker Hub stack orchestrator integration";

    autoStart = mkOption {
      type = types.listOf (
        types.enum [
          "multimodal"
          "gpu"
        ]
      );
      default = [ ];
      description = "Stacks to auto-start on boot";
    };

    enableAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shell aliases for docker-hub";
    };
  };

  config = mkIf cfg.enable {
    # ============================================
    # SHELL ALIASES FOR DOCKER-HUB
    # ============================================
    environment.shellAliases = mkIf cfg.enableAliases {
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # MULTIMODAL AI STACK
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ai-up = "python3 ${orchestrator} up multimodal";
      ai-down = "python3 ${orchestrator} down multimodal";
      ai-status = "python3 ${orchestrator} status multimodal";
      ai-logs = "python3 ${orchestrator} logs multimodal -f";
      ai-health = "python3 ${orchestrator} health multimodal";
      ai-restart = "python3 ${orchestrator} restart multimodal";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # GPU + DATABASE STACK
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      gpu-up = "python3 ${orchestrator} up gpu";
      gpu-down = "python3 ${orchestrator} down gpu";
      gpu-status = "python3 ${orchestrator} status gpu";
      gpu-logs = "python3 ${orchestrator} logs gpu -f";
      gpu-health = "python3 ${orchestrator} health gpu";
      gpu-restart = "python3 ${orchestrator} restart gpu";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # ALL STACKS
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      all-up = "python3 ${orchestrator} up-all";
      all-down = "python3 ${orchestrator} down-all";
      all-status = "python3 ${orchestrator} status";
      all-health = "python3 ${orchestrator} health";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # GENERIC COMMANDS
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      dstacks = "python3 ${orchestrator} list";
      dlogs = "python3 ${orchestrator} logs";
      drestart = "python3 ${orchestrator} restart";
      dhelp = "python3 ${orchestrator} --help";
      dps = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # SERVICE-SPECIFIC SHORTCUTS
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      api-logs = "python3 ${orchestrator} logs gpu api -f";
      api-restart = "python3 ${orchestrator} restart gpu api";
      db-logs = "python3 ${orchestrator} logs gpu mariadb -f";
      ollama-logs = "python3 ${orchestrator} logs multimodal ollama -f";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # OLLAMA MANAGEMENT
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ollama-list = "docker exec -it ollama ollama list";
      ollama-pull = "docker exec -it ollama ollama pull";
      ollama-chat = "docker exec -it ollama ollama run";
      ollama-rm = "docker exec -it ollama ollama rm";

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # TESTING
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      test-gpu-api = "curl -s http://localhost:8000/health | jq";
      test-ollama = "curl -s http://localhost:11434/api/tags | jq";
    };

    # ============================================
    # SMART CLI WRAPPER
    # ============================================
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "docker-hub" ''
        #!/usr/bin/env bash
        # ============================================
        # Docker Hub CLI - Smart Stack Orchestrator
        # ============================================

        ORCH="${orchestrator}"

        # Colors
        CYAN='\033[0;36m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        BOLD='\033[1m'
        NC='\033[0m'

        show_help() {
          echo -e "''${CYAN}''${BOLD}╔══════════════════════════════════════════════════════════╗''${NC}"
          echo -e "''${CYAN}''${BOLD}║          Docker Hub - Stack Orchestrator                ║''${NC}"
          echo -e "''${CYAN}''${BOLD}╚══════════════════════════════════════════════════════════╝''${NC}"
          echo ""
          echo -e "''${GREEN}Usage:''${NC} docker-hub <command> [stack] [service]"
          echo ""
          echo -e "''${YELLOW}Stacks:''${NC}"
          echo "  multimodal   - Full AI stack (Ollama, ComfyUI, vLLM, Whisper, Jupyter)"
          echo "  gpu          - GPU API + Database (FastAPI, MariaDB, Jupyter)"
          echo ""
          echo -e "''${YELLOW}Commands:''${NC}"
          echo "  up [stack]      - Start stack (or all if no stack specified)"
          echo "  down [stack]    - Stop stack"
          echo "  status [stack]  - Show status"
          echo "  logs [stack]    - Follow logs"
          echo "  health [stack]  - Health check"
          echo "  restart [stack] - Restart stack"
          echo "  list            - List available stacks"
          echo ""
          echo -e "''${YELLOW}Quick Commands:''${NC}"
          echo "  ai              - Alias for 'up multimodal'"
          echo "  gpu             - Alias for 'up gpu'"
          echo "  all             - Start all stacks"
          echo "  stop            - Stop all stacks"
          echo ""
          echo -e "''${YELLOW}Examples:''${NC}"
          echo "  docker-hub ai           # Start AI stack"
          echo "  docker-hub gpu          # Start GPU stack"
          echo "  docker-hub status       # Show all status"
          echo "  docker-hub logs gpu api # Follow API logs"
        }

        case "''${1:-help}" in
          ai)
            echo -e "''${GREEN}→ Starting Multimodal AI Stack...''${NC}"
            python3 "$ORCH" up multimodal
            ;;
          gpu)
            echo -e "''${GREEN}→ Starting GPU + Database Stack...''${NC}"
            python3 "$ORCH" up gpu
            ;;
          all)
            echo -e "''${GREEN}→ Starting ALL Stacks...''${NC}"
            python3 "$ORCH" up-all
            ;;
          stop)
            echo -e "''${YELLOW}→ Stopping ALL Stacks...''${NC}"
            python3 "$ORCH" down-all
            ;;
          up|down|status|logs|health|restart|list)
            python3 "$ORCH" "$@"
            ;;
          -h|--help|help)
            show_help
            ;;
          *)
            echo -e "''${RED}Unknown command: $1''${NC}"
            echo "Run 'docker-hub --help' for usage"
            exit 1
            ;;
        esac
      '')

      # Quick GPU test script
      (writeShellScriptBin "test-stacks" ''
        #!/usr/bin/env bash
        # Test all docker-hub endpoints

        echo "═══════════════════════════════════════════"
        echo "Testing Docker Hub Stack Endpoints"
        echo "═══════════════════════════════════════════"
        echo ""

        test_endpoint() {
          local name="$1"
          local url="$2"
          echo -n "Testing $name... "
          if curl -s --connect-timeout 3 "$url" > /dev/null 2>&1; then
            echo -e "\033[0;32m✓ OK\033[0m"
            return 0
          else
            echo -e "\033[0;31m✗ FAIL\033[0m"
            return 1
          fi
        }

        # GPU Stack
        echo "[GPU Stack]"
        test_endpoint "FastAPI (8000)" "http://localhost:8000/health"
        test_endpoint "MariaDB (3306)" "localhost:3306"
        test_endpoint "Jupyter (8888)" "http://localhost:8888"
        echo ""

        # Multimodal Stack
        echo "[Multimodal AI Stack]"
        test_endpoint "Ollama (11434)" "http://localhost:11434/api/tags"
        test_endpoint "ComfyUI (8188)" "http://localhost:8188"
        test_endpoint "vLLM (8000)" "http://localhost:8000/v1/models"
        test_endpoint "Whisper (9000)" "http://localhost:9000/health"
        test_endpoint "Redis (6379)" "localhost:6379"
        echo ""

        echo "═══════════════════════════════════════════"
      '')
    ];

    # ============================================
    # AUTOSTART SERVICE (optional)
    # ============================================
    systemd.services.docker-hub-autostart = mkIf (cfg.autoStart != [ ]) {
      description = "Docker Hub Auto-start Stacks";
      after = [
        "docker.service"
        "network.target"
      ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "kernelcore";
        ExecStart = pkgs.writeShellScript "docker-hub-start" ''
          ${concatMapStringsSep "\n" (
            stack: "${pkgs.python3}/bin/python3 ${orchestrator} up ${stack}"
          ) cfg.autoStart}
        '';
        ExecStop = pkgs.writeShellScript "docker-hub-stop" ''
          ${concatMapStringsSep "\n" (
            stack: "${pkgs.python3}/bin/python3 ${orchestrator} down ${stack}"
          ) cfg.autoStart}
        '';
      };
    };
  };
}
