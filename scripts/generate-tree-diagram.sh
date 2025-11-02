#!/usr/bin/env bash
# ============================================================
# Generate Repository Tree Diagram
# ============================================================
# Creates comprehensive architecture visualization
# Output: ARCHITECTURE-TREE.txt
# ============================================================

set -euo pipefail

REPO_ROOT="/etc/nixos"
OUTPUT_FILE="${REPO_ROOT}/ARCHITECTURE-TREE.txt"

cd "$REPO_ROOT"

echo "🌳 Generating repository tree diagram..."

# ============================================================
# Generate Tree with Smart Filtering
# ============================================================

tree -a \
  -I '.git|.direnv|result|result-*|*.qcow2|*.iso|*.img|nixtrap|archive' \
  --charset ascii \
  -F \
  --dirsfirst \
  -L 5 \
  > "$OUTPUT_FILE"

# ============================================================
# Add Header
# ============================================================

cat > "${OUTPUT_FILE}.tmp" << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                  NIXOS REPOSITORY ARCHITECTURE                     ║
║                     Auto-Generated Tree Diagram                    ║
╚════════════════════════════════════════════════════════════════════╝

Generated: $(date +"%Y-%m-%d %H:%M:%S")
Location: /etc/nixos
Host: $(hostname)

LEGEND:
  /     - Directory
  *     - Executable file
  .nix  - Nix configuration
  .md   - Documentation
  .sh   - Shell script

FILTERS APPLIED:
  ✓ Excluded: .git, result*, *.iso, *.qcow2, archive/, nixtrap/
  ✓ Max depth: 5 levels
  ✓ Directories first, alphabetically sorted

════════════════════════════════════════════════════════════════════

EOF

# Append tree output
cat "$OUTPUT_FILE" >> "${OUTPUT_FILE}.tmp"
mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

echo "✅ Tree diagram generated: $OUTPUT_FILE"
echo ""
echo "📊 Statistics:"
echo "   Files: $(find . -type f -not -path '*/\.*' -not -path '*/archive/*' -not -path '*/result*' | wc -l)"
echo "   Directories: $(find . -type d -not -path '*/\.*' -not -path '*/archive/*' | wc -l)"
echo "   .nix files: $(find . -name '*.nix' -not -path '*/archive/*' | wc -l)"
echo "   .md files: $(find . -name '*.md' -not -path '*/archive/*' | wc -l)"
echo ""
echo "📝 To annotate manually, see: ARCHITECTURE-BLUEPRINT.md"
