#!/usr/bin/env bash

# monitora-rede.sh: Script para monitorar o tráfego de rede e conexões ativas.
# Coleta informações de IPs de origem/destino, portas, e processos associados.

# Cores para saída no terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/monitora-rede.log"

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# --- Coleta de dados --- 

# Coleta de conexões de rede ativas e portas em escuta
get_network_connections() {
    log_message "INFO" "Coletando conexões de rede e portas em escuta..."
    if command -v ss &>/dev/null; then
        # ss -tunap (tcp, udp, numerico, all, processes)
        sudo ss -tunap 2>/dev/null
    elif command -v netstat &>/dev/null; then
        log_message "WARNING" "ss não encontrado. Usando 'netstat' (pode ser mais lento/menos detalhado)."
        sudo netstat -tunap 2>/dev/null
    else
        log_message "ERROR" "Nenhum comando 'ss' ou 'netstat' encontrado para monitorar a rede."
        echo -e "${RED}✗ Erro: Nenhum comando 'ss' ou 'netstat' encontrado. Instale 'iproute2' ou 'net-tools'.${NC}"
        return 1
    fi
    return 0
}

# --- Lógica principal --- 

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}         Coleta de Dados de Tráfego de Rede          ${NC}"
echo -e "${CYAN}====================================================${NC}
"
log_message "INFO" "Iniciando coleta de dados de tráfego de rede."

network_data=$(get_network_connections)

if [ $? -ne 0 ]; then
    log_message "ERROR" "Falha na coleta de dados de rede. Abortando."
    exit 1
fi

if [ -z "$network_data" ]; then
    echo -e "${GREEN}✓ Nenhuma conexão de rede ativa ou porta em escuta detectada.${NC}"
    log_message "INFO" "Nenhuma conexão de rede ativa ou porta em escuta detectada."
    exit 0
fi

# Exibe os dados coletados (pode ser expandido para parsear e formatar melhor)
echo -e "${BLUE}Conexões de Rede Ativas e Portas em Escuta:${NC}"
echo "$network_data" | while IFS= read -r line; do
    # Filtrar linhas de cabeçalho e vazias para não logar ruído
    if [[ -z "$line" || "$line" =~ ^(Netid|State|tcp|udp) ]]; then
        continue
    fi
    echo "  $line"
    log_message "DEBUG" "Rede: $line"
done

log_message "INFO" "Coleta de dados de tráfego de rede concluída."

exit 0
