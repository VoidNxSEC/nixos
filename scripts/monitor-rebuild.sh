#!/usr/bin/env bash
# Script de monitoramento avançado para diagnosticar rebuild do NixOS
# Uso: ./monitor-rebuild.sh [opções]
# Opções:
#   -i INTERVAL    Intervalo de coleta em segundos (padrão: 2s)
#   -r             Executar rebuild automaticamente
#   -d DESKTOP     IP do desktop para envio de logs (padrão: 192.168.15.7)
#   -u USER        Usuário SSH no desktop (padrão: kernelcore)
#   -p PATH        Caminho remoto para logs (padrão: ~/rebuild-diagnostics)
#   -n             Não enviar logs para desktop
#   -v             Modo verbose

set -euo pipefail

# Configurações padrão
INTERVAL=2
RUN_REBUILD=false
DESKTOP_IP="192.168.15.7"
DESKTOP_USER="kernelcore"
DESKTOP_PATH="~/rebuild-diagnostics"
SEND_TO_DESKTOP=true
VERBOSE=false

# Parse argumentos
while getopts "i:rd:u:p:nvh" opt; do
    case $opt in
        i) INTERVAL="$OPTARG" ;;
        r) RUN_REBUILD=true ;;
        d) DESKTOP_IP="$OPTARG" ;;
        u) DESKTOP_USER="$OPTARG" ;;
        p) DESKTOP_PATH="$OPTARG" ;;
        n) SEND_TO_DESKTOP=false ;;
        v) VERBOSE=true ;;
        h)
            echo "Uso: $0 [opções]"
            echo "  -i INTERVAL    Intervalo de coleta em segundos (padrão: 2s)"
            echo "  -r             Executar rebuild automaticamente"
            echo "  -d DESKTOP     IP do desktop para envio de logs (padrão: 192.168.15.7)"
            echo "  -u USER        Usuário SSH no desktop (padrão: kernelcore)"
            echo "  -p PATH        Caminho remoto para logs (padrão: ~/rebuild-diagnostics)"
            echo "  -n             Não enviar logs para desktop"
            echo "  -v             Modo verbose"
            exit 0
            ;;
        *) echo "Opção inválida: -$OPTARG" >&2; exit 1 ;;
    esac
done

LOG_DIR="/tmp/rebuild-monitor-$(date +%Y%m%d-%H%M%S)"
MAIN_LOG="$LOG_DIR/monitor.log"
MEM_LOG="$LOG_DIR/memory.csv"
CPU_LOG="$LOG_DIR/cpu.csv"
PROC_LOG="$LOG_DIR/processes.csv"
DISK_LOG="$LOG_DIR/disk.csv"
NIX_STORE_LOG="$LOG_DIR/nix-store.csv"
NETWORK_LOG="$LOG_DIR/network.csv"
FD_LOG="$LOG_DIR/file-descriptors.csv"
JOURNAL_LOG="$LOG_DIR/journal.log"
TOP_CONSUMERS="$LOG_DIR/top-consumers.log"
REBUILD_OUTPUT="$LOG_DIR/rebuild.log"
REBUILD_STATUS="$LOG_DIR/rebuild-status.txt"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Headers dos CSVs
echo "timestamp,total_mb,used_mb,free_mb,available_mb,swap_used_mb,swap_free_mb" > "$MEM_LOG"
echo "timestamp,cpu_percent,load_1min,load_5min,load_15min" > "$CPU_LOG"
echo "timestamp,process_name,count,total_mem_mb" > "$PROC_LOG"
echo "timestamp,mount_point,total_gb,used_gb,available_gb,use_percent" > "$DISK_LOG"
echo "timestamp,nix_store_gb,tmp_gb,build_dirs_count" > "$NIX_STORE_LOG"
echo "timestamp,rx_mb,tx_mb,rx_packets,tx_packets" > "$NETWORK_LOG"
echo "timestamp,total_fds,nix_daemon_fds,nix_build_fds" > "$FD_LOG"
echo "timestamp,cpu_temp,gpu_temp,nvme_temp" > "$LOG_DIR/temperature.csv"
echo "timestamp,max_processes,current_processes,max_threads,current_threads" > "$LOG_DIR/process-limits.csv"
echo "timestamp,available_mem_mb,min_free_kb,fork_possible" > "$LOG_DIR/fork-analysis.csv"

# Variáveis de estado
REBUILD_PID=""
REBUILD_START_TIME=""
REBUILD_END_TIME=""
INITIAL_NIX_STORE_SIZE=""

log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${msg}" | tee -a "$MAIN_LOG"
}

log_color() {
    local color=$1
    local level=$2
    shift 2
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${color}${timestamp} [${level}] ${msg}${NC}" | tee -a "$MAIN_LOG"
}

get_memory_stats() {
    local timestamp=$(date +%s)

    # Parse /proc/meminfo
    local total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    local free=$(grep MemFree /proc/meminfo | awk '{print int($2/1024)}')
    local available=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
    local used=$((total - available))

    # Parse swap
    local swap_total=$(grep SwapTotal /proc/meminfo | awk '{print int($2/1024)}')
    local swap_free=$(grep SwapFree /proc/meminfo | awk '{print int($2/1024)}')
    local swap_used=$((swap_total - swap_free))

    echo "$timestamp,$total,$used,$free,$available,$swap_used,$swap_free" >> "$MEM_LOG"

    # Check thresholds - validar valores
    if [[ "$total" =~ ^[0-9]+$ ]] && [ "$total" -gt 0 ]; then
        local mem_percent=$((used * 100 / total))
        if [ $mem_percent -gt 90 ]; then
            log_color "$RED" "CRITICAL" "Memória em ${mem_percent}% (${used}MB/${total}MB)"
        elif [ $mem_percent -gt 80 ]; then
            log_color "$YELLOW" "WARNING" "Memória em ${mem_percent}% (${used}MB/${total}MB)"
        fi
    fi

    if [[ "$swap_used" =~ ^[0-9]+$ ]] && [ $swap_used -gt 1000 ]; then
        log_color "$YELLOW" "WARNING" "Swap em uso: ${swap_used}MB"
    fi
}

get_cpu_stats() {
    local timestamp=$(date +%s)

    # CPU percentage (média de todos os cores)
    local cpu_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Load average
    local load_avg=$(cat /proc/loadavg)
    local load_1min=$(echo $load_avg | awk '{print $1}')
    local load_5min=$(echo $load_avg | awk '{print $2}')
    local load_15min=$(echo $load_avg | awk '{print $3}')

    echo "$timestamp,$cpu_percent,$load_1min,$load_5min,$load_15min" >> "$CPU_LOG"

    # Check load vs cores
    local num_cores=$(nproc)
    local load_percent=$(echo "$load_1min $num_cores" | awk '{printf "%.0f", ($1/$2)*100}')

    # Validar valores numéricos
    if [[ "$load_percent" =~ ^[0-9]+$ ]]; then
        if [ $load_percent -gt 150 ]; then
            log_color "$RED" "CRITICAL" "Load average muito alto: $load_1min (${load_percent}% dos $num_cores cores)"
        elif [ $load_percent -gt 100 ]; then
            log_color "$YELLOW" "WARNING" "Load average alto: $load_1min (${load_percent}% dos $num_cores cores)"
        fi
    fi
}

get_process_stats() {
    local timestamp=$(date +%s)

    # Processos de compilação Nix/Rust
    local processes=("nix-daemon" "nix-build" "cargo" "rustc" "cc1plus" "ld" "gcc" "g++" "clang")

    for proc in "${processes[@]}"; do
        local count=$(pgrep -c "$proc" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            # Soma memória de todos os processos desse tipo (em MB)
            local total_mem=$(ps aux | grep "$proc" | grep -v grep | awk '{sum+=$6} END {print int(sum/1024)}')
            echo "$timestamp,$proc,$count,$total_mem" >> "$PROC_LOG"

            if [ "$count" -gt 5 ]; then
                log_color "$BLUE" "INFO" "Processo $proc: $count instâncias, ${total_mem}MB total"
            fi
        fi
    done
}

get_top_consumers() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo "=== TOP MEMORY CONSUMERS - $timestamp ==="
        # BusyBox ps não suporta --sort, então fazemos sort manualmente
        ps aux | tail -n +2 | sort -k6 -rn | head -20 | awk '{printf "%-20s %10s %10s %s\n", $11, $6/1024 "MB", $3"%", $2}'
        echo ""
    } >> "$TOP_CONSUMERS"
}

check_oom_killer() {
    # Verifica se OOM killer foi ativado recentemente (últimos 60 segundos)
    local oom_lines=$(journalctl -b -0 --since "60 seconds ago" --no-pager 2>/dev/null | grep -i "out of memory\|oom" || true)

    if [ -n "$oom_lines" ]; then
        log_color "$RED" "CRITICAL" "OOM Killer detectado!"
        echo "$oom_lines" | tee -a "$MAIN_LOG"
    fi
}

monitor_disk_io() {
    local timestamp=$(date +%s)

    # Verificar I/O wait
    local io_wait=$(iostat -c 1 2 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")

    if (( $(echo "$io_wait > 30" | bc -l 2>/dev/null || echo "0") )); then
        log_color "$YELLOW" "WARNING" "I/O wait alto: ${io_wait}%"
    fi
}

monitor_disk_usage() {
    local timestamp=$(date +%s)

    # Monitorar partições importantes
    for mount in "/" "/nix" "/tmp"; do
        if mountpoint -q "$mount" 2>/dev/null || [ "$mount" == "/" ]; then
            local df_output=$(df -BG "$mount" 2>/dev/null | tail -1)
            local total=$(echo "$df_output" | awk '{print $2}' | tr -d 'G' | tr -d ' ')
            local used=$(echo "$df_output" | awk '{print $3}' | tr -d 'G' | tr -d ' ')
            local available=$(echo "$df_output" | awk '{print $4}' | tr -d 'G' | tr -d ' ')
            local use_percent=$(echo "$df_output" | awk '{print $5}' | tr -d '%' | tr -d ' ')

            # Validar que use_percent é um número antes de comparar
            if [[ "$use_percent" =~ ^[0-9]+$ ]]; then
                echo "$timestamp,$mount,$total,$used,$available,$use_percent" >> "$DISK_LOG"

                # Alertas
                if [ "$use_percent" -gt 90 ]; then
                    log_color "$RED" "CRITICAL" "Disco $mount em ${use_percent}% (${available}GB livres)"
                elif [ "$use_percent" -gt 80 ]; then
                    log_color "$YELLOW" "WARNING" "Disco $mount em ${use_percent}% (${available}GB livres)"
                fi
            fi
        fi
    done
}

monitor_nix_store() {
    local timestamp=$(date +%s)

    # Tamanho do /nix/store
    local nix_store_size=$(du -sbG /nix/store 2>/dev/null | awk '{print $1}' | tr -d 'G' || echo "0")

    # Tamanho do /tmp
    local tmp_size=$(du -sbG /tmp 2>/dev/null | awk '{print $1}' | tr -d 'G' || echo "0")

    # Contar diretórios de build ativos
    local build_dirs=$(find /tmp -maxdepth 1 -name "nix-build-*" -o -name "nix-shell-*" 2>/dev/null | wc -l)

    echo "$timestamp,$nix_store_size,$tmp_size,$build_dirs" >> "$NIX_STORE_LOG"

    # Guardar tamanho inicial se não existe
    if [ -z "$INITIAL_NIX_STORE_SIZE" ]; then
        INITIAL_NIX_STORE_SIZE="$nix_store_size"
    fi

    # Calcular crescimento - validar valores numéricos
    if [[ "$nix_store_size" =~ ^[0-9]+$ ]] && [[ "$INITIAL_NIX_STORE_SIZE" =~ ^[0-9]+$ ]]; then
        local growth=$((nix_store_size - INITIAL_NIX_STORE_SIZE))
        if [ "$growth" -gt 10 ]; then
            log_color "$BLUE" "INFO" "Nix store cresceu ${growth}GB durante rebuild"
        fi
    fi

    if [[ "$build_dirs" =~ ^[0-9]+$ ]] && [ "$build_dirs" -gt 20 ]; then
        log_color "$YELLOW" "WARNING" "${build_dirs} diretórios de build em /tmp"
    fi
}

monitor_network() {
    local timestamp=$(date +%s)

    # Estatísticas de rede (download de caches)
    local rx_bytes=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | awk '{sum+=$1} END {print int(sum/1024/1024)}')
    local tx_bytes=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | awk '{sum+=$1} END {print int(sum/1024/1024)}')
    local rx_packets=$(cat /sys/class/net/*/statistics/rx_packets 2>/dev/null | awk '{sum+=$1} END {print sum}')
    local tx_packets=$(cat /sys/class/net/*/statistics/tx_packets 2>/dev/null | awk '{sum+=$1} END {print sum}')

    echo "$timestamp,$rx_bytes,$tx_bytes,$rx_packets,$tx_packets" >> "$NETWORK_LOG"
}

monitor_file_descriptors() {
    local timestamp=$(date +%s)

    # Total de FDs abertos no sistema
    local total_fds=$(cat /proc/sys/fs/file-nr 2>/dev/null | awk '{print $1}' || echo "0")

    # FDs dos processos Nix
    local nix_daemon_fds=$(lsof -p $(pgrep nix-daemon | head -1) 2>/dev/null | wc -l || echo "0")
    local nix_build_fds=$(lsof -p $(pgrep nix-build | head -1) 2>/dev/null | wc -l || echo "0")

    echo "$timestamp,$total_fds,$nix_daemon_fds,$nix_build_fds" >> "$FD_LOG"

    # Alertas - validar valores numéricos
    local max_fds=$(cat /proc/sys/fs/file-max 2>/dev/null || echo "0")

    if [[ "$max_fds" =~ ^[0-9]+$ ]] && [[ "$total_fds" =~ ^[0-9]+$ ]] && [ "$max_fds" -gt 0 ]; then
        local fd_percent=$((total_fds * 100 / max_fds))

        if [ "$fd_percent" -gt 80 ]; then
            log_color "$YELLOW" "WARNING" "File descriptors em ${fd_percent}% (${total_fds}/${max_fds})"
        fi
    fi
}

capture_journal() {
    # Capturar logs do journal em tempo real (últimos 10 segundos)
    journalctl -b -0 --since "10 seconds ago" --no-pager -u nix-daemon.service 2>/dev/null >> "$JOURNAL_LOG" || true
}

send_to_desktop() {
    if [ "$SEND_TO_DESKTOP" = false ]; then
        return 0
    fi

    log_color "$BLUE" "INFO" "Enviando logs para desktop ${DESKTOP_USER}@${DESKTOP_IP}:${DESKTOP_PATH}..."

    # Testar conectividade SSH
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${DESKTOP_USER}@${DESKTOP_IP}" "exit" 2>/dev/null; then
        log_color "$YELLOW" "WARNING" "Não foi possível conectar ao desktop via SSH. Logs não serão enviados."
        return 1
    fi

    # Criar diretório remoto
    ssh "${DESKTOP_USER}@${DESKTOP_IP}" "mkdir -p ${DESKTOP_PATH}" 2>/dev/null || true

    # Comprimir logs antes de enviar
    local archive_name="rebuild-monitor-$(date +%Y%m%d-%H%M%S).tar.gz"
    local archive_path="/tmp/${archive_name}"

    tar -czf "$archive_path" -C "$(dirname "$LOG_DIR")" "$(basename "$LOG_DIR")" 2>/dev/null

    # Enviar via rsync (mais eficiente)
    if command -v rsync >/dev/null 2>&1; then
        rsync -avz --progress "$archive_path" "${DESKTOP_USER}@${DESKTOP_IP}:${DESKTOP_PATH}/" 2>&1 | tee -a "$MAIN_LOG"
    else
        # Fallback para scp
        scp "$archive_path" "${DESKTOP_USER}@${DESKTOP_IP}:${DESKTOP_PATH}/" 2>&1 | tee -a "$MAIN_LOG"
    fi

    if [ $? -eq 0 ]; then
        log_color "$GREEN" "SUCCESS" "Logs enviados com sucesso para desktop: ${DESKTOP_PATH}/${archive_name}"
        # Também enviar o relatório descompactado para fácil acesso
        scp "$LOG_DIR/report.html" "${DESKTOP_USER}@${DESKTOP_IP}:${DESKTOP_PATH}/latest-report.html" 2>/dev/null || true
    else
        log_color "$RED" "ERROR" "Falha ao enviar logs para desktop"
        return 1
    fi

    # Limpar arquivo temporário
    rm -f "$archive_path"
}

run_rebuild() {
    log_color "$GREEN" "REBUILD" "Iniciando nixos-rebuild switch..."
    REBUILD_START_TIME=$(date +%s)

    # Executar rebuild em background e capturar output
    (sudo nixos-rebuild switch 2>&1 | tee "$REBUILD_OUTPUT"; echo $? > "$REBUILD_STATUS") &
    REBUILD_PID=$!

    log "INFO" "Rebuild iniciado com PID: $REBUILD_PID"
}

check_rebuild_status() {
    if [ -z "$REBUILD_PID" ]; then
        return 0
    fi

    # Verificar se rebuild ainda está rodando
    if ! kill -0 "$REBUILD_PID" 2>/dev/null; then
        # Rebuild terminou
        REBUILD_END_TIME=$(date +%s)
        local exit_code=$(cat "$REBUILD_STATUS" 2>/dev/null || echo "unknown")
        local duration=$((REBUILD_END_TIME - REBUILD_START_TIME))

        if [ "$exit_code" == "0" ]; then
            log_color "$GREEN" "SUCCESS" "Rebuild completado com sucesso em ${duration}s"
        else
            log_color "$RED" "ERROR" "Rebuild falhou com código de saída: $exit_code (duração: ${duration}s)"
        fi

        # Limpar PID
        REBUILD_PID=""
        return 1  # Sinaliza que rebuild terminou
    fi

    return 0  # Rebuild ainda está rodando
}

monitor_temperature() {
    local timestamp=$(date +%s)

    # CPU temperature (via sensors ou hwmon)
    local cpu_temp="N/A"
    if command -v sensors >/dev/null 2>&1; then
        cpu_temp=$(sensors 2>/dev/null | grep -i "Package id 0:\|Tdie:" | head -1 | awk '{print $4}' | tr -d '+°C' || echo "N/A")
    fi

    # Se sensors não funcionar, tentar via hwmon
    if [ "$cpu_temp" == "N/A" ]; then
        if [ -f /sys/class/hwmon/hwmon*/temp1_input ]; then
            local temp_raw=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
            cpu_temp=$(echo "scale=1; $temp_raw / 1000" | bc 2>/dev/null || echo "N/A")
        fi
    fi

    # GPU temperature (NVIDIA)
    local gpu_temp="N/A"
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
    fi

    # NVMe temperature
    local nvme_temp="N/A"
    if command -v smartctl >/dev/null 2>&1; then
        local nvme_device=$(lsblk -d -o NAME,TYPE | grep nvme | head -1 | awk '{print $1}')
        if [ -n "$nvme_device" ]; then
            nvme_temp=$(sudo smartctl -a "/dev/$nvme_device" 2>/dev/null | grep "Temperature:" | awk '{print $2}' || echo "N/A")
        fi
    fi

    echo "$timestamp,$cpu_temp,$gpu_temp,$nvme_temp" >> "$LOG_DIR/temperature.csv"

    # Alertas de temperatura
    if [ "$cpu_temp" != "N/A" ]; then
        local cpu_temp_int=$(echo "$cpu_temp" | cut -d'.' -f1 | tr -d ' ')
        # Validar que é número
        if [[ "$cpu_temp_int" =~ ^[0-9]+$ ]]; then
            if [ "$cpu_temp_int" -gt 85 ]; then
                log_color "$RED" "CRITICAL" "Temperatura da CPU muito alta: ${cpu_temp}°C"
            elif [ "$cpu_temp_int" -gt 75 ]; then
                log_color "$YELLOW" "WARNING" "Temperatura da CPU elevada: ${cpu_temp}°C"
            fi
        fi
    fi

    if [ "$gpu_temp" != "N/A" ]; then
        # Validar que é número
        if [[ "$gpu_temp" =~ ^[0-9]+$ ]]; then
            if [ "$gpu_temp" -gt 80 ]; then
                log_color "$YELLOW" "WARNING" "Temperatura da GPU elevada: ${gpu_temp}°C"
            fi
        fi
    fi
}

monitor_process_limits() {
    local timestamp=$(date +%s)

    # Limites de processos do sistema
    local max_processes=$(cat /proc/sys/kernel/pid_max 2>/dev/null || echo "0")
    local current_processes=$(ps aux | wc -l)

    # Limites de threads
    local max_threads=$(cat /proc/sys/kernel/threads-max 2>/dev/null || echo "0")
    local current_threads=$(ps -eLf | wc -l)

    echo "$timestamp,$max_processes,$current_processes,$max_threads,$current_threads" >> "$LOG_DIR/process-limits.csv"

    # Alertas - validar que temos valores numéricos válidos
    if [[ "$max_processes" =~ ^[0-9]+$ ]] && [[ "$current_processes" =~ ^[0-9]+$ ]] && [ "$max_processes" -gt 0 ]; then
        local process_percent=$((current_processes * 100 / max_processes))

        if [ "$process_percent" -gt 80 ]; then
            log_color "$RED" "CRITICAL" "Limite de processos em ${process_percent}% (${current_processes}/${max_processes})"
        elif [ "$process_percent" -gt 60 ]; then
            log_color "$YELLOW" "WARNING" "Processos em ${process_percent}% do limite (${current_processes}/${max_processes})"
        fi
    fi

    if [[ "$max_threads" =~ ^[0-9]+$ ]] && [[ "$current_threads" =~ ^[0-9]+$ ]] && [ "$max_threads" -gt 0 ]; then
        local thread_percent=$((current_threads * 100 / max_threads))

        if [ "$thread_percent" -gt 80 ]; then
            log_color "$RED" "CRITICAL" "Limite de threads em ${thread_percent}% (${current_threads}/${max_threads})"
        fi
    fi
}

analyze_fork_capability() {
    local timestamp=$(date +%s)

    # Memória disponível para fork
    local available_mem=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')

    # vm.min_free_kbytes - memória mínima que o kernel mantém livre
    local min_free_kb=$(cat /proc/sys/vm/min_free_kbytes 2>/dev/null || echo "0")

    # Verificar se há memória suficiente para fork
    # Um processo médio do Nix precisa de ~500MB para fork
    local fork_possible="yes"

    # Validar que available_mem é numérico
    if [[ "$available_mem" =~ ^[0-9]+$ ]]; then
        if [ "$available_mem" -lt 512 ]; then
            fork_possible="NO"
            log_color "$RED" "CRITICAL" "Memória insuficiente para fork! Disponível: ${available_mem}MB (mínimo recomendado: 512MB)"
            log_color "$RED" "CRITICAL" "Isso causa erros 'unable to fork' durante rebuild!"
        elif [ "$available_mem" -lt 1024 ]; then
            fork_possible="marginal"
            log_color "$YELLOW" "WARNING" "Memória baixa para fork: ${available_mem}MB disponível"
        fi

        echo "$timestamp,$available_mem,$min_free_kb,$fork_possible" >> "$LOG_DIR/fork-analysis.csv"

        # Verificar overcommit settings
        local overcommit_memory=$(cat /proc/sys/vm/overcommit_memory 2>/dev/null || echo "unknown")
        local overcommit_ratio=$(cat /proc/sys/vm/overcommit_ratio 2>/dev/null || echo "unknown")

        if [ "$fork_possible" == "NO" ] || [ "$fork_possible" == "marginal" ]; then
            log_color "$BLUE" "INFO" "Overcommit settings: memory=$overcommit_memory, ratio=$overcommit_ratio"
            log_color "$BLUE" "INFO" "Considere aumentar swap ou limitar jobs paralelos de Nix"

            # Sugestão de max-jobs
            local suggested_jobs=$((available_mem / 1024))
            [ "$suggested_jobs" -lt 1 ] && suggested_jobs=1
            log_color "$BLUE" "INFO" "Sugestão: configure max-jobs = $suggested_jobs em nix.settings"
        fi
    fi

    # Detectar mensagens de fork failure no dmesg
    if dmesg | tail -100 | grep -qi "fork.*failed\|cannot allocate memory" 2>/dev/null; then
        log_color "$RED" "CRITICAL" "Detectadas falhas de fork recentes no kernel log (dmesg)!"
    fi
}

print_summary() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo ""
    log_color "$GREEN" "=====" "SUMMARY - $timestamp ====="

    # Memória
    if [ -f "$MEM_LOG" ] && [ $(wc -l < "$MEM_LOG") -gt 1 ]; then
        local mem_line=$(tail -1 "$MEM_LOG")
        local mem_used=$(echo "$mem_line" | cut -d',' -f3)
        local mem_total=$(echo "$mem_line" | cut -d',' -f2)
        # Validar valores numéricos antes de calcular
        if [[ "$mem_total" =~ ^[0-9]+$ ]] && [ "$mem_total" -gt 0 ]; then
            local mem_percent=$((mem_used * 100 / mem_total))
            echo -e "${BLUE}Memória:${NC} ${mem_used}MB / ${mem_total}MB (${mem_percent}%)" | tee -a "$MAIN_LOG"
        fi
    fi

    # CPU
    if [ -f "$CPU_LOG" ] && [ $(wc -l < "$CPU_LOG") -gt 1 ]; then
        local cpu_line=$(tail -1 "$CPU_LOG")
        local cpu_percent=$(echo "$cpu_line" | cut -d',' -f2)
        local load_1min=$(echo "$cpu_line" | cut -d',' -f3)
        echo -e "${BLUE}CPU:${NC} ${cpu_percent}% | Load: $load_1min" | tee -a "$MAIN_LOG"
    fi

    # Disco
    if [ -f "$DISK_LOG" ] && [ $(wc -l < "$DISK_LOG") -gt 1 ]; then
        echo -e "${BLUE}Disco:${NC}" | tee -a "$MAIN_LOG"
        tail -3 "$DISK_LOG" | awk -F',' '{printf "  %s: %sGB/%sGB (%s%%)\n", $2, $3, $4, $6}' | tee -a "$MAIN_LOG"
    fi

    # Nix Store
    if [ -f "$NIX_STORE_LOG" ] && [ $(wc -l < "$NIX_STORE_LOG") -gt 1 ]; then
        local nix_line=$(tail -1 "$NIX_STORE_LOG")
        local nix_store_gb=$(echo "$nix_line" | cut -d',' -f2)
        local build_dirs=$(echo "$nix_line" | cut -d',' -f4)
        echo -e "${BLUE}Nix Store:${NC} ${nix_store_gb}GB | Build dirs: $build_dirs" | tee -a "$MAIN_LOG"
    fi

    # Processos ativos
    if [ -f "$PROC_LOG" ] && [ $(wc -l < "$PROC_LOG") -gt 1 ]; then
        echo -e "${BLUE}Processos de compilação ativos:${NC}" | tee -a "$MAIN_LOG"
        tail -10 "$PROC_LOG" | awk -F',' '{if ($3 > 0) print "  " $2 ": " $3 " processos, " $4 "MB"}' | tee -a "$MAIN_LOG"
    fi

    # Status do rebuild
    if [ -n "$REBUILD_PID" ]; then
        local elapsed=$(($(date +%s) - REBUILD_START_TIME))
        echo -e "${BLUE}Rebuild:${NC} Em execução há ${elapsed}s (PID: $REBUILD_PID)" | tee -a "$MAIN_LOG"
    fi

    echo ""
}

generate_html_report() {
    local report_file="$LOG_DIR/report.html"

    cat > "$report_file" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>NixOS Rebuild Monitor Report</title>
    <style>
        body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }
        h1, h2 { color: #4fc3f7; }
        .section { background: #2d2d2d; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .critical { color: #f44336; font-weight: bold; }
        .warning { color: #ff9800; }
        .success { color: #4caf50; }
        .info { color: #2196f3; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #444; }
        th { background: #3d3d3d; color: #4fc3f7; }
        pre { background: #252525; padding: 10px; overflow-x: auto; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #3d3d3d; border-radius: 5px; }
    </style>
</head>
<body>
EOF

    echo "<h1>NixOS Rebuild Monitoring Report</h1>" >> "$report_file"
    echo "<p>Generated: $(date '+%Y-%m-%d %H:%M:%S')</p>" >> "$report_file"
    echo "<p>Log Directory: $LOG_DIR</p>" >> "$report_file"

    # Rebuild status
    if [ -n "$REBUILD_END_TIME" ]; then
        local duration=$((REBUILD_END_TIME - REBUILD_START_TIME))
        local exit_code=$(cat "$REBUILD_STATUS" 2>/dev/null || echo "unknown")
        echo "<div class='section'>" >> "$report_file"
        echo "<h2>Rebuild Status</h2>" >> "$report_file"
        if [ "$exit_code" == "0" ]; then
            echo "<p class='success'>✓ Rebuild completado com sucesso</p>" >> "$report_file"
        else
            echo "<p class='critical'>✗ Rebuild falhou (exit code: $exit_code)</p>" >> "$report_file"
        fi
        echo "<p>Duração: ${duration}s ($(($duration / 60))m $(($duration % 60))s)</p>" >> "$report_file"
        echo "</div>" >> "$report_file"
    fi

    # Peak metrics
    echo "<div class='section'><h2>Peak Metrics</h2>" >> "$report_file"

    if [ -f "$MEM_LOG" ] && [ $(wc -l < "$MEM_LOG") -gt 1 ]; then
        local peak_mem=$(tail -n +2 "$MEM_LOG" | sort -t',' -k3 -rn | head -1)
        local peak_mem_used=$(echo "$peak_mem" | cut -d',' -f3)
        local peak_mem_total=$(echo "$peak_mem" | cut -d',' -f2)
        # Validar valores numéricos
        if [[ "$peak_mem_total" =~ ^[0-9]+$ ]] && [ "$peak_mem_total" -gt 0 ]; then
            local peak_mem_percent=$((peak_mem_used * 100 / peak_mem_total))
            echo "<div class='metric'><strong>Peak Memory:</strong> ${peak_mem_used}MB / ${peak_mem_total}MB (${peak_mem_percent}%)</div>" >> "$report_file"
        fi
    fi

    if [ -f "$CPU_LOG" ] && [ $(wc -l < "$CPU_LOG") -gt 1 ]; then
        local peak_cpu=$(tail -n +2 "$CPU_LOG" | sort -t',' -k2 -rn | head -1)
        local peak_cpu_percent=$(echo "$peak_cpu" | cut -d',' -f2 | cut -d'.' -f1)
        local peak_load=$(echo "$peak_cpu" | cut -d',' -f3)
        echo "<div class='metric'><strong>Peak CPU:</strong> ${peak_cpu_percent}% (Load: ${peak_load})</div>" >> "$report_file"
    fi

    echo "</div>" >> "$report_file"

    # Temperature data
    if [ -f "$LOG_DIR/temperature.csv" ] && [ $(wc -l < "$LOG_DIR/temperature.csv") -gt 1 ]; then
        echo "<div class='section'><h2>Temperature Peaks</h2><table>" >> "$report_file"
        echo "<tr><th>Component</th><th>Peak Temp (°C)</th></tr>" >> "$report_file"
        tail -n +2 "$LOG_DIR/temperature.csv" | awk -F',' 'BEGIN{max_cpu=0; max_gpu=0}
            {if($2>max_cpu)max_cpu=$2; if($3>max_gpu)max_gpu=$3}
            END{print max_cpu","max_gpu}' | awk -F',' \
            '{printf "<tr><td>CPU</td><td>%.1f</td></tr><tr><td>GPU</td><td>%.1f</td></tr>\n", $1, $2}' >> "$report_file"
        echo "</table></div>" >> "$report_file"
    fi

    # Critical events
    if [ -f "$MAIN_LOG" ]; then
        local critical_count=$(grep -c "CRITICAL" "$MAIN_LOG" 2>/dev/null || echo "0")
        local warning_count=$(grep -c "WARNING" "$MAIN_LOG" 2>/dev/null || echo "0")

        # Limpar qualquer whitespace/newline
        critical_count=$(echo "$critical_count" | tr -d ' \n\r')
        warning_count=$(echo "$warning_count" | tr -d ' \n\r')

        echo "<div class='section'><h2>Alerts Summary</h2>" >> "$report_file"
        echo "<p class='critical'>Critical Alerts: $critical_count</p>" >> "$report_file"
        echo "<p class='warning'>Warnings: $warning_count</p>" >> "$report_file"

        # Validar que é número antes de comparar
        if [[ "$critical_count" =~ ^[0-9]+$ ]] && [ "$critical_count" -gt 0 ]; then
            echo "<h3>Critical Events:</h3><pre>" >> "$report_file"
            grep "CRITICAL" "$MAIN_LOG" | tail -20 | sed 's/</\&lt;/g; s/>/\&gt;/g' >> "$report_file"
            echo "</pre>" >> "$report_file"
        fi
    fi

    # Files listing
    echo "<div class='section'><h2>Available Data Files</h2><ul>" >> "$report_file"
    for file in "$LOG_DIR"/*.{csv,log,txt}; do
        [ -f "$file" ] && echo "<li>$(basename "$file") ($(du -h "$file" | cut -f1))</li>" >> "$report_file"
    done
    echo "</ul></div>" >> "$report_file"

    echo "</body></html>" >> "$report_file"

    log "INFO" "Relatório HTML gerado: $report_file"
}

# Trap para cleanup
cleanup() {
    log_color "$GREEN" "INFO" "Monitoramento finalizado. Logs salvos em: $LOG_DIR"
    print_summary

    # Gerar relatório texto
    {
        echo "=== REBUILD MONITORING REPORT ==="
        echo "Log Directory: $LOG_DIR"
        echo "Duration: $(date)"
        echo ""

        if [ -n "$REBUILD_END_TIME" ]; then
            local duration=$((REBUILD_END_TIME - REBUILD_START_TIME))
            echo "=== REBUILD STATUS ==="
            echo "Exit code: $(cat "$REBUILD_STATUS" 2>/dev/null || echo "unknown")"
            echo "Duration: ${duration}s"
            echo ""
        fi

        echo "=== PEAK MEMORY USAGE ==="
        [ -f "$MEM_LOG" ] && tail -n +2 "$MEM_LOG" | sort -t',' -k3 -rn | head -5
        echo ""
        echo "=== PEAK CPU LOAD ==="
        [ -f "$CPU_LOG" ] && tail -n +2 "$CPU_LOG" | sort -t',' -k3 -rn | head -5
        echo ""
        echo "=== MOST ACTIVE PROCESSES ==="
        [ -f "$PROC_LOG" ] && tail -n +2 "$PROC_LOG" | sort -t',' -k3 -rn | head -10
        echo ""
        echo "=== CRITICAL EVENTS ==="
        [ -f "$MAIN_LOG" ] && grep "CRITICAL" "$MAIN_LOG" | tail -10 || echo "None"
    } > "$LOG_DIR/report.txt"

    # Gerar relatório HTML
    generate_html_report

    cat "$LOG_DIR/report.txt"

    # Enviar para desktop
    send_to_desktop

    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Main monitoring loop
log_color "$GREEN" "START" "Iniciando monitoramento avançado de rebuild..."
log "INFO" "Logs sendo salvos em: $LOG_DIR"
log "INFO" "Intervalo de coleta: ${INTERVAL}s"
log "INFO" "Envio para desktop: $([ "$SEND_TO_DESKTOP" = true ] && echo "Ativado (${DESKTOP_IP})" || echo "Desativado")"
log "INFO" "Pressione Ctrl+C para parar e gerar relatório"
echo ""

# Iniciar rebuild se solicitado
if [ "$RUN_REBUILD" = true ]; then
    run_rebuild
fi

iteration=0
while true; do
    iteration=$((iteration + 1))

    # Coletar estatísticas básicas (a cada iteração)
    get_memory_stats
    get_cpu_stats
    get_process_stats
    check_oom_killer
    analyze_fork_capability  # CRÍTICO: monitorar capacidade de fork

    # A cada 2 iterações, coletar métricas mais leves
    if [ $((iteration % 2)) -eq 0 ]; then
        monitor_disk_usage
        monitor_network
        monitor_file_descriptors
    fi

    # A cada 5 iterações, coletar métricas mais pesadas e mostrar summary
    if [ $((iteration % 5)) -eq 0 ]; then
        get_top_consumers
        monitor_disk_io
        monitor_nix_store
        monitor_temperature  # Temperaturas
        monitor_process_limits  # Limites de processos/threads
        capture_journal
        print_summary
    fi

    # Verificar status do rebuild (se iniciado)
    if ! check_rebuild_status; then
        # Rebuild terminou, sair do loop
        log_color "$GREEN" "INFO" "Rebuild finalizado. Gerando relatório..."
        break
    fi

    sleep "$INTERVAL"
done
