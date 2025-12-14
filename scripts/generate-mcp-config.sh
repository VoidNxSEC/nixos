#!/usr/bin/env bash
# Generate dynamic MCP server configuration with API keys from SOPS
# Usage:
#   ./generate-mcp-config.sh roo     # Generate for Roo Code/Cline
#   ./generate-mcp-config.sh claude  # Generate for Claude Desktop
#   ./generate-mcp-config.sh both    # Generate both

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths
PROJECT_ROOT="/etc/nixos"
# New path: securellm-mcp binary is installed system-wide via Nix
MCP_SERVER_PATH="$(command -v securellm-mcp 2>/dev/null || echo '/run/current-system/sw/bin/securellm-mcp')"
KNOWLEDGE_DB_PATH="/var/lib/mcp-knowledge/knowledge.db"

# Client config paths
ROO_CONFIG_PATH="${HOME}/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json"
CLAUDE_CONFIG_PATH="${HOME}/.config/Claude/claude_desktop_config.json"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load API keys from SOPS-decrypted secrets
load_api_keys() {
    log_info "Loading API keys from /run/secrets/..."

    # Source the helper script if available
    if [[ -f /etc/load-api-keys.sh ]]; then
        source /etc/load-api-keys.sh > /dev/null 2>&1 || true
    fi

    # Verify at least one key is available
    local keys_loaded=0
    for key_file in /run/secrets/*_api_key; do
        if [[ -f "$key_file" ]]; then
            ((keys_loaded++))
        fi
    done

    if [[ $keys_loaded -eq 0 ]]; then
        log_warn "No API keys found in /run/secrets/. MCP server will work but provider tools may fail."
    else
        log_success "Loaded $keys_loaded API keys"
    fi
}

# Generate base MCP config (common for both clients)
generate_base_config() {
    cat <<EOF
{
  "mcpServers": {
    "securellm-bridge": {
      "command": "$MCP_SERVER_PATH",
      "args": [],
      "env": {
        "PROJECT_ROOT": "$PROJECT_ROOT",
        "KNOWLEDGE_DB_PATH": "$KNOWLEDGE_DB_PATH",
        "ENABLE_KNOWLEDGE": "true",
        "ANTHROPIC_API_KEY": "\${ANTHROPIC_API_KEY:-}",
        "OPENAI_API_KEY": "\${OPENAI_API_KEY:-}",
        "DEEPSEEK_API_KEY": "\${DEEPSEEK_API_KEY:-}",
        "GEMINI_API_KEY": "\${GEMINI_API_KEY:-}",
        "OPENROUTER_API_KEY": "\${OPENROUTER_API_KEY:-}",
        "GROQ_API_KEY": "\${GROQ_API_KEY:-}",
        "MISTRAL_API_KEY": "\${MISTRAL_API_KEY:-}",
        "NVIDIA_API_KEY": "\${NVIDIA_API_KEY:-}",
        "REPLICATE_API_TOKEN": "\${REPLICATE_API_TOKEN:-}"
      }
EOF
}

# Generate Roo Code/Cline config
generate_roo_config() {
    local output_file="${1:-$ROO_CONFIG_PATH}"

    log_info "Generating Roo Code/Cline configuration..."

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"

    # Generate config with Roo-specific fields
    {
        generate_base_config
        cat <<EOF
,
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
EOF
    } > "$output_file"

    log_success "Roo Code config written to: $output_file"
}

# Generate Claude Desktop config
generate_claude_config() {
    local output_file="${1:-$CLAUDE_CONFIG_PATH}"

    log_info "Generating Claude Desktop configuration..."

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"

    # Generate config (simpler format for Claude Desktop)
    {
        generate_base_config
        cat <<EOF

    }
  }
}
EOF
    } > "$output_file"

    log_success "Claude Desktop config written to: $output_file"
}

# Expand environment variables in config file
expand_env_vars() {
    local config_file="$1"

    log_info "Expanding environment variables in $config_file..."

    # Create temporary file with expanded variables
    local temp_file="${config_file}.tmp"

    # Read file and expand env vars
    while IFS= read -r line; do
        # Expand ${VAR:-default} patterns
        expanded_line="$line"

        # Extract all ${VAR:-...} patterns and expand them
        while [[ "$expanded_line" =~ \$\{([A-Z_]+):-([^}]*)\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local default_value="${BASH_REMATCH[2]}"
            local var_value="${!var_name:-$default_value}"

            # Replace in line
            expanded_line="${expanded_line//\$\{$var_name:-$default_value\}/$var_value}"
        done

        echo "$expanded_line"
    done < "$config_file" > "$temp_file"

    # Replace original file
    mv "$temp_file" "$config_file"

    log_success "Environment variables expanded"
}

# Validate MCP server is built
validate_server() {
    if [[ ! -f "$MCP_SERVER_PATH" ]]; then
        log_error "MCP server not built at: $MCP_SERVER_PATH"
        log_info "Building MCP server..."

        cd "$(dirname "$MCP_SERVER_PATH")/.."
        npm run build

        if [[ ! -f "$MCP_SERVER_PATH" ]]; then
            log_error "Failed to build MCP server"
            exit 1
        fi

        log_success "MCP server built successfully"
    else
        log_success "MCP server found at: $MCP_SERVER_PATH"
    fi
}

# Create knowledge database directory
setup_knowledge_db() {
    local db_dir="$(dirname "$KNOWLEDGE_DB_PATH")"

    if [[ ! -d "$db_dir" ]]; then
        log_info "Creating knowledge database directory: $db_dir"
        sudo mkdir -p "$db_dir"
        sudo chown "$USER:users" "$db_dir"
        log_success "Knowledge database directory created"
    fi
}

# Print usage instructions
print_usage() {
    cat <<EOF

${GREEN}MCP Configuration Generated Successfully!${NC}

${BLUE}Next Steps:${NC}

1. ${YELLOW}Reload your IDE${NC} (Roo Code/VSCodium or Claude Desktop)

2. ${YELLOW}Verify MCP tools are available${NC}:
   - Open your IDE
   - Check that MCP tools appear in the tools list
   - Available tools:
     • provider_test - Test LLM provider connectivity
     • security_audit - Run security checks
     • rate_limit_check - Check rate limits
     • build_and_test - Build and test project
     • create_session - Create knowledge session
     • save_knowledge - Save knowledge entries
     • search_knowledge - Search knowledge base
     • ... and more (12 tools total)

3. ${YELLOW}Load API keys${NC} (if not already loaded):
   ${BLUE}source /etc/load-api-keys.sh${NC}

4. ${YELLOW}Test MCP connection${NC}:
   ${BLUE}echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | securellm-mcp${NC}

${GREEN}Configuration Files:${NC}
EOF

    if [[ -f "$ROO_CONFIG_PATH" ]]; then
        echo "  • Roo Code: $ROO_CONFIG_PATH"
    fi

    if [[ -f "$CLAUDE_CONFIG_PATH" ]]; then
        echo "  • Claude Desktop: $CLAUDE_CONFIG_PATH"
    fi

    cat <<EOF

${GREEN}Adding New Providers:${NC}
1. Add API key to ${BLUE}/etc/nixos/secrets/api.yaml${NC}
2. Update ${BLUE}modules/secrets/api-keys.nix${NC}
3. Rebuild NixOS: ${BLUE}sudo nixos-rebuild switch${NC}
4. Re-run this script: ${BLUE}$0 <client>${NC}

${GREEN}Documentation:${NC}
  • MCP Server: /etc/nixos/docs/MCP-ARCHITECTURE-ACCESS.md
  • API Keys: /etc/nixos/docs/guides/SECRETS.md

EOF
}

# Main
main() {
    local mode="${1:-both}"

    echo -e "${BLUE}=== MCP Configuration Generator ===${NC}\n"

    # Validate server
    validate_server

    # Setup knowledge DB
    setup_knowledge_db

    # Load API keys
    load_api_keys

    # Generate configs based on mode
    case "$mode" in
        roo|cline)
            generate_roo_config
            expand_env_vars "$ROO_CONFIG_PATH"
            ;;
        claude)
            generate_claude_config
            expand_env_vars "$CLAUDE_CONFIG_PATH"
            ;;
        both)
            generate_roo_config
            expand_env_vars "$ROO_CONFIG_PATH"

            generate_claude_config
            expand_env_vars "$CLAUDE_CONFIG_PATH"
            ;;
        *)
            log_error "Invalid mode: $mode"
            echo "Usage: $0 [roo|claude|both]"
            exit 1
            ;;
    esac

    # Print usage instructions
    print_usage
}

# Run main
main "$@"
