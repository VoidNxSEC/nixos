#!/usr/bin/env bash

# pre_processa_dados_llm.sh: Módulo de pré-processamento para formatar dados de monitoramento
# em um input JSON estruturado para o LLM (llamacpp).

# Cores para saída no terminal (apenas para debug ou mensagens do script)
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/pre_processa_dados_llm.log"

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# Função auxiliar para escapar strings para JSON
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\"/g; s/\n/\\n/g; s/\t/\\t/g'
}

# --- Coleta e Processamento de Processos ---
# Retorna um array JSON de objetos de processo
get_processed_processes() {
    log_message "INFO" "Iniciando coleta e processamento de dados de processos."
    local raw_process_output=$("/etc/nixos/scripts/monitora-processos-detalhado.sh" 2>&1)
    local process_json_entries=()

    # Usa grep para encontrar blocos que começam com "PID: " e awk para agrupar as linhas
    # e um loop para parsear cada bloco
    echo "$raw_process_output" | awk '/^PID:/{if(x)print x;x=""}{x=(x?x"\n":"") $0}END{print x}' | while IFS= read -r block; do
        if [[ -z "$block" ]]; then
            continue
        fi
        
        local pid="N/A"
        local ppid="N/A"
        local user="N/A"
        local cpu_percent="0.0"
        local mem_percent="0.0"
        local io_mb="0"
        local open_files="0"
        local open_sockets="0"
        local cmd="N/A"

        # Extrai campos do bloco usando grep/awk, tratando o cmd como a última linha
        pid=$(echo "$block" | grep "PID:" | awk '{print $2}' || echo "N/A")
        ppid=$(echo "$block" | grep "PPID:" | awk '{print $4}' || echo "N/A")
        user=$(echo "$block" | grep "USER:" | awk '{print $6}' || echo "N/A")
        cpu_percent=$(echo "$block" | grep "%CPU:" | awk '{print $2}' | sed 's/%//' || echo "0.0")
        mem_percent=$(echo "$block" | grep "%MEM:" | awk '{print $4}' | sed 's/%//' || echo "0.0")
        io_mb=$(echo "$block" | grep "I/O (MB):" | awk '{print $4}' || echo "0")
        open_files=$(echo "$block" | grep "Open Files:" | awk '{print $3}' || echo "0")
        open_sockets=$(echo "$block" | grep "Open Sockets:" | awk '{print $5}' || echo "0")
        cmd=$(echo "$block" | grep "CMD:" | cut -d':' -f2- | xargs || echo "N/A") # Pega o resto da linha como comando

        if [[ "$pid" == "N/A" ]]; then
            log_message "DEBUG" "Bloco de processo ignorado: não foi possível extrair PID válido. Conteúdo: $block"
            continue
        fi

        local process_entry="{"
        process_entry+="\"pid\": \"$(json_escape "$pid")\","
        process_entry+="\"ppid\": \"$(json_escape "$ppid")\","
        process_entry+="\"user\": \"$(json_escape "$user")\","
        process_entry+="\"cpu_percent\": $(json_escape "$cpu_percent"),"
        process_entry+="\"mem_percent\": $(json_escape "$mem_percent"),"
        process_entry+="\"io_mb\": $(json_escape "$io_mb"),"
        process_entry+="\"open_files\": $(json_escape "$open_files"),"
        process_entry+="\"open_sockets\": $(json_escape "$open_sockets"),"
        process_entry+="\"command\": \"$(json_escape "$cmd")\""
        process_entry+="}"
        process_json_entries+=("$process_entry")
    done

    if [ ${#process_json_entries[@]} -eq 0 ]; then
        echo "[]"
    else
        printf "[%s]" "$(IFS=,; echo "${process_json_entries[*]}")"
    fi
    log_message "INFO" "Processamento de dados de processos concluído."
}

# --- Coleta e Processamento de Rede ---
# Retorna um array JSON de objetos de conexão de rede
get_processed_network() {
    log_message "INFO" "Iniciando coleta e processamento de dados de rede."
    local raw_network_data=$("/etc/nixos/scripts/monitora-rede.sh" 2>&1)
    local network_json_entries=()

    # Filtra as linhas de conexão (tcp ou udp) e processa
    echo "$raw_network_data" | grep -E '^(tcp|udp)' | while IFS= read -r line; do
        local proto="N/A"; local state="N/A";
        local local_addr="N/A"; local remote_addr="N/A";
        local program="N/A"; local pid="N/A";

        # Tenta parsear a saída do ss -tunap (preferencial)
        if [[ "$line" =~ ^(tcp|udp)[[:space:]]+([^[:space:]]+)[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+users:\(\(([[:alnum:]_.-]+),pid=([0-9]+),fd=[0-9]+;?)+\)
) ]]; then
            proto=${BASH_REMATCH[1]}
            state=${BASH_REMATCH[2]}
            local_addr=${BASH_REMATCH[3]}
            remote_addr=${BASH_REMATCH[4]}
            program=${BASH_REMATCH[5]}
            pid=${BASH_REMATCH[6]}
        # Tenta parsear a saída do netstat -tunap (fallback)
        elif [[ "$line" =~ ^(tcp|udp)[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([0-9]+)\/([^[:space:]]+) ]]; then
            proto=${BASH_REMATCH[1]}
            local_addr=${BASH_REMATCH[2]}
            remote_addr=${BASH_REMATCH[3]}
            state=${BASH_REMATCH[4]}
            pid=${BASH_REMATCH[5]}
            program=${BASH_REMATCH[6]}
        fi
        
        if [[ "$proto" == "N/A" ]]; then
            log_message "DEBUG" "Linha de rede ignorada (parse inválido): $line"
            continue
        fi

        local connection_entry="{"
        connection_entry+="\"protocol\": \"$(json_escape "$proto")\","
        connection_entry+="\"local_address\": \"$(json_escape "$local_addr")\","
        connection_entry+="\"remote_address\": \"$(json_escape "$remote_addr")\","
        connection_entry+="\"state\": \"$(json_escape "$state")\","
        connection_entry+="\"program\": \"$(json_escape "$program")\","
        connection_entry+="\"pid\": \"$(json_escape "$pid")\""
        connection_entry+="}"
        network_json_entries+=("$connection_entry")
    done

    if [ ${#network_json_entries[@]} -eq 0 ]; then
        echo "[]"
    else
        printf "[%s]" "$(IFS=,; echo "${network_json_entries[*]}")"
    fi
    log_message "INFO" "Processamento de dados de rede concluído."
}

# --- Coleta e Processamento de Logs de Segurança ---
# Retorna um array JSON de objetos de log (já são JSON do journalctl)
get_processed_security_logs() {
    log_message "INFO" "Iniciando coleta e processamento de logs de segurança."
    local raw_log_data=$("/etc/nixos/scripts/monitora-logs-seguranca.sh" 2>&1)
    local log_json_lines=()

    # journalctl -o json produz uma linha JSON por log. Coletamos cada uma.
    while IFS= read -r line; do
        # Apenas verificamos se a linha não está vazia e é um JSON válido. Assume que journalctl já escapou o conteúdo.
        if [[ -n "$line" ]] && echo "$line" | grep -q '^\s*{\s*.*\s*}\s*$'; then # Basic JSON validation regex
            log_json_lines+=("$line")
        fi
    done <<< "$raw_log_data"

    if [ ${#log_json_lines[@]} -eq 0 ]; then
        echo "[]"
    else
        # Junta as linhas JSON com vírgulas e as envolve em um array JSON.
        printf "[%s]" "$(IFS=,; echo "${log_json_lines[*]}")"
    fi
    log_message "INFO" "Processamento de logs de segurança concluído."
}

# --- Lógica principal --- 

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}         Pré-processamento de Dados para LLM          ${NC}"
echo -e "${CYAN}====================================================${NC}"
"
log_message "INFO" "Iniciando pré-processamento de dados para LLM."

full_json="{"
full_json+="\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\","

# Coleta e processa status do sistema (CPU Temp, Load Avg)
local cpu_temp=$(/etc/nixos/scripts/limpa-processos.sh --cpu-temp-only 2>/dev/null || echo "N/A")
local load_avg=$(uptime | awk -F'load average: ' '{print $2}' | awk '{print $1}' | tr -d ',' || echo "N/A")
full_json+="\"system_status\": {\"cpu_temp\": \"$(json_escape "$cpu_temp")\", \"load_avg\": \"$(json_escape "$load_avg")\"},"

full_json+="\"processes\": $(get_processed_processes),"
full_json+="\"network_connections\": $(get_processed_network),"
full_json+="\"security_logs\": $(get_processed_security_logs)"

full_json+="}"

echo "$full_json"
log_message "INFO" "Pré-processamento de dados para LLM concluído. Saída JSON gerada."

exit 0