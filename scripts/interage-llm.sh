#!/usr/bin/env bash

# interage-llm.sh: Script para enviar prompts com dados pré-processados para a API HTTP do llamacpp.
# Recebe um JSON com dados de monitoramento e anomalias, constrói um prompt e envia para o LLM.

# Cores para saída no terminal (apenas para debug ou mensagens do script)
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/interage-llm.log"
LLM_API_URL="http://127.0.0.1:8080/completion"

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# Função auxiliar para escapar strings para JSON (se necessário para o prompt)
json_escape_prompt() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\"/g; s/\n/\\n/g; s/\t/\\t/g'
}

# --- Lógica principal ---

if [ -z "$1" ]; then
    log_message "ERROR" "Nenhum input JSON de dados pré-processados fornecido para interage-llm.sh."
    echo -e "${RED}✗ Erro: Nenhum input JSON fornecido. Use: $0 \"<JSON_DATA>\"${NC}"
    exit 1
fi

raw_input_json_data="$1"

log_message "INFO" "Iniciando interação com o LLM em $LLM_API_URL."

# Construção do Prompt para o LLM
# O prompt é vital. Ele deve guiar o LLM a analisar os dados de segurança.
# qwen coder 14b é um modelo de código, então talvez seja melhor pedir uma análise em formato de código ou lista.
LLM_PROMPT="""
Você é um analista de segurança de sistema de um laptop. Sua tarefa é analisar os seguintes dados de monitoramento do sistema em formato JSON. 
Identifique quaisquer anomalias, ameaças de segurança, ou comportamentos suspeitos. 
Forneça uma análise concisa e, se possível, sugira ações ou recomendações para mitigar as ameaças. 
Responda em formato JSON, com as seguintes chaves: 'analysis_summary' (string), 'threats_identified' (array de strings), 'recommendations' (array de strings).

Dados de Monitoramento: 
${raw_input_json_data}
"""

# Parâmetros para a API do llamacpp
# Estes parâmetros podem precisar de ajuste dependendo do modelo e da sua API específica.
# Assumindo um formato de requisição similar ao OpenAI Chat Completions ou Llama.cpp /completion
REQUEST_BODY=$(cat <<EOF
{
  "prompt": "$(json_escape_prompt "$LLM_PROMPT")",
  "n_predict": 1024, 
  "temperature": 0.1,
  "stop": ["\nUser:", "\nSystem:", "\n### Human:", "\n### Assistant:"]
}
EOF
)

log_message "DEBUG" "Corpo da Requisição LLM: $REQUEST_BODY"

# Envia a requisição HTTP POST para o servidor llamacpp
LLM_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  --data "$REQUEST_BODY" \
  "$LLM_API_URL" 2>&1)

if [ $? -ne 0 ]; then
    log_message "ERROR" "Falha ao conectar ou receber resposta do LLM em $LLM_API_URL. Erro: $LLM_RESPONSE"
    echo -e "${RED}✗ Erro ao interagir com a API do LLM. Verifique o servidor llamacpp e a URL: $LLM_API_URL.${NC}"
    exit 1
fi

# Verifica se a resposta contém erro JSON (ex: 'error' key)
if echo "$LLM_RESPONSE" | jq -e '.error' &>/dev/null; then
    local error_message=$(echo "$LLM_RESPONSE" | jq -r '.error' || echo "Erro desconhecido da API do LLM")
    log_message "ERROR" "API do LLM retornou um erro: $error_message. Resposta completa: $LLM_RESPONSE"
    echo -e "${RED}✗ Erro da API do LLM: $error_message${NC}"
    exit 1
fi

log_message "INFO" "Resposta do LLM recebida com sucesso."

# A API /completion do llamacpp geralmente retorna um JSON com uma chave 'content' ou 'text'
# Vamos tentar extrair o 'content' ou 'text', e depois parsear o JSON dentro dele.
# Ajuste isso se o formato da sua API for diferente.
LLM_OUTPUT_RAW=$(echo "$LLM_RESPONSE" | jq -r '.content' || echo "$LLM_RESPONSE" | jq -r '.text' || echo "N/A")

if [[ "$LLM_OUTPUT_RAW" == "N/A" ]]; then
    log_message "ERROR" "Não foi possível extrair o conteúdo da resposta do LLM. Resposta bruta: $LLM_RESPONSE"
    echo -e "${RED}✗ Erro: Não foi possível extrair conteúdo da resposta do LLM. Formato inesperado.${NC}"
    exit 1
fi

# Agora, esperamos que LLM_OUTPUT_RAW contenha o JSON gerado pelo Qwen Coder.
# Precisamos garantir que seja JSON válido antes de passar adiante.
if echo "$LLM_OUTPUT_RAW" | jq -e . &>/dev/null; then
    echo "$LLM_OUTPUT_RAW"
    log_message "INFO" "Resposta do LLM validada como JSON e retornada."
else
    log_message "ERROR" "Resposta do LLM não é um JSON válido. Conteúdo: $LLM_OUTPUT_RAW"
    echo -e "${RED}✗ Erro: Resposta do LLM não é um JSON válido. Conteúdo bruto: $LLM_OUTPUT_RAW${NC}"
    # Retornamos o bruto para análise posterior, mas sinalizamos o erro.
    echo "{\"error\": \"LLM response not valid JSON\", \"raw_output\": \"$(json_escape "$LLM_OUTPUT_RAW")\"}"
    exit 1
fi

exit 0
