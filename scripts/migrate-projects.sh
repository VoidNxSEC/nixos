#!/usr/bin/env bash
# migrate-projects.sh - Move projects from /etc/nixos/projects to ~/dev/projects
# Clean migration: excludes node_modules, build artifacts, databases

set -euo pipefail

SOURCE_DIR="/etc/nixos/projects"
TARGET_DIR="$HOME/dev/projects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Project Migration: /etc/nixos/projects → ~/dev/projects     ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"
echo -e "${GREEN}✓${NC} Created $TARGET_DIR"

# Projects to migrate
PROJECTS=(
    "securellm-mcp"
    "securellm-bridge"
    "cognitive-vault"
    "vmctl"
    "spider-nix"
    "i915-governor"
)

# Exclusions for rsync (artifacts to skip)
EXCLUDES=(
    "node_modules"
    "build"
    "target"
    "dist"
    ".git"
    "__pycache__"
    "*.pyc"
    "*.db"
    "*.db-shm"
    "*.db-wal"
    ".direnv"
    ".devenv"
    "result"
    "result-*"
)

# Build exclude args
EXCLUDE_ARGS=""
for ex in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$ex"
done

echo ""
echo -e "${YELLOW}Migrating projects (excluding artifacts):${NC}"
echo ""

for project in "${PROJECTS[@]}"; do
    src="$SOURCE_DIR/$project"
    dst="$TARGET_DIR/$project"
    
    if [ -d "$src" ]; then
        echo -n "  → $project... "
        
        # Use rsync for clean copy with exclusions
        rsync -a $EXCLUDE_ARGS "$src/" "$dst/"
        
        # Initialize git if not present
        if [ ! -d "$dst/.git" ]; then
            (cd "$dst" && git init -q)
            echo -e "${GREEN}✓${NC} (git initialized)"
        else
            echo -e "${GREEN}✓${NC}"
        fi
    else
        echo -e "  → $project... ${RED}NOT FOUND${NC}"
    fi
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Migration complete!${NC}"
echo ""
echo -e "Projects are now in: ${CYAN}$TARGET_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps for each project:${NC}"
echo "  1. cd ~/dev/projects/<project>"
echo "  2. git add -A && git commit -m 'Initial commit'"
echo "  3. gh repo create VoidNxSEC/<project> --public --source=."
echo "  4. git push -u origin main"
echo ""
echo -e "${YELLOW}After pushing to GitHub, update flake.nix inputs:${NC}"
echo '  securellm-mcp.url = "github:VoidNxSEC/securellm-mcp";'
echo '  spider-nix.url = "github:VoidNxSEC/spider-nix";'
echo "  # etc..."
echo ""
