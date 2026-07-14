#!/usr/bin/env bash
# Setup Git Hooks
# This script installs custom git hooks for the repository

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.githooks"

echo "🔧 Setting up Git hooks..."

# Check if hooks directory exists
if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "❌ Hooks directory not found: $HOOKS_DIR"
  exit 1
fi

# Make hooks executable
echo "  → Making hooks executable..."
chmod +x "$HOOKS_DIR"/*

# Configure git to use custom hooks directory
echo "  → Configuring git to use .githooks/..."
git config core.hooksPath .githooks

# Verify configuration
CONFIGURED_HOOKS_PATH=$(git config core.hooksPath)
if [[ "$CONFIGURED_HOOKS_PATH" == ".githooks" ]]; then
  echo "✅ Git hooks installed successfully!"
  echo ""
  echo "Active hooks:"
  ls -1 "$HOOKS_DIR" | while read hook; do
    echo "  - $hook"
  done
  echo ""
  echo "To disable hooks temporarily:"
  echo "  git commit --no-verify"
  echo "  git push --no-verify"
  echo ""
  echo "To uninstall hooks:"
  echo "  git config --unset core.hooksPath"
else
  echo "❌ Failed to configure git hooks"
  exit 1
fi
