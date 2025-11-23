#!/usr/bin/env bash
# ============================================================================
# NIX EMERGENCY FRAMEWORK - Sistema de Resposta a Emergências
# ============================================================================
# Versão: 1.0.0
# Autor: kernelcore
# Data: 2025-11-23
#
# Propósito: Framework completo para lidar com situações críticas do sistema:
#   - SWAP thrashing (disco virtual esgotado)
#   - OOM (Out of Memory)
#   - CPU intensive (builds massivos)
#   - Overheat (superaquecimento)
#   - Deadlock (sistema travado)
#
# Uso: nix-emergency <modo> [opções]
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
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

SCRIPT_VERSION="1.0.0"
LOG_FILE="/var/log/nix-emergency.log"
TEMP_THRESHOLD=80  # Temperatura CPU crítica (°C)
SWAP_THRESHOLD=80  # % de swap que dispara alerta
MEM_THRESHOLD=90   # % de RAM que dispara alerta
LOAD_THRESHOLD=20  # Load average crítico

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

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

# ============================================================================
# FUNÇÕES DE DIAGNÓSTICO
# ============================================================================

get_cpu_temp() {
    # Tenta múltiplas fontes de temperatura
    local temp=0

    if command -v sensors &>/dev/null; then
        temp=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d'.' -f1 || echo 0)
    fi

    if [[ $temp -eq 0 ]] && [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    fi

    echo "$temp"
}

get_load_avg() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
}

get_mem_usage() {
    free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}'
}

get_swap_usage() {
    local swap_total=$(free | grep Swap | awk '{print $2}')
    if [[ $swap_total -eq 0 ]]; then
        echo "0"
    else
        free | grep Swap | awk '{printf "%.0f", ($3/$2) * 100}'
    fi
}

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0"
}

# ============================================================================
# FUNÇÕES DE EMERGÊNCIA
# ============================================================================

kill_nix_builds() {
    log "🔴 ABORTANDO BUILDS NIX..."

    local killed=0

    # 1. Matar nix flake check/build
    if pgrep -f "nix flake check" &>/dev/null; then
        pkill -9 -f "nix flake check" 2>/dev/null && killed=$((killed + 1))
        log "  ✓ nix flake check abortado"
    fi

    if pgrep -f "nix build" &>/dev/null; then
        pkill -9 -f "nix build" 2>/dev/null && killed=$((killed + 1))
        log "  ✓ nix build abortado"
    fi

    # 2. Matar workers nixbld
    if pgrep nixbld &>/dev/null; then
        sudo killall -9 nixbld 2>/dev/null && killed=$((killed + 1))
        log "  ✓ Workers nixbld terminados"
    fi

    # 3. Matar compiladores
    for proc in cc1plus cc1 cudafe cicc ninja cmake g++ gcc clang; do
        if pgrep "$proc" &>/dev/null; then
            sudo killall -9 "$proc" 2>/dev/null && killed=$((killed + 1))
        fi
    done
    log "  ✓ Compiladores terminados"

    # 4. Matar npm builds (podem estar consumindo)
    if pgrep -f "npm.*build" &>/dev/null; then
        pkill -9 -f "npm.*build" 2>/dev/null && killed=$((killed + 1))
        log "  ✓ npm builds abortados"
    fi

    log_success "Total de processos terminados: $killed"
}

kill_heavy_processes() {
    log "🔴 TERMINANDO PROCESSOS PESADOS..."

    # Lista top 10 processos por memória e mata os que não são críticos
    local pids=$(ps aux --sort=-%mem | grep -v "systemd\|dbus\|X\|gdm" | head -20 | awk '{print $2}' | tail -n +2)

    for pid in $pids; do
        local pname=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")

        # Whitelist de processos críticos (não matar)
        if [[ "$pname" =~ ^(systemd|dbus|X|Xorg|gdm|sshd|NetworkManager)$ ]]; then
            continue
        fi

        # Matar processo
        if kill -9 "$pid" 2>/dev/null; then
            log "  ✓ Terminado: $pname (PID $pid)"
        fi
    done
}

emergency_swap_clear() {
    log "💾 LIMPANDO SWAP..."

    # 1. Sync filesystem
    sync

    # 2. Drop caches
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    log "  ✓ Caches limpos"

    # 3. Tentar desligar/religar swap (se possível)
    local swap_usage=$(get_swap_usage)
    if [[ $swap_usage -lt 50 ]]; then
        sudo swapoff -a 2>/dev/null && sudo swapon -a 2>/dev/null && log "  ✓ Swap renovado"
    else
        log_warn "  ⚠ Swap muito cheio ($swap_usage%), não renovando"
    fi
}

cpu_cooldown() {
    log "❄️  MODO COOLDOWN - REDUZINDO CARGA..."

    # 1. Matar builds
    kill_nix_builds

    # 2. Limitar frequência CPU (se cpufreq disponível)
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "powersave" | sudo tee "$cpu" > /dev/null 2>&1
        done
        log "  ✓ CPU em modo powersave"
    fi

    # 3. Aguardar cooldown
    log "  ⏳ Aguardando cooldown (30s)..."
    sleep 30

    local temp=$(get_cpu_temp)
    log "  🌡️  Temperatura atual: ${temp}°C"
}

# ============================================================================
# MODOS DE OPERAÇÃO
# ============================================================================

mode_status() {
    echo -e "${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          NIX EMERGENCY - STATUS DO SISTEMA                ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # CPU
    local cpu_usage=$(get_cpu_usage)
    local load_avg=$(get_load_avg)
    local cpu_temp=$(get_cpu_temp)

    echo -e "${CYAN}🖥️  CPU:${NC}"
    echo "   Uso: ${cpu_usage}%"
    echo "   Load Average: $load_avg"
    echo "   Temperatura: ${cpu_temp}°C"

    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "   ${RED}⚠️  ALERTA: Load crítico!${NC}"
    fi

    if [[ $cpu_temp -gt $TEMP_THRESHOLD ]]; then
        echo -e "   ${RED}🔥 ALERTA: Temperatura crítica!${NC}"
    fi

    echo ""

    # Memória
    local mem_usage=$(get_mem_usage)
    local swap_usage=$(get_swap_usage)

    echo -e "${CYAN}💾 MEMÓRIA:${NC}"
    echo "   RAM: ${mem_usage}%"
    echo "   SWAP: ${swap_usage}%"

    if [[ $mem_usage -gt $MEM_THRESHOLD ]]; then
        echo -e "   ${RED}⚠️  ALERTA: RAM crítica!${NC}"
    fi

    if [[ $swap_usage -gt $SWAP_THRESHOLD ]]; then
        echo -e "   ${RED}⚠️  ALERTA: SWAP crítico!${NC}"
    fi

    echo ""

    # Processos NIX ativos
    echo -e "${CYAN}🔧 PROCESSOS NIX:${NC}"
    local nix_builds=$(pgrep -fc "nix.*build\|nix.*flake" || echo 0)
    local nixbld=$(pgrep -c nixbld || echo 0)

    echo "   nix builds: $nix_builds"
    echo "   nixbld workers: $nixbld"

    if [[ $nix_builds -gt 0 ]] || [[ $nixbld -gt 0 ]]; then
        echo -e "   ${YELLOW}⚠️  Builds ativos detectados${NC}"
    fi

    echo ""

    # Diagnóstico geral
    echo -e "${CYAN}📊 DIAGNÓSTICO:${NC}"

    local issues=0

    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "   ${RED}🔴 CPU OVERLOAD${NC} (load: $load_avg)"
        issues=$((issues + 1))
    fi

    if [[ $cpu_temp -gt $TEMP_THRESHOLD ]]; then
        echo -e "   ${RED}🔴 OVERHEAT${NC} (temp: ${cpu_temp}°C)"
        issues=$((issues + 1))
    fi

    if [[ $mem_usage -gt $MEM_THRESHOLD ]]; then
        echo -e "   ${RED}🔴 MEMORY CRITICAL${NC} (${mem_usage}%)"
        issues=$((issues + 1))
    fi

    if [[ $swap_usage -gt $SWAP_THRESHOLD ]]; then
        echo -e "   ${RED}🔴 SWAP THRASHING${NC} (${swap_usage}%)"
        issues=$((issues + 1))
    fi

    if [[ $issues -eq 0 ]]; then
        echo -e "   ${GREEN}✅ Sistema saudável${NC}"
    else
        echo ""
        echo -e "${YELLOW}💡 RECOMENDAÇÃO:${NC}"
        echo "   Execute: nix-emergency abort"
    fi
}

mode_abort() {
    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              MODO EMERGÊNCIA - ABORT                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    log "🚨 INICIANDO MODO ABORT..."

    # 1. Matar builds
    kill_nix_builds

    # 2. Aguardar estabilização
    log "⏳ Aguardando estabilização (10s)..."
    sleep 10

    # 3. Status final
    mode_status

    log_success "✅ ABORT COMPLETO"
}

mode_nuke() {
    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              MODO EMERGÊNCIA - NUKE                        ║"
    echo "║          ⚠️  TERMINARÁ PROCESSOS PESADOS ⚠️                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    read -p "Confirma NUKE (s/N)? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi

    log "💣 INICIANDO MODO NUKE..."

    # 1. Matar builds NIX
    kill_nix_builds
    sleep 5

    # 2. Matar processos pesados
    kill_heavy_processes
    sleep 5

    # 3. Limpar swap
    emergency_swap_clear
    sleep 5

    # 4. Status final
    mode_status

    log_success "✅ NUKE COMPLETO"
}

mode_cooldown() {
    echo -e "${BLUE}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              MODO EMERGÊNCIA - COOLDOWN                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    cpu_cooldown

    log_success "✅ COOLDOWN COMPLETO"
    mode_status
}

mode_swap_emergency() {
    echo -e "${YELLOW}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            MODO EMERGÊNCIA - SWAP CRITICAL                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    log "💾 INICIANDO EMERGÊNCIA SWAP..."

    # 1. Matar builds (maior consumidor)
    kill_nix_builds
    sleep 5

    # 2. Limpar swap
    emergency_swap_clear
    sleep 5

    # 3. Status
    mode_status

    log_success "✅ SWAP EMERGENCY COMPLETO"
}

mode_monitor() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           MODO MONITORAMENTO CONTÍNUO                      ║"
    echo "║           (Ctrl+C para sair)                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    while true; do
        clear
        mode_status

        # Auto-intervenção se crítico
        local swap_usage=$(get_swap_usage)
        local cpu_temp=$(get_cpu_temp)
        local load_avg=$(get_load_avg)

        if [[ $swap_usage -gt 90 ]]; then
            log_error "🚨 SWAP CRÍTICO! Auto-intervenção..."
            mode_swap_emergency
        fi

        if [[ $cpu_temp -gt 90 ]]; then
            log_error "🔥 OVERHEAT CRÍTICO! Auto-cooldown..."
            cpu_cooldown
        fi

        sleep 5
    done
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║               NIX EMERGENCY FRAMEWORK v1.0.0                       ║
║          Sistema de Resposta a Emergências NixOS                   ║
╚════════════════════════════════════════════════════════════════════╝

COMANDOS:

  status              Mostra status completo do sistema
  abort               Aborta builds NIX em execução
  nuke                ⚠️  Termina builds + processos pesados
  cooldown            Reduz carga e temperatura CPU
  swap-emergency      Libera SWAP crítico
  monitor             Monitora continuamente (auto-intervenção)

ALIASES RÁPIDOS (configurar no shell):

  emergency-status    = nix-emergency status
  emergency-abort     = nix-emergency abort
  emergency-nuke      = nix-emergency nuke
  emergency-cooldown  = nix-emergency cooldown

EXEMPLOS:

  # Verificar status
  nix-emergency status

  # Sistema travado? Abortar builds
  nix-emergency abort

  # Swap esgotado?
  nix-emergency swap-emergency

  # CPU superaquecendo?
  nix-emergency cooldown

  # Situação extrema? (cuidado!)
  nix-emergency nuke

  # Monitorar automaticamente
  nix-emergency monitor

SITUAÇÕES DE USO:

  🔴 Sistema travado/lento
     → nix-emergency abort

  🔥 CPU superaquecendo (>85°C)
     → nix-emergency cooldown

  💾 SWAP esgotado (>80%)
     → nix-emergency swap-emergency

  💣 Nada funciona (último recurso)
     → nix-emergency nuke

LOGS:

  /var/log/nix-emergency.log

DOCUMENTAÇÃO:

  /etc/nixos/docs/NIX-EMERGENCY-PROCEDURES.md

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Criar log se não existir
    sudo touch "$LOG_FILE" 2>/dev/null || true
    sudo chmod 666 "$LOG_FILE" 2>/dev/null || true

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local mode="$1"
    shift

    case "$mode" in
        status)
            mode_status
            ;;
        abort)
            mode_abort
            ;;
        nuke)
            mode_nuke
            ;;
        cooldown)
            mode_cooldown
            ;;
        swap-emergency|swap)
            mode_swap_emergency
            ;;
        monitor)
            mode_monitor
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Modo desconhecido: $mode"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Executar
main "$@"
