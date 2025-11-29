#!/usr/bin/env bash
# Tailscale Subnet Router Setup Helper
# Facilita configuração de subnet routing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================="
echo -e "  Tailscale Subnet Router Setup"
echo -e "=======================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Error: Please run as root (sudo)${NC}"
  exit 1
fi

# Check if tailscale is installed
if ! command -v tailscale &> /dev/null; then
  echo -e "${RED}Error: Tailscale is not installed${NC}"
  exit 1
fi

# Function to detect local subnets
detect_subnets() {
  echo -e "${YELLOW}Detecting local subnets...${NC}"
  echo ""
  
  local subnets=()
  while IFS= read -r line; do
    # Extract subnet from ip route output
    subnet=$(echo "$line" | awk '{print $1}')
    interface=$(echo "$line" | awk '{print $3}')
    
    # Skip docker/tailscale/loopback interfaces
    if [[ ! "$interface" =~ ^(docker|tailscale|lo) ]]; then
      subnets+=("$subnet")
      echo -e "  ${GREEN}✓${NC} Found: $subnet (interface: $interface)"
    fi
  done < <(ip route | grep "scope link" | grep -v "docker\|tailscale\|169.254")
  
  echo ""
  
  if [ ${#subnets[@]} -eq 0 ]; then
    echo -e "${RED}No suitable subnets found${NC}"
    exit 1
  fi
  
  echo "${subnets[@]}"
}

# Function to check IP forwarding
check_ip_forwarding() {
  local ipv4_forward=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
  local ipv6_forward=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo "0")
  
  echo -e "${YELLOW}Checking IP forwarding...${NC}"
  
  if [ "$ipv4_forward" = "1" ]; then
    echo -e "  ${GREEN}✓${NC} IPv4 forwarding: enabled"
  else
    echo -e "  ${RED}✗${NC} IPv4 forwarding: disabled"
    echo ""
    echo -e "${YELLOW}Enabling IPv4 forwarding temporarily...${NC}"
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo -e "  ${GREEN}✓${NC} IPv4 forwarding enabled"
    echo ""
    echo -e "${YELLOW}Note:${NC} To make this permanent on NixOS, add to configuration.nix:"
    echo -e "  boot.kernel.sysctl.\"net.ipv4.ip_forward\" = 1;"
  fi
  
  if [ "$ipv6_forward" = "1" ]; then
    echo -e "  ${GREEN}✓${NC} IPv6 forwarding: enabled"
  else
    echo -e "  ${YELLOW}!${NC} IPv6 forwarding: disabled (usually ok)"
  fi
  
  echo ""
}

# Main setup
main() {
  # Detect subnets
  subnets=$(detect_subnets)
  subnet_array=($subnets)
  
  # Ask user to select or confirm
  echo -e "${BLUE}Available subnets:${NC}"
  for i in "${!subnet_array[@]}"; do
    echo "  $((i+1)). ${subnet_array[$i]}"
  done
  echo ""
  
  read -p "Select subnet to advertise (1-${#subnet_array[@]}, or 'a' for all): " choice
  echo ""
  
  local routes=""
  if [ "$choice" = "a" ] || [ "$choice" = "A" ]; then
    # Advertise all subnets
    routes=$(IFS=,; echo "${subnet_array[*]}")
    echo -e "${GREEN}Will advertise all subnets: $routes${NC}"
  elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#subnet_array[@]}" ]; then
    # Advertise selected subnet
    routes="${subnet_array[$((choice-1))]}"
    echo -e "${GREEN}Will advertise: $routes${NC}"
  else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
  fi
  echo ""
  
  # Check IP forwarding
  check_ip_forwarding
  
  # Ask for additional options
  echo -e "${BLUE}Additional options:${NC}"
  read -p "Enable SSH over Tailscale? (Y/n): " enable_ssh
  enable_ssh=${enable_ssh:-y}
  
  read -p "Enable MagicDNS? (Y/n): " enable_dns
  enable_dns=${enable_dns:-y}
  
  read -p "Accept routes from other subnet routers? (Y/n): " accept_routes
  accept_routes=${accept_routes:-y}
  echo ""
  
  # Build command
  local cmd="tailscale up --advertise-routes=$routes"
  
  if [[ "$enable_ssh" =~ ^[Yy] ]]; then
    cmd="$cmd --ssh"
  fi
  
  if [[ "$enable_dns" =~ ^[Yy] ]]; then
    cmd="$cmd --accept-dns"
  fi
  
  if [[ "$accept_routes" =~ ^[Yy] ]]; then
    cmd="$cmd --accept-routes"
  fi
  
  # Show command
  echo -e "${YELLOW}Will execute:${NC}"
  echo -e "  $cmd"
  echo ""
  
  read -p "Proceed? (Y/n): " proceed
  proceed=${proceed:-y}
  
  if [[ ! "$proceed" =~ ^[Yy] ]]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
  fi
  
  # Execute
  echo ""
  echo -e "${BLUE}Configuring Tailscale...${NC}"
  $cmd
  
  echo ""
  echo -e "${GREEN}✓ Tailscale configured successfully!${NC}"
  echo ""
  
  # Show next steps
  echo -e "${BLUE}Next steps:${NC}"
  echo ""
  echo -e "1. ${YELLOW}Approve subnet routes in Tailscale dashboard:${NC}"
  echo -e "   https://login.tailscale.com/admin/machines"
  echo -e "   → Find this device → Edit route settings → Enable subnet routes"
  echo ""
  echo -e "2. ${YELLOW}On client devices (laptop, phone, etc):${NC}"
  echo -e "   sudo tailscale up --accept-routes"
  echo ""
  echo -e "3. ${YELLOW}Test connectivity:${NC}"
  echo -e "   tailscale status"
  echo -e "   ping <device-in-subnet>"
  echo ""
  echo -e "4. ${YELLOW}Make permanent on NixOS:${NC}"
  echo -e "   Add to configuration.nix:"
  echo -e "   services.tailscale.extraUpFlags = ["
  echo -e "     \"--advertise-routes=$routes\""
  echo -e "     \"--ssh\""
  echo -e "     \"--accept-dns\""
  echo -e "   ];"
  echo -e "   boot.kernel.sysctl.\"net.ipv4.ip_forward\" = 1;"
  echo ""
  echo -e "${GREEN}Done! Read docs/TAILSCALE-SUBNET-ROUTING-GUIDE.md for more info.${NC}"
}

# Show help
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: sudo $0"
  echo ""
  echo "Interactive setup for Tailscale subnet routing."
  echo "Makes your local network accessible via Tailscale."
  echo ""
  echo "See: docs/TAILSCALE-SUBNET-ROUTING-GUIDE.md"
  exit 0
fi

# Run main
main