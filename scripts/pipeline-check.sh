#!/usr/bin/env bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Local CI Pipeline...${NC}"

# 1. Formatting Check
echo -e "\n${YELLOW}📝 Checking Formatting (nixfmt)...${NC}"
if ! nix fmt -- --check .; then
    echo -e "${RED}❌ Formatting failed! Run 'nix fmt' to fix.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Formatting passes.${NC}"

# 2. Static Analysis (Deadnix/Statix)
# Note: Assuming these tools are available via nix shell or installed
echo -e "\n${YELLOW}mw Analysis (Linting)...${NC}"
# We use 'nix flake check' which usually includes these if configured, 
# otherwise we check simply via evaluation
if ! nix flake check --show-trace; then
     echo -e "${RED}❌ Flake check failed!${NC}"
     exit 1
fi
echo -e "${GREEN}✅ Static analysis passes.${NC}"

# 3. Security Audit (Local logic)
echo -e "\n${YELLOW}Cw Security Audit...${NC}"
# Check for sops files that might be unencrypted (simple grep heuristic)
if grep -r "BEGIN PGP MESSAGE" . --include="*.yaml" | grep -v "sops" > /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Potential unencrypted secrets found (or false positive).${NC}"
fi

# Ensure secrets.yaml is encrypted if it exists and has content
if [ -f secrets/github.yaml ] && grep -q "cachix_auth_token" secrets/github.yaml && ! grep -q "sops" secrets/github.yaml; then
     echo -e "${RED}❌ CRITICAL: secrets/github.yaml appears unencrypted!${NC}"
     exit 1
fi
echo -e "${GREEN}✅ Basic security checks passed.${NC}"

# 4. Documentation Generation (Preview)
echo -e "\n${YELLOW}📚 Generating Documentation Preview...${NC}"
if [ -f scripts/generate-docs.sh ]; then
    ./scripts/generate-docs.sh
    echo -e "${GREEN}✅ Documentation updated.${NC}"
else
    echo -e "${YELLOW}⚠️  scripts/generate-docs.sh not found, skipping.${NC}"
fi

echo -e "\n${GREEN}🎉 Pipeline Passed Successfully! Ready to commit.${NC}"
