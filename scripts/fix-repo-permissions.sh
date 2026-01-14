#!/usr/bin/env bash
# Fix repository file permissions
# Ensures consistent permissions across all files in the NixOS config repository
#
# This addresses issues caused by restrictive umask (077) which creates files with 600 permissions
# Standard source files should be 644 (readable by all, writable by owner)

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "/etc/nixos")
cd "$REPO_ROOT"

echo "🔧 Fixing repository permissions..."
echo "📂 Repository: $REPO_ROOT"
echo ""

# Fix Nix files
echo "📄 Fixing .nix files..."
find . -type f -name "*.nix" -perm 0600 -not -path "./.git/*" -not -path "./result*" -exec chmod 644 {} + 2>/dev/null || true

# Fix documentation
echo "📄 Fixing .md files..."
find . -type f -name "*.md" -perm 0600 -not -path "./.git/*" -not -path "./result*" -exec chmod 644 {} + 2>/dev/null || true

# Fix YAML/YML
echo "📄 Fixing .yml/.yaml files..."
find . -type f \( -name "*.yml" -o -name "*.yaml" \) -perm 0600 -not -path "./.git/*" -not -path "./result*" -exec chmod 644 {} + 2>/dev/null || true

# Fix JSON configs
echo "📄 Fixing .json files..."
find . -type f -name "*.json" -perm 0600 -not -path "./.git/*" -not -path "./result*" -exec chmod 644 {} + 2>/dev/null || true

# Fix shell scripts (make them executable)
echo "📄 Fixing shell scripts..."
find scripts/ .githooks/ -type f -name "*.sh" ! -perm 0755 -exec chmod 755 {} + 2>/dev/null || true

# Fix Python scripts
echo "📄 Fixing Python files..."
find . -type f -name "*.py" -perm 0600 -not -path "./.git/*" -not -path "./result*" -exec chmod 644 {} + 2>/dev/null || true

# Special handling for secrets directory
if [[ -d "secrets/" ]]; then
    echo "🔒 Fixing secrets directory..."
    chmod 755 secrets/ 2>/dev/null || true
    find secrets/ -type d -exec chmod 755 {} + 2>/dev/null || true
    find secrets/ -type f -name "*.yaml" -exec chmod 644 {} + 2>/dev/null || true
fi

# Verification
echo ""
echo "📊 Verification:"
remaining=$(find . -type f \( -name "*.nix" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) -perm 0600 -not -path "./.git/*" -not -path "./result*" 2>/dev/null | wc -l)

if [[ $remaining -eq 0 ]]; then
    echo "✅ All source files have correct permissions!"
else
    echo "⚠️  Warning: $remaining files still have restrictive permissions"
fi

echo ""
echo "💡 Current umask: $(umask)"
echo "   Recommended umask for development: 022"
echo ""
echo "✅ Repository permissions fixed!"
echo ""
echo "Next steps:"
echo "   git status"
echo "   git add -u"
echo "   git commit -m 'fix: normalize file permissions (644 for source files)'"
echo "   git push"
