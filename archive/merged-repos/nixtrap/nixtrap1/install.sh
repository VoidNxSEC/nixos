#!/usr/bin/env bash
# ============================================================================
# NixOS Cache Server - Instalação Completa Automatizada
# Execute este script para setup end-to-end
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

banner() {
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC}%-59s${CYAN}║${NC}\n" "  $*"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
}

show_menu() {
    clear
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║       NixOS Cache Server - Instalação Automatizada           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Escolha uma opção:

  1) 🚀 Bootstrap Completo (Live ISO)
     └─ Gerar configuração, chaves e certificados

  2) 💾 Instalar NixOS
     └─ Particionar, formatar e instalar sistema

  3) 🔌 Configurar API Server
     └─ Setup do servidor de métricas

  4) 🎨 Deploy Dashboard React
     └─ Build e deploy do dashboard web

  5) 👥 Gerar Config de Cliente
     └─ Configuração para conectar clientes

  6) 📊 Verificar Status
     └─ Health check do sistema

  7) 📚 Ver Documentação
     └─ Abrir README e cheatsheet

  0) ❌ Sair

EOF
    read -p "Opção: " choice
    echo
    case $choice in
        1) option_bootstrap ;;
        2) option_install_nixos ;;
        3) option_setup_api ;;
        4) option_deploy_dashboard ;;
        5) option_client_config ;;
        6) option_check_status ;;
        7) option_docs ;;
        0) exit 0 ;;
        *) warn "Opção inválida"; sleep 2; show_menu ;;
    esac
}

option_bootstrap() {
    banner "Bootstrap do Servidor"
    
    if [ "$EUID" -ne 0 ]; then
        error "Execute como root: sudo $0"
    fi
    
    info "Executando bootstrap..."
    "$PROJECT_ROOT/bootstrap/nixos-cache-bootstrap.sh"
    
    log "Bootstrap concluído!"
    info "Próximo passo: Opção 2 - Instalar NixOS"
    read -p "Pressione ENTER para continuar..."
    show_menu
}

option_install_nixos() {
    banner "Instalação do NixOS"
    
    warn "⚠️  Esta opção irá PARTICIONAR e FORMATAR o disco!"
    read -p "Digite 'SIM' para confirmar: " confirm
    
    if [ "$confirm" != "SIM" ]; then
        warn "Instalação cancelada"
        sleep 2
        show_menu
        return
    fi
    
    # Detectar disco
    info "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo
    read -p "Disco para instalação (ex: sda): " DISK
    DISK="/dev/$DISK"
    
    if [ ! -b "$DISK" ]; then
        error "Disco $DISK não encontrado"
    fi
    
    warn "⚠️  ÚLTIMO AVISO: Todos os dados em $DISK serão PERDIDOS!"
    read -p "Digite 'CONFIRMO' para continuar: " final_confirm
    
    if [ "$final_confirm" != "CONFIRMO" ]; then
        warn "Instalação cancelada"
        sleep 2
        show_menu
        return
    fi
    
    info "Particionando $DISK..."
    parted "$DISK" -- mklabel gpt
    parted "$DISK" -- mkpart primary 512MB -8GB
    parted "$DISK" -- mkpart primary linux-swap -8GB 100%
    parted "$DISK" -- mkpart ESP fat32 1MB 512MB
    parted "$DISK" -- set 3 esp on
    
    info "Formatando partições..."
    mkfs.ext4 -L nixos "${DISK}1"
    mkswap -L swap "${DISK}2"
    mkfs.fat -F 32 -n boot "${DISK}3"
    
    info "Montando partições..."
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    swapon "${DISK}2"
    
    info "Gerando configuração base..."
    nixos-generate-config --root /mnt
    
    info "Copiando configuração do cache server..."
    cp /etc/nixos/cache-server.nix /mnt/etc/nixos/
    cp -r /etc/nixos/cache-keys /mnt/etc/nixos/
    cp -r /etc/nixos/certs /mnt/etc/nixos/
    cp -r /etc/nixos/scripts /mnt/etc/nixos/
    
    info "Criando configuração mínima..."
    cat >> /mnt/etc/nixos/configuration.nix << 'NIXCFG'

  # Importar configuração do cache server
  imports = [ ./cache-server.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "nixos-cache";
  networking.networkmanager.enable = true;

  # User
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
NIXCFG
    
    info "Instalando NixOS..."
    nixos-install
    
    log "Instalação concluída!"
    warn "Defina a senha de root:"
    nixos-enter --root /mnt -c 'passwd'
    
    info "Sistema pronto para reiniciar!"
    read -p "Reiniciar agora? (s/N): " reboot_choice
    
    if [[ "$reboot_choice" =~ ^[Ss]$ ]]; then
        reboot
    else
        info "Não se esqueça de reiniciar antes de continuar"
        read -p "Pressione ENTER para voltar..."
        show_menu
    fi
}

option_setup_api() {
    banner "Configurar API Server"
    
    if [ "$EUID" -ne 0 ]; then
        error "Execute como root: sudo $0"
    fi
    
    info "Copiando arquivos da API..."
    cp "$PROJECT_ROOT/api-server/cache-api-server.sh" /etc/nixos/scripts/
    chmod +x /etc/nixos/scripts/cache-api-server.sh
    
    cp "$PROJECT_ROOT/api-server/cache-api-server.service" /etc/systemd/system/
    
    info "Habilitando serviço..."
    systemctl daemon-reload
    systemctl enable cache-api-server
    systemctl start cache-api-server
    
    sleep 2
    
    if systemctl is-active cache-api-server &>/dev/null; then
        log "API Server está rodando!"
        info "Testando endpoint..."
        if curl -sf http://localhost:8080/api/health &>/dev/null; then
            log "API respondendo corretamente!"
        else
            warn "API não está respondendo"
        fi
    else
        error "Falha ao iniciar API Server"
    fi
    
    read -p "Pressione ENTER para continuar..."
    show_menu
}

option_deploy_dashboard() {
    banner "Deploy Dashboard React"
    
    cd "$PROJECT_ROOT/dashboard"
    
    if ! command -v npm &>/dev/null; then
        warn "npm não encontrado. Instalando Node.js..."
        nix-env -iA nixpkgs.nodejs
    fi
    
    info "Instalando dependências..."
    npm install
    
    echo
    echo "Escolha o modo de deploy:"
    echo "  1) Desenvolvimento (npm run dev)"
    echo "  2) Produção (npm run build)"
    read -p "Opção: " deploy_mode
    
    case $deploy_mode in
        1)
            info "Iniciando servidor de desenvolvimento..."
            info "Dashboard: http://localhost:3000"
            warn "Pressione Ctrl+C para parar"
            npm run dev
            ;;
        2)
            info "Building para produção..."
            npm run build
            
            log "Build concluído!"
            info "Arquivos em: dist/"
            echo
            echo "Para deploy no servidor:"
            echo "  scp -r dist/* admin@servidor:/var/www/dashboard/"
            ;;
        *)
            warn "Opção inválida"
            ;;
    esac
    
    read -p "Pressione ENTER para continuar..."
    show_menu
}

option_client_config() {
    banner "Configuração de Cliente"
    
    if [ ! -f /etc/nixos/cache-keys/cache-pub-key.pem ]; then
        error "Chave pública não encontrada. Execute o bootstrap primeiro."
    fi
    
    PUBLIC_KEY=$(cat /etc/nixos/cache-keys/cache-pub-key.pem)
    SERVER_IP=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1)
    
    cat > /tmp/client-config.nix << CLIENTCFG
# ============================================================================
# Configuração de Cliente para NixOS Cache Server
# Cole no configuration.nix do cliente
# ============================================================================

{ config, pkgs, ... }:

{
  nix.settings = {
    substituters = [
      "https://${SERVER_IP}"
      "https://cache.nixos.org"
    ];
    
    trusted-public-keys = [
      "${PUBLIC_KEY}"
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Para aceitar certificado auto-assinado (dev/staging):
  # security.pki.certificateFiles = [ /caminho/para/server.crt ];
}
CLIENTCFG
    
    log "Configuração de cliente gerada!"
    cat /tmp/client-config.nix
    echo
    info "Arquivo salvo em: /tmp/client-config.nix"
    info "IP do servidor: $SERVER_IP"
    info "Chave pública: $PUBLIC_KEY"
    
    read -p "Pressione ENTER para continuar..."
    show_menu
}

option_check_status() {
    banner "Status do Sistema"
    
    info "Verificando serviços..."
    echo
    
    # nix-serve
    if systemctl is-active nix-serve &>/dev/null; then
        log "nix-serve: ATIVO"
    else
        error "nix-serve: INATIVO"
    fi
    
    # nginx
    if systemctl is-active nginx &>/dev/null; then
        log "nginx: ATIVO"
    else
        error "nginx: INATIVO"
    fi
    
    # prometheus
    if systemctl is-active prometheus &>/dev/null; then
        log "prometheus: ATIVO"
    else
        warn "prometheus: INATIVO"
    fi
    
    # API server
    if systemctl is-active cache-api-server &>/dev/null; then
        log "cache-api-server: ATIVO"
    else
        warn "cache-api-server: INATIVO"
    fi
    
    echo
    info "Testando endpoints..."
    echo
    
    # Cache
    if curl -sf http://localhost:5000/nix-cache-info &>/dev/null; then
        log "Cache HTTP: OK"
    else
        error "Cache HTTP: FALHA"
    fi
    
    # Nginx
    if curl -sfk https://localhost/nix-cache-info &>/dev/null; then
        log "Nginx HTTPS: OK"
    else
        error "Nginx HTTPS: FALHA"
    fi
    
    # API
    if curl -sf http://localhost:8080/api/health &>/dev/null; then
        log "API Health: OK"
    else
        error "API Health: FALHA"
    fi
    
    echo
    info "Recursos do sistema:"
    echo
    
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "  CPU: ${CPU_USAGE}%"
    
    # RAM
    RAM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2*100}')
    echo "  RAM: ${RAM_USAGE}%"
    
    # Disk
    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
    echo "  Disco: ${DISK_USAGE}"
    
    # Nix Store
    STORE_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
    echo "  Nix Store: ${STORE_SIZE}"
    
    read -p "Pressione ENTER para continuar..."
    show_menu
}

option_docs() {
    banner "Documentação"
    
    echo "Documentação disponível:"
    echo
    echo "  1) README principal"
    echo "  2) README completo"
    echo "  3) Cheatsheet de comandos"
    echo "  0) Voltar"
    echo
    read -p "Escolha: " doc_choice
    
    case $doc_choice in
        1) less "$PROJECT_ROOT/README.md" ;;
        2) less "$PROJECT_ROOT/docs/README-COMPLETO.md" ;;
        3) less "$PROJECT_ROOT/docs/CHEATSHEET.sh" ;;
        0) show_menu ;;
        *) warn "Opção inválida"; sleep 1 ;;
    esac
    
    show_menu
}

# Verificar se está no diretório correto
if [ ! -d "$PROJECT_ROOT/bootstrap" ] || [ ! -d "$PROJECT_ROOT/dashboard" ]; then
    error "Execute este script do diretório do projeto"
fi

# Iniciar menu
show_menu
