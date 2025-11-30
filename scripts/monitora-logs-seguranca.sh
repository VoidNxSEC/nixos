#!/usr/bin/env bash

# monitora-logs-seguranca.sh: Script para integrar e filtrar logs do sistema para eventos de segurança relevantes.
# Foca em tentativas de login falhas, uso de sudo, alterações de firewall, etc.

# Cores para saída no terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/monitora-logs-seguranca.log"

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# Variável para armazenar o último timestamp de leitura de logs
LAST_READ_TIMESTAMP_FILE="/tmp/monitora-logs-seguranca.last_timestamp"

# Função para obter logs do journalctl desde o último timestamp
get_security_logs() {
    log_message "INFO" "Coletando logs de segurança desde o último timestamp..."
    local last_timestamp=""
    if [ -f "$LAST_READ_TIMESTAMP_FILE" ]; then
        last_timestamp=$(cat "$LAST_READ_TIMESTAMP_FILE")
    fi

    local journal_command="sudo journalctl -q -f -o json --since \"$last_timestamp\""
    if [ -z "$last_timestamp" ]; then
        journal_command="sudo journalctl -q -f -o json --since \"1 hour ago\"" # Pega a última hora se não houver timestamp
    fi

    # Filtra por unidades de interesse e termos de segurança
    # Exemplos: ssh, sudo, systemd-logind, audit, firewall, auth, network
    # Termos: failed, denied, error, dropped, accepted, connection
    $journal_command | grep -E '(\"_SYSTEMD_UNIT\"\s*:\s*\"(ssh|sudo|systemd-logind|auditd|ufw|firewalld|NetworkManager)\"|\"(MESSAGE)\"\s*:\s*\".*(failed|denied|error|dropped|accepted|connection|authentication).*\" )'

    # Atualiza o timestamp para a próxima execução
    date -u +%Y-%m-%dT%H:%M:%S.000000Z > "$LAST_READ_TIMESTAMP_FILE"
}

# --- Lógica principal --- 

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}         Coleta e Filtragem de Logs de Segurança      ${NC}"
echo -e "${CYAN}====================================================${NC}"
log_message "INFO" "Iniciando coleta e filtragem de logs de segurança."

# A saída do journalctl -f é contínua. Para esta etapa de coleta, rodaremos uma vez.
# Em um monitoramento contínuo, isso seria um loop.
security_logs=$(get_security_logs)

if [ -z "$security_logs" ]; then
    echo -e "${GREEN}✓ Nenhum evento de segurança relevante encontrado nos logs recentes.${NC}"
    log_message "INFO" "Nenhum evento de segurança relevante encontrado nos logs recentes."
    exit 0
fi

echo -e "${BLUE}Eventos de Segurança nos Logs:${NC}"
echo "$security_logs" | while IFS= read -r line; do
    # Aqui você pode parsear o JSON para formatar melhor a saída se necessário
    echo "  $line"
    log_message "DEBUG" "Log Segurança: $line"
done

log_message "INFO" "Coleta e filtragem de logs de segurança concluída."

exit 0
