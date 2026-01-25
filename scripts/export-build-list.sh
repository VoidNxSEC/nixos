#!/usr/bin/env bash
# export-build-list.sh
# Export current system packages for remote build server

set -euo pipefail

OUTPUT_DIR="${1:-/tmp/nix-build-export}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== NixOS Build List Exporter ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# 1. Export full system closure
echo "[1/6] Exporting system closure..."
nix-store --query --requisites /run/current-system > "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt"
TOTAL_PACKAGES=$(wc -l < "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt")
echo "  ✓ $TOTAL_PACKAGES packages exported"

# 2. Export heavy packages
echo "[2/6] Identifying heavy packages (>500MB)..."
nix path-info --size --closure-size --json $(cat "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt") 2>/dev/null | \
  jq -r 'to_entries[] | select(.value.closureSize > 500000000) | [.value.closureSize, .key] | @tsv' | \
  sort -rn | \
  awk '{printf "%8.2f GB  %s\n", $1/1024/1024/1024, $2}' | \
  sed 's|/nix/store/[^-]*-||' > "$OUTPUT_DIR/heavy-packages-$TIMESTAMP.txt"
HEAVY_COUNT=$(wc -l < "$OUTPUT_DIR/heavy-packages-$TIMESTAMP.txt")
echo "  ✓ $HEAVY_COUNT packages >500MB"

# 3. Export chromium/electron packages
echo "[3/6] Identifying Chromium/Electron packages..."
grep -E '(chromium|electron|brave|vscodium|vscode|code-[0-9])' "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt" | \
  sed 's|/nix/store/[^-]*-||' | \
  sort -u > "$OUTPUT_DIR/chromium-packages-$TIMESTAMP.txt" || true
CHROMIUM_COUNT=$(wc -l < "$OUTPUT_DIR/chromium-packages-$TIMESTAMP.txt" || echo 0)
echo "  ✓ $CHROMIUM_COUNT Chromium/Electron packages"

# 4. Export CUDA packages
echo "[4/6] Identifying CUDA packages..."
grep -E 'cuda|cudnn|tensorrt|nccl' "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt" | \
  sed 's|/nix/store/[^-]*-||' | \
  sort -u > "$OUTPUT_DIR/cuda-packages-$TIMESTAMP.txt" || true
CUDA_COUNT=$(wc -l < "$OUTPUT_DIR/cuda-packages-$TIMESTAMP.txt" || echo 0)
echo "  ✓ $CUDA_COUNT CUDA packages"

# 5. Export Python packages
echo "[5/6] Identifying Python packages..."
grep -E 'python3|python[0-9]' "$OUTPUT_DIR/system-closure-$TIMESTAMP.txt" | \
  sed 's|/nix/store/[^-]*-||' | \
  sort -u > "$OUTPUT_DIR/python-packages-$TIMESTAMP.txt" || true
PYTHON_COUNT=$(wc -l < "$OUTPUT_DIR/python-packages-$TIMESTAMP.txt" || echo 0)
echo "  ✓ $PYTHON_COUNT Python packages"

# 6. Create build script for remote server
echo "[6/6] Creating remote build script..."
cat > "$OUTPUT_DIR/remote-build.sh" << 'EOFSCRIPT'
#!/usr/bin/env bash
# Remote build script - Run on build server
# Generated from: kernelcore@nx

set -euo pipefail

CACHE_URL="${1:-http://192.168.15.7:5000}"
BUILD_DIR="/tmp/nix-remote-build"

echo "=== NixOS Remote Build Script ==="
echo "Cache URL: $CACHE_URL"
echo ""

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Read package list
if [ ! -f "system-closure-*.txt" ]; then
    echo "ERROR: No system-closure-*.txt file found"
    echo "Copy the export files to $BUILD_DIR first"
    exit 1
fi

CLOSURE_FILE=$(ls system-closure-*.txt | head -1)
TOTAL=$(wc -l < "$CLOSURE_FILE")

echo "Building $TOTAL packages..."
echo ""

# Option 1: Build everything
build_all() {
    echo "Building all packages..."

    while read -r pkg; do
        echo "  Building: $(basename $pkg)"
        nix-store --realise "$pkg" 2>&1 | grep -v "^copying\|^building"
    done < "$CLOSURE_FILE"
}

# Option 2: Build only heavy packages
build_heavy() {
    echo "Building only heavy packages (>500MB)..."

    if [ ! -f "heavy-packages-*.txt" ]; then
        echo "ERROR: No heavy-packages-*.txt file found"
        return 1
    fi

    HEAVY_FILE=$(ls heavy-packages-*.txt | head -1)

    # Extract store paths from heavy packages file
    while read -r line; do
        # Format: "  X.XX GB  package-name-version"
        PKG_NAME=$(echo "$line" | awk '{print $3}')
        grep "$PKG_NAME" "$CLOSURE_FILE" | head -1
    done < "$HEAVY_FILE" | while read -r pkg; do
        echo "  Building: $(basename $pkg)"
        nix-store --realise "$pkg" || echo "  ✗ Failed: $pkg"
    done
}

# Option 3: Build specific category
build_category() {
    local category="$1"
    local file="${category}-packages-*.txt"

    if [ ! -f $file ]; then
        echo "ERROR: No $file found"
        return 1
    fi

    echo "Building $category packages..."

    CATEGORY_FILE=$(ls $file | head -1)

    while read -r pkg_name; do
        grep "$pkg_name" "$CLOSURE_FILE" | head -1
    done < "$CATEGORY_FILE" | while read -r pkg; do
        echo "  Building: $(basename $pkg)"
        nix-store --realise "$pkg" || echo "  ✗ Failed: $pkg"
    done
}

# Push to cache
push_to_cache() {
    echo ""
    echo "Pushing to cache: $CACHE_URL"

    # Sign and push all built packages
    while read -r pkg; do
        if nix-store --check-validity "$pkg" 2>/dev/null; then
            echo "  Pushing: $(basename $pkg)"
            nix copy --to "$CACHE_URL" "$pkg" || echo "  ✗ Failed to push: $pkg"
        fi
    done < "$CLOSURE_FILE"
}

# Menu
echo "Choose build strategy:"
echo "  1) Build everything (~2-3 hours)"
echo "  2) Build only heavy packages (>500MB) (~1 hour)"
echo "  3) Build Chromium/Electron only (~45 min)"
echo "  4) Build CUDA packages only (~30 min)"
echo "  5) Build Python packages only (~20 min)"
echo "  6) Push existing packages to cache (no build)"
echo ""
read -p "Choice [1-6]: " choice

case $choice in
    1) build_all && push_to_cache ;;
    2) build_heavy && push_to_cache ;;
    3) build_category "chromium" && push_to_cache ;;
    4) build_category "cuda" && push_to_cache ;;
    5) build_category "python" && push_to_cache ;;
    6) push_to_cache ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

echo ""
echo "✓ Done!"
echo ""
echo "Next steps on laptop:"
echo "  1. Verify cache has packages:"
echo "     nix path-info --store $CACHE_URL /nix/store/..."
echo "  2. Rebuild:"
echo "     sudo nixos-rebuild switch"
EOFSCRIPT

chmod +x "$OUTPUT_DIR/remote-build.sh"
echo "  ✓ Script created: $OUTPUT_DIR/remote-build.sh"

# Create summary
echo ""
echo "=== Export Summary ==="
cat > "$OUTPUT_DIR/README.txt" << EOF
NixOS Build Export
Generated: $TIMESTAMP
From: kernelcore@nx

Total Packages: $TOTAL_PACKAGES
Heavy Packages (>500MB): $HEAVY_COUNT
Chromium/Electron: $CHROMIUM_COUNT
CUDA Packages: $CUDA_COUNT
Python Packages: $PYTHON_COUNT

Files:
- system-closure-$TIMESTAMP.txt      : All package store paths
- heavy-packages-$TIMESTAMP.txt      : Packages >500MB
- chromium-packages-$TIMESTAMP.txt   : Chromium/Electron packages
- cuda-packages-$TIMESTAMP.txt       : CUDA packages
- python-packages-$TIMESTAMP.txt     : Python packages
- remote-build.sh                    : Build script for remote server

Usage:
1. Copy this directory to build server:
   scp -r $OUTPUT_DIR build-server:/tmp/

2. On build server:
   cd /tmp/$(basename $OUTPUT_DIR)
   ./remote-build.sh http://192.168.15.7:5000

3. On laptop:
   sudo nixos-rebuild switch
   (Should download from cache instead of building)
EOF

cat "$OUTPUT_DIR/README.txt"

echo ""
echo "=== Files Created ==="
ls -lh "$OUTPUT_DIR"

echo ""
echo "=== Next Steps ==="
echo "1. Copy to build server:"
echo "   scp -r $OUTPUT_DIR build-server:/tmp/"
echo ""
echo "2. On build server, run:"
echo "   cd /tmp/$(basename $OUTPUT_DIR)"
echo "   ./remote-build.sh http://192.168.15.7:5000"
echo ""
echo "3. On laptop, rebuild:"
echo "   sudo nixos-rebuild switch"
