#!/usr/bin/env bash
# Fix permissions for SOPS-encrypted secrets directory
# These files are encrypted, so it's safe to make them readable

set -e

SECRETS_DIR="/etc/nixos/secrets"

echo "🔧 Fixing secrets directory permissions..."

# Make secrets directory readable by owner and group
chmod 755 "$SECRETS_DIR"
echo "✓ Set secrets/ to 755 (drwxr-xr-x)"

# Make secrets subdirectories readable
if [ -d "$SECRETS_DIR/ssh-keys" ]; then
    chmod 755 "$SECRETS_DIR/ssh-keys"
    echo "✓ Set secrets/ssh-keys/ to 755"
fi

# Make all .yaml files readable (they are encrypted)
find "$SECRETS_DIR" -type f -name "*.yaml" -exec chmod 644 {} \;
echo "✓ Set all .yaml files to 644 (-rw-r--r--)"

# Verify permissions
echo ""
echo "📋 Current permissions:"
ls -la "$SECRETS_DIR"
if [ -d "$SECRETS_DIR/ssh-keys" ]; then
    echo ""
    echo "📋 SSH keys directory:"
    ls -la "$SECRETS_DIR/ssh-keys"
fi

echo ""
echo "✅ Permissions fixed! You can now run:"
echo "   git add ."
echo "   nix flake check"
echo "   git push"
