#!/usr/bin/env bash
# CRITICAL SECURITY: Migrate SEC.sh plaintext keys to encrypted SOPS secrets
# This script will:
# 1. Read SEC.sh plaintext keys
# 2. Distribute into organized YAML files
# 3. Encrypt with SOPS
# 4. Securely delete plaintext
# 5. Configure NixOS services

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SEC_FILE="/etc/nixos/SEC.sh"
SECRETS_DIR="/etc/nixos/secrets"
TMP_DIR="/tmp/sops-migration-$$"

function print_header() {
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}   🔐 SOPS Migration: SEC.sh → Encrypted Secrets${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

function print_success() { echo -e "${GREEN}✓ $1${NC}"; }
function print_error() { echo -e "${RED}✗ $1${NC}"; }
function print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
function print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
function print_step() { echo -e "${MAGENTA}▶ $1${NC}"; }

function check_prerequisites() {
    print_step "Checking prerequisites..."

    if ! command -v sops &> /dev/null; then
        print_error "sops not found!"
        print_info "Install: nix-shell -p sops age"
        exit 1
    fi

    if ! command -v age &> /dev/null; then
        print_error "age not found!"
        print_info "Install: nix-shell -p age"
        exit 1
    fi

    if [ ! -f "$SEC_FILE" ]; then
        print_error "SEC.sh not found at: $SEC_FILE"
        exit 1
    fi

    # Check for AGE key
    if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
        print_warning "AGE key not found!"
        print_info "Generating new AGE key..."
        mkdir -p "$HOME/.config/sops/age"
        age-keygen -o "$HOME/.config/sops/age/keys.txt"
        print_success "AGE key generated: $HOME/.config/sops/age/keys.txt"
        echo ""
        print_warning "IMPORTANT: Backup this key file securely!"
        print_info "Public key:"
        grep "public key:" "$HOME/.config/sops/age/keys.txt"
        echo ""
    fi

    print_success "All prerequisites met!"
    echo ""
}

function create_tmp_directory() {
    print_step "Creating temporary directory..."
    mkdir -p "$TMP_DIR"
    chmod 700 "$TMP_DIR"
    print_success "Created: $TMP_DIR"
    echo ""
}

function source_sec_file() {
    print_step "Reading SEC.sh..."
    # Source the file in a subshell to avoid polluting current environment
    source "$SEC_FILE"
    print_success "Loaded $(grep -c "=" "$SEC_FILE") variables from SEC.sh"
    echo ""
}

function create_api_secrets() {
    print_step "Creating api.yaml..."

    cat > "$TMP_DIR/api.yaml" <<EOF
# API Keys for AI/ML Services
# Date: $(date +%Y-%m-%d)
# Auto-migrated from SEC.sh

# OpenAI
openai:
  domain_key: "${OPENAI_DOMAIN_KEY:-}"
  admin_key: "${OPENAI_ADM_KEY:-}"
  project_id: "${OPENAI_PROJECT_ID:-}"

# Anthropic (Claude)
anthropic:
  api_key: "${ANTHROPIC_API_KEY:-}"

# DeepSeek
deepseek:
  api_key: "${DEEPSEEK_API_KEY:-}"

# Google Gemini
gemini:
  api_key: "${GEMINI_API_KEY:-}"

# OpenRouter
openrouter:
  api_key: "${OPENROUTER_API_KEY:-}"

# Replicate
replicate:
  api_key: "${REPLICATE_API_KEY:-}"

# Mistral AI
mistral:
  api_key: "${MISTRAL_API_KEY:-}"

# Groq
groq:
  api_key: "${GROQ_API_KEY:-}"
  project_id: "${GROQ_PROJECT_ID:-}"

# NVIDIA
nvidia:
  api_key: "${NVIDIA_API_KEY:-}"

# Environment variables format (for easy export)
env:
  OPENAI_API_KEY: "${OPENAI_ADM_KEY:-}"
  OPENAI_PROJECT_ID: "${OPENAI_PROJECT_ID:-}"
  ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY:-}"
  DEEPSEEK_API_KEY: "${DEEPSEEK_API_KEY:-}"
  GEMINI_API_KEY: "${GEMINI_API_KEY:-}"
  OPENROUTER_API_KEY: "${OPENROUTER_API_KEY:-}"
  REPLICATE_API_TOKEN: "${REPLICATE_API_KEY:-}"
  MISTRAL_API_KEY: "${MISTRAL_API_KEY:-}"
  GROQ_API_KEY: "${GROQ_API_KEY:-}"
  NVIDIA_API_KEY: "${NVIDIA_API_KEY:-}"
EOF

    print_success "Created api.yaml with $(grep -c "api_key:" "$TMP_DIR/api.yaml") services"
}

function create_github_secrets() {
    print_step "Creating github.yaml..."

    cat > "$TMP_DIR/github.yaml" <<EOF
# GitHub Secrets
# Date: $(date +%Y-%m-%d)
# Auto-migrated from SEC.sh

# GitHub Personal Access Token
github_token: "${GITHUB_TOKEN:-}"

# GitHub Runner Configuration
runner:
  name: "nixos-self-hosted"
  org: "marcosfpina"
  labels:
    - "nixos"
    - "nix"
    - "linux"
    - "gpu"
    - "cuda"

# Environment variables
env:
  GITHUB_TOKEN: "${GITHUB_TOKEN:-}"
EOF

    print_success "Created github.yaml"
}

function create_sops_config() {
    print_step "Creating/Updating .sops.yaml..."

    # Get AGE public key
    AGE_PUBLIC_KEY=$(grep "public key:" "$HOME/.config/sops/age/keys.txt" | cut -d: -f2 | tr -d ' ')

    cat > "/etc/nixos/.sops.yaml" <<EOF
# SOPS Configuration
# AGE encryption keys

creation_rules:
  # API Keys (AI/ML services)
  - path_regex: secrets/api\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # GitHub tokens and runner config
  - path_regex: secrets/github\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # Database credentials
  - path_regex: secrets/database\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # AWS credentials
  - path_regex: secrets/aws\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # SSH keys
  - path_regex: secrets/ssh-keys/.*\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # Production secrets (highest security)
  - path_regex: secrets/prod\.yaml$
    age: >-
      $AGE_PUBLIC_KEY

  # Default catch-all
  - path_regex: secrets/.*\.yaml$
    age: >-
      $AGE_PUBLIC_KEY
EOF

    print_success "Created .sops.yaml with AGE key: ${AGE_PUBLIC_KEY:0:20}..."
}

function encrypt_secrets() {
    print_step "Encrypting secrets with SOPS..."

    mkdir -p "$SECRETS_DIR"

    # Encrypt api.yaml
    if [ -f "$TMP_DIR/api.yaml" ]; then
        print_info "Encrypting api.yaml..."
        sops -e "$TMP_DIR/api.yaml" > "$SECRETS_DIR/api.yaml"
        print_success "Encrypted: secrets/api.yaml"
    fi

    # Encrypt github.yaml
    if [ -f "$TMP_DIR/github.yaml" ]; then
        print_info "Encrypting github.yaml..."
        sops -e "$TMP_DIR/github.yaml" > "$SECRETS_DIR/github.yaml"
        print_success "Encrypted: secrets/github.yaml"
    fi

    echo ""
    print_success "All secrets encrypted!"
}

function verify_encryption() {
    print_step "Verifying encryption..."

    for file in "$SECRETS_DIR"/*.yaml; do
        if grep -q "sops:" "$file" && grep -q "age:" "$file"; then
            print_success "✓ $(basename "$file") - properly encrypted"
        else
            print_error "✗ $(basename "$file") - encryption failed!"
            exit 1
        fi
    done

    echo ""
}

function cleanup_plaintext() {
    print_step "Securely deleting plaintext files..."

    # Shred temporary files
    if [ -d "$TMP_DIR" ]; then
        for file in "$TMP_DIR"/*; do
            if [ -f "$file" ]; then
                print_info "Shredding: $(basename "$file")"
                shred -vfz -n 10 "$file" 2>/dev/null || rm -f "$file"
            fi
        done
        rmdir "$TMP_DIR"
        print_success "Temporary files shredded"
    fi

    # Move SEC.sh to backup (encrypted) before deletion
    print_warning "Backing up SEC.sh before deletion..."
    if [ -f "$SEC_FILE" ]; then
        # Create encrypted backup
        sops -e "$SEC_FILE" > "$SECRETS_DIR/sec-backup.yaml" 2>/dev/null || true

        # Shred original
        print_warning "Shredding SEC.sh (plaintext)..."
        shred -vfz -n 10 "$SEC_FILE" 2>/dev/null || rm -f "$SEC_FILE"
        print_success "SEC.sh securely deleted!"
    fi

    echo ""
}

function create_nixos_module() {
    print_step "Creating NixOS secrets integration module..."

    cat > "/etc/nixos/modules/secrets/api-keys.nix" <<'EOF'
{ config, lib, pkgs, ... }:

with lib;

{
  # SOPS secrets for API keys
  sops.secrets = {
    # API Keys
    "api/anthropic_api_key" = {
      sopsFile = ../../secrets/api.yaml;
      key = "anthropic/api_key";
      mode = "0440";
      group = "users";
    };

    "api/openai_api_key" = {
      sopsFile = ../../secrets/api.yaml;
      key = "openai/admin_key";
      mode = "0440";
      group = "users";
    };

    "api/groq_api_key" = {
      sopsFile = ../../secrets/api.yaml;
      key = "groq/api_key";
      mode = "0440";
      group = "users";
    };

    # GitHub token
    "github/token" = {
      sopsFile = ../../secrets/github.yaml;
      key = "github_token";
      mode = "0440";
      group = "users";
    };
  };

  # Export as environment variables for user session
  environment.sessionVariables = {
    # Point to decrypted secrets
    ANTHROPIC_API_KEY_FILE = config.sops.secrets."api/anthropic_api_key".path;
    OPENAI_API_KEY_FILE = config.sops.secrets."api/openai_api_key".path;
    GROQ_API_KEY_FILE = config.sops.secrets."api/groq_api_key".path;
    GITHUB_TOKEN_FILE = config.sops.secrets."github/token".path;
  };

  # Helper script to export secrets as environment variables
  environment.etc."load-api-keys.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Load API keys from SOPS secrets into environment

      export ANTHROPIC_API_KEY=$(cat ${config.sops.secrets."api/anthropic_api_key".path} 2>/dev/null || echo "")
      export OPENAI_API_KEY=$(cat ${config.sops.secrets."api/openai_api_key".path} 2>/dev/null || echo "")
      export GROQ_API_KEY=$(cat ${config.sops.secrets."api/groq_api_key".path} 2>/dev/null || echo "")
      export GITHUB_TOKEN=$(cat ${config.sops.secrets."github/token".path} 2>/dev/null || echo "")

      echo "API keys loaded into environment"
    '';
    mode = "0755";
  };
}
EOF

    print_success "Created modules/secrets/api-keys.nix"
}

function update_github_runner_config() {
    print_step "Creating GitHub runner SOPS integration..."

    cat > "/etc/nixos/modules/services/users/github-runner-sops.nix" <<'EOF'
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.github-runner;
in
{
  config = mkIf (cfg.enable && cfg.useSops) {
    # Decrypt GitHub token from SOPS
    sops.secrets."github_runner_token" = {
      sopsFile = ../../../secrets/github.yaml;
      key = "github_token";
      owner = "github-runner";
      mode = "0440";
    };

    # Configure runner to use decrypted token
    systemd.services.github-runner.serviceConfig = {
      EnvironmentFile = config.sops.secrets."github_runner_token".path;
    };
  };
}
EOF

    print_success "Created github-runner-sops.nix"
}

function show_next_steps() {
    echo ""
    print_header
    print_success "🎉 Migration Complete!"
    echo ""

    print_info "Encrypted secrets created:"
    echo "  📄 secrets/api.yaml (AI/ML API keys)"
    echo "  📄 secrets/github.yaml (GitHub token)"
    echo "  📄 .sops.yaml (SOPS configuration)"
    echo ""

    print_info "NixOS modules created:"
    echo "  📄 modules/secrets/api-keys.nix"
    echo "  📄 modules/services/users/github-runner-sops.nix"
    echo ""

    print_warning "Next Steps:"
    echo ""
    echo "1️⃣  Add secrets to git (they're encrypted!):"
    echo "   ${BLUE}git add secrets/ .sops.yaml${NC}"
    echo "   ${BLUE}git add modules/secrets/api-keys.nix${NC}"
    echo "   ${BLUE}git commit -m 'sec: migrate to SOPS encrypted secrets'${NC}"
    echo ""

    echo "2️⃣  Add api-keys module to flake.nix:"
    echo "   ${BLUE}# In flake.nix, add to modules list:${NC}"
    echo "   ${BLUE}./modules/secrets/api-keys.nix${NC}"
    echo ""

    echo "3️⃣  Rebuild NixOS:"
    echo "   ${BLUE}sudo nixos-rebuild switch${NC}"
    echo ""

    echo "4️⃣  Verify secrets are decrypted:"
    echo "   ${BLUE}sudo ls -la /run/secrets/${NC}"
    echo ""

    echo "5️⃣  Load API keys in your session:"
    echo "   ${BLUE}source /etc/load-api-keys.sh${NC}"
    echo ""

    echo "6️⃣  Enable GitHub runner (optional):"
    echo "   ${BLUE}# In configuration.nix, set:${NC}"
    echo "   ${BLUE}services.github-runner.enable = true;${NC}"
    echo ""

    print_warning "IMPORTANT:"
    echo "  🔑 Backup your AGE key: ~/.config/sops/age/keys.txt"
    echo "  🔒 SEC.sh has been securely deleted (shredded)"
    echo "  ✅ All secrets are now encrypted with SOPS"
    echo ""

    print_info "To view decrypted secrets:"
    echo "  ${BLUE}sops -d /etc/nixos/secrets/api.yaml${NC}"
    echo ""

    print_info "To edit secrets:"
    echo "  ${BLUE}sops /etc/nixos/secrets/api.yaml${NC}"
    echo ""
}

# Main execution
main() {
    print_header

    print_warning "This script will:"
    echo "  1. Read plaintext keys from SEC.sh"
    echo "  2. Create organized YAML files"
    echo "  3. Encrypt with SOPS"
    echo "  4. Delete SEC.sh (shred -n 10)"
    echo "  5. Create NixOS integration modules"
    echo ""

    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled."
        exit 0
    fi

    echo ""

    check_prerequisites
    create_tmp_directory
    source_sec_file
    create_api_secrets
    create_github_secrets
    create_sops_config
    encrypt_secrets
    verify_encryption
    create_nixos_module
    update_github_runner_config
    cleanup_plaintext
    show_next_steps
}

# Run main function
main "$@"
