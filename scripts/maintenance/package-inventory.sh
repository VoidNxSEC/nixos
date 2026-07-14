#!/usr/bin/env bash
# Extract key packages from configuration

echo "=== LARGE PACKAGES IN CURRENT SYSTEM ==="
nix-store --query --requisites /run/current-system | \
  xargs nix path-info --size --closure-size --json 2>/dev/null | \
  jq -r 'to_entries[] | [.value.closureSize, .key] | @tsv' | \
  sort -rn | head -30 | \
  awk '{printf "%8.2f MB  %s\n", $1/1024/1024, $2}' | \
  sed 's|/nix/store/[^-]*-||'

echo ""
echo "=== PACKAGES LIKELY BUILT FROM SOURCE ==="
echo "(Chromium, Electron apps, CUDA packages)"

nix-store --query --requisites /run/current-system | \
  grep -E '(chromium|electron|brave|vscodium|code|cuda|cudnn|tensorrt|hyprland)' | \
  sed 's|/nix/store/[^-]*-||' | sort -u

