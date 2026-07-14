#!/usr/bin/env bash
# Sync SOPS secrets to GitHub Secrets (DEPRECATED - use SOPS directly in workflows)
#
# This script is kept for backwards compatibility but should NOT be used.
# Instead, use the SOPS integration documented in docs/GITHUB-SOPS-INTEGRATION.md

set -euo pipefail

echo "⚠️  WARNING: This script is DEPRECATED"
echo ""
echo "Modern approach: Use SOPS directly in GitHub Actions workflows"
echo "See: docs/GITHUB-SOPS-INTEGRATION.md"
echo ""
read -p "Continue anyway? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# Configuration
REPO="${GITHUB_REPOSITORY:-kernelcore/nixos}"  # Override with env var
SECRETS_FILE="secrets/github.yaml"

echo "🔐 Syncing SOPS secrets to GitHub..."
echo "Repository: $REPO"
echo ""

# Check dependencies
if ! command -v sops &> /dev/null; then
  echo "❌ sops not found. Install with: nix-env -iA nixpkgs.sops"
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "❌ gh (GitHub CLI) not found. Install with: nix-env -iA nixpkgs.gh"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "❌ yq not found. Install with: nix-env -iA nixpkgs.yq"
  exit 1
fi

# Check gh authentication
if ! gh auth status &> /dev/null; then
  echo "❌ Not authenticated with GitHub CLI"
  echo "Run: gh auth login"
  exit 1
fi

# Check secrets file exists
if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "❌ Secrets file not found: $SECRETS_FILE"
  exit 1
fi

# Decrypt secrets
echo "📂 Decrypting $SECRETS_FILE..."
DECRYPTED=$(sops -d "$SECRETS_FILE")

# Extract and sync secrets
echo ""
echo "Syncing secrets to GitHub repository: $REPO"
echo ""

# Cachix auth token
if CACHIX_TOKEN=$(echo "$DECRYPTED" | yq -r '.github.cachix_auth_token // empty'); then
  if [[ -n "$CACHIX_TOKEN" ]]; then
    echo "  → Setting CACHIX_AUTH_TOKEN..."
    echo "$CACHIX_TOKEN" | gh secret set CACHIX_AUTH_TOKEN --repo "$REPO"
    echo "    ✅ CACHIX_AUTH_TOKEN synced"
  fi
fi

# GitHub Personal Access Token
if GITHUB_PAT=$(echo "$DECRYPTED" | yq -r '.github.personal_access_token // empty'); then
  if [[ -n "$GITHUB_PAT" ]]; then
    echo "  → Setting GITHUB_TOKEN..."
    echo "$GITHUB_PAT" | gh secret set GITHUB_TOKEN --repo "$REPO"
    echo "    ✅ GITHUB_TOKEN synced"
  fi
fi

# Runner token
if RUNNER_TOKEN=$(echo "$DECRYPTED" | yq -r '.github.runner_token // empty'); then
  if [[ -n "$RUNNER_TOKEN" ]]; then
    echo "  → Setting RUNNER_TOKEN..."
    echo "$RUNNER_TOKEN" | gh secret set RUNNER_TOKEN --repo "$REPO"
    echo "    ✅ RUNNER_TOKEN synced"
  fi
fi

# Deploy key
if DEPLOY_KEY=$(echo "$DECRYPTED" | yq -r '.github.deploy_key_private // empty'); then
  if [[ -n "$DEPLOY_KEY" ]]; then
    echo "  → Setting DEPLOY_KEY..."
    echo "$DEPLOY_KEY" | gh secret set DEPLOY_KEY --repo "$REPO"
    echo "    ✅ DEPLOY_KEY synced"
  fi
fi

echo ""
echo "✅ Secrets synced to GitHub repository"
echo ""
echo "⚠️  IMPORTANT: This approach is deprecated!"
echo "   Migrate to SOPS-native workflows instead."
echo "   See: docs/GITHUB-SOPS-INTEGRATION.md"
