#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Generate Repository Architecture Tree Diagram
# ═══════════════════════════════════════════════════════════════════════════
# Creates comprehensive architecture visualization with elegant box-drawing
# Output:
#   - ARCHITECTURE-TREE.txt (UTF-8 box-drawing)
#   - ARCHITECTURE-TREE.md (Markdown format)
#   - docs/architecture/snapshot-YYYYMMDD.txt (versioned)
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

REPO_ROOT="${REPO_ROOT:-/etc/nixos}"
OUTPUT_DIR="${REPO_ROOT}"
OUTPUT_TXT="${OUTPUT_DIR}/ARCHITECTURE-TREE.txt"
OUTPUT_MD="${OUTPUT_DIR}/ARCHITECTURE-TREE.md"
SNAPSHOT_DIR="${REPO_ROOT}/docs/architecture"
SNAPSHOT_FILE="${SNAPSHOT_DIR}/snapshot-$(date +%Y%m%d-%H%M%S).txt"

# Tree settings
MAX_DEPTH="${MAX_DEPTH:-5}"
SHOW_HIDDEN="${SHOW_HIDDEN:-false}"

# Filters
EXCLUDE_PATTERNS=(
  '.git'
  '.direnv'
  'result'
  'result-*'
  '*.qcow2'
  '*.iso'
  '*.img'
  'nixtrap'
  'archive'
  'target'
  'node_modules'
  'build'
  '.backup-staging'
  '__pycache__'
  '*.pyc'
)

# Color codes (for terminal output)
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_DIM='\033[2m'
COLOR_GREEN='\033[32m'
COLOR_BLUE='\033[34m'
COLOR_YELLOW='\033[33m'
COLOR_CYAN='\033[36m'
COLOR_MAGENTA='\033[35m'

# ═══════════════════════════════════════════════════════════════════════════
# Functions
# ═══════════════════════════════════════════════════════════════════════════

log() {
  echo -e "${COLOR_CYAN}▸${COLOR_RESET} $*"
}

success() {
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
}

info() {
  echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $*"
}

# Build exclude pattern for tree command
build_exclude_pattern() {
  local pattern=""
  for exclude in "${EXCLUDE_PATTERNS[@]}"; do
    if [ -n "$pattern" ]; then
      pattern="$pattern|$exclude"
    else
      pattern="$exclude"
    fi
  done
  echo "$pattern"
}

# Generate tree with UTF-8 box-drawing characters
generate_tree() {
  local exclude_pattern
  exclude_pattern=$(build_exclude_pattern)

  local tree_opts=()
  tree_opts+=("-I" "$exclude_pattern")
  tree_opts+=("--dirsfirst")
  tree_opts+=("-F")
  tree_opts+=("-L" "$MAX_DEPTH")

  # Use UTF-8 box-drawing characters (much more elegant!)
  tree_opts+=("--charset" "utf-8")

  if [ "$SHOW_HIDDEN" = "true" ]; then
    tree_opts+=("-a")
  fi

  tree "${tree_opts[@]}" "$REPO_ROOT"
}

# Get repository statistics
get_statistics() {
  local stats_total_files
  local stats_total_dirs
  local stats_nix_files
  local stats_md_files
  local stats_sh_files
  local stats_ml_size
  local stats_repo_size

  stats_total_files=$(find "$REPO_ROOT" -type f \
    -not -path '*/.git/*' \
    -not -path '*/result*' \
    -not -path '*/archive/*' \
    -not -path '*/target/*' \
    -not -path '*/node_modules/*' \
    2>/dev/null | wc -l)

  stats_total_dirs=$(find "$REPO_ROOT" -type d \
    -not -path '*/.git/*' \
    -not -path '*/archive/*' \
    -not -path '*/target/*' \
    2>/dev/null | wc -l)

  stats_nix_files=$(find "$REPO_ROOT" -name '*.nix' \
    -not -path '*/archive/*' \
    2>/dev/null | wc -l)

  stats_md_files=$(find "$REPO_ROOT" -name '*.md' \
    -not -path '*/archive/*' \
    2>/dev/null | wc -l)

  stats_sh_files=$(find "$REPO_ROOT" -name '*.sh' \
    -not -path '*/archive/*' \
    2>/dev/null | wc -l)

  stats_ml_size=$(du -sh "$REPO_ROOT/modules/ml" 2>/dev/null | cut -f1 || echo "N/A")
  stats_repo_size=$(du -sh "$REPO_ROOT" 2>/dev/null | cut -f1 || echo "N/A")

  cat <<EOF
Total Files:       $stats_total_files
Total Directories: $stats_total_dirs
.nix files:        $stats_nix_files
.md files:         $stats_md_files
.sh files:         $stats_sh_files
ML modules size:   $stats_ml_size
Repository size:   $stats_repo_size
EOF
}

# Generate header
generate_header() {
  local format="${1:-txt}"
  local timestamp
  local hostname
  local git_branch
  local git_commit

  timestamp=$(date +"%Y-%m-%d %H:%M:%S %Z")
  hostname=$(hostname)
  git_branch=$(cd "$REPO_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  git_commit=$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  if [ "$format" = "md" ]; then
    cat <<EOF
# NixOS Repository Architecture

> **Auto-Generated Tree Diagram**
> **Generated**: $timestamp
> **Location**: $REPO_ROOT
> **Host**: $hostname
> **Branch**: $git_branch ($git_commit)

## Legend

| Symbol | Meaning |
|--------|---------|
| \`/\`    | Directory |
| \`*\`    | Executable file |
| \`.nix\` | Nix configuration |
| \`.md\`  | Documentation |
| \`.sh\`  | Shell script |

## Filters Applied

✓ **Excluded**: .git, result*, *.iso, *.qcow2, target/, node_modules/, archive/
✓ **Max depth**: $MAX_DEPTH levels
✓ **Sorting**: Directories first, alphabetically sorted

## Repository Statistics

\`\`\`
$(get_statistics)
\`\`\`

## Architecture Tree

\`\`\`
EOF
  else
    cat <<EOF
╔═══════════════════════════════════════════════════════════════════════════╗
║                    NIXOS REPOSITORY ARCHITECTURE                          ║
║                       Auto-Generated Tree Diagram                         ║
╚═══════════════════════════════════════════════════════════════════════════╝

Generated:  $timestamp
Location:   $REPO_ROOT
Host:       $hostname
Branch:     $git_branch ($git_commit)

LEGEND:
  /     → Directory
  *     → Executable file
  .nix  → Nix configuration
  .md   → Documentation
  .sh   → Shell script

FILTERS APPLIED:
  ✓ Excluded: .git, result*, *.iso, *.qcow2, target/, node_modules/, archive/
  ✓ Max depth: $MAX_DEPTH levels
  ✓ Directories first, alphabetically sorted

REPOSITORY STATISTICS:
$(get_statistics | sed 's/^/  /')

═══════════════════════════════════════════════════════════════════════════

EOF
  fi
}

# Generate footer
generate_footer() {
  local format="${1:-txt}"

  if [ "$format" = "md" ]; then
    cat <<EOF
\`\`\`

## Key Areas

### Core System Configuration
- \`hosts/\` - Host-specific configurations
- \`modules/\` - Modular NixOS configurations
- \`overlays/\` - Package overlays
- \`lib/\` - Utility functions and packages

### Security
- \`modules/security/\` - Security hardening
- \`sec/\` - Final security overrides
- \`secrets/\` - SOPS-encrypted secrets

### Machine Learning
- \`modules/ml/\` - ML infrastructure
  - ⚠️ **REFACTORING PLANNED**: See \`docs/ML-ARCHITECTURE-REFACTORING.md\`
  - Target: 3.8GB → 100KB (separate repos)

### Documentation
- \`docs/\` - Comprehensive documentation
- \`CLAUDE.md\` - AI assistant instructions
- \`README.md\` - Repository overview

### Development
- \`scripts/\` - Utility scripts
- \`lib/shells.nix\` - Development shells

## Related Documentation

- [ML Refactoring Plan](docs/ML-ARCHITECTURE-REFACTORING.md)
- [~/dev Security](docs/DEV-DIRECTORY-SECURITY.md)
- [Repository Restructuring](CLAUDE.md)

## Maintenance

This diagram is auto-generated. To regenerate:

\`\`\`bash
bash scripts/generate-architecture-tree.sh
\`\`\`

**Last Generated**: $(date +"%Y-%m-%d %H:%M:%S")
EOF
  else
    cat <<EOF

═══════════════════════════════════════════════════════════════════════════

KEY AREAS:
  • hosts/           → Host-specific configurations
  • modules/         → Modular NixOS configurations
  • modules/ml/      → ML infrastructure (⚠️ REFACTORING PLANNED)
  • modules/security → Security hardening
  • docs/            → Documentation
  • scripts/         → Utility scripts

RELATED DOCUMENTATION:
  • ML Refactoring: docs/ML-ARCHITECTURE-REFACTORING.md
  • ~/dev Security:  docs/DEV-DIRECTORY-SECURITY.md
  • Restructuring:   CLAUDE.md

MAINTENANCE:
  To regenerate: bash scripts/generate-architecture-tree.sh
  Last generated: $(date +"%Y-%m-%d %H:%M:%S")

═══════════════════════════════════════════════════════════════════════════
EOF
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════

main() {
  log "Generating repository architecture tree..."

  cd "$REPO_ROOT"

  # Create snapshot directory
  mkdir -p "$SNAPSHOT_DIR"

  # Generate TXT format (UTF-8 box-drawing)
  log "Creating TXT format with UTF-8 box-drawing..."
  {
    generate_header "txt"
    generate_tree
    generate_footer "txt"
  } > "$OUTPUT_TXT"

  success "TXT diagram: $OUTPUT_TXT"

  # Generate Markdown format
  log "Creating Markdown format..."
  {
    generate_header "md"
    generate_tree
    generate_footer "md"
  } > "$OUTPUT_MD"

  success "Markdown diagram: $OUTPUT_MD"

  # Create versioned snapshot
  log "Creating versioned snapshot..."
  cp "$OUTPUT_TXT" "$SNAPSHOT_FILE"
  success "Snapshot: $SNAPSHOT_FILE"

  # Display summary
  echo ""
  info "Architecture tree generation complete!"
  echo ""
  echo "  📄 Text format:     $OUTPUT_TXT"
  echo "  📝 Markdown format: $OUTPUT_MD"
  echo "  📸 Snapshot:        $SNAPSHOT_FILE"
  echo ""

  # Display statistics
  info "Repository Statistics:"
  get_statistics | sed 's/^/  /'
  echo ""

  # Tip
  info "Tip: Use 'cat $OUTPUT_TXT' or 'less $OUTPUT_TXT' to view"
  info "      Or open $OUTPUT_MD in your editor for Markdown view"
}

# ═══════════════════════════════════════════════════════════════════════════
# Run
# ═══════════════════════════════════════════════════════════════════════════

main "$@"
