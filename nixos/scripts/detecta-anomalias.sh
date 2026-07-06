#!/usr/bin/env bash

# detecta-anomalias.sh: Script para implementar heurísticas de detecção de anomalias.
# Recebe um JSON com dados de monitoramento e sinaliza potenciais ameaças ou eventos de interesse.

# Cores para saída no terminal (apenas para debug ou mensagens do script)
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/detecta-anomalias.log"

# Limiares de Anomalia (ajustáveis)
CPU_THRESHOLD=80   # % de CPU
MEM_THRESHOLD=80   # % de Memória
IO_THRESHOLD=50    # MB de I/O por processo
OPEN_SOCKETS_THRESHOLD=20 # Número de sockets abertos por processo

# Lista de comandos "seguros" ou comuns (para reduzir ruído e focar em incomuns)
# Isso pode ser expandido significativamente e gerenciado externamente.
SAFE_COMMANDS=("systemd" "kworker" "gnome-shell" "Xorg" "dbus-daemon" "bash" "sh" "python" "zsh" "code" "alacritty" "nix-daemon")

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

# --- Lógica principal ---

if [ -z "$1" ]; then
    log_message "ERROR" "Nenhum input JSON fornecido para o script detecta-anomalias.sh."
    echo -e "${RED}✗ Erro: Nenhum input JSON fornecido. Use: $0 \"<JSON_DATA>\"${NC}"
    exit 1
fi

raw_input_json="$1"

log_message "INFO" "Iniciando detecção de anomalias com input JSON."

# Inicializa a estrutura de anomalias
anomalies_json="{"
anomalies_json+="\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\","
anomalies_json+="\"anomalies_detected\": false,\""
anomalies_json+="\"process_anomalies\": [],\""
anomalies_json+="\"network_anomalies\": [],\""
anomalies_json+="\"log_anomalies\": []"
anomalies_json+=" }"

# Use 'jq' para parsear o JSON. Se jq não estiver disponível, o script falhará aqui.
if ! command -v jq &>/dev/null; then
    log_message "ERROR" "Ferramenta 'jq' não encontrada. Necessária para parsear JSON. Instale-a."
    echo -e "${RED}✗ Erro: Ferramenta 'jq' não encontrada. Por favor, instale-a.${NC}"
    exit 1
fi

# Extrair dados do JSON de input
processes=$(echo "$raw_input_json" | jq -c '.processes[]')
network_connections=$(echo "$raw_input_json" | jq -c '.network_connections[]')
security_logs=$(echo "$raw_input_json" | jq -c '.security_logs[]')

process_anomalies_array=()
network_anomalies_array=()
log_anomalies_array=()

# --- Heurísticas de Processos ---
log_message "INFO" "Analisando processos para anomalias..."
while IFS= read -r p_json; do
    local pid=$(echo "$p_json" | jq -r '.pid')
    local cmd=$(echo "$p_json" | jq -r '.command')
    local cpu=$(echo "$p_json" | jq -r '.cpu_percent' | cut -d '.' -f 1 || echo 0)
    local mem=$(echo "$p_json" | jq -r '.mem_percent' | cut -d '.' -f 1 || echo 0)
    local io_mb=$(echo "$p_json" | jq -r '.io_mb' || echo 0)
    local open_sockets=$(echo "$p_json" | jq -r '.open_sockets' || echo 0)
    local user=$(echo "$p_json" | jq -r '.user')

    # Anomalia: Alto consumo de CPU
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
        process_anomalies_array+=("\"Processo '$cmd' (PID: $pid) com alto uso de CPU: $cpu%\"")
        log_message "WARNING" "Anomalia de Processo: PID $pid ($cmd) - Alto CPU ($cpu%)"
    fi

    # Anomalia: Alto consumo de Memória
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
        process_anomalies_array+=("\"Processo '$cmd' (PID: $pid) com alto uso de Memória: $mem%\"")
        log_message "WARNING" "Anomalia de Processo: PID $pid ($cmd) - Alto MEM ($mem%)"
    fi

    # Anomalia: Alto I/O
    if (( $(echo "$io_mb > $IO_THRESHOLD" | bc -l) )); then
        process_anomalies_array+=("\"Processo '$cmd' (PID: $pid) com alto uso de I/O: ${io_mb}MB\"")
        log_message "WARNING" "Anomalia de Processo: PID $pid ($cmd) - Alto I/O (${io_mb}MB)"
    fi

    # Anomalia: Grande número de sockets abertos
    if (( $(echo "$open_sockets > $OPEN_SOCKETS_THRESHOLD" | bc -l) )); then
        process_anomalies_array+=("\"Processo '$cmd' (PID: $pid) com grande número de sockets abertos: $open_sockets\"")
        log_message "WARNING" "Anomalia de Processo: PID $pid ($cmd) - Muitos Sockets Abertos ($open_sockets)"
    fi

    # Anomalia: Processos executando como root com CMD "desconhecido" ou não esperado
    if [[ "$user" == "root" ]]; then
        local is_safe_cmd=false
        for safe_cmd in "${SAFE_COMMANDS[@]}"; do
            if [[ "$cmd" == "$safe_cmd" ]]; then
                is_safe_cmd=true
                break
            fi
        done
        if [ "$is_safe_cmd" = false ] && ! [[ "$cmd" =~ ^/usr/sbin/|^/usr/bin/|^/bin/|^/sbin/ ]]; then # Not a standard system binary path
            process_anomalies_array+=("\"Processo root '$cmd' (PID: $pid) com comando incomum/não seguro. Pode ser uma ameaça.\"")
            log_message "CRITICAL" "Anomalia de Processo: PID $pid ($cmd) - Processo root suspeito."
        fi
    fi

done <<< "$processes"

# --- Heurísticas de Rede ---
log_message "INFO" "Analisando conexões de rede para anomalias..."
while IFS= read -r n_json; do
    local proto=$(echo "$n_json" | jq -r '.protocol')
    local local_addr=$(echo "$n_json" | jq -r '.local_address')
    local remote_addr=$(echo "$n_json" | jq -r '.remote_address')
    local state=$(echo "$n_json" | jq -r '.state')
    local program=$(echo "$n_json" | jq -r '.program')
    local pid=$(echo "$n_json" | jq -r '.pid')

    # Anomalia: Conexão para porta/IP incomum (exemplo: se o remote_addr não for localhost e a porta for alta e desconhecida)
    # Isso é muito simplificado e precisa de uma base de conhecimento de IPs/Portas confiáveis
    if [[ "$remote_addr" != "127.0.0.1" ]] && [[ "$remote_addr" != "0.0.0.0" ]]; then
        local remote_port=$(echo "$remote_addr" | cut -d':' -f2 || echo "0")
        # Exemplo: portas altas não registradas
        if (( remote_port > 1024 )) && (( remote_port < 32768 )) && ! [[ "$program" =~ ^(ssh|https|http|domain) ]]; then # Simplificado: ignorar portas comuns
            network_anomalies_array+=("\"Conexão de saída suspeita: $program (PID: $pid) para $remote_addr:$remote_port (estado: $state)\"")
            log_message "WARNING" "Anomalia de Rede: PID $pid ($program) - Conexão de saída suspeita para $remote_addr:$remote_port."
        fi
    fi

    # Anomalia: Porta em escuta de processo desconhecido/não esperado
    if [[ "$state" == "LISTEN" ]] && [[ "$local_addr" =~ ":" ]] && [[ "$program" == "-" || "$program" == "N/A" ]]; then
        local listen_port=$(echo "$local_addr" | cut -d':' -f2)
        network_anomalies_array+=("\"Porta em escuta suspeita ($listen_port) sem processo associado ou processo desconhecido (PID: $pid)\"")
        log_message "WARNING" "Anomalia de Rede: Porta em escuta suspeita ($listen_port) com PID $pid."
    fi

done <<< "$network_connections"

# --- Heurísticas de Logs de Segurança ---
log_message "INFO" "Analisando logs de segurança para anomalias..."
while IFS= read -r l_json; do
    local message=$(echo "$l_json" | jq -r '.MESSAGE' || echo "N/A")
    local unit=$(echo "$l_json" | jq -r '._SYSTEMD_UNIT' || echo "N/A")
    local priority=$(echo "$l_json" | jq -r '.PRIORITY' || echo "N/A") # 0-7, 0=emerg, 7=debug

    # Anomalia: Tentativas de login SSH falhas
    if [[ "$unit" =~ "ssh" ]] && [[ "$message" =~ "Failed password" || "$message" =~ "authentication failure" ]]; then
        log_anomalies_array+=("\"Tentativa de login SSH falha detectada. Unidade: $unit, Mensagem: $(json_escape \"$message\")\"")
        log_message "ALERT" "Anomalia de Log: Tentativa de login SSH falha."
    fi

    # Anomalia: Uso de sudo por usuário inesperado ou com erro
    if [[ "$unit" =~ "sudo" ]] && [[ "$message" =~ "authentication failure" || "$message" =~ "TTY=\\(.\*\)" ]]; then
        log_anomalies_array+=("\"Uso de sudo com falha de autenticação ou contexto incomum. Mensagem: $(json_escape \"$message\")\"")
        log_message "ALERT" "Anomalia de Log: Uso de sudo suspeito."
    fi

    # Anomalia: Mensagens de erro/alerta de firewall
    if [[ "$unit" =~ "ufw" || "$unit" =~ "firewalld" ]] && [[ "$message" =~ "DENY" || "$message" =~ "REJECT" || "$message" =~ "error" ]]; then
        log_anomalies_array+=("\"Evento de firewall potencialmente anômalo. Unidade: $unit, Mensagem: $(json_escape \"$message\")\"")
        log_message "ALERT" "Anomalia de Log: Evento de firewall."
    fi

    # Anomalia: Logs com alta prioridade (e.g., crit, alert, emerg)
    if [[ "$priority" =~ ^(0|1|2) ]]; then # EMERG, ALERT, CRIT
        log_anomalies_array+=("\"Log de alta prioridade detectado (PRIORITY: $priority). Unidade: $unit, Mensagem: $(json_escape \"$message\")\"")
        log_message "CRITICAL" "Anomalia de Log: Log de alta prioridade ($priority)."
    fi


done <<< "$(echo "$security_logs" | jq -c '.[]')"

# --- Consolidação do Output JSON ---

# Monta os arrays de anomalias
local final_process_anomalies="$(IFS=,; echo "${process_anomalies_array[*]}")"
local final_network_anomalies="$(IFS=,; echo "${network_anomalies_array[*]}")"
local final_log_anomalies="$(IFS=,; echo "${log_anomalies_array[*]}")"

anomalies_json="{"
anomalies_json+="\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",\""
if [ ${#process_anomalies_array[@]} -gt 0 ] || [ ${#network_anomalies_array[@]} -gt 0 ] || [ ${#log_anomalies_array[@]} -gt 0 ]; then
    anomalies_json+="\"anomalies_detected\": true,\""
else
    anomalies_json+="\"anomalies_detected\": false,\""
fi
anomalies_json+="\"process_anomalies\": [${final_process_anomalies}],\""
anomalies_json+="\"network_anomalies\": [${final_network_anomalies}],\""
anomalies_json+="\"log_anomalies\": [${final_log_anomalies}]\""
anomalies_json+=" }"

echo "$anomalies_json"
log_message "INFO" "Detecção de anomalias concluída. Saída JSON gerada."

exit 0
