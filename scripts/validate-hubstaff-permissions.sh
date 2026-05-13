#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Hubstaff NixOS/Wayland Diagnostics ===${NC}"

# 1. User Groups Check
echo -e "\n${YELLOW}[1] Checking User Groups...${NC}"
REQUIRED_GROUPS=("input" "video")
USER_GROUPS=$(groups $USER)
MISSING_GROUPS=0

for group in "${REQUIRED_GROUPS[@]}"; do
    if [[ $USER_GROUPS == *"$group"* ]]; then
        echo -e "  ${GREEN}✓ User is in group '$group'${NC}"
    else
        echo -e "  ${RED}✗ User is NOT in group '$group'${NC}"
        MISSING_GROUPS=1
    fi
done

if [ $MISSING_GROUPS -eq 1 ]; then
    echo -e "  ${RED}Action Required: Add user to missing groups in configuration.nix${NC}"
else
    echo -e "  ${GREEN}Group permissions look correct.${NC}"
fi

# 2. Wayland Session Check
echo -e "\n${YELLOW}[2] Checking Session Type...${NC}"
echo "  XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "  XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    echo -e "  ${GREEN}✓ Running on Wayland${NC}"
else
    echo -e "  ${YELLOW}! Not running on Wayland (Current: $XDG_SESSION_TYPE)${NC}"
fi

# 3. Portal Check
echo -e "\n${YELLOW}[3] Checking XDG Desktop Portals...${NC}"
PORTALS=$(systemctl --user list-units --type=service | grep xdg-desktop-portal)

if [[ -n "$PORTALS" ]]; then
    echo -e "${GREEN}Active Portals:${NC}"
    echo "$PORTALS"
else
    echo -e "${RED}✗ No xdg-desktop-portal services found running!${NC}"
fi

# 4. Screenshot Tools Check
echo -e "\n${YELLOW}[4] Checking Screenshot Tools (in PATH)...${NC}"
for tool in grim slurp; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}✓ $tool found at $(which $tool)${NC}"
    else
        echo -e "  ${RED}✗ $tool not found in user PATH (It should be in Hubstaff wrapper PATH)${NC}"
    fi
done

echo -e "\n${YELLOW}=== Diagnostics Complete ===${NC}"
