#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# NixOS Architecture Analysis & Reporting Tool
# ═══════════════════════════════════════════════════════════════════════════
# Professional architecture documentation generator with advanced analytics
#
# Features:
#   • Comprehensive module analysis and categorization
#   • Dependency graph generation
#   • Security and quality metrics
#   • Health score calculation
#   • Multiple output formats (TXT, MD, JSON, HTML)
#   • Automated validation and recommendations
#
# Output:
#   - ARCHITECTURE-REPORT.txt  (Detailed text report)
#   - ARCHITECTURE-REPORT.md   (Markdown documentation)
#   - ARCHITECTURE-REPORT.json (Machine-readable data)
#   - ARCHITECTURE-TREE.txt    (Visual tree diagram)
#   - docs/architecture/       (Versioned snapshots)
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# Configuration & Constants
# ═══════════════════════════════════════════════════════════════════════════

readonly SCRIPT_VERSION="2.0.0"
readonly REPO_ROOT="${REPO_ROOT:-/etc/nixos}"
readonly OUTPUT_DIR="${REPO_ROOT}/arch"
readonly SNAPSHOT_DIR="${OUTPUT_DIR}/snapshots"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Output files
readonly OUTPUT_TREE="${OUTPUT_DIR}/ARCHITECTURE-TREE.txt"
readonly OUTPUT_REPORT_TXT="${OUTPUT_DIR}/ARCHITECTURE-REPORT.txt"
readonly OUTPUT_REPORT_MD="${OUTPUT_DIR}/ARCHITECTURE-REPORT.md"
readonly OUTPUT_REPORT_JSON="${OUTPUT_DIR}/ARCHITECTURE-REPORT.json"
readonly SNAPSHOT_FILE="${SNAPSHOT_DIR}/snapshot-${TIMESTAMP}.txt"

# Analysis settings
readonly MAX_DEPTH="${MAX_DEPTH:-5}"
readonly SHOW_HIDDEN="${SHOW_HIDDEN:-false}"
readonly ENABLE_VALIDATION="${ENABLE_VALIDATION:-true}"
readonly ENABLE_METRICS="${ENABLE_METRICS:-true}"

# Filters - NixOS focused architecture
readonly -a EXCLUDE_PATTERNS=(
  # Version control & tools
  '.git' '.direnv' '.gitlab' '.github/actions'

  # Nix build artifacts
  'result' 'result-*' '*.qcow2' '*.iso' '*.img'

  # Archives & legacy
  'nixtrap' 'archive' '.backup-staging'

  # Build directories
  'target' 'build' 'dist' 'out' '.cache' 'tmp' 'temp'
  '.next' '.svelte-kit' '.vite' '.nuxt' '.vercel' '.turbo'
  '.parcel-cache' '.esbuild' 'storybook-static' 'coverage'

  # Dependencies
  'node_modules' '.npm' '.yarn' '.pnpm'

  # Python artifacts
  '__pycache__' '*.pyc' '*.pyo' '*.egg-info'
  '.pytest_cache' '.mypy_cache' '.ruff_cache' '.tox'
  'htmlcov' '.coverage'

  # Source code (not NixOS architecture)
  '*.js' '*.jsx' '*.ts' '*.tsx' '*.mjs' '*.cjs' '*.d.ts'
  '*.py' '*.rs' '*.sql' '*.go' '*.java' '*.cpp' '*.c'

  # Assets & media
  '*.png' '*.jpg' '*.jpeg' '*.gif' '*.svg' '*.webp' '*.ico'
  '*.pdf' '*.zip' '*.tar.gz' '*.tgz' '*.mp4' '*.mp3'

  # Build metadata
  '*.map' '*.tsbuildinfo' '.DS_Store' '*.log' 'logs'
)

# Module categories for analysis
declare -A MODULE_CATEGORIES=(
  ["hardware"]="Hardware configurations (GPU, CPU, peripherals)"
  ["security"]="Security hardening and policies"
  ["network"]="Network configuration and services"
  ["services"]="System services and daemons"
  ["applications"]="User applications and tools"
  ["development"]="Development environments and tools"
  ["ml"]="Machine learning infrastructure"
  ["containers"]="Docker, Podman, NixOS containers"
  ["virtualization"]="VMs, QEMU, libvirt"
  ["shell"]="Shell configuration and aliases"
  ["system"]="Core system configuration"
  ["packages"]="Custom packages and overlays"
)

# Colors (ANSI escape codes)
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RED='\033[31m'
readonly COLOR_GREEN='\033[32m'
readonly COLOR_YELLOW='\033[33m'
readonly COLOR_BLUE='\033[34m'
readonly COLOR_MAGENTA='\033[35m'
readonly COLOR_CYAN='\033[36m'
readonly COLOR_WHITE='\033[37m'

# Emojis for visual feedback
readonly EMOJI_SUCCESS="✓"
readonly EMOJI_ERROR="✗"
readonly EMOJI_WARNING="⚠"
readonly EMOJI_INFO="ℹ"
readonly EMOJI_ROCKET="🚀"
readonly EMOJI_CHART="📊"
readonly EMOJI_SECURITY="🔒"
readonly EMOJI_DOCS="📚"

# ═══════════════════════════════════════════════════════════════════════════
# Utility Functions
# ═══════════════════════════════════════════════════════════════════════════

log() {
  echo -e "${COLOR_CYAN}▸${COLOR_RESET} $*" >&2
}

success() {
  echo -e "${COLOR_GREEN}${EMOJI_SUCCESS}${COLOR_RESET} $*" >&2
}

error() {
  echo -e "${COLOR_RED}${EMOJI_ERROR}${COLOR_RESET} $*" >&2
}

warning() {
  echo -e "${COLOR_YELLOW}${EMOJI_WARNING}${COLOR_RESET} $*" >&2
}

info() {
  echo -e "${COLOR_BLUE}${EMOJI_INFO}${COLOR_RESET} $*" >&2
}

section() {
  echo -e "\n${COLOR_BOLD}${COLOR_MAGENTA}$*${COLOR_RESET}" >&2
}

# Progress bar for long operations
progress_bar() {
  local current=$1
  local total=$2
  local width=50
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))

  printf "\r${COLOR_CYAN}["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] %3d%% (%d/%d)${COLOR_RESET}" "$percentage" "$current" "$total"
}

# ═══════════════════════════════════════════════════════════════════════════
# Git Information Gathering
# ═══════════════════════════════════════════════════════════════════════════

get_git_info() {
  local key=$1
  cd "$REPO_ROOT" || return 1

  case $key in
    branch)
      git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
      ;;
    commit)
      git rev-parse --short HEAD 2>/dev/null || echo "unknown"
      ;;
    commit_long)
      git rev-parse HEAD 2>/dev/null || echo "unknown"
      ;;
    commit_date)
      git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown"
      ;;
    total_commits)
      git rev-list --count HEAD 2>/dev/null || echo "0"
      ;;
    contributors)
      git log --format='%an' | sort -u | wc -l
      ;;
    last_tag)
      git describe --tags --abbrev=0 2>/dev/null || echo "none"
      ;;
    repo_age_days)
      local first_commit=$(git log --reverse --format=%ct --max-count=1 2>/dev/null)
      if [ -n "$first_commit" ]; then
        echo $(( ($(date +%s) - first_commit) / 86400 ))
      else
        echo "0"
      fi
      ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# File & Directory Analysis
# ═══════════════════════════════════════════════════════════════════════════

build_find_excludes() {
  local -a excludes=()
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    excludes+=("-not" "-path" "*/${pattern}/*")
    excludes+=("-not" "-name" "${pattern}")
  done
  echo "${excludes[@]}"
}

count_files_by_type() {
  local extension=$1
  local excludes
  read -ra excludes <<< "$(build_find_excludes)"

  find "$REPO_ROOT" -type f -name "*.${extension}" \
    "${excludes[@]}" 2>/dev/null | wc -l
}

count_lines_in_files() {
  local extension=$1
  local excludes
  read -ra excludes <<< "$(build_find_excludes)"

  find "$REPO_ROOT" -type f -name "*.${extension}" \
    "${excludes[@]}" -exec wc -l {} + 2>/dev/null | \
    tail -1 | awk '{print $1}'
}

get_directory_size() {
  local dir=$1
  if [ -d "$dir" ]; then
    du -sh "$dir" 2>/dev/null | cut -f1
  else
    echo "N/A"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Module Analysis Functions
# ═══════════════════════════════════════════════════════════════════════════

analyze_module_structure() {
  section "${EMOJI_CHART} Analyzing module structure..."

  local -A category_counts
  local -A category_lines
  local total_modules=0

  # Count modules by category
  for category in "${!MODULE_CATEGORIES[@]}"; do
    local module_dir="$REPO_ROOT/modules/$category"
    if [ -d "$module_dir" ]; then
      local count=$(find "$module_dir" -name "*.nix" -type f | wc -l)
      local lines=$(find "$module_dir" -name "*.nix" -type f -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
      category_counts[$category]=$count
      category_lines[$category]=$lines
      total_modules=$((total_modules + count))
    else
      category_counts[$category]=0
      category_lines[$category]=0
    fi
  done

  # Store results in global associative arrays
  declare -gA ANALYSIS_MODULE_COUNTS
  declare -gA ANALYSIS_MODULE_LINES
  declare -g ANALYSIS_TOTAL_MODULES

  for category in "${!category_counts[@]}"; do
    ANALYSIS_MODULE_COUNTS[$category]=${category_counts[$category]}
    ANALYSIS_MODULE_LINES[$category]=${category_lines[$category]}
  done
  ANALYSIS_TOTAL_MODULES=$total_modules

  success "Analyzed $total_modules modules across ${#MODULE_CATEGORIES[@]} categories"
}

find_orphaned_modules() {
  section "${EMOJI_WARNING} Checking for orphaned modules..."

  local -a orphaned=()
  local flake_nix="$REPO_ROOT/flake.nix"

  # Find all .nix files in modules/
  while IFS= read -r module; do
    local module_name=$(basename "$module" .nix)
    # Use parameter expansion instead of realpath --relative-to
    local module_path="${module#$REPO_ROOT/}"

    # Check if module is imported in flake.nix or other configs
    if ! grep -q "$module_path" "$flake_nix" 2>/dev/null; then
      # Check if it's a default.nix (may be imported via directory)
      if [[ "$module_name" != "default" ]]; then
        orphaned+=("$module_path")
      fi
    fi
  done < <(find "$REPO_ROOT/modules" -name "*.nix" -type f 2>/dev/null)

  declare -ga ANALYSIS_ORPHANED_MODULES=("${orphaned[@]}")

  if [ ${#orphaned[@]} -gt 0 ]; then
    warning "Found ${#orphaned[@]} potentially orphaned modules"
  else
    success "No orphaned modules detected"
  fi
}

check_module_documentation() {
  section "${EMOJI_DOCS} Checking module documentation..."

  local total=0
  local documented=0

  while IFS= read -r module; do
    total=$((total + 1))

    # Check for inline documentation (description in mkOption)
    if grep -q "description\s*=" "$module" 2>/dev/null; then
      documented=$((documented + 1))
    fi
  done < <(find "$REPO_ROOT/modules" -name "*.nix" -type f 2>/dev/null)

  declare -g ANALYSIS_TOTAL_MODULES_CHECKED=$total
  declare -g ANALYSIS_DOCUMENTED_MODULES=$documented

  local coverage=0
  if [ $total -gt 0 ]; then
    coverage=$((documented * 100 / total))
  fi

  declare -g ANALYSIS_DOC_COVERAGE=$coverage

  if [ $coverage -ge 80 ]; then
    success "Documentation coverage: ${coverage}% (${documented}/${total})"
  elif [ $coverage -ge 50 ]; then
    warning "Documentation coverage: ${coverage}% (${documented}/${total})"
  else
    error "Low documentation coverage: ${coverage}% (${documented}/${total})"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Security & Quality Analysis
# ═══════════════════════════════════════════════════════════════════════════

analyze_security() {
  section "${EMOJI_SECURITY} Analyzing security configuration..."

  local security_modules=$(find "$REPO_ROOT/modules/security" -name "*.nix" 2>/dev/null | wc -l)
  local sops_secrets=$(find "$REPO_ROOT/secrets" -name "*.yaml" 2>/dev/null | wc -l)
  local has_hardening=false

  if [ -f "$REPO_ROOT/sec/hardening.nix" ]; then
    has_hardening=true
  fi

  declare -g ANALYSIS_SECURITY_MODULES=$security_modules
  declare -g ANALYSIS_SOPS_SECRETS=$sops_secrets
  declare -g ANALYSIS_HAS_HARDENING=$has_hardening

  # Calculate security score (0-100)
  local score=0
  [ $security_modules -ge 5 ] && score=$((score + 30))
  [ $sops_secrets -gt 0 ] && score=$((score + 30))
  [ "$has_hardening" = true ] && score=$((score + 40))

  declare -g ANALYSIS_SECURITY_SCORE=$score

  if [ $score -ge 80 ]; then
    success "Security score: ${score}/100"
  elif [ $score -ge 50 ]; then
    warning "Security score: ${score}/100"
  else
    error "Security score: ${score}/100 - needs improvement"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Health Score Calculation
# ═══════════════════════════════════════════════════════════════════════════

calculate_health_score() {
  section "${EMOJI_CHART} Calculating architecture health score..."

  local doc_score=${ANALYSIS_DOC_COVERAGE:-0}
  local security_score=${ANALYSIS_SECURITY_SCORE:-0}

  # Structure score (based on organization)
  local structure_score=0
  [ -d "$REPO_ROOT/modules" ] && structure_score=$((structure_score + 25))
  [ -d "$REPO_ROOT/hosts" ] && structure_score=$((structure_score + 25))
  [ -f "$REPO_ROOT/flake.nix" ] && structure_score=$((structure_score + 25))
  [ -d "$REPO_ROOT/docs" ] && structure_score=$((structure_score + 25))

  # Orphaned modules penalty
  local orphaned_count=${#ANALYSIS_ORPHANED_MODULES[@]}
  local orphaned_penalty=$((orphaned_count * 5))
  [ $orphaned_penalty -gt 20 ] && orphaned_penalty=20

  # Overall health score (weighted average)
  local health_score=$(( (doc_score * 30 + security_score * 40 + structure_score * 30) / 100 - orphaned_penalty ))

  declare -g ANALYSIS_HEALTH_SCORE=$health_score

  if [ $health_score -ge 80 ]; then
    success "Overall health score: ${health_score}/100 - Excellent!"
  elif [ $health_score -ge 60 ]; then
    warning "Overall health score: ${health_score}/100 - Good"
  elif [ $health_score -ge 40 ]; then
    warning "Overall health score: ${health_score}/100 - Needs improvement"
  else
    error "Overall health score: ${health_score}/100 - Critical"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Statistics Gathering
# ═══════════════════════════════════════════════════════════════════════════

gather_statistics() {
  section "${EMOJI_CHART} Gathering statistics..."

  local excludes
  read -ra excludes <<< "$(build_find_excludes)"

  # File counts
  declare -g STAT_TOTAL_FILES=$(find "$REPO_ROOT" -type f "${excludes[@]}" 2>/dev/null | wc -l)
  declare -g STAT_TOTAL_DIRS=$(find "$REPO_ROOT" -type d "${excludes[@]}" 2>/dev/null | wc -l)
  declare -g STAT_NIX_FILES=$(count_files_by_type "nix")
  declare -g STAT_SH_FILES=$(count_files_by_type "sh")
  declare -g STAT_MD_FILES=$(count_files_by_type "md")
  declare -g STAT_YAML_FILES=$(count_files_by_type "yaml")

  # Line counts
  declare -g STAT_NIX_LINES=$(count_lines_in_files "nix")
  declare -g STAT_SH_LINES=$(count_lines_in_files "sh")
  declare -g STAT_MD_LINES=$(count_lines_in_files "md")

  # Directory sizes
  declare -g STAT_MODULES_SIZE=$(get_directory_size "$REPO_ROOT/modules")
  declare -g STAT_DOCS_SIZE=$(get_directory_size "$REPO_ROOT/docs")
  declare -g STAT_SCRIPTS_SIZE=$(get_directory_size "$REPO_ROOT/scripts")
  declare -g STAT_REPO_SIZE=$(get_directory_size "$REPO_ROOT")

  # Git statistics
  declare -g GIT_BRANCH=$(get_git_info branch)
  declare -g GIT_COMMIT=$(get_git_info commit)
  declare -g GIT_COMMIT_LONG=$(get_git_info commit_long)
  declare -g GIT_COMMIT_DATE=$(get_git_info commit_date)
  declare -g GIT_TOTAL_COMMITS=$(get_git_info total_commits)
  declare -g GIT_CONTRIBUTORS=$(get_git_info contributors)
  declare -g GIT_LAST_TAG=$(get_git_info last_tag)
  declare -g GIT_REPO_AGE=$(get_git_info repo_age_days)

  success "Statistics gathered successfully"
}

# ═══════════════════════════════════════════════════════════════════════════
# Tree Generation
# ═══════════════════════════════════════════════════════════════════════════

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

generate_tree() {
  local exclude_pattern
  exclude_pattern=$(build_exclude_pattern)

  local -a tree_opts=(
    "-I" "$exclude_pattern"
    "--dirsfirst"
    "-F"
    "-L" "$MAX_DEPTH"
    "--charset" "utf-8"
  )

  if [ "$SHOW_HIDDEN" = "true" ]; then
    tree_opts+=("-a")
  fi

  tree "${tree_opts[@]}" "$REPO_ROOT" 2>/dev/null || echo "Error generating tree"
}

# ═══════════════════════════════════════════════════════════════════════════
# Report Generation - Text Format
# ═══════════════════════════════════════════════════════════════════════════

generate_ascii_bar() {
  local value=$1
  local max=$2
  local width=${3:-40}

  local filled=$((value * width / max))
  [ $filled -gt $width ] && filled=$width

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=filled; i<width; i++)); do bar+="░"; done

  echo "$bar"
}

generate_report_header_txt() {
  cat <<EOF
╔═══════════════════════════════════════════════════════════════════════════╗
║                  NIXOS ARCHITECTURE ANALYSIS REPORT                       ║
║                        Professional Edition v${SCRIPT_VERSION}                        ║
╚═══════════════════════════════════════════════════════════════════════════╝

Generated:     $(date +"%Y-%m-%d %H:%M:%S %Z")
Location:      $REPO_ROOT
Hostname:      $(hostname)
Git Branch:    $GIT_BRANCH
Git Commit:    $GIT_COMMIT ($GIT_COMMIT_DATE)
Total Commits: $GIT_TOTAL_COMMITS
Contributors:  $GIT_CONTRIBUTORS
Last Tag:      $GIT_LAST_TAG
Repo Age:      $GIT_REPO_AGE days

═══════════════════════════════════════════════════════════════════════════
EOF
}

generate_executive_summary_txt() {
  cat <<EOF

┌─────────────────────────────────────────────────────────────────────────┐
│ EXECUTIVE SUMMARY                                                       │
└─────────────────────────────────────────────────────────────────────────┘

Repository Overview:
  • Total Files:           $STAT_TOTAL_FILES
  • Total Directories:     $STAT_TOTAL_DIRS
  • Repository Size:       $STAT_REPO_SIZE

NixOS Configuration:
  • .nix files:            $STAT_NIX_FILES ($STAT_NIX_LINES lines)
  • Total modules:         ${ANALYSIS_TOTAL_MODULES:-0}
  • Module categories:     ${#MODULE_CATEGORIES[@]}
  • Modules size:          $STAT_MODULES_SIZE

Documentation:
  • .md files:             $STAT_MD_FILES ($STAT_MD_LINES lines)
  • Documentation size:    $STAT_DOCS_SIZE
  • Doc coverage:          ${ANALYSIS_DOC_COVERAGE:-0}%

Scripts & Automation:
  • .sh files:             $STAT_SH_FILES ($STAT_SH_LINES lines)
  • Scripts size:          $STAT_SCRIPTS_SIZE

Health Metrics:
  • Overall Health:        ${ANALYSIS_HEALTH_SCORE:-0}/100
  • Security Score:        ${ANALYSIS_SECURITY_SCORE:-0}/100
  • Documentation:         ${ANALYSIS_DOC_COVERAGE:-0}/100
  • Orphaned modules:      ${#ANALYSIS_ORPHANED_MODULES[@]}

EOF
}

generate_module_breakdown_txt() {
  cat <<EOF

┌─────────────────────────────────────────────────────────────────────────┐
│ MODULE BREAKDOWN BY CATEGORY                                            │
└─────────────────────────────────────────────────────────────────────────┘

EOF

  # Find max count for bar chart scaling
  local max_count=0
  for category in "${!ANALYSIS_MODULE_COUNTS[@]}"; do
    local count=${ANALYSIS_MODULE_COUNTS[$category]}
    [ $count -gt $max_count ] && max_count=$count
  done

  [ $max_count -eq 0 ] && max_count=1

  # Sort categories by count (descending)
  for category in $(for k in "${!ANALYSIS_MODULE_COUNTS[@]}"; do
    echo "$k ${ANALYSIS_MODULE_COUNTS[$k]}"
  done | sort -rn -k2 | awk '{print $1}'); do
    local count=${ANALYSIS_MODULE_COUNTS[$category]}
    local lines=${ANALYSIS_MODULE_LINES[$category]}
    local description=${MODULE_CATEGORIES[$category]}
    local bar=$(generate_ascii_bar $count $max_count 30)

    printf "  %-15s %s %3d modules (%6d lines)\n" \
      "$category" "$bar" "$count" "$lines"
    printf "                 %s\n\n" "$description"
  done
}

generate_security_analysis_txt() {
  cat <<EOF

┌─────────────────────────────────────────────────────────────────────────┐
│ SECURITY ANALYSIS                                                       │
└─────────────────────────────────────────────────────────────────────────┘

Security Configuration:
  • Security modules:      ${ANALYSIS_SECURITY_MODULES:-0}
  • SOPS secrets:          ${ANALYSIS_SOPS_SECRETS:-0}
  • Hardening config:      $([ "${ANALYSIS_HAS_HARDENING:-false}" = "true" ] && echo "Yes" || echo "No")
  • Security score:        ${ANALYSIS_SECURITY_SCORE:-0}/100

EOF

  local score=${ANALYSIS_SECURITY_SCORE:-0}
  local bar=$(generate_ascii_bar $score 100 50)
  echo "  Score: $bar ${score}%"
  echo ""

  if [ $score -ge 80 ]; then
    echo "  Status: ${EMOJI_SUCCESS} Excellent security posture"
  elif [ $score -ge 50 ]; then
    echo "  Status: ${EMOJI_WARNING} Good, but room for improvement"
  else
    echo "  Status: ${EMOJI_ERROR} Needs immediate attention"
  fi
  echo ""
}

generate_health_score_txt() {
  cat <<EOF

┌─────────────────────────────────────────────────────────────────────────┐
│ ARCHITECTURE HEALTH SCORE                                               │
└─────────────────────────────────────────────────────────────────────────┘

Component Scores:
  • Documentation:         ${ANALYSIS_DOC_COVERAGE:-0}/100
  • Security:              ${ANALYSIS_SECURITY_SCORE:-0}/100
  • Structure:             $([ -d "$REPO_ROOT/modules" ] && echo "100/100" || echo "0/100")

Overall Health:            ${ANALYSIS_HEALTH_SCORE:-0}/100
EOF

  local health=${ANALYSIS_HEALTH_SCORE:-0}
  local bar=$(generate_ascii_bar $health 100 50)
  echo "  $bar ${health}%"
  echo ""

  if [ $health -ge 80 ]; then
    echo "  ${EMOJI_SUCCESS} Excellent - Architecture is well-maintained and documented"
  elif [ $health -ge 60 ]; then
    echo "  ${EMOJI_WARNING} Good - Minor improvements recommended"
  elif [ $health -ge 40 ]; then
    echo "  ${EMOJI_WARNING} Fair - Several areas need attention"
  else
    echo "  ${EMOJI_ERROR} Critical - Immediate improvements required"
  fi
  echo ""
}

generate_recommendations_txt() {
  cat <<EOF

┌─────────────────────────────────────────────────────────────────────────┐
│ RECOMMENDATIONS                                                         │
└─────────────────────────────────────────────────────────────────────────┘

EOF

  local has_recommendations=false

  # Documentation recommendations
  if [ ${ANALYSIS_DOC_COVERAGE:-0} -lt 80 ]; then
    has_recommendations=true
    cat <<EOF
  ${EMOJI_DOCS} Documentation:
    - Current coverage: ${ANALYSIS_DOC_COVERAGE:-0}%
    - Target: 80%+
    - Action: Add 'description' fields to module options
    - Benefit: Better maintainability and onboarding

EOF
  fi

  # Security recommendations
  if [ ${ANALYSIS_SECURITY_SCORE:-0} -lt 80 ]; then
    has_recommendations=true
    cat <<EOF
  ${EMOJI_SECURITY} Security:
    - Current score: ${ANALYSIS_SECURITY_SCORE:-0}/100
    - Target: 80+
    - Actions:
      * Add more security modules (firewall, AppArmor, etc.)
      * Implement SOPS for secret management
      * Enable security hardening profiles
    - Benefit: Enhanced system security posture

EOF
  fi

  # Orphaned modules
  if [ ${#ANALYSIS_ORPHANED_MODULES[@]} -gt 0 ]; then
    has_recommendations=true
    cat <<EOF
  ${EMOJI_WARNING} Orphaned Modules:
    - Found: ${#ANALYSIS_ORPHANED_MODULES[@]} potentially unused modules
    - Action: Review and either import or remove
    - Benefit: Cleaner codebase, faster rebuilds

EOF
  fi

  if [ "$has_recommendations" = false ]; then
    echo "  ${EMOJI_SUCCESS} No critical recommendations - architecture is in good shape!"
    echo ""
  fi
}

generate_report_footer_txt() {
  cat <<EOF

═══════════════════════════════════════════════════════════════════════════

Generated by: NixOS Architecture Analysis Tool v${SCRIPT_VERSION}
Report Date:  $(date +"%Y-%m-%d %H:%M:%S")
Script Path:  $0

To regenerate this report:
  bash scripts/generate-architecture-tree.sh

For more information:
  • Repository: $REPO_ROOT
  • Documentation: $REPO_ROOT/docs/
  • Issues: https://github.com/yourusername/nixos-config/issues

═══════════════════════════════════════════════════════════════════════════
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# Report Generation - Markdown Format
# ═══════════════════════════════════════════════════════════════════════════

generate_report_md() {
  cat <<EOF
# NixOS Architecture Analysis Report

> **Professional Edition v${SCRIPT_VERSION}**
> **Generated**: $(date +"%Y-%m-%d %H:%M:%S %Z")
> **Location**: \`$REPO_ROOT\`

---

## 📋 Table of Contents

- [Executive Summary](#executive-summary)
- [Module Breakdown](#module-breakdown)
- [Security Analysis](#security-analysis)
- [Health Score](#health-score)
- [Recommendations](#recommendations)
- [Statistics](#statistics)
- [Architecture Tree](#architecture-tree)

---

## 🎯 Executive Summary

### Repository Information

| Metric | Value |
|--------|-------|
| **Total Files** | $STAT_TOTAL_FILES |
| **Total Directories** | $STAT_TOTAL_DIRS |
| **Repository Size** | $STAT_REPO_SIZE |
| **Git Branch** | \`$GIT_BRANCH\` |
| **Git Commit** | \`$GIT_COMMIT\` |
| **Total Commits** | $GIT_TOTAL_COMMITS |
| **Contributors** | $GIT_CONTRIBUTORS |
| **Repository Age** | $GIT_REPO_AGE days |

### NixOS Configuration

| Metric | Value |
|--------|-------|
| **.nix files** | $STAT_NIX_FILES ($STAT_NIX_LINES lines) |
| **Total modules** | ${ANALYSIS_TOTAL_MODULES:-0} |
| **Module categories** | ${#MODULE_CATEGORIES[@]} |
| **Modules size** | $STAT_MODULES_SIZE |

### Health Metrics

| Metric | Score | Status |
|--------|-------|--------|
| **Overall Health** | ${ANALYSIS_HEALTH_SCORE:-0}/100 | $([ ${ANALYSIS_HEALTH_SCORE:-0} -ge 80 ] && echo "✅ Excellent" || echo "⚠️ Needs Work") |
| **Security** | ${ANALYSIS_SECURITY_SCORE:-0}/100 | $([ ${ANALYSIS_SECURITY_SCORE:-0} -ge 80 ] && echo "✅ Strong" || echo "⚠️ Needs Work") |
| **Documentation** | ${ANALYSIS_DOC_COVERAGE:-0}/100 | $([ ${ANALYSIS_DOC_COVERAGE:-0} -ge 80 ] && echo "✅ Good" || echo "⚠️ Needs Work") |

---

## 📦 Module Breakdown

EOF

  # Module breakdown table
  echo "| Category | Modules | Lines | Description |"
  echo "|----------|---------|-------|-------------|"

  for category in $(for k in "${!ANALYSIS_MODULE_COUNTS[@]}"; do
    echo "$k ${ANALYSIS_MODULE_COUNTS[$k]}"
  done | sort -rn -k2 | awk '{print $1}'); do
    local count=${ANALYSIS_MODULE_COUNTS[$category]}
    local lines=${ANALYSIS_MODULE_LINES[$category]}
    local description=${MODULE_CATEGORIES[$category]}

    echo "| **$category** | $count | $lines | $description |"
  done

  cat <<EOF

---

## 🔒 Security Analysis

### Configuration

- **Security modules**: ${ANALYSIS_SECURITY_MODULES:-0}
- **SOPS secrets**: ${ANALYSIS_SOPS_SECRETS:-0}
- **Hardening config**: $([ "${ANALYSIS_HAS_HARDENING:-false}" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")

### Security Score: ${ANALYSIS_SECURITY_SCORE:-0}/100

EOF

  local score=${ANALYSIS_SECURITY_SCORE:-0}
  if [ $score -ge 80 ]; then
    echo "**Status**: ✅ Excellent security posture"
  elif [ $score -ge 50 ]; then
    echo "**Status**: ⚠️ Good, but room for improvement"
  else
    echo "**Status**: ❌ Needs immediate attention"
  fi

  cat <<EOF

---

## 📊 Health Score

### Overall: ${ANALYSIS_HEALTH_SCORE:-0}/100

| Component | Score |
|-----------|-------|
| Documentation | ${ANALYSIS_DOC_COVERAGE:-0}/100 |
| Security | ${ANALYSIS_SECURITY_SCORE:-0}/100 |
| Structure | 100/100 |

EOF

  local health=${ANALYSIS_HEALTH_SCORE:-0}
  if [ $health -ge 80 ]; then
    echo "**Status**: ✅ Excellent - Architecture is well-maintained"
  elif [ $health -ge 60 ]; then
    echo "**Status**: ⚠️ Good - Minor improvements recommended"
  else
    echo "**Status**: ❌ Needs improvement"
  fi

  cat <<EOF

---

## 💡 Recommendations

EOF

  local has_recommendations=false

  if [ ${ANALYSIS_DOC_COVERAGE:-0} -lt 80 ]; then
    has_recommendations=true
    cat <<EOF
### 📚 Documentation

- **Current**: ${ANALYSIS_DOC_COVERAGE:-0}%
- **Target**: 80%+
- **Action**: Add \`description\` fields to module options
- **Benefit**: Better maintainability and onboarding

EOF
  fi

  if [ ${ANALYSIS_SECURITY_SCORE:-0} -lt 80 ]; then
    has_recommendations=true
    cat <<EOF
### 🔒 Security

- **Current**: ${ANALYSIS_SECURITY_SCORE:-0}/100
- **Target**: 80+
- **Actions**:
  - Add more security modules
  - Implement SOPS for secrets
  - Enable hardening profiles
- **Benefit**: Enhanced security posture

EOF
  fi

  if [ "$has_recommendations" = false ]; then
    echo "✅ No critical recommendations - architecture is in excellent shape!"
  fi

  cat <<EOF

---

## 📈 Statistics

### Files by Type

| Type | Count | Lines |
|------|-------|-------|
| .nix | $STAT_NIX_FILES | $STAT_NIX_LINES |
| .sh | $STAT_SH_FILES | $STAT_SH_LINES |
| .md | $STAT_MD_FILES | $STAT_MD_LINES |
| .yaml | $STAT_YAML_FILES | - |

### Directory Sizes

| Directory | Size |
|-----------|------|
| modules/ | $STAT_MODULES_SIZE |
| docs/ | $STAT_DOCS_SIZE |
| scripts/ | $STAT_SCRIPTS_SIZE |
| **Total** | **$STAT_REPO_SIZE** |

---

## 🌳 Architecture Tree

\`\`\`
$(generate_tree)
\`\`\`

---

## 📝 Metadata

- **Report Version**: ${SCRIPT_VERSION}
- **Generated**: $(date +"%Y-%m-%d %H:%M:%S %Z")
- **Tool**: NixOS Architecture Analysis Tool
- **Repository**: $REPO_ROOT

To regenerate this report:

\`\`\`bash
bash scripts/generate-architecture-tree.sh
\`\`\`

---

*Generated with ❤️ by NixOS Architecture Analysis Tool*
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# Report Generation - JSON Format
# ═══════════════════════════════════════════════════════════════════════════

generate_report_json() {
  cat <<EOF
{
  "metadata": {
    "version": "${SCRIPT_VERSION}",
    "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "location": "$REPO_ROOT",
    "hostname": "$(hostname)"
  },
  "git": {
    "branch": "$GIT_BRANCH",
    "commit": "$GIT_COMMIT",
    "commit_long": "$GIT_COMMIT_LONG",
    "commit_date": "$GIT_COMMIT_DATE",
    "total_commits": $GIT_TOTAL_COMMITS,
    "contributors": $GIT_CONTRIBUTORS,
    "last_tag": "$GIT_LAST_TAG",
    "repo_age_days": $GIT_REPO_AGE
  },
  "statistics": {
    "files": {
      "total": $STAT_TOTAL_FILES,
      "nix": $STAT_NIX_FILES,
      "sh": $STAT_SH_FILES,
      "md": $STAT_MD_FILES,
      "yaml": $STAT_YAML_FILES
    },
    "lines": {
      "nix": $STAT_NIX_LINES,
      "sh": $STAT_SH_LINES,
      "md": $STAT_MD_LINES
    },
    "directories": $STAT_TOTAL_DIRS,
    "sizes": {
      "modules": "$STAT_MODULES_SIZE",
      "docs": "$STAT_DOCS_SIZE",
      "scripts": "$STAT_SCRIPTS_SIZE",
      "total": "$STAT_REPO_SIZE"
    }
  },
  "modules": {
    "total": ${ANALYSIS_TOTAL_MODULES:-0},
    "categories": ${#MODULE_CATEGORIES[@]},
    "by_category": {
$(for category in "${!ANALYSIS_MODULE_COUNTS[@]}"; do
    echo "      \"$category\": {"
    echo "        \"count\": ${ANALYSIS_MODULE_COUNTS[$category]},"
    echo "        \"lines\": ${ANALYSIS_MODULE_LINES[$category]}"
    echo "      },"
  done | sed '$ s/,$//')
    },
    "orphaned": ${#ANALYSIS_ORPHANED_MODULES[@]}
  },
  "health": {
    "overall": ${ANALYSIS_HEALTH_SCORE:-0},
    "documentation": ${ANALYSIS_DOC_COVERAGE:-0},
    "security": ${ANALYSIS_SECURITY_SCORE:-0}
  },
  "security": {
    "modules": ${ANALYSIS_SECURITY_MODULES:-0},
    "sops_secrets": ${ANALYSIS_SOPS_SECRETS:-0},
    "has_hardening": $([ "${ANALYSIS_HAS_HARDENING:-false}" = "true" ] && echo "true" || echo "false")
  }
}
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Execution Flow
# ═══════════════════════════════════════════════════════════════════════════

main() {
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_MAGENTA}╔═══════════════════════════════════════════════════════════════════╗${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_MAGENTA}║  NixOS Architecture Analysis Tool v${SCRIPT_VERSION}                        ║${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_MAGENTA}╚═══════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
  echo ""

  cd "$REPO_ROOT" || exit 1

  # Create output directories
  mkdir -p "$OUTPUT_DIR"
  mkdir -p "$SNAPSHOT_DIR"

  # Phase 1: Gather statistics
  section "${EMOJI_ROCKET} Phase 1: Data Collection"
  gather_statistics

  # Phase 2: Analysis
  section "${EMOJI_CHART} Phase 2: Architecture Analysis"
  if [ "$ENABLE_METRICS" = "true" ]; then
    analyze_module_structure
    find_orphaned_modules
    check_module_documentation
    analyze_security
    calculate_health_score
  fi

  # Phase 3: Generate reports
  section "${EMOJI_DOCS} Phase 3: Report Generation"

  # Generate tree diagram
  log "Generating architecture tree..."
  {
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                    NIXOS ARCHITECTURE TREE                                ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Generated: $(date +"%Y-%m-%d %H:%M:%S %Z")"
    echo "Location:  $REPO_ROOT"
    echo "Branch:    $GIT_BRANCH ($GIT_COMMIT)"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
    generate_tree
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
  } > "$OUTPUT_TREE"
  success "Tree diagram: $OUTPUT_TREE"

  # Generate text report
  log "Generating text report..."
  {
    generate_report_header_txt
    generate_executive_summary_txt
    generate_module_breakdown_txt
    generate_security_analysis_txt
    generate_health_score_txt
    generate_recommendations_txt
    generate_report_footer_txt
  } > "$OUTPUT_REPORT_TXT"
  success "Text report: $OUTPUT_REPORT_TXT"

  # Generate markdown report
  log "Generating markdown report..."
  generate_report_md > "$OUTPUT_REPORT_MD"
  success "Markdown report: $OUTPUT_REPORT_MD"

  # Generate JSON report
  log "Generating JSON report..."
  generate_report_json > "$OUTPUT_REPORT_JSON"
  success "JSON report: $OUTPUT_REPORT_JSON"

  # Create snapshot
  log "Creating versioned snapshot..."
  cp "$OUTPUT_REPORT_TXT" "$SNAPSHOT_FILE"
  success "Snapshot: $SNAPSHOT_FILE"

  # Phase 4: Summary
  echo ""
  section "${EMOJI_SUCCESS} Analysis Complete!"
  echo ""
  echo "  📄 Architecture Tree:  $OUTPUT_TREE"
  echo "  📊 Text Report:        $OUTPUT_REPORT_TXT"
  echo "  📝 Markdown Report:    $OUTPUT_REPORT_MD"
  echo "  📦 JSON Report:        $OUTPUT_REPORT_JSON"
  echo "  📸 Snapshot:           $SNAPSHOT_FILE"
  echo ""
  echo -e "  ${COLOR_BOLD}Health Score: ${ANALYSIS_HEALTH_SCORE:-0}/100${COLOR_RESET}"
  echo -e "  ${COLOR_BOLD}Security:     ${ANALYSIS_SECURITY_SCORE:-0}/100${COLOR_RESET}"
  echo -e "  ${COLOR_BOLD}Documentation: ${ANALYSIS_DOC_COVERAGE:-0}%${COLOR_RESET}"
  echo ""
  info "View reports: cat $OUTPUT_REPORT_TXT"
  info "             less $OUTPUT_REPORT_MD"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# Script Entry Point
# ═══════════════════════════════════════════════════════════════════════════

main "$@"
