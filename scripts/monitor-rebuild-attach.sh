#!/usr/bin/env bash
# Script para ANEXAR monitoração a um rebuild já em andamento
# Não executa rebuild, apenas monitora processos existentes

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configurações
INTERVAL=1
LOG_DIR="/tmp/rebuild-attach-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$LOG_DIR"

# Arquivos de log
MAIN_LOG="$LOG_DIR/monitor.log"
SNAPSHOT_LOG="$LOG_DIR/snapshots.log"

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "[$timestamp] $@" | tee -a "$MAIN_LOG"
}

log_color() {
    local color=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo -e "${color}[$timestamp]${NC} $@" | tee -a "$MAIN_LOG"
}

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║     NIXOS REBUILD - MONITOR ATTACH (TEMPO REAL)             ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""
log_color "$GREEN" "Procurando processos de rebuild em andamento..."

# Encontrar PID do rebuild
REBUILD_PID=$(pgrep -f "nixos-rebuild" | head -1 || echo "")

if [ -z "$REBUILD_PID" ]; then
    log_color "$RED" "❌ Nenhum processo nixos-rebuild encontrado!"
    echo ""
    echo "Processos relacionados ao Nix:"
    ps aux | grep -E "nix-daemon|nix-build|switch-to-configuration" | grep -v grep || echo "Nenhum processo Nix ativo"
    exit 1
fi

log_color "$GREEN" "✅ Rebuild encontrado! PID: $REBUILD_PID"
echo ""

# Função para capturar snapshot completo
capture_snapshot() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    local snapshot_file="$LOG_DIR/snapshot-$(date +%s%3N).txt"

    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  SNAPSHOT: $timestamp"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""

        # 1. PROCESS TREE
        echo "┌─ PROCESS TREE ────────────────────────────────────────────┐"
        pstree -p $REBUILD_PID 2>/dev/null || echo "Process ended"
        echo ""

        # 2. ALL RELATED PROCESSES
        echo "┌─ ALL NIX/REBUILD PROCESSES ──────────────────────────────┐"
        ps aux | head -1
        ps aux | grep -E "nixos-rebuild|switch-to-configuration|nix-daemon|nix-build|nix.*build" | grep -v grep || echo "None"
        echo ""

        # 3. ACTIVE BUILDS
        echo "┌─ ACTIVE BUILD PROCESSES ──────────────────────────────────┐"
        ps aux | grep -E "gcc|g\+\+|clang|rustc|cargo|cc1|ld|make" | grep -v grep | head -10 || echo "None"
        echo ""

        # 4. MEMORY STATE
        echo "┌─ MEMORY ──────────────────────────────────────────────────┐"
        free -h
        echo ""
        echo "TOP CONSUMERS:"
        ps aux --sort=-%mem | head -11
        echo ""

        # 5. CPU LOAD
        echo "┌─ CPU LOAD ────────────────────────────────────────────────┐"
        cat /proc/loadavg
        echo ""
        echo "TOP CPU:"
        ps aux --sort=-%cpu | head -11
        echo ""

        # 6. SYSTEMD STATE
        echo "┌─ SYSTEMD JOBS ────────────────────────────────────────────┐"
        systemctl list-jobs --no-pager 2>/dev/null || echo "No jobs"
        echo ""

        # 7. SYSTEMD UNITS TRANSITIONING
        echo "┌─ SYSTEMD UNITS (activating/deactivating) ────────────────┐"
        systemctl list-units --state=activating,reloading,deactivating --no-pager 2>/dev/null || echo "None"
        echo ""

        # 8. FAILED UNITS
        echo "┌─ FAILED SYSTEMD UNITS ────────────────────────────────────┐"
        systemctl --failed --no-pager 2>/dev/null || echo "None"
        echo ""

        # 9. CONTAINERS
        echo "┌─ PODMAN CONTAINERS ───────────────────────────────────────┐"
        podman ps -a 2>/dev/null || echo "Podman not available"
        echo ""

        # 10. RECENT JOURNAL ERRORS
        echo "┌─ RECENT ERRORS (last 10 seconds) ────────────────────────┐"
        journalctl -p err --since "10 seconds ago" --no-pager 2>/dev/null | tail -20 || echo "None"
        echo ""

        # 11. NIX-DAEMON LOGS
        echo "┌─ NIX-DAEMON LOGS (last 10 seconds) ──────────────────────┐"
        journalctl -u nix-daemon.service --since "10 seconds ago" --no-pager 2>/dev/null | tail -20 || echo "None"
        echo ""

        # 12. PODMAN LOGS
        echo "┌─ OPENSEARCH LOGS (last 10 lines) ────────────────────────┐"
        podman logs --tail 10 opensearch 2>/dev/null || echo "Container not running"
        echo ""

        echo "┌─ OPENSEARCH-DASHBOARDS LOGS (last 10 lines) ─────────────┐"
        podman logs --tail 10 opensearch-dashboards 2>/dev/null || echo "Container not running"
        echo ""

        # 13. DISK I/O
        echo "┌─ DISK USAGE ──────────────────────────────────────────────┐"
        df -h / /nix /tmp 2>/dev/null || true
        echo ""

        # 14. OOM/FORK FAILURES
        echo "┌─ KERNEL ERRORS (OOM/Fork) ────────────────────────────────┐"
        dmesg | tail -50 | grep -i "out of memory\|oom\|fork.*fail\|cannot allocate" || echo "None"
        echo ""

        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""

    } > "$snapshot_file"

    # Também adiciona ao log de snapshots
    cat "$snapshot_file" >> "$SNAPSHOT_LOG"
}

# Display status
display_status() {
    clear

    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║     NIXOS REBUILD - MONITOR ATTACH (TEMPO REAL)             ║
╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    local current_time=$(date '+%H:%M:%S')
    echo -e "${BOLD}⏰ Tempo: $current_time${NC} | Logs: $LOG_DIR"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if rebuild still running
    if kill -0 $REBUILD_PID 2>/dev/null; then
        local proc_start=$(stat -c %Y /proc/$REBUILD_PID 2>/dev/null)
        local now=$(date +%s)
        local elapsed=$((now - proc_start))
        echo -e "${GREEN}🟢 Rebuild ATIVO${NC} (PID: $REBUILD_PID, há ${elapsed}s)"
    else
        echo -e "${RED}🔴 Rebuild FINALIZADO${NC} (PID: $REBUILD_PID não existe mais)"
        return 1
    fi

    echo ""
    echo -e "${BOLD}┌─ PROCESSOS NIX/REBUILD ──────────────────────────────────────┐${NC}"
    ps aux | grep -E "nixos-rebuild|nix-daemon|nix-build|switch-to-configuration" | grep -v grep | while read line; do
        echo "  $line"
    done || echo "  Nenhum processo"
    echo ""

    echo -e "${BOLD}┌─ BUILDS ATIVOS ───────────────────────────────────────────────┐${NC}"
    local builds=$(ps aux | grep -E "gcc|g\+\+|clang|rustc|cargo" | grep -v grep | wc -l)
    if [ $builds -gt 0 ]; then
        echo -e "  ${CYAN}$builds processos de compilação ativos${NC}"
        ps aux | grep -E "gcc|g\+\+|clang|rustc|cargo" | grep -v grep | head -5 | while read line; do
            echo "  $(echo $line | awk '{print $11, $12, $13}')"
        done
    else
        echo "  Nenhuma compilação ativa"
    fi
    echo ""

    echo -e "${BOLD}┌─ MEMÓRIA ─────────────────────────────────────────────────────┐${NC}"
    local mem_line=$(free | grep Mem)
    local mem_total=$(echo $mem_line | awk '{print $2}')
    local mem_used=$(echo $mem_line | awk '{print $3}')
    local mem_avail=$(echo $mem_line | awk '{print $7}')
    local mem_percent=$((mem_used * 100 / mem_total))
    local mem_color=$GREEN
    [ $mem_percent -gt 80 ] && mem_color=$YELLOW
    [ $mem_percent -gt 90 ] && mem_color=$RED

    echo -e "  ${mem_color}Uso: ${mem_percent}%${NC} ($(( mem_used / 1024 ))MB / $(( mem_total / 1024 ))MB)"
    echo -e "  Disponível: $(( mem_avail / 1024 ))MB"

    local swap_used=$(free | grep Swap | awk '{print $3}')
    local swap_mb=$((swap_used / 1024))
    if [ $swap_mb -gt 100 ]; then
        echo -e "  ${YELLOW}⚠️  Swap: ${swap_mb}MB em uso${NC}"
    fi
    echo ""

    echo -e "${BOLD}┌─ CPU LOAD ────────────────────────────────────────────────────┐${NC}"
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local load_1=$(echo $load | awk '{print $1}')
    local cores=$(nproc)
    local load_pct=$(echo "$load_1 $cores" | awk '{printf "%.0f", ($1/$2)*100}')
    local load_color=$GREEN
    [ $load_pct -gt 100 ] && load_color=$YELLOW
    [ $load_pct -gt 150 ] && load_color=$RED

    echo -e "  ${load_color}Load: $load${NC} (${load_pct}% de $cores cores)"
    echo ""

    echo -e "${BOLD}┌─ SYSTEMD ─────────────────────────────────────────────────────┐${NC}"
    local jobs=$(systemctl list-jobs --no-pager 2>/dev/null | grep -c "^[0-9]" || echo 0)
    if [ $jobs -gt 0 ]; then
        echo -e "  ${YELLOW}Jobs ativos: $jobs${NC}"
        systemctl list-jobs --no-pager 2>/dev/null | head -6 | tail -5
    else
        echo "  Nenhum job ativo"
    fi
    echo ""

    echo -e "${BOLD}┌─ CONTAINERS ──────────────────────────────────────────────────┐${NC}"
    local containers=$(podman ps --format "{{.Names}} - {{.Status}}" 2>/dev/null)
    if [ -n "$containers" ]; then
        echo "$containers" | while read line; do
            echo "  $line"
        done
    else
        echo "  Nenhum container rodando"
    fi
    echo ""

    echo -e "${BOLD}┌─ ÚLTIMOS LOGS ────────────────────────────────────────────────┐${NC}"
    journalctl -u nix-daemon.service --since "5 seconds ago" --no-pager 2>/dev/null | tail -5 | while read line; do
        echo "  $line"
    done || echo "  Sem logs recentes"
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}Pressione Ctrl+C para parar e gerar relatório${NC}"
}

# Cleanup
cleanup() {
    log_color "$YELLOW" "🛑 Parando monitoração..."

    # Relatório final
    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║            RELATÓRIO FINAL - ATTACH MONITOR                  ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Rebuild PID Monitorado: $REBUILD_PID"
        echo "Início Monitoração: $(stat -c %y "$MAIN_LOG" | cut -d. -f1)"
        echo "Fim Monitoração: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""

        if kill -0 $REBUILD_PID 2>/dev/null; then
            echo "Status: ⚡ AINDA RODANDO"
        else
            echo "Status: ✅ FINALIZADO"
        fi

        echo ""
        echo "=== ARQUIVOS GERADOS ==="
        ls -lh "$LOG_DIR"

        echo ""
        echo "=== SNAPSHOTS CAPTURADOS ==="
        ls -1 "$LOG_DIR"/snapshot-*.txt | wc -l
        echo "snapshots salvos"

    } | tee "$LOG_DIR/FINAL-REPORT.txt"

    log_color "$GREEN" "✅ Logs salvos em: $LOG_DIR"

    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Loop principal
iteration=0
while true; do
    iteration=$((iteration + 1))

    # Display status
    if ! display_status; then
        log_color "$CYAN" "Rebuild finalizado. Capturando snapshot final..."
        capture_snapshot
        sleep 2
        break
    fi

    # Capturar snapshot a cada 5 iterações (5 segundos)
    if [ $((iteration % 5)) -eq 0 ]; then
        capture_snapshot
    fi

    sleep $INTERVAL
done

cleanup
