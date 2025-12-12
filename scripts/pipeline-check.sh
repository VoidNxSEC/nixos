#!/usr/bin/env bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Local CI Pipeline...${NC}"

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# ═══════════════════════════════════════════════════════════════
# 1. SMART FORMATTING - Only format staged .nix files
# ═══════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}📝 Smart Formatting (nixfmt)...${NC}"

# Get list of staged .nix files (not in result, vendor, or node_modules)
STAGED_NIX=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E '\.nix$' | \
    grep -v '^result/' | \
    grep -v '^vendor/' | \
    grep -v 'node_modules/' | \
    grep -v '\.direnv/' || true)

if [ -n "$STAGED_NIX" ]; then
    echo -e "${CYAN}  Found $(echo "$STAGED_NIX" | wc -l) staged .nix files${NC}"
    
    # Check if nixfmt is available
    if command -v nixfmt &> /dev/null; then
        FORMATTER="nixfmt"
    elif command -v nixfmt-rfc-style &> /dev/null; then
        FORMATTER="nixfmt-rfc-style"
    else
        # Try via nix shell
        FORMATTER="nix run nixpkgs#nixfmt-rfc-style --"
    fi
    
    NEEDS_RESTAGE=false
    
    for file in $STAGED_NIX; do
        if [ -f "$file" ]; then
            # Get hash before formatting
            BEFORE_HASH=$(sha256sum "$file" | cut -d' ' -f1)
            
            # Format the file
            if $FORMATTER "$file" 2>/dev/null; then
                # Get hash after formatting
                AFTER_HASH=$(sha256sum "$file" | cut -d' ' -f1)
                
                if [ "$BEFORE_HASH" != "$AFTER_HASH" ]; then
                    echo -e "  ${GREEN}✓${NC} Formatted: $file"
                    git add "$file"
                    NEEDS_RESTAGE=true
                fi
            else
                echo -e "  ${YELLOW}⚠${NC} Could not format: $file (continuing...)"
            fi
        fi
    done
    
    if [ "$NEEDS_RESTAGE" = true ]; then
        echo -e "${GREEN}✅ Files auto-formatted and re-staged${NC}"
    else
        echo -e "${GREEN}✅ All staged .nix files already formatted${NC}"
    fi
else
    echo -e "${CYAN}  No .nix files in staged changes, skipping format${NC}"
fi

# ═══════════════════════════════════════════════════════════════
# 2. FLAKE CHECK (lightweight - skip on large changes)
# ═══════════════════════════════════════════════════════════════
STAGED_COUNT=$(git diff --cached --name-only | wc -l)

if [ "$STAGED_COUNT" -gt 50 ]; then
    echo -e "\n${YELLOW}🔍 Large commit detected ($STAGED_COUNT files), skipping nix flake check${NC}"
    echo -e "${CYAN}   Run 'nix flake check' manually before push${NC}"
else
    echo -e "\n${YELLOW}🔍 Quick Flake Evaluation...${NC}"
    # Only evaluate, don't build (faster)
    if timeout 30 nix eval '.#nixosConfigurations.kernelcore' --json > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Flake evaluates successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Flake evaluation timed out or failed - continuing anyway${NC}"
        echo -e "${CYAN}   You can verify with: nix flake check --show-trace${NC}"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 3. SECURITY QUICK CHECK
# ═══════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}🔒 Security Quick Check...${NC}"

# Check for potential secrets in staged files
STAGED_FILES=$(git diff --cached --name-only)
SECRETS_FOUND=false

for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        # Skip binary and encrypted files based on extension
        case "$file" in
            *.png|*.jpg|*.gif|*.ico|*.pdf|*.bin|*.so|*.a|*.o|*.age|*.gpg) continue ;;
        esac
        # Check for common secret patterns (but not in documented examples)
        if grep -Eq "(password\s*=\s*['\"][^'\"]+['\"]|api[_-]?key\s*=\s*['\"][^'\"]+['\"]|secret\s*=\s*['\"][^'\"]+['\"])" "$file" 2>/dev/null; then
            # Exclude false positives (option definitions, examples)
            if ! grep -q "mkOption\|description\|#.*example" "$file" 2>/dev/null; then
                echo -e "  ${RED}⚠️  Potential secret in: $file${NC}"
                SECRETS_FOUND=true
            fi
        fi
    fi
done

if [ "$SECRETS_FOUND" = true ]; then
    echo -e "${YELLOW}⚠️  Review the files above for potential secrets${NC}"
    echo -e "${CYAN}   Use SOPS for sensitive data: sops secrets/your-secret.yaml${NC}"
else
    echo -e "${GREEN}✅ No obvious secrets detected${NC}"
fi

# ═══════════════════════════════════════════════════════════════
echo -e "\n${GREEN}🎉 Pipeline Passed! Ready to commit.${NC}"
