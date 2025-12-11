#!/usr/bin/env bash
# ============================================================================
# NIX HARD RESET - Limpeza Agressiva Total do Sistema
# ============================================================================
# Versão: 2.0.0
# Autor: kernelcore
# Data: 2025-12-10
#
# Propósito: Reset COMPLETO do sistema para offload pesado:
#   - Procura e remove arquivos >1GB
#   - Limpeza agressiva do Nix store
#   - Remove todas as gerações antigas
#   - Limpa build caches (cargo, npm, go, etc.)
#   - Reset de profiles e channels
#   - Preparação para offload limpo
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

MIN_FILE_SIZE="1G"  # Buscar arquivos maiores que 1GB
LOG_FILE="/var/log/nix-hard-reset.log"

# ============================================================================
# FUNÇÕES DE LOGGING
# ============================================================================

log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}$*${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

report_space() {
    # Usar df -h para ter output mais confiável
    local df_output=$(df -h / | tail -1)
    local used=$(echo "$df_output" | awk '{print $(NF-4)}')
    local free=$(echo "$df_output" | awk '{print $(NF-2)}')
    local percent=$(echo "$df_output" | awk '{print $(NF-1)}')
    echo -e "   ${CYAN}Usado:${NC} ${used} | ${CYAN}Livre:${NC} ${free} | ${CYAN}Uso:${NC} $percent"
}

# ============================================================================
# FUNÇÕES DE LIMPEZA
# ============================================================================

find_large_files() {
    log_header "🔍 FASE 1: PROCURANDO ARQUIVOS >1GB"

    log "Escaneando sistema (pode demorar alguns minutos)..."

    local search_paths=(
        "/home"
        "/tmp"
        "/var/tmp"
        "/var/log"
        "/var/cache"
    )

    echo -e "\n${BOLD}Arquivos maiores que 1GB encontrados:${NC}\n"

    local total_size=0
    local file_count=0

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            log "Escaneando $path..."
            while IFS= read -r -d '' file; do
                if [[ -f "$file" ]]; then
                    local size=$(du -h "$file" | cut -f1)
                    local size_bytes=$(du -b "$file" | cut -f1)
                    echo -e "  ${YELLOW}$size${NC} - $file"
                    total_size=$((total_size + size_bytes))
                    file_count=$((file_count + 1))
                fi
            done < <(find "$path" -type f -size +${MIN_FILE_SIZE} -print0 2>/dev/null || true)
        fi
    done

    if [[ $file_count -eq 0 ]]; then
        log_success "Nenhum arquivo >1GB encontrado!"
    else
        local total_gb=$((total_size / 1024 / 1024 / 1024))
        log_warn "Total: $file_count arquivos ocupando ${total_gb}GB"
        echo ""
        read -p "Deseja ver um relatório detalhado e decidir o que deletar? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}💡 Arquivos grandes encontrados. Revise manualmente.${NC}"
            echo "   Use: rm -f <arquivo> para deletar"
        fi
    fi

    report_space
}

kill_all_builds() {
    log_header "🔴 FASE 2: ABORTANDO TODOS OS BUILDS"

    log "Terminando processos Nix..."
    pkill -9 -f "nix.*build\|nix.*flake\|nix-daemon" 2>/dev/null || true
    sudo killall -9 nixbld 2>/dev/null || true

    log "Terminando compiladores..."
    sudo killall -9 cc1plus cc1 g++ gcc clang cargo rustc go node npm 2>/dev/null || true

    log "Terminando builds CUDA..."
    sudo killall -9 nvcc cudafe cicc 2>/dev/null || true

    log_success "Todos os builds abortados"
    sleep 3
}

clean_nix_store() {
    log_header "📦 FASE 3: LIMPEZA AGRESSIVA DO NIX STORE"

    log "Tamanho atual do /nix/store:"
    sudo du -sh /nix/store 2>/dev/null || echo "Não calculável"

    log "Removendo TODAS as gerações antigas do sistema..."
    sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>/dev/null || true

    log "Removendo TODAS as gerações antigas do usuário..."
    nix-env --delete-generations old 2>/dev/null || true

    log "Garbage collection do usuário..."
    nix-collect-garbage -d 2>/dev/null || true

    log "Garbage collection do sistema (pode demorar 10-15 min)..."
    sudo nix-collect-garbage -d 2>/dev/null || true

    log "Otimizando store (deduplicação - pode demorar)..."
    sudo nix-store --optimise 2>/dev/null || true

    log "Verificando integridade do store..."
    sudo nix-store --verify --check-contents 2>/dev/null || log_warn "Verificação falhou (não crítico)"

    log_success "Nix store limpo e otimizado"
    report_space
}

clean_profiles_and_channels() {
    log_header "🔧 FASE 4: RESET DE PROFILES E CHANNELS"

    log "Removendo symlinks de resultado..."
    rm -f ~/result* /tmp/result* /etc/nixos/result* 2>/dev/null || true

    log "Limpando profiles quebrados..."
    find /nix/var/nix/profiles -type l ! -exec test -e {} \; -delete 2>/dev/null || true

    log "Estado atual dos channels:"
    nix-channel --list || echo "Nenhum channel configurado"

    log_success "Profiles e channels limpos"
    report_space
}

clean_build_caches() {
    log_header "🗂️  FASE 5: LIMPEZA DE BUILD CACHES"

    # Cargo (Rust)
    if [[ -d ~/.cargo ]]; then
        log "Limpando cache Cargo (Rust)..."
        local cargo_size=$(du -sh ~/.cargo 2>/dev/null | cut -f1 || echo "0")
        log "  Tamanho atual: $cargo_size"
        rm -rf ~/.cargo/registry/cache/* 2>/dev/null || true
        rm -rf ~/.cargo/registry/index/* 2>/dev/null || true
        rm -rf ~/.cargo/git/db/* 2>/dev/null || true
        log_success "  Cargo cache limpo"
    fi

    # npm
    if [[ -d ~/.npm ]]; then
        log "Limpando cache npm..."
        local npm_size=$(du -sh ~/.npm 2>/dev/null | cut -f1 || echo "0")
        log "  Tamanho atual: $npm_size"
        npm cache clean --force 2>/dev/null || true
        log_success "  npm cache limpo"
    fi

    # Go
    if [[ -d ~/go ]]; then
        log "Limpando cache Go..."
        rm -rf ~/go/pkg/mod/cache/* 2>/dev/null || true
        log_success "  Go cache limpo"
    fi

    # pip
    if [[ -d ~/.cache/pip ]]; then
        log "Limpando cache pip..."
        rm -rf ~/.cache/pip/* 2>/dev/null || true
        log_success "  pip cache limpo"
    fi

    # direnv
    if [[ -d ~/.direnv ]]; then
        log "Limpando cache direnv..."
        rm -rf ~/.direnv/* 2>/dev/null || true
        log_success "  direnv cache limpo"
    fi

    report_space
}

clean_logs() {
    log_header "📝 FASE 6: LIMPEZA DE LOGS"

    log "Parando auditd..."
    sudo systemctl stop auditd 2>/dev/null || true

    log "Limpando logs de audit..."
    sudo find /var/log/audit -name "audit.log.*" -delete 2>/dev/null || true
    sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null || true

    log "Reiniciando auditd..."
    sudo systemctl start auditd 2>/dev/null || true

    log "Limpando journal (manter últimos 3 dias)..."
    sudo journalctl --vacuum-time=3d
    sudo journalctl --vacuum-size=100M

    log "Limpando logs antigos..."
    sudo find /var/log -name "*.log.*" -delete 2>/dev/null || true
    sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
    sudo find /var/log -name "*.old" -delete 2>/dev/null || true

    log_success "Logs limpos"
    report_space
}

clean_tmp() {
    log_header "🗑️  FASE 7: LIMPEZA DE TEMPORÁRIOS"

    log "Limpando /tmp..."
    sudo find /tmp -type f -atime +1 -delete 2>/dev/null || true
    sudo find /tmp -type d -empty -delete 2>/dev/null || true

    log "Limpando /var/tmp..."
    sudo find /var/tmp -type f -atime +1 -delete 2>/dev/null || true

    log "Limpando cache do usuário..."
    if [[ -d ~/.cache ]]; then
        local cache_size=$(du -sh ~/.cache 2>/dev/null | cut -f1 || echo "0")
        log "  Tamanho atual: $cache_size"
        read -p "Limpar ~/.cache? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf ~/.cache/*
            log_success "  Cache limpo"
        fi
    fi

    log_success "Temporários limpos"
    report_space
}

clean_docker() {
    log_header "🐳 FASE 8: LIMPEZA DOCKER (Opcional)"

    if command -v docker &> /dev/null && sudo systemctl is-active docker &>/dev/null; then
        read -p "Limpar Docker (containers, images, volumes)? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Limpando Docker..."
            docker system prune -a --volumes -f 2>/dev/null || true
            log_success "Docker limpo"
            report_space
        fi
    else
        log "Docker não disponível ou não rodando"
    fi
}

restart_nix_daemon() {
    log_header "🔄 FASE 9: REINICIANDO NIX DAEMON"

    log "Parando nix-daemon..."
    sudo systemctl stop nix-daemon.socket 2>/dev/null || true
    sudo systemctl stop nix-daemon.service 2>/dev/null || true

    sleep 3

    log "Iniciando nix-daemon..."
    sudo systemctl start nix-daemon.socket
    sudo systemctl start nix-daemon.service

    sleep 2

    if sudo systemctl is-active nix-daemon.service &>/dev/null; then
        log_success "nix-daemon reiniciado com sucesso"
    else
        log_error "Falha ao reiniciar nix-daemon"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Banner
    echo -e "${BOLD}${RED}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                    NIX HARD RESET v2.0.0                           ║
║              Limpeza Agressiva Total do Sistema                    ║
║                                                                    ║
║  ⚠️  ESTE SCRIPT VAI:                                              ║
║     • Procurar arquivos >1GB                                      ║
║     • Deletar TODAS as gerações antigas                           ║
║     • Fazer GC agressivo                                          ║
║     • Limpar todos os build caches                                ║
║     • Resetar profiles e channels                                 ║
║     • Limpar logs e temporários                                   ║
║                                                                    ║
║  💡 Esperado liberar: 50-200GB                                     ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo ""
    read -p "Continuar com HARD RESET? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Abortado pelo usuário."
        exit 0
    fi

    # Criar log
    sudo touch "$LOG_FILE" 2>/dev/null || true
    sudo chmod 666 "$LOG_FILE" 2>/dev/null || true

    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "INICIANDO NIX HARD RESET"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo -e "${BOLD}📊 Espaço ANTES da limpeza:${NC}"
    df -h / | grep -v Filesystem
    echo ""

    # Executar fases
    find_large_files
    kill_all_builds
    clean_nix_store
    clean_profiles_and_channels
    clean_build_caches
    clean_logs
    clean_tmp
    clean_docker
    restart_nix_daemon

    # Resumo final
    echo ""
    log_header "✅ HARD RESET COMPLETO!"

    echo -e "${BOLD}📊 Espaço DEPOIS da limpeza:${NC}"
    df -h / | grep -v Filesystem
    echo ""

    echo -e "${BOLD}📈 Resumo:${NC}"
    df -h / | awk 'NR==2 {
        print "   Total:      " $2
        print "   Usado:      " $3 " (" $5 ")"
        print "   Disponível: " $4
    }'

    echo ""
    echo -e "${BOLD}${GREEN}💡 PRÓXIMOS PASSOS:${NC}"
    echo "1. Sistema limpo e pronto para offload pesado"
    echo "2. Testar rebuild: sudo nixos-rebuild dry-build --flake /etc/nixos#kernelcore --fast"
    echo "3. Se OK, fazer rebuild completo: sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --fast --cores 8 --max-jobs 8"
    echo ""
    echo -e "📝 Log completo em: ${LOG_FILE}"
    echo ""

    log_success "HARD RESET FINALIZADO COM SUCESSO!"
}

# Executar
main "$@"
