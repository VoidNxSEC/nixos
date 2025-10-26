#!/usr/bin/env bash
# SOPS Secret Management Helper
# Usage: ./scripts/add-secret.sh <secret-type>

set -euo pipefail

SECRETS_DIR="/etc/nixos/secrets"
TMP_DIR="/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  SOPS Secret Management Helper${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
}

function print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

function print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

function show_usage() {
    cat <<EOF
Usage: $0 <secret-type> [options]

Secret Types:
  api         - API keys (Anthropic, OpenAI, HuggingFace, etc)
  github      - GitHub Actions runner token
  database    - Database credentials (PostgreSQL, MongoDB, Redis)
  aws         - AWS credentials
  ssh         - SSH keys for deployment
  vpn         - VPN credentials (NordVPN, WireGuard)
  custom      - Custom secret file

Options:
  -h, --help    Show this help message
  -e, --edit    Edit existing secret
  -v, --view    View decrypted secret
  -l, --list    List all encrypted secrets

Examples:
  $0 api                  # Create new API keys secret
  $0 github --edit        # Edit existing GitHub secret
  $0 database --view      # View database credentials
  $0 --list               # List all secrets

EOF
}

function list_secrets() {
    print_header
    print_info "Encrypted secrets in $SECRETS_DIR:"
    echo ""

    if [ ! -d "$SECRETS_DIR" ]; then
        print_error "Secrets directory not found: $SECRETS_DIR"
        print_info "Run: sudo mkdir -p $SECRETS_DIR"
        exit 1
    fi

    find "$SECRETS_DIR" -name "*.yaml" -type f 2>/dev/null | while read -r file; do
        rel_path="${file#$SECRETS_DIR/}"
        size=$(du -h "$file" | cut -f1)
        modified=$(stat -c %y "$file" | cut -d' ' -f1)
        echo "  📄 $rel_path"
        echo "     Size: $size | Modified: $modified"
        echo ""
    done
}

function view_secret() {
    local secret_file="$1"

    if [ ! -f "$secret_file" ]; then
        print_error "Secret file not found: $secret_file"
        exit 1
    fi

    print_info "Decrypting: $secret_file"
    echo ""
    sops -d "$secret_file"
}

function edit_secret() {
    local secret_file="$1"

    if [ ! -f "$secret_file" ]; then
        print_error "Secret file not found: $secret_file"
        print_info "Use 'add' mode to create a new secret"
        exit 1
    fi

    print_info "Editing: $secret_file"
    print_warning "Your default editor will open. Make changes and save."
    echo ""

    sops "$secret_file"

    print_success "Secret updated successfully!"
}

function create_api_secret() {
    local tmp_file="$TMP_DIR/api-$(date +%s).yaml"
    local dest_file="$SECRETS_DIR/api.yaml"

    cat > "$tmp_file" <<'EOF'
# API Keys for External Services
# Date: $(date +%Y-%m-%d)
# IMPORTANT: This file will be encrypted with SOPS

# AI Services
anthropic_api_key: "sk-ant-api03-REPLACE_WITH_YOUR_KEY"
openai_api_key: "sk-proj-REPLACE_WITH_YOUR_KEY"
groq_api_key: "gsk_REPLACE_WITH_YOUR_KEY"
huggingface_token: "hf_REPLACE_WITH_YOUR_TOKEN"

# Cloud Providers
google_cloud_api_key: "AIzaSy_REPLACE_WITH_YOUR_KEY"

# Version Control
github_api_token: "ghp_REPLACE_WITH_YOUR_TOKEN"
gitlab_api_token: "glpat-REPLACE_WITH_YOUR_TOKEN"

# Environment variables format (optional)
env:
  ANTHROPIC_API_KEY: "sk-ant-api03-REPLACE"
  OPENAI_API_KEY: "sk-proj-REPLACE"
  HF_TOKEN: "hf_REPLACE"
EOF

    print_info "Opening editor to fill in API keys..."
    ${EDITOR:-nano} "$tmp_file"

    # Check if user made changes
    if grep -q "REPLACE_WITH_YOUR" "$tmp_file"; then
        print_warning "Template placeholders detected. Did you replace them?"
        read -p "Continue with encryption? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cancelled. Cleaning up..."
            shred -vfz -n 10 "$tmp_file" 2>/dev/null || rm -f "$tmp_file"
            exit 0
        fi
    fi

    # Encrypt
    print_info "Encrypting secret..."
    sops -e "$tmp_file" > "$dest_file"

    # Verify encryption
    if [ $? -eq 0 ]; then
        print_success "Secret encrypted and saved to: $dest_file"

        # Secure delete
        print_info "Securely deleting plaintext file..."
        shred -vfz -n 10 "$tmp_file" 2>/dev/null || rm -f "$tmp_file"

        print_success "Plaintext securely deleted!"
        echo ""
        print_info "Next steps:"
        echo "  1. git add $dest_file"
        echo "  2. git commit -m 'sec: add API keys'"
        echo "  3. git push"
    else
        print_error "Encryption failed!"
        rm -f "$tmp_file"
        exit 1
    fi
}

function create_github_secret() {
    local tmp_file="$TMP_DIR/github-$(date +%s).yaml"
    local dest_file="$SECRETS_DIR/github.yaml"

    cat > "$tmp_file" <<'EOF'
# GitHub Actions Runner Configuration
# Date: $(date +%Y-%m-%d)
# Generate token at: https://github.com/settings/tokens

# Runner registration token
github_runner_token: "REPLACE_WITH_RUNNER_TOKEN"

# Organization/Repository info
github_org: "marcosfpina"
github_repo: "your-repo-name"

# Optional: GitHub App credentials (alternative to PAT)
# github_app_id: "123456"
# github_app_installation_id: "12345678"
# github_app_private_key: |
#   -----BEGIN RSA PRIVATE KEY-----
#   REPLACE_WITH_YOUR_KEY
#   -----END RSA PRIVATE KEY-----
EOF

    print_info "Opening editor to add GitHub credentials..."
    ${EDITOR:-nano} "$tmp_file"

    # Encrypt
    print_info "Encrypting secret..."
    sops -e "$tmp_file" > "$dest_file"

    if [ $? -eq 0 ]; then
        print_success "Secret encrypted and saved to: $dest_file"
        shred -vfz -n 10 "$tmp_file" 2>/dev/null || rm -f "$tmp_file"
        print_success "Plaintext securely deleted!"
    else
        print_error "Encryption failed!"
        rm -f "$tmp_file"
        exit 1
    fi
}

function create_database_secret() {
    local tmp_file="$TMP_DIR/database-$(date +%s).yaml"
    local dest_file="$SECRETS_DIR/database.yaml"

    cat > "$tmp_file" <<'EOF'
# Database Credentials
# Date: $(date +%Y-%m-%d)

postgresql:
  host: "localhost"
  port: 5432
  username: "kernelcore"
  password: "REPLACE_WITH_SECURE_PASSWORD"
  database: "kernelcore"
  connection_string: "postgresql://kernelcore:REPLACE_WITH_SECURE_PASSWORD@localhost:5432/kernelcore"

mongodb:
  host: "localhost"
  port: 27017
  username: "admin"
  password: "REPLACE_WITH_SECURE_PASSWORD"
  database: "mydb"
  connection_string: "mongodb://admin:REPLACE_WITH_SECURE_PASSWORD@localhost:27017/mydb"

redis:
  host: "localhost"
  port: 6379
  password: "REPLACE_WITH_SECURE_PASSWORD"
EOF

    print_info "Opening editor to add database credentials..."
    ${EDITOR:-nano} "$tmp_file"

    # Encrypt
    print_info "Encrypting secret..."
    sops -e "$tmp_file" > "$dest_file"

    if [ $? -eq 0 ]; then
        print_success "Secret encrypted and saved to: $dest_file"
        shred -vfz -n 10 "$tmp_file" 2>/dev/null || rm -f "$tmp_file"
        print_success "Plaintext securely deleted!"
    else
        print_error "Encryption failed!"
        rm -f "$tmp_file"
        exit 1
    fi
}

# Main script
print_header

# Check if sops is installed
if ! command -v sops &> /dev/null; then
    print_error "sops command not found!"
    print_info "Install with: nix-shell -p sops"
    exit 1
fi

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -l|--list)
        list_secrets
        exit 0
        ;;
    -v|--view)
        if [ -z "${2:-}" ]; then
            print_error "Please specify secret file to view"
            echo "Usage: $0 --view <secret-file>"
            exit 1
        fi
        view_secret "$2"
        exit 0
        ;;
    api)
        create_api_secret
        ;;
    github)
        if [ "${2:-}" == "--edit" ]; then
            edit_secret "$SECRETS_DIR/github.yaml"
        else
            create_github_secret
        fi
        ;;
    database)
        create_database_secret
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        echo ""
        show_usage
        exit 1
        ;;
esac
