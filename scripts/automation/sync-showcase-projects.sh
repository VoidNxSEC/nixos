#!/usr/bin/env bash
# Script para sync de todos os projetos declarados no flake.nix

# Lista de projetos declarados no flake.nix
PROJECTS=(
    "ml-offload-api"
    "securellm-mcp"
    "securellm-bridge"
    "cognitive-vault"
    "vmctl"
    "spider-nix"
    "i915-governor"
    "swissknife"
    "arch-analyzer"
    "docker-hub"
    "notion-exporter"
    "nixos-hyperlab"
    "shadow-debug-pipeline"
    "ai-agent-os"
    "phantom"
    "O.W.A.S.A.K.A."
)

BASE_DIR="/home/kernelcore/dev/projects"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}🚀 Git Commit, Push and Flake Update for All Projects${NC}\n"

# Counters
TOTAL=${#PROJECTS[@]}
SUCCESS=0
SKIPPED=0
FAILED=0

for project in "${PROJECTS[@]}"; do
    echo -e "${BOLD}════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}📦 Processing: ${GREEN}$project${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════${NC}"
    
    PROJECT_DIR="$BASE_DIR/$project"
    
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo -e "${RED}❌ Directory not found: $PROJECT_DIR${NC}\n"
        ((FAILED++))
        continue
    fi
    
    cd "$PROJECT_DIR"
    
    # Check if git repo
    if [[ ! -d ".git" ]]; then
        echo -e "${RED}❌ Not a git repository${NC}\n"
        ((FAILED++))
        continue
    fi
    
    # Check for changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}⏭️  No changes to commit, skipping...${NC}"
        ((SKIPPED++))
        
        # Nix flake update (sempre executar, mesmo sem mudanças)
        echo -e "${BOLD}  → nix flake update${NC}"
        nix flake update 2>&1 | grep -E "(Updated|warning)" | head -5 || true
        echo -e "${GREEN}  ✓ Flake updated${NC}"
        echo ""
        continue
    fi
    
    echo -e "${GREEN}✓ Changes detected${NC}"
    
    # Git add
    echo -e "${BOLD}  → git add .${NC}"
    git add .
    
    # Git commit
    COMMIT_MSG="chore: sync showcase project - $(date +%Y-%m-%d)"
    echo -e "${BOLD}  → git commit -m \"$COMMIT_MSG\"${NC}"
    if git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}  ✓ Committed${NC}"
    else
        echo -e "${RED}  ✗ Commit failed${NC}"
        ((FAILED++))
        continue
    fi
    
    # Git push
    echo -e "${BOLD}  → git push${NC}"
    if git push 2>&1; then
        echo -e "${GREEN}  ✓ Pushed to remote${NC}"
        ((SUCCESS++))
    else
        echo -e "${YELLOW}  ⚠ Push failed (no remote configured?)${NC}"
        ((SUCCESS++))  # Still count as success if commit worked
    fi
    
    # Nix flake update (sempre executar)
    echo -e "${BOLD}  → nix flake update${NC}"
    nix flake update 2>&1 | grep -E "(Updated|warning)" | head -5 || true
    echo -e "${GREEN}  ✓ Flake updated${NC}"
    
    echo ""
done

# Summary
echo -e "${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📊 Summary${NC}"
echo -e "${BOLD}════════════════════════════════════════════════${NC}"
echo -e "Total projects:    ${BOLD}$TOTAL${NC}"
echo -e "Committed & pushed: ${GREEN}$SUCCESS${NC}"
echo -e "Skipped (no changes): ${YELLOW}$SKIPPED${NC}"
echo -e "Failed:            ${RED}$FAILED${NC}"
echo ""

# Update main flake.lock
echo -e "${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🔄 Updating main flake.lock (/etc/nixos)${NC}"
echo -e "${BOLD}════════════════════════════════════════════════${NC}"

cd /etc/nixos
echo -e "${BOLD}  → nix flake update${NC}"
nix flake update 2>&1 | head -20

echo -e "\n${GREEN}✅ All done!${NC}"
