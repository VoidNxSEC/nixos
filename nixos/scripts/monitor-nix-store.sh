#!/usr/bin/env bash
#
# monitor-nix-store.sh
# Monitora logs do Nix Store e Rebuild em tempo real.
#
# Uso:
#   ./monitor-nix-store.sh [live|rebuild]
#
#   live    - (Padrão) Monitora logs do daemon via journalctl.
#             Útil para ver o que o Nix está baixando ou compilando em segundo plano
#             independente de quem iniciou o processo (nix-shell, rebuild, etc).
#
#   rebuild - Executa um 'nixos-rebuild switch' completo, mas usando
#             o 'nix-output-monitor' (nom) para uma visualização gráfica detalhada
#             do que está acontecendo no store.
#

MODE="${1:-live}"
set -o pipefail

# Cores
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

if [ "$MODE" == "live" ]; then
    echo -e "${BLUE}=== Diagnóstico de Rebuild em Andamento ===${RESET}"

    # Verificação de Processos
    if pgrep -f "nixos-rebuild" > /dev/null; then
        PIDS=$(pgrep -f "nixos-rebuild" | tr '\n' ' ')
        echo -e "Status 'nixos-rebuild': ${GREEN}EM EXECUÇÃO${RESET} (PIDs: $PIDS)"
    else
        echo -e "Status 'nixos-rebuild': ${RED}NÃO ENCONTRADO${RESET}"
        echo -e "${YELLOW}Nota: Se o processo pai morreu, o daemon ainda pode estar finalizando o trabalho.${RESET}"
    fi

    # Verificação do Daemon
    if pgrep -x "nix-daemon" > /dev/null; then
        CPU=$(ps -o %cpu= -p $(pgrep -x nix-daemon | head -1) | tr -d ' ')
        echo -e "Status 'nix-daemon':    ${GREEN}ATIVO${RESET} (CPU: ${CPU}%)"
    fi
    echo ""

    echo -e "${BLUE}=== Monitorando Logs do Store (Ctrl+C para sair) ===${RESET}"
    
    # Verifica se estamos rodando como root ou usuário com acesso ao journal
    if ! journalctl -u nix-daemon -n 1 &>/dev/null; then
        echo -e "${YELLOW}Aviso: Pode ser necessário sudo para ver logs do daemon.${RESET}"
    fi

    # Monitora o daemon. O grep filtra mensagens de Garbage Collection que podem ser ruidosas.
    # O sed adiciona cores básicas para facilitar leitura rápida.
    journalctl -u nix-daemon -f -o cat | \
        grep --line-buffered -v "triggering GC" | \
        sed --unbuffered \
            -e "s/building/$(printf $YELLOW)building$(printf $RESET)/g" \
            -e "s/downloading/$(printf $BLUE)downloading$(printf $RESET)/g" \
            -e "s/copying/$(printf $GREEN)copying$(printf $RESET)/g" \
            -e "s/error/$(printf $RED)error$(printf $RESET)/g" \
            -e "s/failed/$(printf $RED)failed$(printf $RESET)/g"
            
elif [ "$MODE" == "rebuild" ]; then
    echo -e "${BLUE}=== Iniciando NixOS Rebuild com Monitoramento Otimizado ===${RESET}"
    
    if command -v nom &> /dev/null; then
        echo -e "${GREEN}Detectado: nix-output-monitor (nom)${RESET}"
        echo "Usando visualização gráfica..."
        # Executa o rebuild passando logs em JSON para o nom processar
        sudo nixos-rebuild switch --log-format internal-json -v |& nom --json
    else
        echo -e "${YELLOW}Aviso: 'nom' (nix-output-monitor) não encontrado no PATH.${RESET}"
        echo "Recomendação: Adicione 'nix-output-monitor' aos seus pacotes."
        echo "Usando fallback para log padrão verbose..."
        sudo nixos-rebuild switch -v
    fi
else
    echo "Opção inválida: $MODE"
    echo "Uso: $0 [live|rebuild]"
    exit 1
fi
