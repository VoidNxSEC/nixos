#!/usr/bin/env bash

# limpa-processos.sh: Script para identificar e terminar processos por nome ou PID, incluindo limpeza de zumbis.
# Adicionalmente, oferece uma funcionalidade de análise inteligente para identificar e permitir o kill seletivo de
# processos que consomem muitos recursos (CPU, Memória, I/O).
# Inclui funcionalidades de emergência baseadas no nix-emergency.sh para builds Nix e cooldown da CPU.

# Cores para saída no terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m" # Sem cor

LOG_FILE="/tmp/limpa-processos.log"
TEMP_THRESHOLD=80  # Temperatura CPU crítica (°C)

# Função para logar mensagens
log_message() {
    local type="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [${type}] ${message}" | tee -a "$LOG_FILE"
}

# Função para exibir uso do script
usage() {
    echo -e "${BLUE}Uso:${NC} $0 <nome_do_processo_ou_PID>"
    echo -e "  Exemplo: $0 firefox"
    echo -e "  Exemplo: $0 12345"
    echo -e "  Exemplo: $0 --clean-zombies"
    echo -e "  Exemplo: $0 --heavy-analysis # Analisa e permite kill seletivo de processos pesados"
    echo -e "  Exemplo: $0 --nix-kill-fast # Aborta imediatamente builds Nix em execução (com confirmação)"
    echo -e "  Exemplo: $0 --cpu-cooldown # Força a CPU para modo powersave"
    echo -e "  Exemplo: $0 --cpu-temp-only # Retorna apenas a temperatura atual da CPU"
    exit 1
}

# Função para verificar se um PID existe e está ativo
is_pid_active() {
    local pid="$1"
    ps -p "$pid" &>/dev/null
    return $?
}

# Função para obter a temperatura da CPU
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

# Função para matar um processo
kill_process() {
    local pid="$1"
    local proc_name="$2"

    if is_pid_active "$pid"; then
        log_message "INFO" "Tentando terminar o processo '$proc_name' (PID: $pid) com kill -9..."
        if sudo kill -9 "$pid" &>/dev/null; then
            sleep 0.1 # Pequena pausa para o sistema processar
            if ! is_pid_active "$pid"; then
                log_message "SUCCESS" "Processo '$proc_name' (PID: $pid) terminado com sucesso."
                echo -e "${GREEN}✓ Processo '$proc_name' (PID: $pid) terminado.${NC}"
                return 0
            else
                log_message "ERROR" "Falha ao terminar o processo '$proc_name' (PID: $pid). Ainda ativo."
                echo -e "${RED}✗ Falha ao terminar o processo '$proc_name' (PID: $pid).${NC}"
                return 1
            fi
        else
            log_message "ERROR" "Erro ao executar 'sudo kill -9 $pid' para '$proc_name'."
            echo -e "${RED}✗ Erro ao executar kill para '$proc_name' (PID: $pid).${NC}"
            return 1
        fi
    else
        log_message "INFO" "Processo '$proc_name' (PID: $pid) não está ativo ou já foi terminado. Ignorando."
        echo -e "${YELLOW}ℹ Processo '$proc_name' (PID: $pid) não ativo. Ignorando.${NC}"
        return 0 # Considera sucesso se o processo já não está lá
    fi
}

# Função para limpar processos zumbis
clean_zombies() {
    log_message "INFO" "Verificando processos zumbis..."
    local zombie_pids=$(ps -ef | awk '$8 == "Z" {print $2}')
    local cleaned_count=0

    if [ -z "$zombie_pids" ]; then
        log_message "INFO" "Nenhum processo zumbi encontrado."
        echo -e "${GREEN}✓ Nenhum processo zumbi encontrado.${NC}"
        return 0
    fi

    log_message "WARNING" "Processos zumbis encontrados: $zombie_pids"
    echo -e "${YELLOW}⚠️ Processos zumbis encontrados. Tentando limpar...${NC}"

    for pid in $zombie_pids; do
        local parent_pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
        if [ -n "$parent_pid" ] && is_pid_active "$parent_pid"; then
            log_message "INFO" "Tentando enviar SIGCHLD para o pai ($parent_pid) do zumbi $pid."
            if sudo kill -s SIGCHLD "$parent_pid" &>/dev/null; then
                sleep 0.1
                if ! is_pid_active "$pid"; then # Verifica se o zumbi desapareceu
                    log_message "SUCCESS" "Zumbi $pid limpo através do pai $parent_pid."
                    cleaned_count=$((cleaned_count + 1))
                else
                    log_message "WARNING" "Zumbi $pid ainda presente após sinal SIGCHLD para o pai $parent_pid."
                fi
            else
                log_message "ERROR" "Falha ao enviar SIGCHLD para o pai $parent_pid do zumbi $pid."
            fi
        else
            log_message "INFO" "Pai do zumbi $pid não encontrado ou inativo. Zumbi deve ser eventualmente limpo pelo init."
        fi
    done

    if [ "$cleaned_count" -gt 0 ]; then
        echo -e "${GREEN}✓ $cleaned_count processo(s) zumbi limpo(s).${NC}"
    else
        echo -e "${YELLOW}ℹ Nenhum zumbi limpo diretamente, o sistema operacional os limpará eventualmente.${NC}"
    fi
    return 0
}

# Função para abortar builds Nix (baseada no nix-emergency.sh)
kill_nix_builds() {
    log_message "INFO" "🔴 ABORTANDO BUILDS NIX..."
    echo -e "${RED}${BOLD}🔴 ABORTANDO BUILDS NIX...${NC}"

    local killed=0

    # 1. Matar nix flake check/build
    if pgrep -f "nix flake check" &>/dev/null; then
        pkill -9 -f "nix flake check" 2>/dev/null && killed=$((killed + 1))
        log_message "INFO" "  ✓ nix flake check abortado"
    fi

    if pgrep -f "nix build" &>/dev/null; then
        pkill -9 -f "nix build" 2>/dev/null && killed=$((killed + 1))
        log_message "INFO" "  ✓ nix build abortado"
    fi

    # 2. Matar workers nixbld
    if pgrep nixbld &>/dev/null; then
        sudo killall -9 nixbld 2>/dev/null && killed=$((killed + 1))
        log_message "INFO" "  ✓ Workers nixbld terminados"
    fi

    # 3. Matar compiladores comuns em builds Nix
    for proc in cc1plus cc1 cudafe cicc ninja cmake g++ gcc clang rustc cargo; do
        if pgrep "$proc" &>/dev/null;
        then
            sudo killall -9 "$proc" 2>/dev/null && killed=$((killed + 1))
        fi
    done
    log_message "INFO" "  ✓ Compiladores e ferramentas de build terminados"

    # 4. Matar npm builds (se aplicável, para projetos baseados em JS/TS no Nix)
    if pgrep -f "npm.*build" &>/dev/null;
    then
        pkill -9 -f "npm.*build" 2>/dev/null && killed=$((killed + 1))
        log_message "INFO" "  ✓ npm builds abortados"
    fi

    log_message "SUCCESS" "Total de processos Nix/builds terminados: $killed"
    echo -e "${GREEN}✓ Total de processos Nix/builds terminados: $killed${NC}"
    return 0
}

# Função para forçar a CPU para modo powersave
cpu_cooldown_action() {
    log_message "INFO" "❄️  MODO COOLDOWN - TENTANDO REDUZIR CARGA DA CPU..."
    echo -e "${BLUE}❄️  MODO COOLDOWN - TENTANDO REDUZIR CARGA DA CPU...${NC}"

    # Limitar frequência CPU (se cpufreq disponível)
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor;
        do
            echo "powersave" | sudo tee "$cpu" > /dev/null 2>&1
        done
        log_message "INFO" "  ✓ CPU em modo powersave"
        echo -e "${GREEN}  ✓ CPU em modo powersave${NC}"
    else
        log_message "WARNING" "  ⚠ Diretório cpufreq não encontrado. Não foi possível definir o governador da CPU."
        echo -e "${YELLOW}  ⚠ Não foi possível definir o governador da CPU (diretório cpufreq não encontrado).${NC}"
    fi

    local current_temp=$(get_cpu_temp)
    log_message "INFO" "  🌡️  Temperatura atual da CPU: ${current_temp}°C"
    echo -e "${YELLOW}  🌡️  Temperatura atual da CPU: ${current_temp}°C${NC}"
}

# Função para obter estatísticas de I/O de TODOS os processos (usando iotop se disponível, senão ps)
# Retorna: PID;IO_VALUE;CMD
get_all_io_stats() {
    if command -v iotop &>/dev/null;
    then
        iotop -b -P -n 1 | awk 'NR > 1 && $1 ~ /^[0-9]+$/ {
            pid=$1; read=$4; write=$6; cmd=$NF;
            gsub(/K|M|G/, "", read); gsub(/K|M|G/, "", write);
            if (read ~ /^[0-9.]+$/) { read_val = read; } else { read_val = 0; }
            if (write ~ /^[0-9.]+$/) { write_val = write; } else { write_val = 0; }

            if (index($4, "K")) read_val = read_val / 1024;
            else if (index($4, "G")) read_val = read_val * 1024;

            if (index($6, "K")) write_val = write_val / 1024;
            else if (index($6, "G")) write_val = write_val * 1024;

            total_io = read_val + write_val;
            print pid ";" total_io ";" cmd
        }'
    else
        ps -eo pid,io,args --no-headers | awk '{print $1 ";" $2 ";" $3}'
    fi
}

# Função para analisar e permitir kill seletivo de processos pesados (com agregação por CMD)
analyze_and_kill_heavy_processes() {
    log_message "INFO" "Iniciando análise de processos pesados com agregação por CMD..."
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}         Análise de Processos Pesados             ${NC}"
    echo -e "${CYAN}         (Agregado por Comando - CMD)             ${NC}"
    echo -e "${CYAN}====================================================${NC}"

    declare -A cmd_cpu_usage
    declare -A cmd_mem_usage
    declare -A cmd_io_usage
    declare -A cmd_pids # Mapeia CMD para uma lista de PIDs
    declare -A all_pids_details # Mapeia PID para detalhes: %CPU;%MEM;CMD

    local item_counter=0

    local current_cpu_temp=$(get_cpu_temp)
    if [[ "$current_cpu_temp" -gt "$TEMP_THRESHOLD" ]]; then
        echo -e "${RED}${BOLD}🔥 ALERTA: Temperatura da CPU (${current_cpu_temp}°C) está ACIMA do limite (${TEMP_THRESHOLD}°C)!${NC}"
        echo -e "  Considere executar: $0 --cpu-cooldown para reduzir a carga.${NC}"
        log_message "WARNING" "CPU Hot: ${current_cpu_temp}°C. Recomendar cooldown."
    fi
    echo -e "${BLUE}Coletando e agregando dados em tempo real (pode levar alguns segundos)...${NC} 
"

    # Coleta de CPU e Memória
    ps aux --no-headers | while read user pid cpu mem vsz rss tty stat start time cmd;
    do
        # Use o nome do comando como chave de agregação
        # Para comandos com argumentos, pegamos apenas o executável (ex: /usr/bin/python -> python)
        local base_cmd=$(basename "$cmd")

        # Agregação
        cmd_cpu_usage["$base_cmd"]=$(echo "${cmd_cpu_usage["$base_cmd"]:-0} + $cpu" | bc)
        cmd_mem_usage["$base_cmd"]=$(echo "${cmd_mem_usage["$base_cmd"]:-0} + $mem" | bc)
        cmd_pids["$base_cmd"]+="$pid "
        all_pids_details["$pid"]="$cpu;$mem;$base_cmd"
    done

    # Coleta de I/O
    get_all_io_stats | while IFS=';' read pid io_val cmd_io;
    do
        local base_cmd_io=$(basename "$cmd_io")
        cmd_io_usage["$base_cmd_io"]=$(echo "${cmd_io_usage["$base_cmd_io"]:-0} + $io_val" | bc)
        # Se o PID já foi processado por ps aux, atualiza/adiciona a info de I/O
        if [[ -n "${all_pids_details["$pid"]}" ]]; then
            all_pids_details["$pid"]+=";$io_val"
        else # Caso iotop pegue um processo que ps aux não pegou na mesma rodada
            # Isso é menos provável para o top, mas é uma contingência
            local cpu_val=0.0; local mem_val=0.0;
            local cmd_from_pid=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ' || echo "$base_cmd_io")
            all_pids_details["$pid"]="$cpu_val;$mem_val;$cmd_from_pid;$io_val"
            cmd_pids["$cmd_from_pid"]+="$pid " # Garante que o CMD tenha o PID associado
        fi
    done

    # --- Apresentação dos Top 5 (agregado por CMD) ---

    # --- CPU ---
    echo -e "${MAGENTA}--- TOP 5 CONSUMIDORES DE CPU (Agregado por CMD) ---${NC}"
    echo -e "  ${YELLOW}Nº  %CPU  COMANDO${NC}"
    local top_cpu_cmds=$(for cmd in "${!cmd_cpu_usage[@]}"; do echo "${cmd_cpu_usage["$cmd"]} $cmd"; done | sort -nr | head -n 5)
    if [ -z "$top_cpu_cmds" ]; then
        echo "  Nenhum processo consumindo CPU notavelmente."
    else
        echo "$top_cpu_cmds" | while read cpu_percent cmd;
        do
            item_counter=$((item_counter + 1))
            printf "%2d) %-5s %s\n" "$item_counter" "$cpu_percent" "$cmd"
            all_pids_to_kill["$item_counter"]="CMD:$cmd"
        done
    fi
    echo ""

    # --- MEMÓRIA ---
    echo -e "${MAGENTA}--- TOP 5 CONSUMIDORES DE MEMÓRIA (Agregado por CMD) ---${NC}"
    echo -e "  ${YELLOW}Nº  %MEM  COMANDO${NC}"
    local top_mem_cmds=$(for cmd in "${!cmd_mem_usage[@]}"; do echo "${cmd_mem_usage["$cmd"]} $cmd"; done | sort -nr | head -n 5)
    if [ -z "$top_mem_cmds" ]; then
        echo "  Nenhum processo consumindo memória notavelmente."
    else
        echo "$top_mem_cmds" | while read mem_percent cmd;
        do
            item_counter=$((item_counter + 1))
            printf "%2d) %-5s %s\n" "$item_counter" "$mem_percent" "$cmd"
            all_pids_to_kill["$item_counter"]="CMD:$cmd"
        done
    fi
    echo ""

    # --- I/O ---
    echo -e "${MAGENTA}--- TOP 5 CONSUMIDORES DE I/O (Agregado por CMD) ---${NC}"
    echo -e "  ${YELLOW}Nº  I/O(MB) COMANDO${NC}"
    local top_io_cmds=$(for cmd in "${!cmd_io_usage[@]}"; do echo "${cmd_io_usage["$cmd"]} $cmd"; done | sort -nr | head -n 5)
    if [ -z "$top_io_cmds" ]; then
        echo "  Nenhum processo consumindo I/O notavelmente."
        echo -e "  (Garanta que 'iotop' esteja instalado para dados de I/O em tempo real mais precisos)."
    else
        echo "$top_io_cmds" | while read io_val cmd;
        do
            item_counter=$((item_counter + 1))
            printf "%2d) %-9s %s\n" "$item_counter" "${io_val}MB" "$cmd"
            all_pids_to_kill["$item_counter"]="CMD:$cmd"
        done
    fi
    echo ""

    if [ "$item_counter" -eq 0 ]; then
        echo -e "${GREEN}✓ Nenhuma atividade significativa de processos pesados detectada.${NC}"
        return 0
    fi

    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${CYAN}  Selecione os NÚMEROS dos COMANDOS para TERMINAR   ${NC}"
    echo -e "${YELLOW}(Ex: 1 3 5 ou 'all' para todos, 'c' para cooldown, 'q' para sair)${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    read -p "$(echo -e "${GREEN}Sua escolha > ${NC}")" selection

    if [[ "$selection" =~ ^[Qq]$ ]]; then
        log_message "INFO" "Usuário optou por sair da seleção de processos."
        echo -e "${BLUE}Análise concluída. Nenhum processo terminado.${NC}"
        return 0
    elif [[ "$selection" =~ ^[Cc]$ ]]; then
        log_message "INFO" "Usuário solicitou cooldown da CPU."
        cpu_cooldown_action
        log_message "INFO" "Análise de processos pesados concluída após cooldown."
        return 0
    elif [[ "$selection" =~ ^[Aa][Ll][Ll]$ ]]; then
        log_message "WARNING" "Usuário selecionou TODOS os processos agregados para terminação."
        local selected_cmds_for_kill=""
        for i in $(seq 1 "$item_counter"); do
            selected_cmds_for_kill+="$(echo "${all_pids_to_kill["$i"]}" | cut -d':' -f2) "
        done
    else
        local selected_cmds_for_kill=""
        for num in $selection;
        do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$item_counter" ]; then
                selected_cmds_for_kill+="$(echo "${all_pids_to_kill["$num"]}" | cut -d':' -f2) "
            else
                echo -e "${RED}✗ Seleção inválida: '$num'. Ignorando.${NC}"
                log_message "WARNING" "Seleção inválida de comando: '$num'."
            fi
        done
    fi

    if [ -z "$selected_cmds_for_kill" ]; then
        echo -e "${BLUE}Nenhum comando válido selecionado. Nenhum processo terminado.${NC}"
        return 0
    fi

    local pids_to_kill_final=""
    echo -e "
${YELLOW}Detalhes dos processos a serem terminados (PIDs individuais):${NC}"
    echo -e "${YELLOW}PID   %CPU  %MEM  COMANDO${NC}"
    for cmd_to_kill in $selected_cmds_for_kill;
    do
        log_message "INFO" "Comando selecionado para kill: $cmd_to_kill"
        local pids_for_this_cmd="${cmd_pids["$cmd_to_kill"]}"
        for pid in $pids_for_this_cmd;
        do
            if is_pid_active "$pid"; then
                pids_to_kill_final+="$pid "
                local details="${all_pids_details["$pid"]}"
                local cpu_val=$(echo "$details" | cut -d';' -f1)
                local mem_val=$(echo "$details" | cut -d';' -f2)
                local io_val_detail=$(echo "$details" | cut -d';' -f4 || echo "N/A") # IO pode não existir

                # Re-fetch command name in case it's long and ps aux truncated it
                local full_cmd_name=$(ps -p "$pid" -o cmd= --no-headers 2>/dev/null || echo "$cmd_to_kill")

                printf "% -5s %-5s %-5s %s\n" "$pid" "$cpu_val" "$mem_val" "$full_cmd_name"
            fi
        done
    done

    if [ -z "$pids_to_kill_final" ]; then
        echo -e "${BLUE}Nenhum PID ativo encontrado para os comandos selecionados. Nenhum processo terminado.${NC}"
        return 0
    fi

    read -p "$(echo -e "${RED}CONFIRMAR A TERMINAÇÃO DESTES PROCESSOS (PIDs listados acima)? (s/N) > ${NC}")" confirm_kill
    if [[ "$confirm_kill" =~ ^[Ss]$ ]]; then
        log_message "WARNING" "Confirmação de kill recebida para PIDs: $pids_to_kill_final."
        echo -e "${RED}Iniciando terminação dos processos selecionados...${NC}"
        local killed_success=0
        local killed_failure=0
        for pid_to_kill in $pids_to_kill_final;
        do
            local proc_name_to_kill=$(ps -p "$pid_to_kill" -o comm= | tr -d ' ' || echo "desconhecido")
            if kill_process "$pid_to_kill" "$proc_name_to_kill"; then
                killed_success=$((killed_success + 1))
            else
                killed_failure=$((killed_failure + 1))
            fi
        done
        echo -e "${CYAN}
--- Relatório Final de Terminação ---${NC}"
        echo -e "${GREEN}✓ Processos terminados com sucesso: $killed_success${NC}"
        echo -e "${RED}✗ Falha ao terminar processos: $killed_failure${NC}"
    else
        log_message "INFO" "Terminação de processos cancelada pelo usuário."
        echo -e "${BLUE}Terminação cancelada. Nenhum processo foi encerrado.${NC}"
    fi

    log_message "INFO" "Análise de processos pesados concluída."
}


# --- Lógica principal ---
if [ "$#" -eq 0 ]; then
    usage
fi

case "$1" in
    --clean-zombies)
        clean_zombies
        exit $?
        ;;
    --heavy-analysis)
        analyze_and_kill_heavy_processes
        clean_zombies # Tentar limpar zumbis após a análise e kill
        exit $?
        ;;
    --nix-kill-fast)
        log_message "WARNING" "Usuário solicitou terminação rápida de builds Nix."
        echo -e "${YELLOW}⚠️  ATENÇÃO: Esta opção terminará TODOS os builds Nix detectados imediatamente!${NC}"
        read -p "$(echo -e "${RED}CONFIRMAR TERMINAÇÃO RÁPIDA DE BUILDS NIX? (s/N) > ${NC}")" confirm_nix_kill
        if [[ "$confirm_nix_kill" =~ ^[Ss]$ ]]; then
            kill_nix_builds
        else
            log_message "INFO" "Terminação rápida de builds Nix cancelada pelo usuário."
            echo -e "${BLUE}Terminação rápida de builds Nix cancelada.${NC}"
        fi
        clean_zombies # Tentar limpar zumbis após a operação
        exit $?
        ;;
    --cpu-cooldown)
        log_message "INFO" "Usuário solicitou cooldown da CPU."
        cpu_cooldown_action
        exit $?
        ;;
    --cpu-temp-only)
        get_cpu_temp
        exit $?
        ;;
    *)
        TARGET="$1"

        # Verificar se é um PID
        if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
            PID="$TARGET"
            if is_pid_active "$PID"; then
                PROC_NAME=$(ps -p "$PID" -o comm= | tr -d ' ')
                log_message "INFO" "Argumento '$TARGET' interpretado como PID. Processo: $PROC_NAME"
                kill_process "$PID" "$PROC_NAME"
            else
                log_message "ERROR" "PID '$PID' não encontrado ou inativo."
                echo -e "${RED}✗ Erro: PID '$PID' não encontrado ou inativo.${NC}"
                exit 1
            fi
        else # É um nome de processo
            PROC_NAME="$TARGET"
            log_message "INFO" "Argumento '$TARGET' interpretado como nome de processo."
            PIDS=$(pgrep -d ' ' "$PROC_NAME")

            if [ -z "$PIDS" ]; then
                log_message "INFO" "Nenhum processo encontrado com o nome '$PROC_NAME'."
                echo -e "${YELLOW}ℹ Nenhum processo encontrado com o nome '$PROC_NAME'.${NC}"
                exit 0
            fi

            log_message "INFO" "PIDs encontrados para '$PROC_NAME': $PIDS"
            echo -e "${YELLOW}PIDs encontrados para '$PROC_NAME': $PIDS. Terminando...${NC}"

            SUCCESS=0
            FAILURE=0
            for PID in $PIDS;
            do
                if kill_process "$PID" "$PROC_NAME"; then
                    SUCCESS=$((SUCCESS + 1))
                else
                    FAILURE=$((FAILURE + 1))
                fi
            done

            if [ "$FAILURE" -eq 0 ]; then
                log_message "SUCCESS" "Todos os $SUCCESS processos de '$PROC_NAME' terminados com sucesso."
                echo -e "${GREEN}✓ Todos os $SUCCESS processos de '$PROC_NAME' terminados.${NC}"
            elif [ "$SUCCESS" -eq 0 ]; then
                log_message "ERROR" "Falha ao terminar todos os processos de '$PROC_NAME'."
                echo -e "${RED}✗ Falha ao terminar processos de '$PROC_NAME'.${NC}"
                exit 1
            else
                log_message "WARNING" "$SUCCESS processos de '$PROC_NAME' terminados, mas $FAILURE falharam."
                echo -e "${YELLOW}ℹ $SUCCESS processos de '$PROC_NAME' terminados, $FAILURE falharam.${NC}"
                exit 1
            fi
        fi
        ;;
esac

# Tentar limpar zumbis após a operação principal, se não foi a função --heavy-analysis ou --nix-kill-fast que o fez.
if [[ "$1" != "--heavy-analysis" ]] && [[ "$1" != "--nix-kill-fast" ]]; then
    clean_zombies
fi

exit 0