#!/usr/bin/env bash
# Script para criar os arquivos MCP que faltam após o rebuild

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== MCP Configuration Fix Script ===${NC}"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

# Path do MCP config gerado pelo Nix
MCP_CONFIG_STORE="/nix/store/6bpjhb0mz3kdv8b3ixvv6dvhxm73y4wh-mcp-config.json"

if [ ! -f "$MCP_CONFIG_STORE" ]; then
    echo -e "${RED}Error: MCP config not found in Nix store${NC}"
    echo "Looking for: $MCP_CONFIG_STORE"
    echo ""
    echo "Searching for mcp-config.json in /nix/store..."
    find /nix/store -name "mcp-config.json" -type f 2>/dev/null | head -5
    exit 1
fi

echo -e "${GREEN}✓ Found MCP config in Nix store${NC}"
echo ""

# 1. Fix Roo/Claude Code config
echo -e "${BLUE}1. Creating Roo MCP config...${NC}"
mkdir -p /home/kernelcore/.roo
chown kernelcore:users /home/kernelcore/.roo
chmod 750 /home/kernelcore/.roo

ln -sf "$MCP_CONFIG_STORE" /home/kernelcore/.roo/mcp.json
chown -h kernelcore:users /home/kernelcore/.roo/mcp.json

echo -e "${GREEN}✓ Created /home/kernelcore/.roo/mcp.json${NC}"

# 2. Codex setup (skip - package not downloaded yet)
echo -e "${YELLOW}2. Skipping Codex (package not downloaded yet)${NC}"
echo "   → Download Codex first with: nix run .#packages.tar.download codex"
echo "   → After download, run rebuild to create codex user and service"

# 3. Fix Gemini config
echo -e "${BLUE}3. Creating Gemini MCP config...${NC}"
mkdir -p /var/lib/gemini-agent/.gemini
chown gemini-agent:gemini-agent /var/lib/gemini-agent/.gemini
chmod 750 /var/lib/gemini-agent/.gemini

ln -sf "$MCP_CONFIG_STORE" /var/lib/gemini-agent/.gemini/mcp.json
chown -h gemini-agent:gemini-agent /var/lib/gemini-agent/.gemini/mcp.json

echo -e "${GREEN}✓ Created /var/lib/gemini-agent/.gemini/mcp.json${NC}"

# 4. Create Gemini workspace
echo -e "${BLUE}4. Creating Gemini workspace...${NC}"
mkdir -p /var/lib/gemini-agent/dev
chown gemini-agent:gemini-agent /var/lib/gemini-agent/dev
chmod 750 /var/lib/gemini-agent/dev

echo -e "${GREEN}✓ Created /var/lib/gemini-agent/dev${NC}"

# 5. Verify all configs
echo ""
echo -e "${BLUE}=== Verification ===${NC}"
echo ""

echo -e "${YELLOW}Roo config:${NC}"
ls -lh /home/kernelcore/.roo/mcp.json 2>&1

echo ""
echo -e "${YELLOW}Codex config:${NC}"
ls -lh /var/lib/codex/.codex/mcp.json 2>&1

echo ""
echo -e "${YELLOW}Gemini config:${NC}"
ls -lh /var/lib/gemini-agent/.gemini/mcp.json 2>&1

echo ""
echo -e "${YELLOW}Workspaces:${NC}"
ls -ld /home/kernelcore/dev /var/lib/codex/dev /var/lib/gemini-agent/dev 2>&1

echo ""
echo -e "${GREEN}=== MCP Configuration Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Test Codex MCP connection"
echo "  2. Test Roo/Claude Code MCP connection"  
echo "  3. Test Gemini MCP connection"