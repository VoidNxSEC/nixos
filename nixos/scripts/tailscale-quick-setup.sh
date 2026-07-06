#!/usr/bin/env bash
# Tailscale Quick Setup - Post-rebuild configuration
# Run this after nixos-rebuild to complete Tailscale setup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Tailscale Quick Setup - Post-Rebuild Config       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
  echo -e "${RED}Please run as normal user (not root)${NC}"
  echo "This script will use sudo when needed"
  exit 1
fi

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
  echo -e "${RED}✗ Tailscale is not installed${NC}"
  echo ""
  echo "Please run: sudo nixos-rebuild switch --flake .#nx"
  exit 1
fi

echo -e "${GREEN}✓ Tailscale is installed${NC}"
echo ""

# Check if tailscaled is running
if ! systemctl is-active --quiet tailscaled; then
  echo -e "${YELLOW}Starting tailscaled service...${NC}"
  sudo systemctl start tailscaled
  sleep 2
fi

if systemctl is-active --quiet tailscaled; then
  echo -e "${GREEN}✓ tailscaled service is running${NC}"
else
  echo -e "${RED}✗ Failed to start tailscaled${NC}"
  exit 1
fi
echo ""

# Check if already authenticated
if sudo tailscale status &> /dev/null; then
  echo -e "${GREEN}✓ Tailscale is already authenticated${NC}"
  echo ""
  echo -e "${CYAN}Current Status:${NC}"
  sudo tailscale status | head -5
  echo ""
  
  read -p "Do you want to re-authenticate? (y/N): " reauth
  if [[ ! "$reauth" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Setup complete! Your Tailscale is ready.${NC}"
    echo ""
    echo -e "${CYAN}Useful commands:${NC}"
    echo -e "  ${BOLD}my-ips${NC}          - Show all your IPs and info"
    echo -e "  ${BOLD}ts-status${NC}       - Tailscale status"
    echo -e "  ${BOLD}docker-ts-urls${NC}  - URLs of Docker containers"
    exit 0
  fi
  
  echo ""
  echo -e "${YELLOW}Re-authenticating...${NC}"
fi

# Authenticate
echo -e "${BLUE}${BOLD}Step 1: Authenticate with Tailscale${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will open your browser for authentication."
echo "Login with Google, GitHub, or Microsoft account."
echo ""
read -p "Press Enter to continue..."
echo ""

echo -e "${CYAN}Running: sudo tailscale up${NC}"
sudo tailscale up

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Authentication successful!${NC}"
else
  echo ""
  echo -e "${RED}✗ Authentication failed${NC}"
  echo "Please check the error messages above"
  exit 1
fi

sleep 2

# Show status
echo ""
echo -e "${BLUE}${BOLD}Step 2: Verification${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${CYAN}Your Tailscale Information:${NC}"
echo ""

TSIP=$(tailscale ip -4 2>/dev/null || echo "N/A")
TSHOST=$(tailscale status 2>/dev/null | grep $(hostname) | awk '{print $2}' || echo "N/A")
LOCALIP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1 || echo "N/A")

echo -e "  ${GREEN}✓${NC} Tailscale IP: ${BOLD}$TSIP${NC}"
echo -e "  ${GREEN}✓${NC} Hostname: ${BOLD}$TSHOST${NC}"
echo -e "  ${GREEN}✓${NC} Local IP: ${BOLD}$LOCALIP${NC}"
echo ""

# Show peers if any
PEER_COUNT=$(tailscale status --peers 2>/dev/null | wc -l || echo "0")
if [ "$PEER_COUNT" -gt 0 ]; then
  echo -e "${CYAN}Connected Devices:${NC}"
  tailscale status --peers | head -5
  echo ""
fi

# Next steps
echo ""
echo -e "${BLUE}${BOLD}Step 3: Next Steps${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}📱 Setup on other devices:${NC}"
echo ""
echo "1. Install Tailscale app on phone/tablet"
echo "2. Login with same account"
echo "3. Enable 'Accept routes' in settings"
echo ""

echo -e "${YELLOW}🖥️  Setup Desktop (when available):${NC}"
echo ""
echo "1. Add to configuration.nix:"
echo "   imports = [ ../../modules/network/vpn/tailscale-desktop.nix ];"
echo ""
echo "2. Adjust subnet in tailscale-desktop.nix if needed"
echo "   (default is 192.168.1.0/24)"
echo ""
echo "3. Rebuild: sudo nixos-rebuild switch"
echo "4. Authenticate: sudo tailscale up"
echo "5. IMPORTANT: Approve subnet routes in dashboard:"
echo "   https://login.tailscale.com/admin/machines"
echo ""

echo -e "${YELLOW}🐳 Docker + Tailscale:${NC}"
echo ""
echo "Run any container: docker run -d -p 8080:8080 your-image"
echo "Access from anywhere: http://$TSIP:8080"
echo "Or use hostname: http://$TSHOST:8080"
echo ""
echo "See URLs: ${BOLD}docker-ts-urls${NC}"
echo ""

echo -e "${YELLOW}📚 Documentation:${NC}"
echo ""
echo "  • Complete Guide: docs/TAILSCALE-COMPLETE-SETUP.md"
echo "  • Quick Start: docs/TAILSCALE-QUICKSTART-GUIDE.md"
echo "  • Subnet Routing: docs/TAILSCALE-SUBNET-ROUTING-GUIDE.md"
echo ""

echo -e "${YELLOW}🎯 Useful Commands:${NC}"
echo ""
echo "  ${BOLD}my-ips${NC}          - Show all IPs and network info"
echo "  ${BOLD}ts-status${NC}       - Tailscale connection status"
echo "  ${BOLD}ts-ip${NC}           - Your Tailscale IP"
echo "  ${BOLD}ts-hostname${NC}     - Your Tailscale hostname"
echo "  ${BOLD}ts-url${NC}          - Base HTTP URL (add :port)"
echo "  ${BOLD}docker-ts-urls${NC}  - URLs of all Docker containers"
echo "  ${BOLD}ts-ping${NC} <host>  - Ping another Tailscale device"
echo "  ${BOLD}ts-check${NC}        - Quick connectivity check"
echo ""

echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              ✓ Tailscale Setup Complete!                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Your network is now secure and accessible from anywhere! 🎉${NC}"
echo ""