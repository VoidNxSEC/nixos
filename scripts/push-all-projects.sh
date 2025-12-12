#!/usr/bin/env bash
# push-all-projects.sh - Create GitHub repos and push all projects
# Uses gh CLI (GitHub CLI)

set -euo pipefail

PROJECTS_DIR="$HOME/dev/projects"
ORG="VoidNxSEC"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Push All Projects to GitHub (${ORG})                        ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check gh is authenticated
if ! gh auth status &>/dev/null; then
    echo -e "${RED}✗ GitHub CLI not authenticated. Run: gh auth login${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} GitHub CLI authenticated"
echo ""

# Projects to push
PROJECTS=(
    "securellm-mcp:MCP server for IDE integration with NixOS"
    "securellm-bridge:Secure LLM proxy with enterprise security"
    "cognitive-vault:Secure password manager"
    "vmctl:VM management CLI for libvirt"
    "spider-nix:Enterprise web crawler"
    "i915-governor:Intel iGPU memory governor"
)

for entry in "${PROJECTS[@]}"; do
    project="${entry%%:*}"
    description="${entry#*:}"
    
    dir="$PROJECTS_DIR/$project"
    
    if [ ! -d "$dir" ]; then
        echo -e "  ${RED}✗${NC} $project - directory not found"
        continue
    fi
    
    echo -e "${YELLOW}→ $project${NC}"
    cd "$dir"
    
    # Check if repo already exists on GitHub
    if gh repo view "$ORG/$project" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Repo already exists on GitHub"
        
        # Just push if local has commits
        if git rev-parse HEAD &>/dev/null; then
            git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || echo "  Already up to date"
        fi
    else
        # Create repo and push
        echo -e "  Creating repo..."
        
        # Stage and commit if needed
        git add -A
        git commit -m "Initial commit" 2>/dev/null || true
        
        # Create repo on GitHub
        gh repo create "$ORG/$project" --public --description "$description" --source=. --push
        
        echo -e "  ${GREEN}✓${NC} Created and pushed!"
    fi
    
    echo ""
done

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Done!${NC} All projects pushed to github.com/${ORG}"
echo ""
echo -e "Now run in /etc/nixos:"
echo -e "  ${CYAN}nix flake update${NC}"
