#!/usr/bin/env bash

# ============================================================
# Alias Inspector - Advanced Alias Tracking & Debugging
# ============================================================
# Usage: alias-inspector.sh [command] [args]
#
# Commands:
#   find <name>       - Find where an alias is defined
#   info <name>       - Show detailed info about an alias
#   search <pattern>  - Search aliases by pattern
#   list [category]   - List all aliases or by category
#   stats             - Show alias statistics
#   trace <name>      - Trace alias resolution chain
#   help              - Show this help
# ============================================================

set -euo pipefail

ALIAS_DIR="/etc/nixos/modules/shell/aliases"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# Helper Functions
# ============================================================

print_header() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

print_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================
# Command: find <name>
# ============================================================
cmd_find() {
    local name="$1"
    print_header "Finding alias: $name"

    local found=0
    while IFS= read -r file; do
        if grep -q "\"$name\"" "$file" 2>/dev/null; then
            echo -e "\n${GREEN}Found in:${NC} $file"
            echo -e "${YELLOW}───────────────────────────────────────────${NC}"
            grep -n --color=always -B 1 -A 2 "\"$name\"" "$file"
            found=1
        fi
    done < <(find "$ALIAS_DIR" -name '*.nix' -type f)

    if [ $found -eq 0 ]; then
        print_error "Alias '$name' not found in config files"
        echo ""
        print_warning "Try: alias $name  (to see if it's defined elsewhere)"
    fi
}

# ============================================================
# Command: info <name>
# ============================================================
cmd_info() {
    local name="$1"
    print_header "Alias Information: $name"

    # Check if alias exists in current shell
    if alias "$name" &>/dev/null; then
        print_section "Current Definition"
        alias "$name"

        print_section "Type Information"
        type "$name"

        print_section "Full Resolution Chain"
        type -a "$name" 2>/dev/null || echo "Single definition"
    else
        print_error "Alias '$name' is not currently active in shell"
    fi

    # Find in config files
    print_section "Configuration Files"
    cmd_find "$name"
}

# ============================================================
# Command: search <pattern>
# ============================================================
cmd_search() {
    local pattern="$1"
    print_header "Searching aliases matching: $pattern"

    print_section "Active Aliases"
    alias | grep --color=always -i "$pattern" || print_warning "No active aliases found"

    print_section "In Configuration Files"
    grep -r --color=always -i -n "$pattern" "$ALIAS_DIR" --include='*.nix' | head -50 || print_warning "No matches in config"
}

# ============================================================
# Command: list [category]
# ============================================================
cmd_list() {
    local category="${1:-all}"

    if [ "$category" = "all" ]; then
        print_header "All Alias Categories"

        echo -e "\n${GREEN}Available categories:${NC}"
        find "$ALIAS_DIR" -type d | sed 's|.*/||' | sort | nl

        echo -e "\n${GREEN}Alias files:${NC}"
        find "$ALIAS_DIR" -name '*.nix' -type f | while read -r file; do
            local count=$(grep -c '\".*\" =' "$file" 2>/dev/null || echo 0)
            echo -e "  ${BLUE}$(basename "$file")${NC} - $count aliases"
        done
    else
        print_header "Aliases in category: $category"

        if [ -d "$ALIAS_DIR/$category" ]; then
            grep -h '=' "$ALIAS_DIR/$category"/*.nix 2>/dev/null | grep -v '^[[:space:]]*#' | sort
        elif [ -f "$ALIAS_DIR/$category.nix" ]; then
            grep -h '=' "$ALIAS_DIR/$category.nix" | grep -v '^[[:space:]]*#' | sort
        else
            print_error "Category not found: $category"
        fi
    fi
}

# ============================================================
# Command: stats
# ============================================================
cmd_stats() {
    print_header "Alias Statistics"

    print_section "Total Counts"
    local total_active=$(alias | wc -l)
    echo "Active aliases in shell: $total_active"

    local total_files=$(find "$ALIAS_DIR" -name '*.nix' -type f | wc -l)
    echo "Alias definition files: $total_files"

    print_section "By Category"
    find "$ALIAS_DIR" -name '*.nix' -type f | while read -r file; do
        local count=$(grep -c '\".*\" =' "$file" 2>/dev/null || echo 0)
        local name=$(basename "$file" .nix)
        printf "  %-30s %3d aliases\n" "$name" "$count"
    done | sort -k2 -rn

    print_section "Top 10 Longest Alias Definitions"
    while IFS= read -r file; do
        grep '=' "$file" 2>/dev/null | while IFS= read -r line; do
            echo "${#line} $file: $line"
        done
    done < <(find "$ALIAS_DIR" -name '*.nix' -type f) | sort -rn | head -10 | \
    while read -r length rest; do
        echo "  $length chars - ${rest:0:80}..."
    done
}

# ============================================================
# Command: trace <name>
# ============================================================
cmd_trace() {
    local name="$1"
    print_header "Tracing alias resolution: $name"

    print_section "Step 1: Check if defined"
    if alias "$name" &>/dev/null; then
        print_success "Alias is active"
        alias "$name"
    else
        print_warning "Not an active alias"
    fi

    print_section "Step 2: Type resolution"
    type "$name" 2>/dev/null || print_error "Command not found"

    print_section "Step 3: Full resolution chain"
    type -a "$name" 2>/dev/null || echo "Single definition"

    print_section "Step 4: Configuration source"
    cmd_find "$name"

    print_section "Step 5: Dependencies"
    if alias "$name" &>/dev/null; then
        local def=$(alias "$name" | sed "s/^alias $name='//;s/'$//")
        echo "Command in definition: $def"

        # Extract first command
        local first_cmd=$(echo "$def" | awk '{print $1}')
        echo ""
        echo "First command: $first_cmd"
        type "$first_cmd" 2>/dev/null || echo "  (not found or builtin)"
    fi
}

# ============================================================
# Command: help
# ============================================================
cmd_help() {
    cat <<EOF
${CYAN}Alias Inspector - Advanced Alias Tracking & Debugging${NC}

${GREEN}Usage:${NC}
  $(basename "$0") <command> [args]

${GREEN}Commands:${NC}
  ${YELLOW}find${NC} <name>       Find where an alias is defined in config
  ${YELLOW}info${NC} <name>       Show detailed information about an alias
  ${YELLOW}search${NC} <pattern>  Search aliases by pattern (name or definition)
  ${YELLOW}list${NC} [category]   List all aliases or by category
  ${YELLOW}stats${NC}             Show statistics about aliases
  ${YELLOW}trace${NC} <name>      Trace complete alias resolution chain
  ${YELLOW}help${NC}              Show this help message

${GREEN}Examples:${NC}
  $(basename "$0") find lt
  $(basename "$0") info tree
  $(basename "$0") search docker
  $(basename "$0") list nix
  $(basename "$0") trace rebuild

${GREEN}Quick Commands (use directly):${NC}
  ${YELLOW}aliases${NC}           Show all active aliases (sorted)
  ${YELLOW}alias-search${NC}      Search active aliases
  ${YELLOW}alias-count${NC}       Count total aliases
  ${YELLOW}what${NC} <name>       Show what command will run (type -a)

${GREEN}Configuration:${NC}
  Alias files: ${ALIAS_DIR}

EOF
}

# ============================================================
# Main
# ============================================================

main() {
    if [ $# -eq 0 ]; then
        cmd_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        find)
            [ $# -eq 0 ] && { print_error "Usage: $0 find <name>"; exit 1; }
            cmd_find "$1"
            ;;
        info)
            [ $# -eq 0 ] && { print_error "Usage: $0 info <name>"; exit 1; }
            cmd_info "$1"
            ;;
        search)
            [ $# -eq 0 ] && { print_error "Usage: $0 search <pattern>"; exit 1; }
            cmd_search "$1"
            ;;
        list)
            cmd_list "${1:-all}"
            ;;
        stats)
            cmd_stats
            ;;
        trace)
            [ $# -eq 0 ] && { print_error "Usage: $0 trace <name>"; exit 1; }
            cmd_trace "$1"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
