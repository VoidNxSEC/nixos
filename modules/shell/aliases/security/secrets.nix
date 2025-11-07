{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Security & Secrets Management Aliases
# ============================================================
# SOPS secret management shortcuts
# Uses: /etc/nixos/scripts/add-secret.sh
# ============================================================

{
  environment.shellAliases = {
    # ========================================
    # SOPS Direct Commands
    # ========================================
    # Note: sops-edit, sops-encrypt, sops-decrypt already defined in modules/secrets/sops-config.nix
    # Using different names to avoid conflicts

    # Quick SOPS with AGE key pre-configured
    "sops-quick" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops";
    "sops-view" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d";
    "sops-set" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --set";
    "sops-updatekeys" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops updatekeys";

    # ========================================
    # Secret Management (via helper script)
    # ========================================

    # List all secrets
    "secrets-list" = "/etc/nixos/scripts/add-secret.sh --list";
    "sl" = "/etc/nixos/scripts/add-secret.sh --list";

    # View secrets (descriptografado)
    "secret-view" = "/etc/nixos/scripts/add-secret.sh --view";
    "sv" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d";

    # Edit secrets
    "secret-edit" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops";
    "se" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops";

    # Quick access to common secrets
    "secret-api" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops /etc/nixos/secrets/api.yaml";
    "secret-github" =
      "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops /etc/nixos/secrets/github.yaml";
    "secret-aws" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops /etc/nixos/secrets/aws.yaml";
    "secret-db" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops /etc/nixos/secrets/database.yaml";

    # View specific secrets (read-only)
    "view-api" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d /etc/nixos/secrets/api.yaml";
    "view-github" =
      "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d /etc/nixos/secrets/github.yaml";
    "view-aws" = "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d /etc/nixos/secrets/aws.yaml";
    "view-db" =
      "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d /etc/nixos/secrets/database.yaml";

    # ========================================
    # Create New Secrets
    # ========================================

    "secret-new-api" = "/etc/nixos/scripts/add-secret.sh api";
    "secret-new-github" = "/etc/nixos/scripts/add-secret.sh github";
    "secret-new-db" = "/etc/nixos/scripts/add-secret.sh database";

    # ========================================
    # Extract Secret to Environment Variable
    # ========================================

    # Usage: secret-get api.yaml openai_api_key
    "secret-get" = ''
      sops-get() {
        local file="$1"
        local key="$2"
        if [ -z "$file" ] || [ -z "$key" ]; then
          echo "Usage: secret-get <file> <key>"
          echo "Example: secret-get api.yaml openai_api_key"
          return 1
        fi
        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d --extract "[\"$key\"]" "/etc/nixos/secrets/$file"
      }
      sops-get
    '';

    # ========================================
    # Reencrypt all secrets (after key rotation)
    # ========================================

    "secrets-reencrypt" = ''
      cd /etc/nixos && for file in secrets/*.yaml; do
        echo "Reencrypting $file..."
        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops updatekeys "$file"
      done
    '';

    # ========================================
    # AGE Key Management
    # ========================================

    # Show AGE public key (for sharing)
    "age-pubkey" = "age-keygen -y ~/.config/sops/age/keys.txt";

    # Generate new AGE key (backup old one first!)
    "age-keygen-new" = "age-keygen >> ~/.config/sops/age/keys.txt";

    # ========================================
    # Security Checks
    # ========================================

    # Check for plaintext secrets in repo (DANGEROUS!)
    "secrets-check-plaintext" = ''
      echo "🔍 Checking for potential plaintext secrets..."
      grep -r "password\s*=\|apiKey\s*=\|api_key\s*=\|secret\s*=" /etc/nixos/modules --include="*.nix" --color=always || echo "✅ No plaintext secrets found"
    '';

    # Verify all secrets can be decrypted
    "secrets-verify" = ''
      echo "🔐 Verifying all secrets..."
      for file in /etc/nixos/secrets/*.yaml; do
        if [ -f "$file" ]; then
          echo -n "Checking $(basename $file)... "
          if SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d "$file" > /dev/null 2>&1; then
            echo "✅"
          else
            echo "❌ FAILED"
          fi
        fi
      done
    '';

    # ========================================
    # Helper/Documentation
    # ========================================

    "secrets-help" = ''
            cat <<EOF
      🔐 SOPS Secrets Management - Quick Reference

      📋 List & View:
        secrets-list       List all encrypted secrets
        sl                 Short alias for secrets-list
        sv <file>          View secret (descriptografado)
        view-api           View API keys
        view-github        View GitHub secrets
        view-aws           View AWS credentials
        view-db            View database credentials

      ✏️  Edit:
        se <file>          Edit secret in SOPS
        secret-api         Edit API keys
        secret-github      Edit GitHub secrets
        secret-aws         Edit AWS credentials
        secret-db          Edit database credentials

      ➕ Create New:
        secret-new-api     Create new API keys secret
        secret-new-github  Create new GitHub secret
        secret-new-db      Create new database secret

      🔧 Advanced:
        secret-get <file> <key>    Extract specific key value
        secrets-reencrypt          Reencrypt all secrets
        age-pubkey                 Show your AGE public key
        secrets-verify             Verify all secrets decrypt OK
        secrets-check-plaintext    Check for plaintext leaks

      📖 Documentation:
        cat /etc/nixos/docs/guides/SECRETS.md
        /etc/nixos/scripts/add-secret.sh --help

      EOF
    '';

    "sops-help" = "secrets-help";
  };
}
