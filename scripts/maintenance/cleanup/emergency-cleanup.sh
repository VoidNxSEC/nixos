#!/usr/bin/env bash

# emergency-cleanup.sh: Script consolidado para redução de danos em momentos de overhead
# Combina: parada de serviços systemd + limpeza de processos + limpeza de disco

# Cores para saída
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

LOG_FILE="/tmp/emergency-cleanup.log"
TEMP_THRESHOLD=80

# ============================================================================
# LOGGING
# ============================================================================

log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# ============================================================================
# MENU PRINCIPAL
# ============================================================================

show_menu() {
    clear
    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       🚨 EMERGENCY CLEANUP - REDUÇÃO DE DANOS 🚨          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    local cpu_temp=$(get_cpu_temp)
    local cpu_color="${GREEN}"
    [[ "$cpu_temp" -gt 70 ]] && cpu_color="${YELLOW}"
    [[ "$cpu_temp" -gt "$TEMP_THRESHOLD" ]] && cpu_color="${RED}"

    echo -e "  ${CYAN}Status do Sistema:${NC}"
    echo -e "    🌡️  CPU: ${cpu_color}${cpu_temp}°C${NC}"
    echo -e "    💾 Disco: $(df -h / | awk 'NR==2 {print $5 " usado (" $4 " livre)"}')"
    echo -e "    ⚙️  Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Escolha uma ação:${NC}"
    echo ""
    echo -e "  ${RED}${BOLD}EMERGÊNCIA - AÇÃO IMEDIATA${NC}"
    echo -e "  ${RED}1)${NC} 🔴 PARADA TOTAL - Para TUDO (serviços + builds + processos)"
    echo -e "  ${RED}2)${NC} ⚡ KILL NIX BUILDS - Aborta builds Nix imediatamente"
    echo -e "  ${RED}3)${NC} ❄️  CPU COOLDOWN - Força powersave + para builds"
    echo ""
    echo -e "  ${YELLOW}${BOLD}SERVIÇOS SYSTEMD${NC}"
    echo -e "  ${YELLOW}4)${NC} 🛑 Para serviços pesados (monitoring, containers, GPU)"
    echo -e "  ${YELLOW}5)${NC} ▶️  Reinicia serviços parados"
    echo ""
    echo -e "  ${BLUE}${BOLD}PROCESSOS${NC}"
    echo -e "  ${BLUE}6)${NC} 🔍 Análise de processos pesados (CPU/MEM/IO)"
    echo -e "  ${BLUE}7)${NC} 🧟 Limpar processos zumbis"
    echo -e "  ${BLUE}8)${NC} 🎯 Matar processo específico (nome ou PID)"
    echo ""
    echo -e "  ${GREEN}${BOLD}LIMPEZA DE DISCO${NC}"
    echo -e "  ${GREEN}9)${NC} 🧹 Limpeza agressiva (logs + cache + Nix GC)"
    echo -e "  ${GREEN}10)${NC} 📝 Limpar apenas logs (audit + journal)"
    echo -e "  ${GREEN}11)${NC} 📦 Nix GC rápido (sem optimize)"
    echo ""
    echo -e "  ${CYAN}0)${NC} 🚪 Sair"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -n "Escolha > "
}

# ============================================================================
# FUNÇÕES DE TEMPERATURA E SISTEMA
# ============================================================================

get_cpu_temp() {
    local temp=0
    if command -v sensors &>/dev/null; then
        temp=$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d'.' -f1 || echo 0)
    fi
    if [[ $temp -eq 0 ]] && [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    fi
    echo "$temp"
}

is_pid_active() {
    ps -p "$1" &>/dev/null
}

report_space() {
    CURRENT=$(df / | tail -1 | awk '{print $3}')
    FREE=$(df / | tail -1 | awk '{print $4}')
    echo -e "   ${CYAN}Usado:${NC} ${CURRENT} | ${GREEN}Livre:${NC} ${FREE}"
}

# ============================================================================
# 1. PARADA TOTAL DE EMERGÊNCIA
# ============================================================================

emergency_stop_all() {
    log_message "CRITICAL" "🔴 PARADA TOTAL DE EMERGÊNCIA INICIADA"
    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     🔴 PARADA TOTAL - EMERGÊNCIA MÁXIMA 🔴                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}Esta ação irá:${NC}"
    echo "  1. Parar todos os serviços pesados (monitoring, containers, etc)"
    echo "  2. Abortar todos os builds Nix"
    echo "  3. Forçar CPU para modo powersave"
    echo "  4. Matar processos pesados opcionalmente"
    echo ""
    read -p "$(echo -e "${RED}CONFIRMAR PARADA TOTAL? (s/N) > ${NC}")" confirm

    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Operação cancelada.${NC}"
        return
    fi

    echo ""
    echo -e "${RED}Executando parada total...${NC}"
    echo ""

    # 1. Para serviços systemd
    stop_heavy_services

    # 2. Mata builds Nix
    kill_nix_builds

    # 3. CPU cooldown
    cpu_cooldown_action

    # 4. Limpa zumbis
    clean_zombies

    echo ""
    echo -e "${GREEN}✅ Parada total concluída!${NC}"
    log_message "SUCCESS" "Parada total de emergência concluída"

    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 2. KILL NIX BUILDS
# ============================================================================

kill_nix_builds() {
    log_message "WARNING" "Iniciando kill de builds Nix"
    echo -e "${RED}${BOLD}🔴 ABORTANDO BUILDS NIX...${NC}"

    local killed=0

    # nix flake check/build
    if pgrep -f "nix flake" &>/dev/null; then
        pkill -9 -f "nix flake" 2>/dev/null && killed=$((killed + 1))
        echo -e "${GREEN}  ✓ nix flake abortado${NC}"
    fi

    if pgrep -f "nix build" &>/dev/null; then
        pkill -9 -f "nix build" 2>/dev/null && killed=$((killed + 1))
        echo -e "${GREEN}  ✓ nix build abortado${NC}"
    fi

    # Workers nixbld
    if pgrep nixbld &>/dev/null; then
        sudo killall -9 nixbld 2>/dev/null && killed=$((killed + 1))
        echo -e "${GREEN}  ✓ Workers nixbld terminados${NC}"
    fi

    # Compiladores
    for proc in cc1plus cc1 cudafe cicc ninja cmake g++ gcc clang rustc cargo; do
        if pgrep "$proc" &>/dev/null; then
            sudo killall -9 "$proc" 2>/dev/null && killed=$((killed + 1))
        fi
    done
    echo -e "${GREEN}  ✓ Compiladores terminados${NC}"

    # npm builds
    if pgrep -f "npm.*build" &>/dev/null; then
        pkill -9 -f "npm.*build" 2>/dev/null && killed=$((killed + 1))
        echo -e "${GREEN}  ✓ npm builds abortados${NC}"
    fi

    echo -e "${GREEN}✓ Total: $killed processos Nix terminados${NC}"
    log_message "SUCCESS" "Nix builds terminados: $killed processos"
}

# ============================================================================
# 3. CPU COOLDOWN
# ============================================================================

cpu_cooldown_action() {
    log_message "INFO" "Iniciando CPU cooldown"
    echo -e "${BLUE}❄️  MODO COOLDOWN - REDUZINDO CARGA DA CPU...${NC}"

    # Força powersave
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "powersave" | sudo tee "$cpu" > /dev/null 2>&1
        done
        echo -e "${GREEN}  ✓ CPU em modo powersave${NC}"
    else
        echo -e "${YELLOW}  ⚠ cpufreq não disponível${NC}"
    fi

    local temp=$(get_cpu_temp)
    echo -e "${CYAN}  🌡️  Temperatura: ${temp}°C${NC}"
    log_message "INFO" "CPU cooldown aplicado. Temperatura: ${temp}°C"
}

# ============================================================================
# 4. PARA SERVIÇOS SYSTEMD PESADOS
# ============================================================================

stop_heavy_services() {
    log_message "INFO" "Parando serviços systemd pesados"
    echo -e "${YELLOW}🛑 PARANDO SERVIÇOS PESADOS...${NC}"

    local services=(
        "clamav-daemon.service"
        "github-runner-nixos-self-hosted.service"
        "grafana.service"
        "prometheus.service"
        "prometheus-node-exporter.service"
        "nvidia-gpu-monitor.service"
        "container@ml-jupyter.service"
        "container@ml-ollama.service"
        "container@dev-proxy.service"
    )

    local stopped=0
    for service in "${services[@]}"; do
        if sudo systemctl is-active "$service" &>/dev/null; then
            sudo systemctl stop "$service" 2>/dev/null && {
                echo -e "${GREEN}  ✓ Parado: $service${NC}"
                stopped=$((stopped + 1))
            }
        fi
    done

    echo -e "${GREEN}✓ $stopped serviços parados${NC}"
    log_message "SUCCESS" "$stopped serviços systemd parados"
}

# ============================================================================
# 5. REINICIA SERVIÇOS
# ============================================================================

restart_services() {
    log_message "INFO" "Reiniciando serviços"
    echo -e "${GREEN}▶️  REINICIANDO SERVIÇOS...${NC}"

    read -p "Reiniciar quais? (1=Monitoring 2=Containers 3=GPU 4=Todos 0=Cancelar) > " choice

    case $choice in
        1)
            sudo systemctl start grafana prometheus prometheus-node-exporter
            echo -e "${GREEN}  ✓ Monitoring reiniciado${NC}"
            ;;
        2)
            sudo systemctl start container@ml-jupyter container@ml-ollama container@dev-proxy
            echo -e "${GREEN}  ✓ Containers reiniciados${NC}"
            ;;
        3)
            sudo systemctl start nvidia-gpu-monitor
            echo -e "${GREEN}  ✓ GPU monitor reiniciado${NC}"
            ;;
        4)
            stop_heavy_services # Usando a mesma lista mas com start
            services=(
                "clamav-daemon.service"
                "github-runner-nixos-self-hosted.service"
                "grafana.service"
                "prometheus.service"
                "prometheus-node-exporter.service"
                "nvidia-gpu-monitor.service"
                "container@ml-jupyter.service"
                "container@ml-ollama.service"
                "container@dev-proxy.service"
            )
            for service in "${services[@]}"; do
                sudo systemctl start "$service" 2>/dev/null && echo -e "${GREEN}  ✓ $service${NC}"
            done
            ;;
        *)
            echo -e "${BLUE}Cancelado${NC}"
            ;;
    esac

    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 6. ANÁLISE DE PROCESSOS PESADOS
# ============================================================================

analyze_heavy_processes() {
    log_message "INFO" "Iniciando análise de processos pesados"

    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Análise de Processos Pesados (TOP 10)            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    local temp=$(get_cpu_temp)
    if [[ "$temp" -gt "$TEMP_THRESHOLD" ]]; then
        echo -e "${RED}${BOLD}🔥 ALERTA: CPU em ${temp}°C (limite: ${TEMP_THRESHOLD}°C)${NC}"
        echo ""
    fi

    echo -e "${MAGENTA}--- TOP 10 CPU ---${NC}"
    ps aux --sort=-%cpu | head -11 | tail -10 | awk '{printf "  %5s  %4s%%  %s\n", $2, $3, $11}'

    echo ""
    echo -e "${MAGENTA}--- TOP 10 MEMÓRIA ---${NC}"
    ps aux --sort=-%mem | head -11 | tail -10 | awk '{printf "  %5s  %4s%%  %s\n", $2, $4, $11}'

    echo ""
    echo -e "${YELLOW}Ações disponíveis:${NC}"
    echo "  k) Matar processo por PID"
    echo "  n) Matar todos os builds Nix"
    echo "  c) CPU cooldown"
    echo "  q) Voltar"
    echo ""
    read -p "Escolha > " action

    case $action in
        k)
            read -p "PID para matar > " pid
            if [[ "$pid" =~ ^[0-9]+$ ]] && is_pid_active "$pid"; then
                local pname=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                sudo kill -9 "$pid" 2>/dev/null && \
                    echo -e "${GREEN}✓ Processo $pid ($pname) terminado${NC}" || \
                    echo -e "${RED}✗ Falha ao terminar $pid${NC}"
            else
                echo -e "${RED}PID inválido ou processo não existe${NC}"
            fi
            ;;
        n) kill_nix_builds ;;
        c) cpu_cooldown_action ;;
        *) ;;
    esac

    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 7. LIMPAR ZUMBIS
# ============================================================================

clean_zombies() {
    log_message "INFO" "Limpando processos zumbis"
    echo -e "${YELLOW}🧟 LIMPANDO PROCESSOS ZUMBIS...${NC}"

    local zombie_pids=$(ps -ef | awk '$8 == "Z" {print $2}')

    if [ -z "$zombie_pids" ]; then
        echo -e "${GREEN}✓ Nenhum zumbi encontrado${NC}"
        return
    fi

    local cleaned=0
    for pid in $zombie_pids; do
        local ppid=$(ps -o ppid= -p "$pid" | tr -d ' ')
        if [ -n "$ppid" ] && is_pid_active "$ppid"; then
            sudo kill -s SIGCHLD "$ppid" 2>/dev/null && cleaned=$((cleaned + 1))
        fi
    done

    echo -e "${GREEN}✓ $cleaned zumbis limpos${NC}"
    log_message "SUCCESS" "$cleaned processos zumbis limpos"
}

# ============================================================================
# 8. MATAR PROCESSO ESPECÍFICO
# ============================================================================

kill_specific_process() {
    read -p "Nome do processo ou PID > " target

    if [[ -z "$target" ]]; then
        echo -e "${RED}Nome/PID não fornecido${NC}"
        read -p "Pressione ENTER..."
        return
    fi

    if [[ "$target" =~ ^[0-9]+$ ]]; then
        # É PID
        if is_pid_active "$target"; then
            local pname=$(ps -p "$target" -o comm= | tr -d ' ')
            sudo kill -9 "$target" && \
                echo -e "${GREEN}✓ Processo $target ($pname) terminado${NC}" || \
                echo -e "${RED}✗ Falha ao terminar $target${NC}"
        else
            echo -e "${RED}PID $target não existe${NC}"
        fi
    else
        # É nome
        local pids=$(pgrep -d ' ' "$target")
        if [ -z "$pids" ]; then
            echo -e "${YELLOW}Nenhum processo '$target' encontrado${NC}"
        else
            echo -e "${YELLOW}PIDs encontrados: $pids${NC}"
            read -p "Confirmar kill? (s/N) > " confirm
            if [[ "$confirm" =~ ^[Ss]$ ]]; then
                for pid in $pids; do
                    sudo kill -9 "$pid" && echo -e "${GREEN}✓ $pid terminado${NC}"
                done
            fi
        fi
    fi

    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 9. LIMPEZA AGRESSIVA (LOGS + CACHE + NIX)
# ============================================================================

aggressive_cleanup() {
    log_message "WARNING" "Iniciando limpeza agressiva"

    echo -e "${RED}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          🧹 LIMPEZA AGRESSIVA DE DISCO 🧹                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}Esta operação pode liberar 50-200GB!${NC}"
    echo ""
    echo "  1. Logs de audit (pode ser 100GB+)"
    echo "  2. Journal logs (últimos 7 dias)"
    echo "  3. Cache VSCodium/Roo"
    echo "  4. Nix garbage collection"
    echo "  5. Docker system prune"
    echo ""
    read -p "Continuar? (s/N) > " confirm

    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Cancelado${NC}"
        read -p "Pressione ENTER..."
        return
    fi

    echo ""
    echo -e "${CYAN}📊 Espaço ANTES:${NC}"
    df -h / | grep -v Filesystem
    echo ""

    # 1. Audit logs
    echo -e "${YELLOW}1/5 Limpando logs de audit...${NC}"
    sudo systemctl stop auditd 2>/dev/null || true
    sudo find /var/log/audit -name "audit.log.*" -delete 2>/dev/null || true
    sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null || true
    sudo systemctl start auditd 2>/dev/null || true
    echo -e "${GREEN}  ✓ Audit logs limpos${NC}"
    report_space

    # 2. Journal
    echo ""
    echo -e "${YELLOW}2/5 Limpando journal...${NC}"
    sudo journalctl --vacuum-time=7d
    sudo journalctl --vacuum-size=500M
    echo -e "${GREEN}  ✓ Journal limpo${NC}"
    report_space

    # 3. VSCodium cache
    echo ""
    echo -e "${YELLOW}3/5 Limpando cache VSCodium...${NC}"
    rm -rf ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/tasks/* 2>/dev/null || true
    rm -rf ~/.config/VSCodium/Cache/* 2>/dev/null || true
    echo -e "${GREEN}  ✓ VSCodium cache limpo${NC}"
    report_space

    # 4. Nix GC
    echo ""
    echo -e "${YELLOW}4/5 Nix garbage collection (pode demorar)...${NC}"
    nix-collect-garbage -d 2>/dev/null || true
    sudo nix-collect-garbage -d
    echo -e "${GREEN}  ✓ Nix GC concluído${NC}"
    report_space

    # 5. Docker
    echo ""
    echo -e "${YELLOW}5/5 Limpando Docker...${NC}"
    if command -v docker &>/dev/null && sudo systemctl is-active docker &>/dev/null; then
        docker system prune -f --volumes 2>/dev/null || true
        echo -e "${GREEN}  ✓ Docker limpo${NC}"
    else
        echo -e "${BLUE}  ⏭️  Docker não disponível${NC}"
    fi
    report_space

    echo ""
    echo -e "${GREEN}✅ LIMPEZA CONCLUÍDA!${NC}"
    echo ""
    echo -e "${CYAN}📊 Espaço DEPOIS:${NC}"
    df -h / | grep -v Filesystem

    log_message "SUCCESS" "Limpeza agressiva concluída"
    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 10. LIMPAR APENAS LOGS
# ============================================================================

clean_logs_only() {
    log_message "INFO" "Limpando apenas logs"
    echo -e "${YELLOW}📝 LIMPANDO LOGS...${NC}"

    echo "Espaço antes:"
    report_space
    echo ""

    # Audit
    sudo systemctl stop auditd 2>/dev/null || true
    sudo find /var/log/audit -name "audit.log.*" -delete 2>/dev/null || true
    sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null || true
    sudo systemctl start auditd 2>/dev/null || true
    echo -e "${GREEN}✓ Audit logs limpos${NC}"

    # Journal
    sudo journalctl --vacuum-time=7d
    sudo journalctl --vacuum-size=500M
    echo -e "${GREEN}✓ Journal limpo${NC}"

    # Outros logs
    sudo find /var/log -name "*.log.*" -delete 2>/dev/null || true
    sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
    echo -e "${GREEN}✓ Logs antigos removidos${NC}"

    echo ""
    echo "Espaço depois:"
    report_space

    log_message "SUCCESS" "Logs limpos"
    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# 11. NIX GC RÁPIDO
# ============================================================================

quick_nix_gc() {
    log_message "INFO" "Executando Nix GC rápido"
    echo -e "${YELLOW}📦 NIX GARBAGE COLLECTION (SEM OPTIMIZE)...${NC}"

    echo "Espaço antes:"
    report_space
    echo ""

    nix-collect-garbage -d 2>/dev/null || true
    sudo nix-collect-garbage -d

    echo -e "${GREEN}✓ Nix GC concluído${NC}"
    echo ""
    echo "Espaço depois:"
    report_space

    log_message "SUCCESS" "Nix GC rápido concluído"
    read -p "Pressione ENTER para continuar..."
}

# ============================================================================
# MAIN LOOP
# ============================================================================

main() {
    log_message "INFO" "Emergency cleanup script iniciado"

    while true; do
        show_menu
        read choice

        case $choice in
            1) emergency_stop_all ;;
            2) kill_nix_builds; read -p "Pressione ENTER..." ;;
            3) cpu_cooldown_action; read -p "Pressione ENTER..." ;;
            4) stop_heavy_services; read -p "Pressione ENTER..." ;;
            5) restart_services ;;
            6) analyze_heavy_processes ;;
            7) clean_zombies; read -p "Pressione ENTER..." ;;
            8) kill_specific_process ;;
            9) aggressive_cleanup ;;
            10) clean_logs_only ;;
            11) quick_nix_gc ;;
            0)
                echo -e "${GREEN}Saindo...${NC}"
                log_message "INFO" "Emergency cleanup script finalizado"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if [ "$#" -eq 0 ]; then
    main
else
    # Permite uso direto via argumentos
    case "$1" in
        --stop-all) emergency_stop_all ;;
        --kill-nix) kill_nix_builds ;;
        --cooldown) cpu_cooldown_action ;;
        --stop-services) stop_heavy_services ;;
        --analyze) analyze_heavy_processes ;;
        --clean-zombies) clean_zombies ;;
        --aggressive) aggressive_cleanup ;;
        --clean-logs) clean_logs_only ;;
        --nix-gc) quick_nix_gc ;;
        *)
            echo "Uso: $0 [--stop-all|--kill-nix|--cooldown|--stop-services|--analyze|--clean-zombies|--aggressive|--clean-logs|--nix-gc]"
            echo "Ou execute sem argumentos para menu interativo"
            exit 1
            ;;
    esac
fi
