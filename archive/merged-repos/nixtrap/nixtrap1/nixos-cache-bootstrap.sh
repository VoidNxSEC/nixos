#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# NixOS Cache Server Bootstrap
# Orchestração completa: diagnóstico, configuração, TLS, monitoramento
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/nixos-bootstrap-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

banner() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $* ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# ============================================================================
# Fase 1: Diagnóstico do Sistema
# ============================================================================
phase_diagnostic() {
    banner "FASE 1: Diagnóstico do Sistema"
    
    log "Detectando hardware disponível..."
    
    # CPU Info
    CPU_COUNT=$(nproc)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    
    # Memory Info
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    
    # Disk Info
    DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
    DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
    
    # Network Info
    PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    
    info "CPU: $CPU_MODEL ($CPU_COUNT cores)"
    info "RAM: ${TOTAL_RAM_GB}GB"
    info "Disco: $DISK_AVAIL disponível de $DISK_TOTAL"
    info "Interface primária: $PRIMARY_IFACE"
    
    # Recomendações baseadas em hardware
    if [ "$TOTAL_RAM_GB" -lt 4 ]; then
        warn "RAM < 4GB - Builds limitados, considere upgrade"
        MAX_JOBS=1
        CORES=1
    elif [ "$TOTAL_RAM_GB" -lt 8 ]; then
        info "RAM adequada para builds moderados"
        MAX_JOBS=2
        CORES=1
    else
        log "RAM excelente para cache server"
        MAX_JOBS=4
        CORES=2
    fi
    
    export CPU_COUNT TOTAL_RAM_GB MAX_JOBS CORES PRIMARY_IFACE
}

# ============================================================================
# Fase 2: Geração de Chaves e Certificados
# ============================================================================
phase_crypto() {
    banner "FASE 2: Criptografia - Chaves e Certificados"
    
    KEYS_DIR="/etc/nixos/cache-keys"
    CERTS_DIR="/etc/nixos/certs"
    
    log "Criando diretórios para chaves..."
    mkdir -p "$KEYS_DIR" "$CERTS_DIR"
    chmod 700 "$KEYS_DIR" "$CERTS_DIR"
    
    # Gerar chave de assinatura do cache (se não existir)
    if [ ! -f "$KEYS_DIR/cache-priv-key.pem" ]; then
        log "Gerando par de chaves para assinatura do cache..."
        nix-store --generate-binary-cache-key cache-key \
            "$KEYS_DIR/cache-priv-key.pem" \
            "$KEYS_DIR/cache-pub-key.pem"
        
        chmod 600 "$KEYS_DIR/cache-priv-key.pem"
        chmod 644 "$KEYS_DIR/cache-pub-key.pem"
        
        log "Chaves geradas com sucesso!"
        info "Chave pública: $(cat "$KEYS_DIR/cache-pub-key.pem")"
    else
        info "Chaves já existem, pulando geração"
    fi
    
    # Gerar certificado TLS auto-assinado (para dev/staging)
    if [ ! -f "$CERTS_DIR/server.crt" ]; then
        log "Gerando certificado TLS auto-assinado..."
        
        HOSTNAME=$(hostname)
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$CERTS_DIR/server.key" \
            -out "$CERTS_DIR/server.crt" \
            -subj "/C=BR/ST=Bahia/L=Feira de Santana/O=NixCache/CN=$HOSTNAME" \
            -addext "subjectAltName=DNS:$HOSTNAME,DNS:localhost,IP:127.0.0.1"
        
        chmod 600 "$CERTS_DIR/server.key"
        chmod 644 "$CERTS_DIR/server.crt"
        
        log "Certificado TLS gerado!"
        info "Válido por 365 dias"
        warn "⚠️  Certificado auto-assinado - apenas para dev/staging"
        info "Para produção, use Let's Encrypt ou CA corporativa"
    else
        info "Certificado TLS já existe"
    fi
    
    export KEYS_DIR CERTS_DIR
}

# ============================================================================
# Fase 3: Geração da Configuração NixOS
# ============================================================================
phase_config() {
    banner "FASE 3: Geração da Configuração NixOS"
    
    CONFIG_FILE="/etc/nixos/cache-server.nix"
    
    log "Gerando configuração otimizada para o hardware..."
    
    cat > "$CONFIG_FILE" << EOF
# ============================================================================
# NixOS Cache Server Configuration
# Gerado automaticamente em $(date)
# Hardware: ${CPU_COUNT} cores, ${TOTAL_RAM_GB}GB RAM
# ============================================================================

{ config, pkgs, ... }:

{
  # ========================================
  # Serviço de Cache (nix-serve)
  # ========================================
  services.nix-serve = {
    enable = true;
    secretKeyFile = "${KEYS_DIR}/cache-priv-key.pem";
    port = 5000;  # Porta interna (nginx fará proxy)
    bindAddress = "127.0.0.1";  # Apenas local, nginx expõe via TLS
  };

  # ========================================
  # Reverse Proxy com TLS (nginx)
  # ========================================
  services.nginx = {
    enable = true;
    
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    
    # Configuração de cache do nginx (para melhor performance)
    appendHttpConfig = ''
      proxy_cache_path /var/cache/nginx/nix-cache 
        levels=1:2 
        keys_zone=nix_cache:10m 
        max_size=1g 
        inactive=24h 
        use_temp_path=off;
    '';
    
    virtualHosts."cache.local" = {
      forceSSL = true;
      sslCertificate = "${CERTS_DIR}/server.crt";
      sslCertificateKey = "${CERTS_DIR}/server.key";
      
      # TLS moderno e seguro
      sslProtocols = "TLSv1.2 TLSv1.3";
      sslCiphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256";
      sslPreferServerCiphers = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:5000";
        
        extraConfig = ''
          # Cache de respostas do nix-serve
          proxy_cache nix_cache;
          proxy_cache_valid 200 24h;
          proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
          proxy_cache_lock on;
          
          # Headers otimizados
          proxy_set_header Host \$host;
          proxy_set_header X-Real-IP \$remote_addr;
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto \$scheme;
          
          # Timeouts aumentados para builds grandes
          proxy_read_timeout 600s;
          proxy_connect_timeout 600s;
          proxy_send_timeout 600s;
        '';
      };
      
      # Endpoint de health check
      locations."/health" = {
        return = "200 'OK'";
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
      
      # Métricas básicas (nginx stub_status)
      locations."/nginx-metrics" = {
        extraConfig = ''
          stub_status on;
          access_log off;
          allow 127.0.0.1;
          deny all;
        '';
      };
    };
  };

  # ========================================
  # Configurações do Nix
  # ========================================
  nix.settings = {
    # Paralelismo otimizado para hardware
    max-jobs = ${MAX_JOBS};  # Baseado em RAM disponível
    cores = ${CORES};         # Cores por job
    
    # Storage management
    max-free = \${toString (25 * 1024 * 1024 * 1024)};  # 25GB
    min-free = \${toString (10 * 1024 * 1024 * 1024)};  # 10GB
    
    # Performance
    auto-optimise-store = true;
    http-connections = 50;
    
    # Build cache
    keep-outputs = true;
    keep-derivations = true;
  };

  # Garbage collection automático
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # ========================================
  # Hardening do Sistema
  # ========================================
  systemd.services.nix-serve = {
    serviceConfig = {
      # Isolamento de filesystem
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/nix/store" ];
      
      # Isolamento de rede
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      
      # Restrições de privilégios
      NoNewPrivileges = true;
      PrivateDevices = true;
      
      # Limites de recursos
      MemoryMax = "${TOTAL_RAM_GB}G";
      TasksMax = 100;
    };
  };

  # ========================================
  # Firewall
  # ========================================
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 443 ];  # HTTPS apenas
    
    # Regras extras para logging
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 443 -j LOG --log-prefix "CACHE-HTTPS: " --log-level 4
    '';
  };

  # ========================================
  # Monitoramento
  # ========================================
  services.prometheus = {
    enable = true;
    port = 9090;
    
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ 
          "systemd" 
          "processes"
          "filesystem"
          "netdev"
          "meminfo"
          "loadavg"
        ];
        port = 9100;
      };
      
      nginx = {
        enable = true;
        scrapeUri = "http://127.0.0.1/nginx-metrics";
        port = 9113;
      };
    };
    
    scrapeConfigs = [
      {
        job_name = "cache-server";
        static_configs = [{
          targets = [ 
            "localhost:9100"  # Node exporter
            "localhost:9113"  # Nginx exporter
          ];
        }];
        scrape_interval = "15s";
      }
    ];
  };

  # ========================================
  # Logging
  # ========================================
  services.journald.extraConfig = ''
    Storage=persistent
    MaxRetentionSec=2week
    MaxFileSec=1day
    SystemMaxUse=1G
  '';

  # ========================================
  # Backup Automático da Configuração
  # ========================================
  systemd.timers.config-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.config-backup = {
    script = ''
      cd /etc/nixos
      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git commit -m "Auto backup \$(date +%Y-%m-%d)" || true
    '';
    serviceConfig.Type = "oneshot";
  };

  # ========================================
  # Pacotes do Sistema
  # ========================================
  environment.systemPackages = with pkgs; [
    # Ferramentas de rede
    curl
    wget
    nmap
    iperf3
    
    # Monitoramento
    htop
    iotop
    nload
    
    # Debug
    tcpdump
    strace
    
    # Utilitários
    git
    vim
    tmux
    jq
  ];
  
  # ========================================
  # Performance do Sistema
  # ========================================
  boot.kernel.sysctl = {
    # Network tuning
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 67108864";
    "net.ipv4.tcp_wmem" = "4096 65536 67108864";
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # File descriptors
    "fs.file-max" = 2097152;
  };
}
EOF

    log "Configuração gerada: $CONFIG_FILE"
    info "Revise e ajuste conforme necessário antes de aplicar"
}

# ============================================================================
# Fase 4: Scripts Auxiliares
# ============================================================================
phase_scripts() {
    banner "FASE 4: Scripts de Monitoramento e Manutenção"
    
    SCRIPTS_DIR="/etc/nixos/scripts"
    mkdir -p "$SCRIPTS_DIR"
    
    # Script de monitoramento em tempo real
    cat > "$SCRIPTS_DIR/monitor.sh" << 'EOF'
#!/usr/bin/env bash
# Monitor de performance do cache server

INTERVAL=${1:-5}

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  NixOS Cache Server - Monitor em Tempo Real              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo
    
    # CPU e Load
    echo "=== CPU & Load ==="
    uptime | awk '{print "Load Average: " $(NF-2) " " $(NF-1) " " $NF}'
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% usado"
    echo
    
    # Memória
    echo "=== Memória ==="
    free -h | grep Mem | awk '{printf "RAM: %s / %s (%s usado)\n", $3, $2, $3/$2*100"%"}'
    echo
    
    # Disco
    echo "=== Disco ==="
    df -h / | tail -1 | awk '{printf "Root: %s / %s (%s usado)\n", $3, $2, $5}'
    du -sh /nix/store 2>/dev/null | awk '{printf "Nix Store: %s\n", $1}'
    echo
    
    # Rede
    echo "=== Rede ==="
    ss -s | grep TCP | head -1
    echo
    
    # Serviços
    echo "=== Serviços ==="
    systemctl is-active nix-serve && echo "✓ nix-serve: ATIVO" || echo "✗ nix-serve: INATIVO"
    systemctl is-active nginx && echo "✓ nginx: ATIVO" || echo "✗ nginx: INATIVO"
    systemctl is-active prometheus && echo "✓ prometheus: ATIVO" || echo "✗ prometheus: INATIVO"
    echo
    
    # Últimos builds
    echo "=== Últimos Builds ==="
    journalctl -u nix-daemon --since "5 minutes ago" --no-pager -n 3 | grep -i "building\|built" | tail -3
    
    echo
    echo "Atualizando em ${INTERVAL}s... (Ctrl+C para sair)"
    sleep "$INTERVAL"
done
EOF
    chmod +x "$SCRIPTS_DIR/monitor.sh"
    
    # Script de health check
    cat > "$SCRIPTS_DIR/health-check.sh" << 'EOF'
#!/usr/bin/env bash
# Health check do cache server

set -euo pipefail

checks_passed=0
checks_failed=0

check() {
    local name=$1
    local command=$2
    
    if eval "$command" &>/dev/null; then
        echo "✓ $name"
        ((checks_passed++))
        return 0
    else
        echo "✗ $name"
        ((checks_failed++))
        return 1
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  NixOS Cache Server - Health Check                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Checks de serviços
check "nix-serve rodando" "systemctl is-active nix-serve"
check "nginx rodando" "systemctl is-active nginx"
check "prometheus rodando" "systemctl is-active prometheus"

# Checks de conectividade
check "nix-serve responde (HTTP)" "curl -sf http://localhost:5000/nix-cache-info"
check "nginx responde (HTTPS)" "curl -sfk https://localhost/health"

# Checks de recursos
check "Disco com espaço" "[ \$(df / | tail -1 | awk '{print \$5}' | sed 's/%//') -lt 90 ]"
check "RAM disponível" "[ \$(free | grep Mem | awk '{print \$3/\$2*100}' | cut -d. -f1) -lt 95 ]"

echo
echo "═══════════════════════════════════════════════════════════"
echo "Resultado: $checks_passed passed, $checks_failed failed"
echo "═══════════════════════════════════════════════════════════"

[ $checks_failed -eq 0 ]
EOF
    chmod +x "$SCRIPTS_DIR/health-check.sh"
    
    # Script de backup das chaves
    cat > "$SCRIPTS_DIR/backup-keys.sh" << 'EOF'
#!/usr/bin/env bash
# Backup das chaves criptográficas

BACKUP_DIR="${HOME}/cache-keys-backup-$(date +%Y%m%d)"
KEYS_DIR="/etc/nixos/cache-keys"
CERTS_DIR="/etc/nixos/certs"

mkdir -p "$BACKUP_DIR"

echo "Copiando chaves para $BACKUP_DIR..."
cp -r "$KEYS_DIR" "$BACKUP_DIR/"
cp -r "$CERTS_DIR" "$BACKUP_DIR/"

tar czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "✓ Backup criado: ${BACKUP_DIR}.tar.gz"
echo "⚠️  Guarde este arquivo em local seguro!"
echo "⚠️  Contém chaves privadas sensíveis!"
EOF
    chmod +x "$SCRIPTS_DIR/backup-keys.sh"
    
    log "Scripts criados em $SCRIPTS_DIR/"
}

# ============================================================================
# Fase 5: Cliente de Teste
# ============================================================================
phase_client_config() {
    banner "FASE 5: Configuração de Cliente"
    
    CLIENT_CONFIG="/etc/nixos/client-config-example.nix"
    SERVER_IP=$(ip -4 addr show "$PRIMARY_IFACE" | grep inet | awk '{print $2}' | cut -d/ -f1)
    PUBLIC_KEY=$(cat "${KEYS_DIR}/cache-pub-key.pem")
    
    cat > "$CLIENT_CONFIG" << EOF
# ============================================================================
# Configuração de Cliente para Cache Server
# Cole este conteúdo no configuration.nix do cliente
# ============================================================================

{ config, pkgs, ... }:

{
  nix.settings = {
    # Substituters (ordem de prioridade)
    substituters = [
      "https://${SERVER_IP}"          # Cache local (TLS)
      "https://cache.nixos.org"       # Cache oficial (fallback)
    ];
    
    # Chaves públicas confiáveis
    trusted-public-keys = [
      "${PUBLIC_KEY}"
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    
    # Trust self-signed cert (apenas para dev/staging!)
    # Em produção, adicione o cert à trusted CA store
    extra-substituters = [];
  };
}

# ============================================================================
# IMPORTANTE: Trust do Certificado Auto-assinado
# ============================================================================
# 
# Como o certificado é auto-assinado, o cliente precisa confiar nele.
# Opções:
#
# 1. Para desenvolvimento/staging (menos seguro):
#    \$ sudo nix build --option require-sigs false
#
# 2. Para produção (recomendado):
#    - Use Let's Encrypt (certbot)
#    - Ou adicione o CA cert ao trust store do sistema:
#      \$ sudo cp /caminho/server.crt /etc/ssl/certs/
#      \$ sudo update-ca-certificates
#
# 3. Curl test (ignorando cert - apenas para testar):
#    \$ curl -k https://${SERVER_IP}/nix-cache-info
#
EOF

    log "Configuração de cliente salva: $CLIENT_CONFIG"
    info "Servidor IP: $SERVER_IP"
    info "Chave pública: $PUBLIC_KEY"
}

# ============================================================================
# Fase 6: Documentação e Finalização
# ============================================================================
phase_finalize() {
    banner "FASE 6: Documentação e Próximos Passos"
    
    README="/etc/nixos/README-cache-server.md"
    
    cat > "$README" << EOF
# NixOS Cache Server - Documentação

Servidor de cache gerado automaticamente em $(date)

## 📊 Informações do Sistema

- **CPU**: ${CPU_MODEL} (${CPU_COUNT} cores)
- **RAM**: ${TOTAL_RAM_GB}GB
- **Interface**: ${PRIMARY_IFACE}
- **Configuração**: /etc/nixos/cache-server.nix

## 🚀 Aplicando a Configuração

\`\`\`bash
# 1. Importe a configuração no configuration.nix
# Adicione esta linha:
# imports = [ ./cache-server.nix ];

# 2. Aplique a configuração
sudo nixos-rebuild switch

# 3. Verifique os serviços
systemctl status nix-serve nginx prometheus
\`\`\`

## 🔐 Chaves e Certificados

- **Chaves de assinatura**: ${KEYS_DIR}/
  - \`cache-priv-key.pem\` (privada - **não compartilhe!**)
  - \`cache-pub-key.pem\` (pública - compartilhe com clientes)

- **Certificados TLS**: ${CERTS_DIR}/
  - \`server.crt\` (certificado auto-assinado, válido por 365 dias)
  - \`server.key\` (chave privada)

### ⚠️ Backup das Chaves

\`\`\`bash
/etc/nixos/scripts/backup-keys.sh
# Guarde o arquivo .tar.gz em local seguro!
\`\`\`

## 📈 Monitoramento

### Dashboard Prometheus
- URL: http://localhost:9090
- Métricas do sistema: http://localhost:9100/metrics
- Métricas do nginx: http://localhost:9113/metrics

### Monitor em Tempo Real
\`\`\`bash
/etc/nixos/scripts/monitor.sh
\`\`\`

### Health Check
\`\`\`bash
/etc/nixos/scripts/health-check.sh
\`\`\`

## 🔧 Comandos Úteis

### Verificar Cache
\`\`\`bash
# Local (HTTP)
curl http://localhost:5000/nix-cache-info

# Via nginx (HTTPS)
curl -k https://localhost/nix-cache-info
\`\`\`

### Logs
\`\`\`bash
# nix-serve
journalctl -u nix-serve -f

# nginx
journalctl -u nginx -f

# Todos os builds
journalctl -u nix-daemon -f
\`\`\`

### Garbage Collection
\`\`\`bash
# Manual
sudo nix-collect-garbage -d

# Ver espaço usado
du -sh /nix/store
\`\`\`

### Verificar Store
\`\`\`bash
sudo nix-store --verify --check-contents
\`\`\`

## 👥 Configurando Clientes

Veja \`/etc/nixos/client-config-example.nix\` para configuração de clientes.

**Chave pública para clientes:**
\`\`\`
$(cat "${KEYS_DIR}/cache-pub-key.pem")
\`\`\`

## 🛠️ Próximos Passos

### Curto Prazo
- [ ] Aplicar a configuração com \`nixos-rebuild switch\`
- [ ] Configurar pelo menos um cliente
- [ ] Testar build e cache: \`nix-build '<nixpkgs>' -A hello\`
- [ ] Monitorar uso de recursos por 24h

### Médio Prazo
- [ ] Substituir certificado auto-assinado por Let's Encrypt
- [ ] Configurar alertas (email/slack) para problemas
- [ ] Ajustar GC policy baseado em uso real
- [ ] Documentar runbook operacional

### Longo Prazo
- [ ] Considerar distributed builds se hardware limitado
- [ ] Avaliar multi-tier caching
- [ ] Planejar upgrade de hardware se necessário

## 🎯 Métricas de Sucesso

- ✅ Cache hit latency < 100ms
- ✅ Build time reduction > 20%
- ✅ Service uptime > 99%
- ✅ Disco nunca > 85% cheio
- ✅ Zero OOM kills

## 📚 Referências

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix-serve Documentation](https://github.com/edolstra/nix-serve)
- [Nginx TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)

---

**Logs do Bootstrap**: ${LOG_FILE}
**Gerado por**: nixos-cache-bootstrap.sh
EOF

    log "Documentação criada: $README"
    
    echo
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ✨ BOOTSTRAP COMPLETO!                                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo
    info "📁 Arquivos gerados:"
    info "   - Configuração: /etc/nixos/cache-server.nix"
    info "   - Chaves: ${KEYS_DIR}/"
    info "   - Certificados: ${CERTS_DIR}/"
    info "   - Scripts: /etc/nixos/scripts/"
    info "   - Docs: ${README}"
    echo
    warn "⚠️  PRÓXIMO PASSO IMPORTANTE:"
    echo "   1. Revise a configuração gerada"
    echo "   2. Adicione 'imports = [ ./cache-server.nix ];' ao configuration.nix"
    echo "   3. Execute: sudo nixos-rebuild switch"
    echo
    info "📖 Leia ${README} para instruções completas"
    echo
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║       NixOS Cache Server - Bootstrap Automático           ║"
    echo "║                                                            ║"
    echo "║  Diagnóstico → Chaves → Config → Scripts → Docs           ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo
    
    # Verificar se está rodando como root
    if [ "$EUID" -ne 0 ]; then
        error "Execute como root: sudo $0"
    fi
    
    log "Iniciando bootstrap do cache server..."
    log "Log completo: $LOG_FILE"
    echo
    
    phase_diagnostic
    phase_crypto
    phase_config
    phase_scripts
    phase_client_config
    phase_finalize
    
    log "Bootstrap concluído com sucesso!"
    exit 0
}

# Execute!
main "$@"
