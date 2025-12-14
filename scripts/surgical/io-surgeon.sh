#!/usr/bin/env bash
# io-surgeon.sh - Diagnóstico cirúrgico de IO e Memória
# Foca em: ZRAM Efficiency, Dirty Pages Bloat, e IO Wait por Processo

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== IO SURGEON REPORT ===${NC}"

# 1. ZRAM Status (O Salvador do Desktop)
echo -e "\n${YELLOW}1. ZRAM Efficiency (Memory Compression)${NC}"
if command -v zramctl &> /dev/null; then
    zramctl --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR,TOTAL,STREAMS,MOUNTPOINT | grep -v NAME
    
    # Check Compression Ratio
    DATA=$(zramctl --output DATA --bytes --noheadings | tr -d ' ')
    TOTAL=$(zramctl --output TOTAL --bytes --noheadings | tr -d ' ')
    if [ ! -z "$DATA" ] && [ "$DATA" -gt 0 ]; then
        RATIO=$(echo "scale=2; $DATA / $TOTAL" | bc)
        echo -e "Compression Ratio: ${GREEN}${RATIO}x${NC} (Higher is better)"
    else
        echo "ZRAM empty or not used yet."
    fi
else
    echo -e "${RED}zramctl not found!${NC}"
fi

# 2. Dirty Pages (O Assassino Silencioso)
# Se isso estiver alto (>300MB), o sistema vai travar quando tentar escrever no disco.
echo -e "\n${YELLOW}2. Writeback Pressure (Dirty Pages)${NC}"
DIRTY=$(grep -e "Dirty:" -e "Writeback:" /proc/meminfo)
echo "$DIRTY"
DIRTY_VAL=$(echo "$DIRTY" | grep "Dirty" | awk '{print $2}')
if [ "$DIRTY_VAL" -gt 300000 ]; then
    echo -e "${RED}WARNING: High Dirty Pages count! System may stall on sync.${NC}"
else
    echo -e "${GREEN}Writeback buffer is healthy.${NC}"
fi

# 3. PSI (IO Pressure Stall Information)
echo -e "\n${YELLOW}3. IO Pressure Stalls (Last 10s)${NC}"
if [ -f /proc/pressure/io ]; then
    cat /proc/pressure/io
    AVG10=$(awk -F 'avg10=' '{print $2}' /proc/pressure/io | awk '{print $1}')
    if (( $(echo "$AVG10 > 10.0" | bc -l) )); then
         echo -e "${RED}CRITICAL: Programs are waiting >10% of time for Disk IO!${NC}"
    fi
else
    echo "PSI not supported on this kernel."
fi

# 4. Top IO Consumers (Quem está matando o disco?)
echo -e "\n${YELLOW}4. Top 5 Processes BLOCKING IO (Waiting)${NC}"
# PID, User, %Wait, Command
ps -eo pid,user,wchan:20,comm --sort=-wchan | grep -v "0" | head -n 6
