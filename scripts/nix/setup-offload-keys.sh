#!/usr/bin/env bash
# setup-offload-keys.sh
# Helper script to finalize NixOS Remote Build setup

set -e

DESKTOP="desktop"
BUILDER_KEY="$HOME/.ssh/nix-builder"
PUB_KEY_PATH="$BUILDER_KEY.pub"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}== NixOS Remote Build Setup ==${NC}"

# 1. Verify/Generate Builder Key
if [ ! -f "$BUILDER_KEY" ]; then
    echo -e "${YELLOW}Generating builder key ($BUILDER_KEY)...${NC}"
    ssh-keygen -t ed25519 -f "$BUILDER_KEY" -N "" -C "nix-builder@laptop"
else
    echo -e "${GREEN}✓ Builder key exists${NC}"
fi

PUB_KEY=$(cat "$PUB_KEY_PATH")

# 2. Authorize Key on Desktop
echo -e "\n${YELLOW}Setting up builder access on Desktop...${NC}"
echo "You may be asked for the sudo password for user 'cypher' on '$DESKTOP'."

ssh -t "$DESKTOP" "sudo bash -c '
    id nix-builder &>/dev/null || useradd -m nix-builder
    mkdir -p /home/nix-builder/.ssh
    if ! grep -q \"$PUB_KEY\" /home/nix-builder/.ssh/authorized_keys 2>/dev/null; then
        echo \"$PUB_KEY\" >> /home/nix-builder/.ssh/authorized_keys
        echo \"Key added to authorized_keys\"
    else
        echo \"Key already authorized\"
    fi
    chown -R nix-builder:users /home/nix-builder/.ssh
    chmod 700 /home/nix-builder/.ssh
    chmod 600 /home/nix-builder/.ssh/authorized_keys
'"

# 3. Fetch Binary Cache Key
echo -e "\n${YELLOW}Fetching Binary Cache Public Key...${NC}"
CACHE_KEY=$(ssh "$DESKTOP" "sudo cat /var/cache-pub-key.pem 2>/dev/null || sudo cat /etc/nix/signing-key.pub 2>/dev/null")

if [ -z "$CACHE_KEY" ]; then
    echo -e "${RED}❌ Failed to fetch cache key!${NC}"
    echo "Please ensure /var/cache-pub-key.pem exists on the desktop."
    exit 1
fi

CLEAN_KEY=$(echo "$CACHE_KEY" | tr -d '\r\n')
echo -e "${GREEN}✓ Cache Key retrieved:${NC}"
echo "$CLEAN_KEY"

echo -e "\n${GREEN}== Configuration Update Required ==${NC}"
echo "Please update 'modules/services/laptop-offload-client.nix' with this key in 'trusted-public-keys':"
echo -e "${YELLOW}\"$CLEAN_KEY\"${NC}"
