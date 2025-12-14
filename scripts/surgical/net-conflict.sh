#!/usr/bin/env bash
# net-conflict.sh - Monitor de Conflitos de Interface (VPN vs Físico vs IDS)
# Detecta: MTU Mismatches, TX drops (Tailscale vs Wifi), e erros de Driver

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== NETWORK CONFLICT WAR ROOM ===${NC}"

# Detecta interfaces
WIFI_IFACE=$(ip link | grep -E 'wlp|wlan' | awk -F: '{print $2}' | tr -d ' ' | head -n1)
VPN_IFACE=$(ip link | grep -E 'tailscale|tun' | awk -F: '{print $2}' | tr -d ' ' | head -n1)
DOCKER_IFACE=$(ip link | grep -E 'docker' | awk -F: '{print $2}' | tr -d ' ' | head -n1)

echo -e "Interfaces Detected:"
echo -e "  Physical: ${BLUE}${WIFI_IFACE:-None}${NC}"
echo -e "  VPN:      ${BLUE}${VPN_IFACE:-None}${NC}"
echo -e "  Docker:   ${BLUE}${DOCKER_IFACE:-None}${NC}"

echo -e "\n${YELLOW}1. MTU Analysis (Fragmentation Risk)${NC}"
if [ ! -z "$WIFI_IFACE" ]; then
    MTU_PHY=$(cat /sys/class/net/$WIFI_IFACE/mtu)
    echo "  $WIFI_IFACE MTU: $MTU_PHY"
fi
if [ ! -z "$VPN_IFACE" ]; then
    MTU_VPN=$(cat /sys/class/net/$VPN_IFACE/mtu)
    echo "  $VPN_IFACE MTU: $MTU_VPN"
    
    if [ "$MTU_VPN" -ge "$MTU_PHY" ]; then
        echo -e "  ${RED}CONFLICT:${NC} VPN MTU ($MTU_VPN) >= Physical MTU ($MTU_PHY). Packet fragmentation will kill performance!"
    else
        echo -e "  ${GREEN}OK:${NC} VPN MTU is smaller (encapsulation safe)."
    fi
fi

echo -e "\n${YELLOW}2. Interface Drops & Errors (The Silent Killer)${NC}"
if [ ! -z "$WIFI_IFACE" ]; then
    echo "Physical ($WIFI_IFACE):"
    ip -s link show $WIFI_IFACE | grep -A1 "RX:" | tail -n2
    DROPS=$(ip -s link show $WIFI_IFACE | grep -A1 "RX:" | tail -n1 | awk '{print $3}')
    if [ "$DROPS" -gt 0 ]; then
        echo -e "${RED}  WARNING: Packet drops detected on physical interface!${NC}"
    fi
fi

echo -e "\n${YELLOW}3. Suricata/IDS Conflict Check${NC}"
if systemctl is-active --quiet suricata; then
    echo -e "Suricata Status: ${GREEN}ACTIVE${NC}"
    
    # Check what interface Suricata is actually sniffing (via lsof/fd)
    SURICATA_PID=$(pgrep suricata | head -n1)
    if [ ! -z "$SURICATA_PID" ]; then
        echo "Suricata is sniffing:"
        ls -l /proc/$SURICATA_PID/fd | grep "socket" | head -n 3
        
        # Check for AF_PACKET errors in dmesg
        if dmesg | tail -n 50 | grep -q "AF_PACKET"; then
             echo -e "${RED}  CRITICAL: Kernel reporting AF_PACKET errors. Driver conflict detected!${NC}"
        else
             echo -e "  Kernel logs clean (no immediate AF_PACKET panic)."
        fi
    fi
else
    echo -e "Suricata Status: ${BLUE}INACTIVE${NC} (Safe from conflict)"
fi

echo -e "\n${YELLOW}4. Tailscale Routing Conflict${NC}"
if [ ! -z "$VPN_IFACE" ]; then
    # Check if we have overlapping routes
    echo "Checking for route overlap:"
    ip route show table main | grep "$VPN_IFACE" | head -n 3
fi
