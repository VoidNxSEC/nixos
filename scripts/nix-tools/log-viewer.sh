#!/usr/bin/env bash
# log-viewer.sh - Visualizador de Logs Inteligente e Colorido

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SERVICE="$1"
shift

if [ -z "$SERVICE" ]; then
    echo -e "${YELLOW}Usage:${NC} $(basename "$0") <service_name|keyword> [journalctl_args]"
    echo -e "${BLUE}  Example:${NC} $(basename "$0") suricata"
    echo -e "${BLUE}  Example:${NC} $(basename "$0") OOM"
    echo -e "${BLUE}  Example:${NC} $(basename "$0") docker -f${NC}"
    exit 1
fi

# Function to colorize journalctl output
colorize_log() {
    while IFS= read -r line; do
        if [[ "$line" =~ "error"|"fail"|"failed"|"failure"|"killed"|"kill"|"shutdown"|"shutting down"|"down"|"segfault"|"crit"|"alert"|"emerg"|"traceback"|"exception"|"fatal" ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" =~ "warn"|"warning"|"W:" ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ "$line" =~ "info"|"I:" ]]; then
            echo -e "${BLUE}$line${NC}"
        elif [[ "$line" =~ "start"|"starting"|"activate"|"activated"|"up"|"success"|"succeeded" ]]; then
            echo -e "${GREEN}$line${NC}"
        else
            echo -e "$line"
        fi
    done
}

# Check if it's a known service
if systemctl list-units --type=service --all | grep -qw "$SERVICE"; then
    echo -e "${CYAN}${BOLD}--- Journal for service: $SERVICE ---${NC}"
    journalctl -u "$SERVICE" -e -n 100 --no-pager "$@" | colorize_log
elif [[ "$SERVICE" == "kernel" || "$SERVICE" == "dmesg" ]]; then
    echo -e "${CYAN}${BOLD}--- Kernel Messages (dmesg) ---${NC}"
    dmesg -T | colorize_log
else # Assume keyword search
    echo -e "${CYAN}${BOLD}--- Journal search for keyword: $SERVICE ---${NC}"
    journalctl -g "$SERVICE" --since "1 hour ago" -e -n 100 --no-pager "$@" | colorize_log
fi
