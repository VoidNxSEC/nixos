#!/usr/bin/env bash
# ============================================================================
# API Server para Monitoramento
# Expõe métricas do servidor via HTTP JSON para consumo do app React
# ============================================================================

set -euo pipefail

PORT=${1:-8080}
LOG_FILE="/var/log/nixos-cache-api.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Função para coletar métricas do sistema
collect_metrics() {
    cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": {
    "hostname": "$(hostname)",
    "uptime_seconds": $(cat /proc/uptime | awk '{print int($1)}'),
    "load_average": {
      "1min": $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs),
      "5min": $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | xargs),
      "15min": $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | xargs)
    }
  },
  "cpu": {
    "count": $(nproc),
    "usage_percent": $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
  },
  "memory": {
    "total_gb": $(free -g | grep Mem | awk '{print $2}'),
    "used_gb": $(free -g | grep Mem | awk '{print $3}'),
    "available_gb": $(free -g | grep Mem | awk '{print $7}'),
    "used_percent": $(free | grep Mem | awk '{printf "%.1f", $3/$2*100}')
  },
  "disk": {
    "root": {
      "total": "$(df -h / | tail -1 | awk '{print $2}')",
      "used": "$(df -h / | tail -1 | awk '{print $3}')",
      "available": "$(df -h / | tail -1 | awk '{print $4}')",
      "used_percent": "$(df -h / | tail -1 | awk '{print $5}')"
    },
    "nix_store": {
      "size": "$(du -sh /nix/store 2>/dev/null | awk '{print $1}')",
      "path_count": $(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l)
    }
  },
  "network": {
    "connections": {
      "established": $(ss -tan | grep ESTAB | wc -l),
      "time_wait": $(ss -tan | grep TIME-WAIT | wc -l),
      "listen": $(ss -tln | grep LISTEN | wc -l)
    },
    "interfaces": [
      $(ip -j addr show | jq -c '.[] | select(.operstate == "UP") | {name: .ifname, ip: .addr_info[0].local}' | paste -sd,)
    ]
  },
  "services": {
    "nix_serve": {
      "active": $(systemctl is-active nix-serve 2>/dev/null || echo "inactive"),
      "memory_mb": $(systemctl show nix-serve -p MemoryCurrent 2>/dev/null | cut -d= -f2 | awk '{printf "%.0f", $1/1024/1024}')
    },
    "nginx": {
      "active": $(systemctl is-active nginx 2>/dev/null || echo "inactive"),
      "memory_mb": $(systemctl show nginx -p MemoryCurrent 2>/dev/null | cut -d= -f2 | awk '{printf "%.0f", $1/1024/1024}')
    },
    "prometheus": {
      "active": $(systemctl is-active prometheus 2>/dev/null || echo "inactive")
    }
  },
  "cache": {
    "recent_builds": [
      $(journalctl -u nix-daemon --since "10 minutes ago" --no-pager -o json | grep -i "building\|built" | tail -5 | jq -c '{time: .["__REALTIME_TIMESTAMP"], message: .MESSAGE}' | paste -sd, 2>/dev/null || echo "")
    ]
  }
}
EOF
}

# Função para health check
health_check() {
    local status="healthy"
    local issues=[]
    
    # Check disk space
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 85 ]; then
        status="warning"
        issues+=("Disk usage above 85%")
    fi
    
    # Check services
    if ! systemctl is-active nix-serve &>/dev/null; then
        status="unhealthy"
        issues+=("nix-serve not running")
    fi
    
    if ! systemctl is-active nginx &>/dev/null; then
        status="unhealthy"
        issues+=("nginx not running")
    fi
    
    cat <<EOF
{
  "status": "$status",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "checks": {
    "disk_space": $([ "$disk_usage" -lt 85 ] && echo "true" || echo "false"),
    "nix_serve": $(systemctl is-active nix-serve &>/dev/null && echo "true" || echo "false"),
    "nginx": $(systemctl is-active nginx &>/dev/null && echo "true" || echo "false")
  }
}
EOF
}

# HTTP handler simples
handle_request() {
    local method=$1
    local path=$2
    
    case "$path" in
        "/api/metrics")
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Access-Control-Allow-Origin: *"
            echo ""
            collect_metrics
            ;;
        "/api/health")
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Access-Control-Allow-Origin: *"
            echo ""
            health_check
            ;;
        "/api/logs")
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Access-Control-Allow-Origin: *"
            echo ""
            echo '{"logs": ['
            journalctl -u nix-daemon --since "1 hour ago" --no-pager -o json -n 50 | \
                jq -c '{time: .["__REALTIME_TIMESTAMP"], priority: .PRIORITY, message: .MESSAGE}' | \
                paste -sd,
            echo ']}'
            ;;
        *)
            echo "HTTP/1.1 404 Not Found"
            echo "Content-Type: application/json"
            echo ""
            echo '{"error": "Endpoint not found"}'
            ;;
    esac
}

# Server loop
log "Starting NixOS Cache API Server on port $PORT"

while true; do
    # Listen usando nc (netcat)
    {
        read -r request_line
        method=$(echo "$request_line" | awk '{print $1}')
        path=$(echo "$request_line" | awk '{print $2}')
        
        # Skip headers
        while read -r line; do
            [ -z "$line" ] || [ "$line" = $'\r' ] && break
        done
        
        log "Request: $method $path"
        handle_request "$method" "$path"
    } | nc -l -p "$PORT" -q 1
done
