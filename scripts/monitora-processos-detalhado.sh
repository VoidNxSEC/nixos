#!/usr/bin/env bash

# monitora-processos-detalhado.sh: Script para coletar dados detalhados de processos.
# Coleta informações de CPU, Memória, I/O, CMD completo, PID, usuário, PID pai, e open files/sockets.

# Cores para saída no terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/monitora-processos-detalhado.log"

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# --- Coleta de dados ---

# Coleta de informações básicas do processo (PID, PPID, USER, %CPU, %MEM, CMD completo)
get_basic_process_info() {
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu --no-headers 2>/dev/null | tail -n +2 || \
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu 2>/dev/null | tail -n +2 # Fallback for BusyBox ps
}

# Coleta de I/O (requer sudo para iotop, ou usa ps como fallback)
get_io_info() {
    if command -v iotop &>/dev/null; then
        # iotop -b (batch), -P (show PIDs), -n 1 (one iteration), -o (only processes with I/O)
        sudo iotop -b -P -n 1 2>/dev/null | awk 'NR > 1 && $1 ~ /^[0-9]+$/ {
            pid=$1; read=$4; write=$6;
            gsub(/K|M|G/, "", read); gsub(/K|M|G/, "", write);
            if (read ~ /^[0-9.]+$/) { read_val = read; } else { read_val = 0; }
            if (write ~ /^[0-9.]+$/) { write_val = write; } else { write_val = 0; }

            if (index($4, "K")) read_val = read_val / 1024; else if (index($4, "G")) read_val = read_val * 1024;
            if (index($6, "K")) write_val = write_val / 1024; else if (index($6, "G")) write_val = write_val * 1024;

            total_io = read_val + write_val;
            print pid ":" total_io # PID:IO_MB
        }'
    else
        log_message "WARNING" "iotop não encontrado ou sem permissão. Usando 'ps' para I/O (menos preciso)."
        ps -eo pid,io --no-headers 2>/dev/null | tail -n +2 || \
        ps -eo pid,io 2>/dev/null | tail -n +2 # Fallback for BusyBox ps
    fi
}

# Coleta de arquivos e sockets abertos (requer sudo para lsof)
get_open_files_sockets() {
    local pid="$1"
    # lsof -i (internet files) -a (AND) -p <pid>
    # lsof -F n (file name) -p <pid>
    local open_files_count=$(sudo lsof -p "$pid" -F n 2>/dev/null | grep -c '^n')
    local open_sockets_count=$(sudo lsof -a -i -p "$pid" -F n 2>/dev/null | grep -c '^n')
    echo "$open_files_count:$open_sockets_count" # FILES:SOCKETS
}

# --- Lógica principal ---

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}         Coleta de Dados Detalhados de Processos      ${NC}"
echo -e "${CYAN}====================================================${NC}"
log_message "INFO" "Iniciando coleta de dados detalhados de processos."

# Coleta de dados básicos
process_data=$(get_basic_process_info)

# Coleta de dados de I/O
io_data=$(get_io_info)

declare -A io_map
while IFS=':' read pid io_val;
do
    io_map["$pid"]="$io_val"
done <<< "$io_data"

# Processa e exibe os dados
while IFS= read -r line;
do
    if [[ -z "$line" ]]; then
        continue
    fi

    # Extrai campos do ps
    pid=$(echo "$line" | awk '{print $1}')
    ppid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $3}')
    cpu=$(echo "$line" | awk '{print $4}')
    mem=$(echo "$line" | awk '{print $5}')
    cmd=$(echo "$line" | awk '{$1=$2=$3=$4=$5=""; print $0}' | xargs)

    io_val="${io_map["$pid"]:-0}"

    # Coleta arquivos e sockets abertos
    files_sockets=$(get_open_files_sockets "$pid")
    open_files=$(echo "$files_sockets" | cut -d':' -f1)
    open_sockets=$(echo "$files_sockets" | cut -d':' -f2)

    # Formata a saída
    echo -e "${BLUE}PID:${NC} $pid | ${BLUE}PPID:${NC} $ppid | ${BLUE}USER:${NC} $user"
    echo -e "  ${BLUE}%CPU:${NC} $cpu% | ${BLUE}%MEM:${NC} $mem% | ${BLUE}I/O (MB):${NC} $io_val"
    echo -e "  ${BLUE}CMD:${NC} $cmd"
    echo -e "  ${BLUE}Open Files:${NC} $open_files | ${BLUE}Open Sockets:${NC} $open_sockets"
    echo "----------------------------------------------------"

    log_message "DEBUG" "PID: $pid, PPID: $ppid, USER: $user, CPU: $cpu, MEM: $mem, I/O: $io_val, FILES: $open_files, SOCKETS: $open_sockets, CMD: $cmd"

done <<< "$process_data"

log_message "INFO" "Coleta de dados detalhados de processos concluída."

exit 0
