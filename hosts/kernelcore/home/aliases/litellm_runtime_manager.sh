#!/bin/bash
# ============================================================
# LiteLLM Runtime Manager
# Dynamic port management, workspace isolation, SSH intercept
# ============================================================

# ============================================================
# 🎯 CONFIGURATION
# ============================================================

LITELLM_CONTAINER="litellm-manager"
LITELLM_IMAGE="voidnxlabs/dhi-llmrouter:1"
LITELLM_NETWORK="llm-control-plane"
WORKSPACE_DIR="${LITELLM_WORKSPACE:-$HOME/litellm-workspace}"
CONFIG_FILE="$WORKSPACE_DIR/config.yaml"
SSH_PORT="${LITELLM_SSH_PORT:-2222}"

# Colors para output bonito
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# 🛠️ UTILITY FUNCTIONS
# ============================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${LITELLM_CONTAINER}$"
}

# ============================================================
# 📦 LIFECYCLE MANAGEMENT
# ============================================================

llm_init() {
    log_info "Initializing LiteLLM workspace..."
    
    # Cria workspace
    mkdir -p "$WORKSPACE_DIR"/{config,logs,cache,models}
    
    # Cria network se não existir
    docker network create "$LITELLM_NETWORK" 2>/dev/null || true
    
    # Cria config inicial se não existir
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
model_list:
  - model_name: gpt-3.5-turbo
    litellm_params:

  - model_name: gpt-4
    litellm_params:

litellm_settings:
  drop_params: true
  set_verbose: true
  success_callback: ["langfuse"]
  
general_settings:
  master_key: sk-litellm-local
  database_url: "sqlite:///workspace/cache/litellm.db"
EOF
        log_success "Config created at: $CONFIG_FILE"
    fi
    
    # Cria Dockerfile com SSH
    cat > "$WORKSPACE_DIR/Dockerfile" <<'EOF'
FROM voidnxlabs/dhi-llmrouter:1

# Instala SSH + tools úteis
RUN apt-get update && apt-get install -y \
    openssh-server \
    vim \
    htop \
    curl \
    jq \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir /var/run/sshd
RUN echo 'root:litellm' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/sshd_config

# SSH login sem PAM
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

EXPOSE 22 4000

# Startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
EOF

    # Entrypoint script
    cat > "$WORKSPACE_DIR/entrypoint.sh" <<'EOF'
#!/bin/bash
set -e

# Start SSH
service ssh start

# Start LiteLLM
exec litellm --config /workspace/config/config.yaml --port 4000
EOF

    log_success "Workspace initialized at: $WORKSPACE_DIR"
    log_info "Next: run 'llm-build' to build custom image"
}

llm_build() {
    log_info "Building custom LiteLLM image..."
    
    if [ ! -f "$WORKSPACE_DIR/Dockerfile" ]; then
        log_error "Dockerfile not found. Run 'llm-init' first"
        return 1
    fi
    
    docker build -t litellm-ssh "$WORKSPACE_DIR"
    log_success "Image built: litellm-ssh"
}

llm_start() {
    if check_container_running; then
        log_warn "Container already running"
        return 0
    fi
    
    log_info "Starting LiteLLM with runtime management..."
    
    docker run -d \
        --name "$LITELLM_CONTAINER" \
        --network "$LITELLM_NETWORK" \
        --gpus all \
        -p 4000:4000 \
        -p "$SSH_PORT:22" \
        -v "$WORKSPACE_DIR/config:$WORKSPACE_DIR/config" \
        -v "$WORKSPACE_DIR/logs:/app/logs" \
        -v "$WORKSPACE_DIR/cache:/workspace/cache" \
        -v "$WORKSPACE_DIR/models:/models" \
        -e WORKSPACE=/workspace \
        -e LITELLM_LOG=DEBUG \
        --restart unless-stopped \
        litellm-ssh
    
    sleep 3
    
    if check_container_running; then
        log_success "LiteLLM started!"
        log_info "API: http://localhost:4000"
        log_info "SSH: ssh root@localhost -p $SSH_PORT (password: litellm)"
        llm_status
    else
        log_error "Failed to start. Check logs with 'llm-logs'"
    fi
}

llm_stop() {
    log_info "Stopping LiteLLM..."
    docker stop "$LITELLM_CONTAINER" 2>/dev/null || log_warn "Container not running"
    docker rm "$LITELLM_CONTAINER" 2>/dev/null
    log_success "Stopped"
}

llm_restart() {
    llm_stop
    sleep 2
    llm_start
}

llm_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  LiteLLM Runtime Manager - Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if check_container_running; then
        log_success "Container: RUNNING"
        
        # Info do container
        local ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$LITELLM_CONTAINER")
        local uptime=$(docker inspect -f '{{.State.StartedAt}}' "$LITELLM_CONTAINER")
        
        echo "  IP Address: $ip"
        echo "  Started: $uptime"
        echo ""
        
        # Portas expostas
        echo "  Exposed Ports:"
        docker port "$LITELLM_CONTAINER" | sed 's/^/    /'
        echo ""
        
        # Health check
        echo "  Health Check:"
        if curl -sf http://localhost:4000/health > /dev/null 2>&1; then
            log_success "  API responding"
        else
            log_error "  API not responding"
        fi
        
        if nc -z localhost "$SSH_PORT" 2>/dev/null; then
            log_success "  SSH accessible"
        else
            log_warn "  SSH not accessible"
        fi
        
        # Resource usage
        echo ""
        echo "  Resource Usage:"
        docker stats "$LITELLM_CONTAINER" --no-stream --format "    CPU: {{.CPUPerc}}  |  Memory: {{.MemUsage}}"
    else
        log_error "Container: NOT RUNNING"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ============================================================
# 🔌 RUNTIME PORT MANAGEMENT
# ============================================================

llm_port_add() {
    if [ -z "$1" ]; then
        log_error "Usage: llm-port-add <host_port:container_port>"
        return 1
    fi
    
    local mapping="$1"
    log_info "Adding port mapping: $mapping"
    
    # Para adicionar porta em runtime, precisamos usar socat ou nginx
    # Vamos criar um proxy container
    local proxy_name="litellm-proxy-${mapping%:*}"
    
    docker run -d \
        --name "$proxy_name" \
        --network "$LITELLM_NETWORK" \
        -p "$mapping" \
        alpine/socat \
        tcp-listen:${mapping#*:},fork,reuseaddr tcp-connect:$LITELLM_CONTAINER:${mapping#*:}
    
    log_success "Port proxy created: $proxy_name"
}

llm_port_remove() {
    if [ -z "$1" ]; then
        log_error "Usage: llm-port-remove <host_port>"
        return 1
    fi
    
    local port="$1"
    local proxy_name="litellm-proxy-$port"
    
    docker stop "$proxy_name" 2>/dev/null && docker rm "$proxy_name" 2>/dev/null
    log_success "Port proxy removed: $port"
}

llm_port_list() {
    log_info "Active port mappings:"
    docker port "$LITELLM_CONTAINER" 2>/dev/null || log_warn "Container not running"
    
    echo ""
    log_info "Port proxies:"
    docker ps --filter "name=litellm-proxy-" --format "  {{.Names}}: {{.Ports}}"
}

# ============================================================
# 🔧 RUNTIME INTERACTION
# ============================================================

llm_ssh() {
    log_info "Connecting via SSH..."
    ssh -o StrictHostKeyChecking=no root@localhost -p "$SSH_PORT"
}

llm_shell() {
    log_info "Entering container shell..."
    docker exec -it "$LITELLM_CONTAINER" bash
}

llm_exec() {
    if [ -z "$1" ]; then
        log_error "Usage: llm-exec <command>"
        return 1
    fi
    
    docker exec "$LITELLM_CONTAINER" "$@"
}

llm_logs() {
    local lines="${1:-100}"
    docker logs -f --tail "$lines" "$LITELLM_CONTAINER"
}

llm_top() {
    docker exec "$LITELLM_CONTAINER" htop
}

# ============================================================
# 🔄 CONFIG HOT-RELOAD
# ============================================================

llm_config_edit() {
    ${EDITOR:-vim} "$CONFIG_FILE"
}

llm_config_reload() {
    log_info "Reloading config (hot-reload)..."
    
    # Envia SIGHUP pro processo litellm (se suportar)
    # Ou restart graceful
    docker exec "$LITELLM_CONTAINER" pkill -HUP -f litellm || {
        log_warn "Hot-reload não suportado, fazendo restart..."
        llm_restart
    }
    
    log_success "Config reloaded"
}

llm_config_validate() {
    log_info "Validating config..."
    docker exec "$LITELLM_CONTAINER" litellm --config /workspace/config/config.yaml --test
}

# ============================================================
# 📊 MONITORING & DEBUG
# ============================================================

llm_health() {
    log_info "Running health check..."
    
    # API health
    echo -n "API: "
    curl -sf http://localhost:4000/health | jq -r '.status' || echo "FAILED"
    
    # Models available
    echo "Models:"
    curl -sf http://localhost:4000/v1/models | jq -r '.data[].id' | sed 's/^/  - /'
    
    # SSH connectivity
    echo -n "SSH: "
    nc -z localhost "$SSH_PORT" && echo "OK" || echo "FAILED"
}

llm_test_api() {
    log_info "Testing API with sample request..."
    
    curl -X POST http://localhost:4000/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-litellm-local" \
        -d '{
          "model": "gpt-3.5-turbo",
          "messages": [{"role": "user", "content": "Say hello"}],
          "max_tokens": 50
        }' | jq
}

llm_metrics() {
    log_info "Fetching metrics..."
    
    # CPU/Memory
    echo "Resources:"
    docker stats "$LITELLM_CONTAINER" --no-stream
    
    echo ""
    echo "Disk usage:"
    docker exec "$LITELLM_CONTAINER" du -sh /workspace/* /app/logs 2>/dev/null
    
    echo ""
    echo "Network connections:"
    docker exec "$LITELLM_CONTAINER" netstat -tuln | grep LISTEN
}

llm_debug() {
    log_info "Entering debug mode..."
    
    echo "Available debug commands:"
    echo "  ps aux              - Running processes"
    echo "  tail -f /app/logs/* - Live logs"
    echo "  curl localhost:4000/health - Health check"
    echo "  env                 - Environment vars"
    echo "  exit                - Exit debug"
    echo ""
    
    docker exec -it "$LITELLM_CONTAINER" bash
}

# ============================================================
# 🌐 NETWORK MANAGEMENT
# ============================================================

llm_network_inspect() {
    log_info "Network inspection..."
    docker network inspect "$LITELLM_NETWORK" | jq '.[0].Containers'
}

#    
#        
#        docker run -d \
#            --network "$LITELLM_NETWORK" \
#            --gpus all \
#        
#    fi
#    
#    # Conecta à mesma network
#    
#    # Test connection
#    log_info "Testing connection..."
#}

# ============================================================
# 📚 HELP & DOCUMENTATION
# ============================================================

llm_help() {
    cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎛️  LiteLLM Runtime Manager - Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 LIFECYCLE
  llm-init              Initialize workspace & configs
  llm-build             Build custom Docker image with SSH
  llm-start             Start LiteLLM container
  llm-stop              Stop container
  llm-restart           Restart container
  llm-status            Show detailed status

🔌 PORT MANAGEMENT
  llm-port-add <mapping>    Add port (e.g., 8080:4000)
  llm-port-remove <port>    Remove port proxy
  llm-port-list             List all port mappings

🔧 RUNTIME INTERACTION
  llm-ssh               SSH into container
  llm-shell             Docker exec bash
  llm-exec <cmd>        Execute command in container
  llm-logs [lines]      Follow logs (default: 100)
  llm-top               Show htop in container

🔄 CONFIG MANAGEMENT
  llm-config-edit       Edit config in $EDITOR
  llm-config-reload     Hot-reload config
  llm-config-validate   Validate config syntax

📊 MONITORING & DEBUG
  llm-health            Run health checks
  llm-test-api          Test API with sample request
  llm-metrics           Show resource metrics
  llm-debug             Enter debug mode

🌐 NETWORK
  llm-network-inspect   Inspect network topology

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 QUICK START:
  1. llm-init              # Setup workspace
  2. llm-build             # Build custom image
  3. llm-start             # Start container
  5. llm-test-api          # Test everything

🔐 SSH ACCESS:
  ssh root@localhost -p 2222
  Password: litellm

📂 WORKSPACE:
  $WORKSPACE_DIR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ============================================================
# EXPORT FUNCTIONS (para source no shell)
# ============================================================

alias llm-init='llm_init'
alias llm-build='llm_build'
alias llm-start='llm_start'
alias llm-stop='llm_stop'
alias llm-restart='llm_restart'
alias llm-status='llm_status'
alias llm-port-add='llm_port_add'
alias llm-port-remove='llm_port_remove'
alias llm-port-list='llm_port_list'
alias llm-ssh='llm_ssh'
alias llm-shell='llm_shell'
alias llm-exec='llm_exec'
alias llm-logs='llm_logs'
alias llm-top='llm_top'
alias llm-config-edit='llm_config_edit'
alias llm-config-reload='llm_config_reload'
alias llm-config-validate='llm_config_validate'
alias llm-health='llm_health'
alias llm-test-api='llm_test_api'
alias llm-metrics='llm_metrics'
alias llm-debug='llm_debug'
alias llm-network-inspect='llm_network_inspect'
alias llm-help='llm_help'

# Se rodado diretamente (não source)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Verifica se tem subcomando
    if [ $# -eq 0 ]; then
        llm_help
        exit 0
    fi
    
    # Executa subcomando
    cmd="llm_${1//-/_}"
    shift
    
    if type "$cmd" &>/dev/null; then
        "$cmd" "$@"
    else
        log_error "Unknown command: $1"
        llm_help
        exit 1
    fi
fi

#echo "✓ LiteLLM Runtime Manager loaded! Type 'llm-help' for commands"
