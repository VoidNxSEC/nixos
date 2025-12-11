#!/usr/bin/env bash
# Update Rust Package Helper
# Usage: ./scripts/update-rust-package.sh codex rust-v0.57.0

set -e

PACKAGE=$1
TAG=$2
STORAGE_DIR="/etc/nixos/modules/packages/tar-packages/storage"
ARCH="x86_64-unknown-linux-musl"

if [[ -z "$PACKAGE" || -z "$TAG" ]]; then
  echo "Usage: $0 <package> <release-tag>"
  echo "Example: $0 codex rust-v0.57.0"
  exit 1
fi

cd "$STORAGE_DIR"

FILE="${PACKAGE}-${ARCH}.tar.gz"

# Download (adjust URL pattern as needed)
echo "📦 Downloading $PACKAGE $TAG..."
wget "https://github.com/openai/${PACKAGE}/releases/download/${TAG}/${FILE}" -O "${FILE}"

# Calculate hash
echo "🔐 Calculating SHA256..."
SHA256=$(nix-hash --type sha256 --flat "$FILE")

echo ""
echo "✅ Downloaded: $STORAGE_DIR/$FILE"
echo "✅ SHA256: $SHA256"
echo ""
echo "📝 Update modules/packages/tar-packages/packages/${PACKAGE}.nix:"
echo "  source.sha256 = \"$SHA256\";"
echo ""
echo "🔨 Then rebuild:"
echo "  sudo nixos-rebuild switch --flake .#kernelcore --max-jobs 8 --cores 8"
