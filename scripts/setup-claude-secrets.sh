#!/usr/bin/env bash
# Setup Claude Secrets - Temporary script until rebuild

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

PROFILE_DIR="$HOME/.config/claude-profiles"
CLAUDE_ENV="$HOME/.claude-env"

# Create directory
mkdir -p "$PROFILE_DIR"
chmod 700 "$PROFILE_DIR"

echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║           Claude Code - Secrets Configuration                ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# CONFIGURAR AWS BEDROCK
# ============================================================

echo -e "${YELLOW}${BOLD}1. AWS Bedrock Configuration${NC}"
echo ""
echo "You'll need:"
echo "  - AWS Access Key ID (from AWS IAM Console)"
echo "  - AWS Secret Access Key"
echo "  - AWS Region (us-east-1, us-west-2, etc.)"
echo ""
read -p "Configure AWS Bedrock now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "AWS Access Key ID: " aws_key_id
    read -sp "AWS Secret Access Key: " aws_secret
    echo ""
    read -p "AWS Region [us-east-1]: " aws_region
    aws_region=${aws_region:-us-east-1}

    if [ -z "$aws_key_id" ] || [ -z "$aws_secret" ]; then
        echo -e "${RED}Error: AWS credentials cannot be empty${NC}"
    else
        cat > "$PROFILE_DIR/bedrock.env" <<EOF
# AWS Bedrock Configuration
export AWS_ACCESS_KEY_ID="$aws_key_id"
export AWS_SECRET_ACCESS_KEY="$aws_secret"
export AWS_REGION="$aws_region"
export CLAUDE_API_TYPE="bedrock"
export CLAUDE_MODEL="anthropic.claude-sonnet-4-20250514-v1:0"
EOF

        chmod 600 "$PROFILE_DIR/bedrock.env"
        echo -e "${GREEN}✓ AWS Bedrock configured successfully${NC}"
        echo "  Saved to: $PROFILE_DIR/bedrock.env"
        echo ""
    fi
fi

# ============================================================
# CONFIGURAR CLAUDE API OFICIAL
# ============================================================

echo -e "${YELLOW}${BOLD}2. Anthropic Official API Configuration${NC}"
echo ""
echo "You'll need:"
echo "  - Anthropic API Key (from https://console.anthropic.com/)"
echo ""
read -p "Configure Anthropic API now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -sp "Anthropic API Key: " api_key
    echo ""

    if [ -z "$api_key" ]; then
        echo -e "${RED}Error: API key cannot be empty${NC}"
    else
        cat > "$PROFILE_DIR/api.env" <<EOF
# Anthropic Official API Configuration
export ANTHROPIC_API_KEY="$api_key"
export CLAUDE_API_TYPE="anthropic"
export CLAUDE_MODEL="claude-sonnet-4"
EOF

        chmod 600 "$PROFILE_DIR/api.env"
        echo -e "${GREEN}✓ Anthropic API configured successfully${NC}"
        echo "  Saved to: $PROFILE_DIR/api.env"
        echo ""
    fi
fi

# ============================================================
# ESCOLHER PROFILE PADRÃO
# ============================================================

echo ""
echo -e "${YELLOW}${BOLD}3. Choose Default Profile${NC}"
echo ""
echo "Available profiles:"
[ -f "$PROFILE_DIR/bedrock.env" ] && echo -e "  ${GREEN}bedrock${NC} - AWS Bedrock (configured)"
[ -f "$PROFILE_DIR/api.env" ] && echo -e "  ${GREEN}api${NC}     - Anthropic Official API (configured)"
echo -e "  ${YELLOW}pro${NC}     - Claude Pro (no config needed)"
echo ""
read -p "Default profile [bedrock]: " default_profile
default_profile=${default_profile:-bedrock}

# Validate profile
if [[ ! "$default_profile" =~ ^(pro|api|bedrock)$ ]]; then
    echo -e "${RED}Invalid profile. Using 'bedrock'${NC}"
    default_profile="bedrock"
fi

# Set default profile
echo "$default_profile" > "$PROFILE_DIR/current"

# Create global env file
if [ "$default_profile" = "pro" ]; then
    cat > "$CLAUDE_ENV" <<EOF
# Claude Code Environment
# Profile: pro (Claude Pro web-based)
export CLAUDE_PROFILE="pro"
EOF
else
    if [ -f "$PROFILE_DIR/$default_profile.env" ]; then
        cat "$PROFILE_DIR/$default_profile.env" > "$CLAUDE_ENV"
        echo "export CLAUDE_PROFILE=\"$default_profile\"" >> "$CLAUDE_ENV"
    else
        echo -e "${RED}Warning: Profile '$default_profile' not configured${NC}"
    fi
fi

chmod 600 "$CLAUDE_ENV"

# ============================================================
# SUMMARY
# ============================================================

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                   ✓ Configuration Complete                   ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Configured profiles:${NC}"
[ -f "$PROFILE_DIR/bedrock.env" ] && echo -e "  ✓ AWS Bedrock"
[ -f "$PROFILE_DIR/api.env" ] && echo -e "  ✓ Anthropic API"
echo ""
echo -e "${CYAN}Active profile:${NC} ${BOLD}$default_profile${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "  1. Load environment:"
echo -e "     ${BOLD}source $CLAUDE_ENV${NC}"
echo ""
echo "  2. Rebuild NixOS to activate full profile system:"
echo -e "     ${BOLD}rebuild switch${NC}"
echo ""
echo "  3. After rebuild, manage profiles with:"
echo -e "     ${BOLD}claude-profile list${NC}"
echo -e "     ${BOLD}claude-profile use bedrock${NC}"
echo -e "     ${BOLD}claude-profile use api${NC}"
echo ""
echo "  4. Test your configuration:"
echo -e "     ${BOLD}claude-profile test${NC}"
echo ""
echo -e "${CYAN}Files created:${NC}"
echo "  $PROFILE_DIR/bedrock.env (if configured)"
echo "  $PROFILE_DIR/api.env (if configured)"
echo "  $PROFILE_DIR/current"
echo "  $CLAUDE_ENV"
echo ""
echo -e "${YELLOW}Security note:${NC} All files have chmod 600 (owner read/write only)"
echo ""
