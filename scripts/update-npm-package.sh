#!/usr/bin/env bash
# Update NPM Package Helper
# Usage: ./scripts/update-npm-package.sh gemini-cli v0.21.0-nightly.20251210.abc123

set -e

PACKAGE=$1
VERSION=$2
STORAGE_DIR="/etc/nixos/modules/packages/js-packages/storage"
PACKAGE_FILE="${PACKAGE}-${VERSION}.tar.gz"

if [[ -z "$PACKAGE" || -z "$VERSION" ]]; then
  echo "Usage: $0 <package> <version>"
  echo "Example: $0 gemini-cli v0.21.0-nightly.20251210.abc123"
  exit 1
fi

cd "$STORAGE_DIR"

# Download
echo "📦 Downloading $PACKAGE $VERSION..."
wget "https://github.com/google-gemini/${PACKAGE}/archive/refs/tags/${VERSION}.tar.gz" -O "$PACKAGE_FILE"

# Calculate hash
echo "🔐 Calculating SHA256..."
SHA256=$(nix-hash --type sha256 --flat "$PACKAGE_FILE")

echo ""
echo "✅ Downloaded: $STORAGE_DIR/$PACKAGE_FILE"
echo "✅ SHA256: $SHA256"
echo ""
echo "📝 Next steps:"
echo "1. Update modules/packages/js-packages/${PACKAGE}.nix:"
echo "   version = \"${VERSION#v}\";"
echo "   sha256 = \"$SHA256\";"
echo ""
echo "2. Build to get npmDepsHash:"
echo "   cd /etc/nixos && nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages --show-trace 2>&1 | grep 'got:'"
echo ""
echo "3. Update npmDepsHash in ${PACKAGE}.nix"
echo ""
echo "4. Rebuild:"
echo "   sudo nixos-rebuild switch --flake .#kernelcore --max-jobs 8 --cores 8"
