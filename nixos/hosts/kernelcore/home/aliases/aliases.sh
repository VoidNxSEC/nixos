#!/usr/bin/env bash
# =============================================================================
# Docker Stack Orchestrator - Shell Aliases
# =============================================================================
# Para usar:
#   source ~/Documents/nx/docker/aliases.sh
# ou adicione no seu ~/.bashrc ou ~/.zshrc:
#   source ~/Documents/nx/docker/aliases.sh
# =============================================================================

DOCKER_ORCH_PATH="$HOME/Documents/nx/docker/main.py"

# =============================================================================
# ALIASES PRINCIPAIS
# =============================================================================

# Stacks completos
alias dstack='python3 "$DOCKER_ORCH_PATH"'
alias dstack-list='python3 "$DOCKER_ORCH_PATH" list'

# Multimodal AI Stack
alias ai-up='python3 "$DOCKER_ORCH_PATH" up multimodal'
alias ai-down='python3 "$DOCKER_ORCH_PATH" down multimodal'
alias ai-status='python3 "$DOCKER_ORCH_PATH" status multimodal'
alias ai-logs='python3 "$DOCKER_ORCH_PATH" logs multimodal -f'
alias ai-health='python3 "$DOCKER_ORCH_PATH" health multimodal'
alias ai-restart='python3 "$DOCKER_ORCH_PATH" restart multimodal'

# GPU + Database Stack
alias gpu-up='python3 "$DOCKER_ORCH_PATH" up gpu'
alias gpu-down='python3 "$DOCKER_ORCH_PATH" down gpu'
alias gpu-status='python3 "$DOCKER_ORCH_PATH" status gpu'
alias gpu-logs='python3 "$DOCKER_ORCH_PATH" logs gpu -f'
alias gpu-health='python3 "$DOCKER_ORCH_PATH" health gpu'
alias gpu-restart='python3 "$DOCKER_ORCH_PATH" restart gpu'

# Todos os stacks
alias all-up='python3 "$DOCKER_ORCH_PATH" up-all'
alias all-down='python3 "$DOCKER_ORCH_PATH" down-all'
alias all-status='python3 "$DOCKER_ORCH_PATH" status'
alias all-health='python3 "$DOCKER_ORCH_PATH" health'

# =============================================================================
# FUNÇÕES HELPERS
# =============================================================================

# Logs de serviço específico
dlogs() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Uso: dlogs <stack> <service>"
        echo "Exemplos:"
        echo "  dlogs gpu api"
        return 1
    fi
    python3 "$DOCKER_ORCH_PATH" logs "$1" "$2" -f
}

# Restart de serviço específico
drestart() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Uso: drestart <stack> <service>"
        echo "Exemplos:"
        echo "  drestart gpu api"
        echo "  drestart multimodal nginx"
        return 1
    fi
    python3 "$DOCKER_ORCH_PATH" restart "$1" "$2"
}

# Quick status de todos os containers Docker
dps() {
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
}

# =============================================================================
# ALIASES ESPECÍFICOS POR SERVIÇO
# =============================================================================

# API
alias api-logs='dlogs gpu api'
alias api-restart='drestart gpu api'

# Jupyter
alias jupyter-logs-gpu='dlogs gpu jupyter'
alias jupyter-logs-ai='dlogs multimodal jupyter'

# Nginx
alias nginx-logs-gpu='dlogs gpu nginx'
alias nginx-logs-ai='dlogs multimodal nginx'

# Database
alias db-logs='dlogs gpu db'
alias db-restart='drestart gpu db'


# vLLM
alias vllm-logs='dlogs multimodal vllm'
alias vllm-restart='drestart multimodal vllm'

# Whisper
alias whisper-logs='dlogs multimodal whisper-api'
alias whisper-restart='drestart multimodal whisper-api'

# =============================================================================
# TESTES E HEALTH CHECKS
# =============================================================================

# Testa API GPU
test-gpu-api() {
    echo "🧪 Testando GPU API..."
    echo ""
    echo "Health check direto (porta 8000):"
    curl -s http://localhost:8000/health | jq . 2>/dev/null || curl -s http://localhost:8000/health
    echo ""
    echo "Health check via nginx (porta 80):"
    curl -s http://localhost/api/health | jq . 2>/dev/null || curl -s http://localhost/api/health
}

# Testa todos os endpoints
test-all() {
    echo "🧪 Testando todos os endpoints..."
    echo ""

    echo "1. Nginx (porta 80):"
    curl -s http://localhost/ | head -3
    echo ""

    echo "2. GPU API (porta 8000):"
    curl -s http://localhost:8000/health 2>/dev/null || echo "✗ Não acessível"
    echo ""

    echo "3. Jupyter GPU (porta 8888):"
    curl -s -I http://localhost:8888 2>/dev/null | head -1 || echo "✗ Não acessível"
    echo ""

    #curl -s http://localhost:11434/api/tags 2>/dev/null | head -3 || echo "✗ Não acessível"
}

# =============================================================================
# HELP
# =============================================================================

dhelp() {
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────────────────┐
│                 Docker Stack Orchestrator - Aliases                     │
└─────────────────────────────────────────────────────────────────────────┘

📚 GERENCIAMENTO DE STACKS:
  dstack          - Orquestrador principal (python3 main.py)
  dstack-list     - Lista todos os stacks disponíveis

🤖 MULTIMODAL AI STACK:
  ai-up           - Sobe stack multimodal
  ai-down         - Para stack multimodal
  ai-status       - Status do stack
  ai-logs         - Logs (follow)
  ai-health       - Health check
  ai-restart      - Reinicia stack

🚀 GPU + DATABASE STACK:
  gpu-up          - Sobe stack GPU
  gpu-down        - Para stack GPU
  gpu-status      - Status do stack
  gpu-logs        - Logs (follow)
  gpu-health      - Health check
  gpu-restart     - Reinicia stack

🌐 TODOS OS STACKS:
  all-up          - Sobe TUDO
  all-down        - Para TUDO
  all-status      - Status de tudo
  all-health      - Health check de tudo

🔧 SERVIÇOS ESPECÍFICOS:
  dlogs <stack> <service>     - Logs de um serviço
  drestart <stack> <service>  - Restart de um serviço

  api-logs        - Logs da API
  db-logs         - Logs do MariaDB
  nginx-logs-gpu  - Logs nginx (gpu stack)


🧪 TESTES:
  test-gpu-api    - Testa endpoints da GPU API
  test-all        - Testa todos os endpoints
  dps             - Status rápido dos containers

📖 EXEMPLOS:
  ai-up                    # Sobe stack AI
  dlogs gpu api            # Logs da API
  drestart multimodal nginx # Reinicia nginx

EOF
}

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

echo "✓ Docker Stack Orchestrator aliases carregados!"
echo "  Digite 'dhelp' para ver todos os comandos disponíveis"

# Export das funções
export -f dlogs
export -f drestart
export -f dps
export -f test-gpu-api
export -f test-all
export -f dhelp
