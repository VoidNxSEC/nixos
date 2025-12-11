#!/usr/bin/env bash
set -e

echo "Updating packages with nvfetcher..."

# Ensure we are in the project root
cd "$(dirname "$0")/.."

if ! command -v nvfetcher &> /dev/null; then
    echo "nvfetcher not found, running via nix run..."
    nix run nixpkgs#nvfetcher -- -c modules/packages/nvfetcher.toml -o modules/packages/_sources
else
    nvfetcher -c modules/packages/nvfetcher.toml -o modules/packages/_sources
fi

echo "Package sources updated in modules/packages/_sources/generated.nix"
