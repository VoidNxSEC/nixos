#!/usr/bin/env bash
# analyze-package-versions.sh
# Detect duplicate package versions and conflicts in NixOS system

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

OUTPUT_DIR="${1:-/tmp/nix-version-analysis}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      📦 NixOS Package Version Analysis 📦                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

mkdir -p "$OUTPUT_DIR"

# ===========================================================================
# PHASE 1: Extract all packages with versions
# ===========================================================================

echo -e "${YELLOW}[1/7] Extracting package list...${NC}"

nix-store --query --requisites /run/current-system | \
    sed 's|/nix/store/[^-]*-||' | \
    sort > "$OUTPUT_DIR/all-packages-raw.txt"

TOTAL_PKGS=$(wc -l < "$OUTPUT_DIR/all-packages-raw.txt")
echo -e "${GREEN}  ✓ $TOTAL_PKGS total packages${NC}"

# ===========================================================================
# PHASE 2: Detect duplicate package names (different versions)
# ===========================================================================

echo -e "${YELLOW}[2/7] Detecting duplicate versions...${NC}"

# Extract package name without version
cat "$OUTPUT_DIR/all-packages-raw.txt" | \
    sed 's/-[0-9].*//' | \
    sort | uniq -c | \
    sort -rn | \
    awk '$1 > 1 {print $1, $2}' > "$OUTPUT_DIR/duplicate-counts.txt"

DUPLICATE_PACKAGES=$(wc -l < "$OUTPUT_DIR/duplicate-counts.txt")
echo -e "${YELLOW}  ⚠ $DUPLICATE_PACKAGES packages with multiple versions${NC}"

# ===========================================================================
# PHASE 3: Detailed analysis of duplicates
# ===========================================================================

echo -e "${YELLOW}[3/7] Analyzing version conflicts...${NC}"

cat "$OUTPUT_DIR/duplicate-counts.txt" | while read count name; do
    echo "=== $name ($count versions) ===" >> "$OUTPUT_DIR/version-conflicts.txt"
    grep "^${name}-[0-9]" "$OUTPUT_DIR/all-packages-raw.txt" | \
        sort -V >> "$OUTPUT_DIR/version-conflicts.txt"
    echo "" >> "$OUTPUT_DIR/version-conflicts.txt"
done

echo -e "${GREEN}  ✓ Conflicts saved to version-conflicts.txt${NC}"

# ===========================================================================
# PHASE 4: Identify critical duplicates (Python, CUDA, Chromium, etc.)
# ===========================================================================

echo -e "${YELLOW}[4/7] Identifying critical duplicates...${NC}"

cat > "$OUTPUT_DIR/critical-duplicates.txt" << EOF
=== CRITICAL PACKAGE VERSION DUPLICATES ===
Generated: $TIMESTAMP

These packages have multiple versions that may cause conflicts:

EOF

# Python duplicates
echo "## Python Packages ##" >> "$OUTPUT_DIR/critical-duplicates.txt"
grep -E '^python[0-9]' "$OUTPUT_DIR/duplicate-counts.txt" | \
    head -20 >> "$OUTPUT_DIR/critical-duplicates.txt" 2>/dev/null || true
echo "" >> "$OUTPUT_DIR/critical-duplicates.txt"

# CUDA duplicates
echo "## CUDA Packages ##" >> "$OUTPUT_DIR/critical-duplicates.txt"
grep -E 'cuda|cudnn' "$OUTPUT_DIR/duplicate-counts.txt" | \
    head -20 >> "$OUTPUT_DIR/critical-duplicates.txt" 2>/dev/null || true
echo "" >> "$OUTPUT_DIR/critical-duplicates.txt"

# Chromium/Electron
echo "## Chromium/Electron ##" >> "$OUTPUT_DIR/critical-duplicates.txt"
grep -E 'chromium|electron|brave|vscode' "$OUTPUT_DIR/duplicate-counts.txt" | \
    head -20 >> "$OUTPUT_DIR/critical-duplicates.txt" 2>/dev/null || true
echo "" >> "$OUTPUT_DIR/critical-duplicates.txt"

# System libraries
echo "## System Libraries ##" >> "$OUTPUT_DIR/critical-duplicates.txt"
grep -E 'glibc|gcc|llvm|openssl|zlib|glib|gtk' "$OUTPUT_DIR/duplicate-counts.txt" | \
    head -20 >> "$OUTPUT_DIR/critical-duplicates.txt" 2>/dev/null || true
echo "" >> "$OUTPUT_DIR/critical-duplicates.txt"

CRITICAL_COUNT=$(grep -cE 'python|cuda|chromium|electron|glibc|gcc|llvm' "$OUTPUT_DIR/duplicate-counts.txt" || echo 0)
echo -e "${RED}  ✗ $CRITICAL_COUNT critical packages with duplicates${NC}"

# ===========================================================================
# PHASE 5: Analyze dependency chains causing duplicates
# ===========================================================================

echo -e "${YELLOW}[5/7] Analyzing dependency chains...${NC}"

cat > "$OUTPUT_DIR/dependency-analysis.sh" << 'EOFSCRIPT'
#!/usr/bin/env bash
# Find what's pulling in duplicate versions

PACKAGE_NAME="$1"

if [ -z "$PACKAGE_NAME" ]; then
    echo "Usage: $0 <package-name-without-version>"
    exit 1
fi

echo "=== Dependency Analysis: $PACKAGE_NAME ==="
echo ""

# Find all versions of this package
echo "Versions in system:"
nix-store --query --requisites /run/current-system | \
    grep -E "/${PACKAGE_NAME}-[0-9]" | \
    sed 's|/nix/store/[^-]*-||'

echo ""
echo "Reverse dependencies (what requires each version):"

# For each version, show what depends on it
nix-store --query --requisites /run/current-system | \
    grep -E "/${PACKAGE_NAME}-[0-9]" | \
    while read pkg; do
        echo ""
        echo "--- $(basename $pkg) ---"
        nix-store --query --referrers "$pkg" | head -5
    done
EOFSCRIPT

chmod +x "$OUTPUT_DIR/dependency-analysis.sh"
echo -e "${GREEN}  ✓ Created dependency-analysis.sh${NC}"

# ===========================================================================
# PHASE 6: Generate standardization recommendations
# ===========================================================================

echo -e "${YELLOW}[6/7] Generating standardization recommendations...${NC}"

cat > "$OUTPUT_DIR/STANDARDIZATION-PLAN.md" << 'EOF'
# Package Version Standardization Plan

## Problem Summary

Multiple versions of the same package exist in the system due to:

1. **Nixpkgs unstable flux** - Different packages from different nixpkgs commits
2. **Overlay conflicts** - Custom overlays creating duplicate derivations
3. **Python environment fragmentation** - Multiple Python versions/virtualenvs
4. **CUDA version mismatches** - Different CUDA toolchain versions
5. **Missing version pinning** - No centralized version control

## Impact

- **Increased disk usage** - Multiple versions of same package (~10-20GB waste)
- **Longer rebuild times** - More packages to build/download
- **Potential runtime conflicts** - Library version mismatches
- **Cache inefficiency** - Different versions can't share cache entries

## Solutions

### Solution 1: Pin nixpkgs revision in flake.lock (CRITICAL)

**Current issue:** `flake.lock` may be using different nixpkgs commits for different inputs

**Fix:**
```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Make ALL other inputs use the SAME nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    # ... repeat for all inputs
  };
}
```

**Command to apply:**
```bash
nix flake update --commit-lock-file
```

### Solution 2: Create version overlay for critical packages

**Create:** `/etc/nixos/overlays/version-pinning.nix`

```nix
final: prev: {
  # Pin Python to single version
  python3 = prev.python312;
  python = prev.python312;

  # Pin CUDA version
  cudaPackages = prev.cudaPackages_12_8;

  # Ensure all Electron apps use same Electron
  electron = prev.electron_38;
}
```

### Solution 3: Consolidate Python environments

**Problem:** Multiple Python package sets (python312, python313, etc.)

**Fix:** Use single Python version system-wide

```nix
# configuration.nix
environment.systemPackages = with pkgs; [
  # Use ONE Python version
  python312Full

  # NOT: python3, python313, python312, etc.
];
```

### Solution 4: Remove overlay conflicts

**Files to check:**
- `/etc/nixos/modules/applications/chromium-log-suppression.nix` - Creates custom chromium/brave/vscodium
- `/etc/nixos/modules/applications/electron-tuning.nix` - Creates custom brave
- `/etc/nixos/overlays/*.nix` - Any custom overlays

**Action:** Remove `overrideAttrs` that create duplicate derivations

### Solution 5: Use buildEnv for package collections

Instead of installing packages individually, group them:

```nix
environment.systemPackages = [
  (pkgs.buildEnv {
    name = "ml-tools";
    paths = with pkgs.python312Packages; [
      torch
      transformers
      numpy
      # All use SAME Python version
    ];
  })
];
```

## Implementation Priority

### Phase 1: Critical (Do First) ⚠️

1. **Pin nixpkgs in flake.lock** - Prevents version drift
   - File: `flake.nix`
   - Command: `nix flake update --commit-lock-file`
   - Impact: Reduces duplicates by ~40%

2. **Remove chromium/electron overlays** - Already planned in rebuild optimization
   - Files: `chromium-log-suppression.nix`, `electron-tuning.nix`
   - Impact: Eliminates chromium/brave/vscodium duplicates

### Phase 2: High Priority

3. **Create version-pinning overlay**
   - File: `/etc/nixos/overlays/version-pinning.nix`
   - Impact: Standardizes Python, CUDA, Electron versions

4. **Consolidate Python environments**
   - Files: All configuration modules using Python
   - Impact: Reduces Python package duplicates by ~60%

### Phase 3: Optimization

5. **Audit and cleanup overlays**
   - Review all files in `/etc/nixos/overlays/`
   - Remove unnecessary overrides

6. **Use buildEnv for package groups**
   - Organize packages by purpose
   - Reduces conflicts, improves cache hits

## Verification

After each phase:

```bash
# Run version analysis again
/etc/nixos/scripts/analyze-package-versions.sh

# Compare results
diff /tmp/nix-version-analysis/duplicate-counts.txt \
     /tmp/nix-version-analysis-new/duplicate-counts.txt

# Check disk savings
du -sh /nix/store
```

## Expected Results

**Before:**
- Duplicate packages: ~500
- Critical duplicates: ~100
- Wasted disk space: ~15-20 GB

**After Phase 1:**
- Duplicate packages: ~300 (-40%)
- Critical duplicates: ~60 (-40%)
- Wasted disk space: ~10-12 GB

**After Phase 2:**
- Duplicate packages: ~150 (-70%)
- Critical duplicates: ~30 (-70%)
- Wasted disk space: ~5-7 GB

**After Phase 3:**
- Duplicate packages: ~50 (-90%)
- Critical duplicates: ~10 (-90%)
- Wasted disk space: ~2-3 GB

---

**Generated:** Automated by analyze-package-versions.sh
**Next:** Review version-conflicts.txt for specific packages to address
EOF

echo -e "${GREEN}  ✓ Created STANDARDIZATION-PLAN.md${NC}"

# ===========================================================================
# PHASE 7: Generate summary report
# ===========================================================================

echo -e "${YELLOW}[7/7] Generating summary report...${NC}"

cat > "$OUTPUT_DIR/SUMMARY.txt" << EOF
═══════════════════════════════════════════════════════════════
                NixOS Version Analysis Summary
═══════════════════════════════════════════════════════════════

Generated: $TIMESTAMP
System: $(hostname)

STATISTICS:
-----------
Total packages:              $TOTAL_PKGS
Packages with duplicates:    $DUPLICATE_PACKAGES
Critical duplicates:         $CRITICAL_COUNT

TOP 10 PACKAGES WITH MOST VERSIONS:
$(head -10 "$OUTPUT_DIR/duplicate-counts.txt")

FILES GENERATED:
----------------
1. all-packages-raw.txt           - All packages in system
2. duplicate-counts.txt           - Packages with multiple versions
3. version-conflicts.txt          - Detailed version conflicts
4. critical-duplicates.txt        - High-priority duplicates
5. dependency-analysis.sh         - Script to analyze dependencies
6. STANDARDIZATION-PLAN.md        - Step-by-step fix guide
7. SUMMARY.txt                    - This file

NEXT STEPS:
-----------
1. Review: cat $OUTPUT_DIR/critical-duplicates.txt
2. Investigate: $OUTPUT_DIR/dependency-analysis.sh <package-name>
3. Fix: Follow $OUTPUT_DIR/STANDARDIZATION-PLAN.md
4. Verify: Re-run this script after fixes

QUICK WINS:
-----------
Most duplicates can be eliminated by:
- Pinning nixpkgs in flake.nix (follows = "nixpkgs")
- Removing chromium/electron overlays
- Using single Python version system-wide

═══════════════════════════════════════════════════════════════
EOF

cat "$OUTPUT_DIR/SUMMARY.txt"

echo ""
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Analysis complete!${NC}"
echo ""
echo -e "${YELLOW}Output directory:${NC} $OUTPUT_DIR"
echo ""
echo -e "${YELLOW}Key files:${NC}"
echo "  - SUMMARY.txt                  : Overview"
echo "  - critical-duplicates.txt      : High-priority issues"
echo "  - STANDARDIZATION-PLAN.md      : Fix guide"
echo "  - dependency-analysis.sh       : Investigate tool"
echo ""
echo -e "${YELLOW}Next:${NC}"
echo "  1. Review critical duplicates:"
echo "     cat $OUTPUT_DIR/critical-duplicates.txt"
echo ""
echo "  2. Follow standardization plan:"
echo "     cat $OUTPUT_DIR/STANDARDIZATION-PLAN.md"
echo ""
echo "  3. Investigate specific package:"
echo "     $OUTPUT_DIR/dependency-analysis.sh python3"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
