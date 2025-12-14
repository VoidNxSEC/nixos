#!/usr/bin/env bash
# Script de monitoração COMPLETA para debug de nixos-rebuild
# Monitora processos, memória, CPU, disco, logs, containers, tudo!

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
INTERVAL=2
LOG_DIR="/tmp/rebuild-debug-$(date +%Y%m%d-%H%M%S)"
REBUILD_CMD="${1:-sudo nixos-rebuild switch --flake /etc/nixos#kernelcore}"
FOLLOW_LOGS=true

mkdir -p "$LOG_DIR"

# Arquivos de log
MAIN_LOG="$LOG_DIR/monitor.log"
PROCESSES_LOG="$LOG_DIR/processes.log"
MEMORY_LOG="$LOG_DIR/memory.log"
SYSTEMD_LOG="$LOG_DIR/systemd.log"
PODMAN_LOG="$LOG_DIR/podman.log"
ERRORS_LOG="$LOG_DIR/errors.log"
REBUILD_OUTPUT="$LOG_DIR/rebuild-output.log"
REBUILD_STDERR="$LOG_DIR/rebuild-stderr.log"

# Funções de log
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
║        NIXOS REBUILD - MONITORAÇÃO COMPLETA DE DEBUG        ║
╚══════════════════════════════════════════════════════════════╝
EOF

log_color "$GREEN" "Iniciando monitoração completa..."
log "Log directory: $LOG_DIR"
log "Rebuild command: $REBUILD_CMD"
log "Interval: ${INTERVAL}s"
echo ""

# Iniciar rebuild em background
log_color "$CYAN" "▶ Iniciando rebuild..."
{
    $REBUILD_CMD 2>&1 | tee "$REBUILD_OUTPUT" 2>&1
    echo $? > "$LOG_DIR/rebuild-exit-code.txt"
} &
REBUILD_PID=$!

log "Rebuild PID: $REBUILD_PID"
echo ""

# Função para capturar processos relacionados ao rebuild
capture_processes() {
    local timestamp=$(date +%s.%3N)

    {
        echo "=== TIMESTAMP: $timestamp ==="
        echo ""

        echo "=== REBUILD PROCESS TREE ==="
        pstree -p $REBUILD_PID 2>/dev/null || echo "Rebuild process ended"
        echo ""

        echo "=== ALL REBUILD RELATED PROCESSES ==="
        ps aux | head -1
        ps aux | grep -E "nixos-rebuild|switch-to-configuration|nix-daemon|nix-build|nix.*build|podman" | grep -v grep || echo "No processes found"
        echo ""

        echo "=== NIX BUILDS ACTIVE ==="
        ps aux | grep -E "^[^ ]+ +[0-9]+ .*(gcc|g\+\+|clang|rustc|cargo|cc1|ld|make)" | grep -v grep || echo "No active builds"
        echo ""

        echo "=== SYSTEMD UNITS STARTING/ACTIVATING ==="
        systemctl list-units --state=activating,reloading,deactivating 2>/dev/null || true
        echo ""

        echo "=== SYSTEMD JOBS QUEUE ==="
        systemctl list-jobs 2>/dev/null || echo "No jobs"
        echo ""

    } >> "$PROCESSES_LOG"
}

# Função para capturar memória
capture_memory() {
    local timestamp=$(date +%s.%3N)

    {
        echo "=== TIMESTAMP: $timestamp ==="
        echo ""

        echo "=== MEMORY OVERVIEW ==="
        free -h
        echo ""

        echo "=== TOP MEMORY CONSUMERS (Top 20) ==="
        ps aux --sort=-%mem | head -21
        echo ""

        echo "=== SWAP USAGE ==="
        swapon --show 2>/dev/null || echo "No swap"
        echo ""

        echo "=== MEMORY PRESSURE ==="
        cat /proc/pressure/memory 2>/dev/null || echo "Pressure stall information not available"
        echo ""

        echo "=== AVAILABLE MEMORY FOR FORK ==="
        local avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local avail_mb=$((avail / 1024))
        echo "Available: ${avail_mb}MB"
        if [ $avail_mb -lt 512 ]; then
            echo "⚠️  WARNING: Low memory for fork operations!"
        fi
        echo ""

    } >> "$MEMORY_LOG"
}

# Função para capturar logs do systemd
capture_systemd_logs() {
    local timestamp=$(date +%s.%3N)

    {
        echo "=== TIMESTAMP: $timestamp ==="
        echo ""

        # Logs do nixos-rebuild service se existir
        journalctl -u nixos-rebuild-switch-to-configuration.service --since "5 seconds ago" --no-pager 2>/dev/null || true

        # Logs do nix-daemon
        journalctl -u nix-daemon.service --since "5 seconds ago" --no-pager 2>/dev/null || true

        # Logs de serviços OCI/Podman
        journalctl -u "podman-*" --since "5 seconds ago" --no-pager 2>/dev/null || true

        echo ""
    } >> "$SYSTEMD_LOG"
}

# Função para capturar logs de containers
capture_podman_logs() {
    local timestamp=$(date +%s.%3N)

    {
        echo "=== TIMESTAMP: $timestamp ==="
        echo ""

        echo "=== PODMAN CONTAINERS STATUS ==="
        podman ps -a 2>/dev/null || echo "Podman not available"
        echo ""

        echo "=== OPENSEARCH CONTAINER LOGS (last 20 lines) ==="
        podman logs --tail 20 opensearch 2>/dev/null || echo "Container not running"
        echo ""

        echo "=== OPENSEARCH-DASHBOARDS CONTAINER LOGS (last 20 lines) ==="
        podman logs --tail 20 opensearch-dashboards 2>/dev/null || echo "Container not running"
        echo ""

    } >> "$PODMAN_LOG"
}

# Função para detectar erros
detect_errors() {
    local timestamp=$(date +%s.%3N)

    {
        echo "=== TIMESTAMP: $timestamp ==="
        echo ""

        echo "=== OOM KILLER ==="
        dmesg | tail -100 | grep -i "out of memory\|oom\|killed process" || echo "No OOM events"
        echo ""

        echo "=== FORK FAILURES ==="
        dmesg | tail -100 | grep -i "fork.*fail\|cannot allocate memory" || echo "No fork failures"
        echo ""

        echo "=== SYSTEMD FAILURES ==="
        systemctl --failed --no-pager 2>/dev/null || echo "No failed units"
        echo ""

        echo "=== RECENT JOURNAL ERRORS ==="
        journalctl -p err --since "10 seconds ago" --no-pager 2>/dev/null || echo "No errors"
        echo ""

        echo "=== NIX BUILD ERRORS IN OUTPUT ==="
        tail -50 "$REBUILD_OUTPUT" 2>/dev/null | grep -i "error\|failed\|abort" || echo "No errors detected"
        echo ""

    } >> "$ERRORS_LOG"
}

# Função para display status
display_status() {
    clear

    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║        NIXOS REBUILD - MONITORAÇÃO COMPLETA DE DEBUG        ║
╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    echo -e "${BOLD}📊 STATUS GERAL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Rebuild status
    if kill -0 $REBUILD_PID 2>/dev/null; then
        local elapsed=$(($(date +%s) - $(stat -c %Y /proc/$REBUILD_PID)))
        echo -e "${CYAN}Rebuild:${NC} 🟢 Rodando (PID: $REBUILD_PID, há ${elapsed}s)"
    else
        local exit_code=$(cat "$LOG_DIR/rebuild-exit-code.txt" 2>/dev/null || echo "?")
        if [ "$exit_code" = "0" ]; then
            echo -e "${GREEN}Rebuild:${NC} ✅ Completado com sucesso"
        else
            echo -e "${RED}Rebuild:${NC} ❌ Falhou (exit code: $exit_code)"
        fi
    fi

    # Memória
    local mem_line=$(free | grep Mem)
    local mem_total=$(echo $mem_line | awk '{print $2}')
    local mem_used=$(echo $mem_line | awk '{print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    local mem_color=$GREEN
    [ $mem_percent -gt 80 ] && mem_color=$YELLOW
    [ $mem_percent -gt 90 ] && mem_color=$RED
    echo -e "${mem_color}Memória:${NC} ${mem_percent}% ($(( mem_used / 1024 ))MB / $(( mem_total / 1024 ))MB)"

    # Swap
    local swap_line=$(free | grep Swap)
    local swap_used=$(echo $swap_line | awk '{print $3}')
    local swap_mb=$((swap_used / 1024))
    if [ $swap_mb -gt 100 ]; then
        echo -e "${YELLOW}Swap:${NC} ${swap_mb}MB em uso ⚠️"
    fi

    # CPU Load
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local load_1min=$(echo $load | awk '{print $1}')
    local num_cores=$(nproc)
    local load_percent=$(echo "$load_1min $num_cores" | awk '{printf "%.0f", ($1/$2)*100}')
    local load_color=$GREEN
    [ $load_percent -gt 100 ] && load_color=$YELLOW
    [ $load_percent -gt 150 ] && load_color=$RED
    echo -e "${load_color}CPU Load:${NC} $load (${load_percent}% de $num_cores cores)"

    # Systemd jobs
    local jobs_count=$(systemctl list-jobs --no-pager 2>/dev/null | grep -c "^[0-9]" || echo 0)
    if [ $jobs_count -gt 0 ]; then
        echo -e "${YELLOW}Systemd Jobs:${NC} $jobs_count ativos"
    fi

    # Processos nix
    local nix_count=$(pgrep -c "nix-daemon\|nix-build\|nixos-rebuild" 2>/dev/null || echo 0)
    if [ $nix_count -gt 0 ]; then
        echo -e "${BLUE}Processos Nix:${NC} $nix_count ativos"
    fi

    # Containers
    local containers_running=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l || echo 0)
    if [ $containers_running -gt 0 ]; then
        echo -e "${CYAN}Containers:${NC} $containers_running rodando"
        podman ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2 | while read line; do
            echo "  └─ $line"
        done
    fi

    echo ""
    echo -e "${BOLD}📝 ÚLTIMOS LOGS DO REBUILD${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -15 "$REBUILD_OUTPUT" 2>/dev/null || echo "Aguardando output..."

    echo ""
    echo -e "${BOLD}🔍 DETALHES${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Logs salvos em: $LOG_DIR"
    echo "Pressione Ctrl+C para parar e gerar relatório completo"
    echo ""
}

# Função de cleanup
cleanup() {
    log_color "$YELLOW" "🛑 Parando monitoração..."

    # Gerar relatório final
    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║            RELATÓRIO FINAL - REBUILD DEBUG                  ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Log Directory: $LOG_DIR"
        echo "Rebuild Command: $REBUILD_CMD"
        echo "Start Time: $(stat -c %y "$MAIN_LOG" | cut -d. -f1)"
        echo "End Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""

        if [ -f "$LOG_DIR/rebuild-exit-code.txt" ]; then
            local exit_code=$(cat "$LOG_DIR/rebuild-exit-code.txt")
            echo "Exit Code: $exit_code"
            if [ "$exit_code" = "0" ]; then
                echo "Status: ✅ SUCCESS"
            else
                echo "Status: ❌ FAILED"
            fi
        else
            echo "Status: ⚠️  INTERRUPTED"
        fi

        echo ""
        echo "=== FILES GENERATED ==="
        ls -lh "$LOG_DIR"

        echo ""
        echo "=== FINAL MEMORY STATE ==="
        free -h

        echo ""
        echo "=== FINAL SYSTEMD STATE ==="
        systemctl --failed --no-pager || echo "No failed units"

        echo ""
        echo "=== ERRORS SUMMARY ==="
        echo "OOM Events:"
        grep -c "out of memory\|oom" "$ERRORS_LOG" 2>/dev/null || echo "0"
        echo ""
        echo "Fork Failures:"
        grep -c "fork.*fail" "$ERRORS_LOG" 2>/dev/null || echo "0"
        echo ""
        echo "Systemd Failures:"
        grep -c "Failed with result" "$SYSTEMD_LOG" 2>/dev/null || echo "0"

    } > "$LOG_DIR/FINAL-REPORT.txt"

    cat "$LOG_DIR/FINAL-REPORT.txt"

    log_color "$GREEN" "✅ Relatório completo salvo em: $LOG_DIR/FINAL-REPORT.txt"
    log_color "$GREEN" "📂 Todos os logs em: $LOG_DIR"

    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Loop principal de monitoração
iteration=0
while true; do
    iteration=$((iteration + 1))

    # Display status (a cada iteração)
    display_status

    # Capturar processos (a cada iteração)
    capture_processes

    # Capturar memória (a cada 2 iterações)
    if [ $((iteration % 2)) -eq 0 ]; then
        capture_memory
    fi

    # Capturar logs systemd (a cada iteração)
    capture_systemd_logs

    # Capturar logs podman (a cada 3 iterações)
    if [ $((iteration % 3)) -eq 0 ]; then
        capture_podman_logs
    fi

    # Detectar erros (a cada 2 iterações)
    if [ $((iteration % 2)) -eq 0 ]; then
        detect_errors
    fi

    # Verificar se rebuild terminou
    if ! kill -0 $REBUILD_PID 2>/dev/null; then
        log_color "$CYAN" "Rebuild finalizado, aguardando 5 segundos para capturar logs finais..."
        sleep 5

        # Captura final
        capture_processes
        capture_memory
        capture_systemd_logs
        capture_podman_logs
        detect_errors

        break
    fi

    sleep $INTERVAL
done

# Cleanup automático
cleanup
