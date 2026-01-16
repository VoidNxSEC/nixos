#!/usr/bin/env bash
# Setup GitLab secrets in SOPS
# Run this script to add GitLab token to encrypted secrets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="/etc/nixos/secrets"
SOPS_CONFIG="/etc/nixos/.sops.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 GitLab Secrets Setup${NC}"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs sudo privileges. Rerunning with sudo...${NC}"
    exec sudo "$0" "$@"
fi

# Step 1: Check if .sops.yaml has gitlab rule
echo -e "${YELLOW}[1/4]${NC} Checking .sops.yaml configuration..."

if ! grep -q "secrets/gitlab\.yaml" "$SOPS_CONFIG"; then
    echo -e "${YELLOW}Adding GitLab rule to .sops.yaml...${NC}"

    # Backup .sops.yaml
    cp "$SOPS_CONFIG" "$SOPS_CONFIG.backup-$(date +%Y%m%d-%H%M%S)"

    # Add GitLab rule before the default catch-all
    sed -i '/# Default catch-all/i \  # GitLab secrets\n  - path_regex: secrets/gitlab\\.yaml$\n    age: >-\n      age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn,\n      age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn\n' "$SOPS_CONFIG"

    echo -e "${GREEN}✓ GitLab rule added to .sops.yaml${NC}"
else
    echo -e "${GREEN}✓ GitLab rule already exists${NC}"
fi

# Step 2: Encrypt the secret
echo -e "${YELLOW}[2/4]${NC} Encrypting GitLab secrets..."

# Create temporary unencrypted file
cat > /tmp/gitlab-secret.yaml <<'EOF'
# GitLab Secrets

gitlab:
  token: glpat-toN0ppvu9pwemhHSeA1m
  username: marcosfpina
  email: sec@voidnxlabs.com

  api:
    url: https://gitlab.com/api/v4

  ssh:
    key_path: /home/kernelcore/.ssh/id_ed25519_gitlab

  gpg:
    key_id: 5606AB430E95F5AD

  runner:
    enabled: false
    token: ""
EOF

# Encrypt with SOPS
cd /etc/nixos
sops --encrypt /tmp/gitlab-secret.yaml > "$SECRETS_DIR/gitlab.yaml"

echo -e "${GREEN}✓ Secrets encrypted${NC}"

# Step 3: Set permissions
echo -e "${YELLOW}[3/4]${NC} Setting secure permissions..."

chmod 600 "$SECRETS_DIR/gitlab.yaml"
chown root:root "$SECRETS_DIR/gitlab.yaml"

echo -e "${GREEN}✓ Permissions set (600, root:root)${NC}"

# Step 4: Verify decryption
echo -e "${YELLOW}[4/4]${NC} Verifying encryption..."

if sops --decrypt "$SECRETS_DIR/gitlab.yaml" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Secrets can be decrypted successfully${NC}"
else
    echo -e "${RED}✗ Failed to decrypt secrets${NC}"
    exit 1
fi

# Cleanup
rm -f /tmp/gitlab-secret.yaml

echo ""
echo -e "${GREEN}✅ GitLab secrets setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Import the module in your NixOS configuration:"
echo "     imports = [ /home/kernelcore/arch/cerebro/nix/gitlab-secrets.nix ];"
echo ""
echo "  2. Rebuild NixOS:"
echo "     sudo nixos-rebuild switch --flake /etc/nixos#kernelcore"
echo ""
echo "  3. Test GitLab CLI:"
echo "     glab auth status"
echo ""
