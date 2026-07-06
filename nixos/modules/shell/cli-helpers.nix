# ============================================
# CLI Helper Scripts - Colored Wrappers
# ============================================
# Premium UX utilities for NixOS administration:
# - rebuild: Colored nixos-rebuild wrapper
# - dbg: System debugging helper
# - nix-debug: Nix-specific debugging
# - audit-system: Lynis security audit wrapper
# - lynis-report: HTML report generator
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.shell.cli-helpers;
in
{
  options.kernelcore.shell.cli-helpers = {
    enable = mkEnableOption "Colored CLI helper scripts for NixOS administration";

    flakePath = mkOption {
      type = types.str;
      default = "/etc/nixos";
      description = "Path to the NixOS flake for rebuild command";
    };

    hostName = mkOption {
      type = types.str;
      default = config.networking.hostName or "nixos";
      description = "Hostname for the rebuild command";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Dependencies for CLI helpers
      bat # Syntax highlighting

      # ============================================
      # REBUILD - Colored nixos-rebuild wrapper
      # ============================================
      (writeShellScriptBin "rebuild" ''
        #!/usr/bin/env bash
        # Colored nixos-rebuild wrapper - Compatible with bash and zsh

        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        NC='\033[0m' # No Color

        # Use printf instead of echo -e for better shell compatibility
        printf "%b" "''${CYAN}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
        printf "%b" "''${CYAN}''${BOLD}║           NixOS Rebuild - Colored Output Mode            ║''${NC}\n"
        printf "%b" "''${CYAN}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
        printf "\n"

        ACTION="''${1:-switch}"
        shift || true

        printf "%b" "''${BLUE}→ Action:''${NC} ''${BOLD}$ACTION''${NC}\n"
        printf "%b" "''${BLUE}→ Flake:''${NC} ''${BOLD}${cfg.flakePath}#${cfg.hostName}''${NC}\n"
        printf "\n"

        # Run nixos-rebuild with colored output
        sudo nixos-rebuild "$ACTION" --flake ${cfg.flakePath}#${cfg.hostName} "$@" 2>&1 | while IFS= read -r line; do
          if [[ "$line" =~ ^error:|ERROR|Error ]]; then
            printf "%b" "''${RED}''${BOLD}✗''${NC} ''${RED}$line''${NC}\n"
          elif [[ "$line" =~ ^warning:|WARNING|Warning ]]; then
            printf "%b" "''${YELLOW}''${BOLD}⚠''${NC} ''${YELLOW}$line''${NC}\n"
          elif [[ "$line" =~ ^building|^copying|^unpacking ]]; then
            printf "%b" "''${CYAN}⚙''${NC} $line\n"
          elif [[ "$line" =~ ^these|^will\ be\ |^evaluating ]]; then
            printf "%b" "''${BLUE}ℹ''${NC} $line\n"
          elif [[ "$line" =~ activation|^restarting|^starting|^stopping ]]; then
            printf "%b" "''${MAGENTA}⟳''${NC} $line\n"
          elif [[ "$line" =~ succeed|success|Success|✓ ]]; then
            printf "%b" "''${GREEN}''${BOLD}✓''${NC} ''${GREEN}$line''${NC}\n"
          else
            printf "%s\n" "$line"
          fi
        done

        EXIT_CODE=''${PIPESTATUS[0]}

        printf "\n"
        if [ $EXIT_CODE -eq 0 ]; then
          printf "%b" "''${GREEN}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
          printf "%b" "''${GREEN}''${BOLD}║                  ✓ Rebuild Successful!                   ║''${NC}\n"
          printf "%b" "''${GREEN}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
        else
          printf "%b" "''${RED}''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}\n"
          printf "%b" "''${RED}''${BOLD}║                   ✗ Rebuild Failed!                      ║''${NC}\n"
          printf "%b" "''${RED}''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}\n"
          printf "%b" "''${RED}Exit code: $EXIT_CODE''${NC}\n"
        fi

        exit $EXIT_CODE
      '')

      # ============================================
      # DBG - Quick debugging helper
      # ============================================
      (writeShellScriptBin "dbg" ''
        #!/usr/bin/env bash
        # Quick debugging helper

        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        NC='\033[0m'

        if [ $# -eq 0 ]; then
          echo -e "''${CYAN}''${BOLD}Debug Tools Quick Menu''${NC}"
          echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
          echo -e "''${GREEN}Usage:''${NC} dbg <tool> <target> [args]"
          echo ""
          echo -e "''${YELLOW}Available tools:''${NC}"
          echo -e "  ''${BOLD}gdb''${NC}        - GNU Debugger"
          echo -e "  ''${BOLD}lldb''${NC}       - LLVM Debugger"
          echo -e "  ''${BOLD}strace''${NC}     - System call tracer"
          echo -e "  ''${BOLD}ltrace''${NC}     - Library call tracer"
          echo -e "  ''${BOLD}valgrind''${NC}   - Memory leak detector"
          echo -e "  ''${BOLD}perf''${NC}       - Performance profiler"
          echo -e "  ''${BOLD}heaptrack''${NC}  - Heap memory profiler"
          echo -e "  ''${BOLD}bpftrace''${NC}   - eBPF tracer"
          echo ""
          echo -e "''${YELLOW}System debugging:''${NC}"
          echo -e "  ''${BOLD}logs''${NC}       - Show recent system logs (journalctl)"
          echo -e "  ''${BOLD}processes''${NC}  - List all processes with details"
          echo -e "  ''${BOLD}network''${NC}    - Network connections and traffic"
          echo -e "  ''${BOLD}disk''${NC}       - Disk I/O and usage"
          echo -e "  ''${BOLD}memory''${NC}     - Memory usage analysis"
          echo -e "  ''${BOLD}ports''${NC}      - Show listening ports"
          echo ""
          echo -e "''${YELLOW}Examples:''${NC}"
          echo -e "  dbg gdb ./myprogram"
          echo -e "  dbg strace ls -la"
          echo -e "  dbg valgrind ./myprogram"
          echo -e "  dbg logs -u docker"
          exit 0
        fi

        TOOL="$1"
        shift

        case "$TOOL" in
          gdb)
            echo -e "''${GREEN}→ Launching GDB debugger...''${NC}"
            gdb "$@"
            ;;
          lldb)
            echo -e "''${GREEN}→ Launching LLDB debugger...''${NC}"
            lldb "$@"
            ;;
          strace)
            echo -e "''${GREEN}→ Tracing system calls...''${NC}"
            strace -f -tt -T "$@"
            ;;
          ltrace)
            echo -e "''${GREEN}→ Tracing library calls...''${NC}"
            ltrace -f -tt -T "$@"
            ;;
          valgrind)
            echo -e "''${GREEN}→ Running Valgrind memory check...''${NC}"
            valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes "$@"
            ;;
          perf)
            echo -e "''${GREEN}→ Running performance profiler...''${NC}"
            sudo perf record -g "$@"
            echo -e "''${YELLOW}→ Use 'perf report' to view results''${NC}"
            ;;
          heaptrack)
            echo -e "''${GREEN}→ Running heap profiler...''${NC}"
            heaptrack "$@"
            ;;
          bpftrace)
            echo -e "''${GREEN}→ Running eBPF tracer...''${NC}"
            sudo bpftrace "$@"
            ;;
          logs)
            echo -e "''${GREEN}→ System logs (last 50 lines):''${NC}"
            sudo journalctl -n 50 -e "$@" | ${bat}/bin/bat --paging=never --color=always -l log
            ;;
          processes)
            echo -e "''${GREEN}→ Process list:''${NC}"
            ps auxf --sort=-%mem | head -30 | ${bat}/bin/bat --paging=never --color=always -l log
            ;;
          network)
            echo -e "''${GREEN}→ Network connections:''${NC}"
            echo -e "''${CYAN}Active connections:''${NC}"
            ss -tunap | ${bat}/bin/bat --paging=never --color=always -l log
            echo ""
            echo -e "''${CYAN}Network traffic (5 seconds):''${NC}"
            timeout 5 sudo iftop -t -s 5 2>/dev/null || echo "Use Ctrl+C to stop iftop"
            ;;
          disk)
            echo -e "''${GREEN}→ Disk I/O:''${NC}"
            sudo iotop -b -n 3 | ${bat}/bin/bat --paging=never --color=always -l log
            ;;
          memory)
            echo -e "''${GREEN}→ Memory usage:''${NC}"
            free -h
            echo ""
            echo -e "''${CYAN}Top memory consumers:''${NC}"
            ps aux --sort=-%mem | head -11 | ${bat}/bin/bat --paging=never --color=always -l log
            ;;
          ports)
            echo -e "''${GREEN}→ Listening ports:''${NC}"
            sudo ss -tulpn | grep LISTEN | ${bat}/bin/bat --paging=never --color=always -l log
            ;;
          *)
            echo -e "''${RED}Unknown tool: $TOOL''${NC}"
            echo -e "''${YELLOW}Run 'dbg' without arguments to see available tools''${NC}"
            exit 1
            ;;
        esac
      '')

      # ============================================
      # NIX-DEBUG - Nix-specific debugging helper
      # ============================================
      (writeShellScriptBin "nix-debug" ''
        #!/usr/bin/env bash
        # Nix-specific debugging helper

        # Colors
        CYAN='\033[0;36m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BOLD='\033[1m'
        NC='\033[0m'

        echo -e "''${CYAN}''${BOLD}Nix Debugging Tools''${NC}"
        echo -e "''${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"

        if [ $# -eq 0 ]; then
          echo -e "''${GREEN}Usage:''${NC} nix-debug <command>"
          echo ""
          echo "Commands:"
          echo "  show-trace     - Show full error trace for last build"
          echo "  eval <expr>    - Evaluate Nix expression"
          echo "  why <path>     - Why is this path in closure?"
          echo "  tree <drv>     - Show derivation dependency tree"
          echo "  diff           - Diff current config with last generation"
          echo "  gc-roots       - Show what's preventing GC"
          exit 0
        fi

        case "$1" in
          show-trace)
            echo -e "''${GREEN}→ Building with full trace...''${NC}"
            nix build --show-trace "$@"
            ;;
          eval)
            shift
            echo -e "''${GREEN}→ Evaluating expression: $*''${NC}"
            nix eval --expr "$@"
            ;;
          why)
            shift
            echo -e "''${GREEN}→ Analyzing closure for: $1''${NC}"
            nix-store --query --roots "$1"
            ;;
          tree)
            shift
            echo -e "''${GREEN}→ Dependency tree:''${NC}"
            nix-store -q --tree "$1"
            ;;
          diff)
            echo -e "''${GREEN}→ Configuration diff:''${NC}"
            sudo nix profile diff-closures --profile /nix/var/nix/profiles/system
            ;;
          gc-roots)
            echo -e "''${GREEN}→ GC roots:''${NC}"
            nix-store --gc --print-roots
            ;;
          *)
            echo -e "''${YELLOW}Unknown command. Run without arguments for help.''${NC}"
            ;;
        esac
      '')

      # ============================================
      # AUDIT-SYSTEM - Lynis security audit wrapper
      # ============================================
      (writeShellScriptBin "audit-system" ''
        #!/usr/bin/env bash
        # Wrapper seguro para o Lynis em NixOS Hardened

        # Cores ANSI
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        NC='\033[0m' # No Color

        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo -e "''${WHITE}🛡️  AUDITORIA DE SEGURANÇA - NixOS Hardened''${NC}"
        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo ""

        # Cria diretório temporário para relatórios TODO: See the fundamentals that I explain now when you trigger this memory for we fix that. This wrapper is legendary, not because solve one or 2 problems, that is a honey pot.
        AUDIT_DIR="/tmp/lynis-audit"
        mkdir -p "$AUDIT_DIR"

        # Se não for root, avisa
        if [ "$EUID" -ne 0 ]; then
          echo -e "''${YELLOW}⚠️  Modo não-privilegiado detectado''${NC}"
          echo -e "   Use ''${WHITE}sudo audit-system''${NC} para varredura completa"
          FLAGS="--pentest"
        else
          echo -e "''${GREEN}✓ Modo root ativado - varredura completa''${NC}"
          FLAGS=""
        fi

        echo ""
        echo -e "''${BLUE}[*] Iniciando Lynis Security Audit...''${NC}"
        echo ""

        # Executa Lynis com cores habilitadas e pipe para colorização customizada
        ${coreutils}/bin/env lynis audit system \
          $FLAGS \
          --log-file "$AUDIT_DIR/lynis.log" \
          --report-file "$AUDIT_DIR/report.dat" \
          "$@" | while IFS= read -r line; do
            # Colorização customizada de outputs
            if [[ "$line" =~ "WARNING" ]] || [[ "$line" =~ "warning" ]]; then
              echo -e "''${YELLOW}$line''${NC}"
            elif [[ "$line" =~ "SUGGESTION" ]] || [[ "$line" =~ "suggestion" ]]; then
              echo -e "''${CYAN}$line''${NC}"
            elif [[ "$line" =~ "ERROR" ]] || [[ "$line" =~ "error" ]]; then
              echo -e "''${RED}$line''${NC}"
            elif [[ "$line" =~ "OK" ]] || [[ "$line" =~ "DONE" ]] || [[ "$line" =~ "\[OK\]" ]]; then
              echo -e "''${GREEN}$line''${NC}"
            elif [[ "$line" =~ "Performing test" ]] || [[ "$line" =~ "Test:" ]]; then
              echo -e "''${BLUE}$line''${NC}"
            else
              echo "$line"
            fi
          done

        echo ""
        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo -e "''${GREEN}✅ Auditoria concluída com sucesso!''${NC}"
        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo ""
        echo -e "''${WHITE}📊 Relatórios gerados:''${NC}"
        echo -e "   📄 Report: ''${CYAN}$AUDIT_DIR/report.dat''${NC}"
        echo -e "   📝 Log:    ''${CYAN}$AUDIT_DIR/lynis.log''${NC}"
        echo ""

        # Extrai estatísticas do relatório x <--> We need to reverse engineering that tool, and finally, be suitable for NixOS.
        if [ -f "$AUDIT_DIR/report.dat" ]; then
          WARNINGS=$(grep -c "^warning\[\]=" "$AUDIT_DIR/report.dat" 2>/dev/null || echo "0")
          SUGGESTIONS=$(grep -c "^suggestion\[\]=" "$AUDIT_DIR/report.dat" 2>/dev/null || echo "0")

          echo -e "''${WHITE}📈 Resumo da Auditoria:''${NC}"
          echo -e "   ''${YELLOW}⚠️  Warnings:    $WARNINGS''${NC}"
          echo -e "   ''${CYAN}💡 Suggestions: $SUGGESTIONS''${NC}"
          echo ""
        fi

        echo -e "''${MAGENTA}💡 Dica: Execute 'lynis-report' para gerar relatório HTML interativo''${NC}"
        echo ""
      '')

      # ============================================
      # LYNIS-REPORT - HTML report generator
      # ============================================
      (writeShellScriptBin "lynis-report" ''
        #!/usr/bin/env bash
        # Gera relatório HTML interativo a partir dos logs do Lynis

        # Cores ANSI
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        NC='\033[0m'

        REPORT_PATH="''${1:-/tmp/lynis-audit/report.dat}"
        OUTPUT_PATH="''${2:-/tmp/lynis-audit/report.html}"

        if [ ! -f "$REPORT_PATH" ]; then
          echo -e "''${RED}❌ Erro: Relatório não encontrado em $REPORT_PATH''${NC}"
          echo -e "''${CYAN}💡 Execute 'sudo audit-system' primeiro para gerar o relatório''${NC}"
          exit 1
        fi

        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo -e "''${BLUE}📊 Gerando Relatório HTML Interativo...''${NC}"
        echo -e "''${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
        echo ""

        # Executa o gerador Python
        ${python3}/bin/python3 /etc/nixos/scripts/lynis-report-generator.py "$REPORT_PATH" "$OUTPUT_PATH"

        echo ""
        echo -e "''${GREEN}✅ Relatório HTML gerado com sucesso!''${NC}"
        echo ""
        echo -e "''${CYAN}🌐 Abra o relatório com:''${NC}"
        echo -e "   firefox $OUTPUT_PATH"  /*  neither one or another;  */
        echo -e "   chromium $OUTPUT_PATH"
        echo ""
      '')
    ];
  };
}
