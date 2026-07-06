#!/usr/bin/env bash
# psi-sentinel.sh - O "Canário" de Travamentos
# Monitora Pressure Stall Information (CPU, IO, Memory)
# Se algum desses valores subir, a interface gráfica VAI travar.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== SYSTEM PRESSURE SENTINEL ===${NC}"
echo "Metric: % of time tasks are STALLED waiting for resource (10s avg)"

check_pressure() {
    RESOURCE=$1
    FILE="/proc/pressure/$RESOURCE"
    
    if [ -f "$FILE" ]; then
        # Extrai avg10
        VAL=$(awk -F 'avg10=' '{print $2}' "$FILE" | awk '{print $1}')
        
        # Thresholds
        if (( $(echo "$VAL > 40.0" | bc -l) )); then
            COLOR=$RED
            STATUS="CRITICAL STALL"
        elif (( $(echo "$VAL > 10.0" | bc -l) )); then
            COLOR=$YELLOW
            STATUS="WARNING"
        else
            COLOR=$GREEN
            STATUS="OK"
        fi
        
        printf "% -8s | ${COLOR}% -10s${NC} | Load: %s%%\n" "$RESOURCE" "$STATUS" "$VAL"
    else
        echo "$RESOURCE: Not supported"
    fi
}

echo -e "\nResource | Status     | Stall %"
echo "---------+------------+--------"
check_pressure "cpu"
check_pressure "memory"
check_pressure "io"

echo -e "\n${YELLOW}Interpretation:${NC}"
echo "  CPU Stall > 20%: System feels sluggish."
echo "  Mem Stall > 10%: Swapping hard / Reclaiming cache aggressively."
echo "  IO  Stall > 20%: Disk is the bottleneck (Apps will freeze)."

echo -e "\n${GREEN}Recommended Actions based on current state:${NC}"
IO_VAL=$(awk -F 'avg10=' '{print $2}' /proc/pressure/io 2>/dev/null | awk '{print $1}')
MEM_VAL=$(awk -F 'avg10=' '{print $2}' /proc/pressure/memory 2>/dev/null | awk '{print $1}')

if (( $(echo "$IO_VAL > 15.0" | bc -l) )); then
    echo "  - IO is choking. Check 'scripts/surgical/io-surgeon.sh'."
    echo "  - Stop indexing services (OpenSearch, Baloo, Tracker)."
elif (( $(echo "$MEM_VAL > 15.0" | bc -l) )); then
    echo "  - RAM is choking. Check ZRAM status."
    echo "  - Close Electron apps or reduce browser tabs."
else
    echo "  - System pressure is within healthy limits."
fi
