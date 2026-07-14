#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    INTEL - Enterprise Project Intelligence                   ║
# ║              Unified CLI for Project Audit, Metrics & Analysis              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   intel                    Audit current directory
#   intel <path>             Audit specified path
#   intel scan <dir>         Multi-project scan
#   intel nix                Audit /etc/nixos
#   intel dev                Scan ~/dev/Projects
#   intel score <path>       Quick viability score
#   intel health <path>      Quick health check
#   intel deps <path>        Dependency analysis
#   intel quality <path>     Code quality metrics
#   intel compare <p1> <p2>  Compare two projects

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

PHANTOM_DIR="${PHANTOM_DIR:-$HOME/dev/Projects/phantom}"
AUDITOR_SCRIPT="$PHANTOM_DIR/project_auditor.py"
NIXOS_DIR="/etc/nixos"
DEV_DIR="$HOME/dev/Projects"

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BOLD="\033[1m"
NC="\033[0m"

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  ██╗███╗   ██╗████████╗███████╗██╗                           ║
║  ██║████╗  ██║╚══██╔══╝██╔════╝██║                           ║
║  ██║██╔██╗ ██║   ██║   █████╗  ██║                           ║
║  ██║██║╚██╗██║   ██║   ██╔══╝  ██║                           ║
║  ██║██║ ╚████║   ██║   ███████╗███████╗                      ║
║  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝                      ║
║  Enterprise Project Intelligence v1.0                        ║
╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

show_help() {
    show_banner
    echo "Usage: intel [command] [options] [path]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  (no cmd) <path>     Full project audit (default)"
    echo "  scan <dir>          Multi-project scan"
    echo "  nix                 Audit NixOS config (/etc/nixos)"
    echo "  dev                 Scan ~/dev/Projects"
    echo "  score <path>        Quick viability score only"
    echo "  health <path>       Quick health check"
    echo "  deps <path>         Dependency analysis"
    echo "  quality <path>      Code quality metrics"
    echo "  compare <p1> <p2>   Compare two projects"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --format, -f FMT    Output: table, json, markdown (default: table)"
    echo "  --ai                Enable AI analysis (requires LLM)"
    echo "  --output, -o FILE   Save report to file"
    echo "  --verbose, -v       Verbose output"
    echo "  --help, -h          Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  intel .                         # Audit current directory"
    echo "  intel nix                       # Audit NixOS configuration"
    echo "  intel scan ~/dev                # Scan all projects in ~/dev"
    echo "  intel score . -f json           # Get viability score as JSON"
    echo "  intel compare proj1 proj2       # Compare two projects"
}

check_auditor() {
    if [[ ! -f "$AUDITOR_SCRIPT" ]]; then
        echo -e "${RED}Error: Project auditor not found at $AUDITOR_SCRIPT${NC}"
        echo "Please set PHANTOM_DIR or ensure the auditor exists."
        exit 1
    fi
}

run_auditor() {
    local args=("$@")
    
    # Try to use nix develop if we're in a flake environment
    if [[ -f "$PHANTOM_DIR/flake.nix" ]]; then
        cd "$PHANTOM_DIR"
        nix develop --command python3 "$AUDITOR_SCRIPT" "${args[@]}" 2>/dev/null || \
            python3 "$AUDITOR_SCRIPT" "${args[@]}"
    else
        python3 "$AUDITOR_SCRIPT" "${args[@]}"
    fi
}

run_audit() {
    local target="$1"
    local format="${2:-table}"
    local extra_args=("${@:3}")
    
    echo -e "${CYAN}🧠 INTEL: Auditing ${target}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    run_auditor --path "$target" --format "$format" "${extra_args[@]}"
}

run_scan() {
    local target="$1"
    local format="${2:-table}"
    local extra_args=("${@:3}")
    
    echo -e "${CYAN}🧠 INTEL: Scanning ${target}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    run_auditor --scan "$target" --format "$format" "${extra_args[@]}"
}

run_score() {
    local target="${1:-.}"
    echo -e "${CYAN}🧠 INTEL: Viability Score${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local output
    output=$(run_auditor --path "$target" --format json 2>/dev/null)
    
    echo "$output" | jq -r '.[0] | 
        "Project:        \(.name)\n" +
        "Score:          \(.viability.score // "N/A")/100 (\(.viability.grade // "?"))\n" +
        "Status:         \(.status)\n" +
        "Recommendation: \(.viability.recommendation // "unknown" | gsub("_"; " "))\n" +
        "Tech Stack:     \(.tech_stack.primary_languages | join(", "))"'
}

run_health() {
    local target="${1:-.}"
    echo -e "${CYAN}🧠 INTEL: Health Check${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local output
    output=$(run_auditor --path "$target" --format json 2>/dev/null)
    
    echo "$output" | jq -r '.[0] | 
        "Project: \(.name)\n━━━━━━━━━━━━━━━━━━━━━\n" +
        (if .quality.readme_exists then "✅" else "❌" end) + " README\n" +
        (if .quality.has_license then "✅" else "❌" end) + " LICENSE\n" +
        (if .quality.linting_configured then "✅" else "❌" end) + " Linting\n" +
        (if .activity.is_git_repo then "✅" else "❌" end) + " Git Repository\n" +
        (if (.security.security_score // 0) >= 70 then "✅" else "❌" end) + " Security (\(.security.security_score // 0)/100)\n" +
        "━━━━━━━━━━━━━━━━━━━━━\n" +
        "Overall Score: \(.viability.score // 0)/100"'
}

run_deps() {
    local target="${1:-.}"
    echo -e "${CYAN}🧠 INTEL: Dependency Analysis${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local output
    output=$(run_auditor --path "$target" --format json 2>/dev/null)
    
    echo "$output" | jq -r '.[0] | 
        "Project:    \(.name)\n" +
        "Total:      \(.dependencies.total_dependencies // 0)\n" +
        "Direct:     \(.dependencies.direct_dependencies // 0)\n" +
        "Dev:        \(.dependencies.dev_dependencies // 0)\n" +
        "Outdated:   \(.dependencies.outdated_dependencies // 0)\n" +
        "Vulnerable: \(.dependencies.vulnerable_dependencies // 0)\n" +
        "Freshness:  \(.dependencies.dependency_freshness // 0)/100"'
}

run_quality() {
    local target="${1:-.}"
    echo -e "${CYAN}🧠 INTEL: Code Quality Metrics${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local output
    output=$(run_auditor --path "$target" --format json 2>/dev/null)
    
    echo "$output" | jq -r '.[0] | 
        "Project:         \(.name)\n" +
        "Lines of Code:   \(.code.total_lines | tostring | gsub("(?<=[0-9])(?=(?:[0-9]{3})+$)"; ","))\n" +
        "Files:           \(.code.file_count)\n" +
        "Languages:       \(.tech_stack.primary_languages | join(", "))\n" +
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
        "Complexity (avg): \(.complexity.cyclomatic_complexity_avg // 0 | round)\n" +
        "Maintainability:  \(.complexity.maintainability_index // 0 | round)/100\n" +
        "Documentation:    \(.quality.documentation_score // 0 | round)/100\n" +
        "Test Coverage:    ~\(.quality.test_coverage_estimate // 0 | round)%"'
}

run_compare() {
    local p1="$1"
    local p2="$2"
    
    echo -e "${CYAN}🧠 INTEL: Project Comparison${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local out1 out2
    out1=$(run_auditor --path "$p1" --format json 2>/dev/null)
    out2=$(run_auditor --path "$p2" --format json 2>/dev/null)
    
    echo -e "\n${BOLD}$p1:${NC}"
    echo "$out1" | jq -r '.[0] | "  Score: \(.viability.score)/100 (\(.viability.grade))\n  Status: \(.status)\n  Lines: \(.code.total_lines)"'
    
    echo -e "\n${BOLD}$p2:${NC}"
    echo "$out2" | jq -r '.[0] | "  Score: \(.viability.score)/100 (\(.viability.grade))\n  Status: \(.status)\n  Lines: \(.code.total_lines)"'
    
    # Compare scores
    local s1 s2
    s1=$(echo "$out1" | jq -r '.[0].viability.score // 0')
    s2=$(echo "$out2" | jq -r '.[0].viability.score // 0')
    
    echo ""
    if (( $(echo "$s1 > $s2" | bc -l) )); then
        echo -e "${GREEN}Winner: $p1 (Δ +$(echo "$s1 - $s2" | bc) points)${NC}"
    elif (( $(echo "$s2 > $s1" | bc -l) )); then
        echo -e "${GREEN}Winner: $p2 (Δ +$(echo "$s2 - $s1" | bc) points)${NC}"
    else
        echo -e "${YELLOW}Tie! Both projects have equal scores.${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

check_auditor

# Parse arguments
CMD=""
TARGET=""
FORMAT="table"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        scan|nix|dev|score|health|deps|quality|compare)
            CMD="$1"
            shift
            ;;
        --format|-f)
            FORMAT="$2"
            shift 2
            ;;
        --ai)
            EXTRA_ARGS+=("--ai")
            shift
            ;;
        --verbose|-v)
            EXTRA_ARGS+=("--verbose")
            shift
            ;;
        --output|-o)
            EXTRA_ARGS+=("--output" "$2")
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            else
                # For compare command, second target
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# Default command based on context
if [[ -z "$CMD" ]]; then
    CMD="audit"
fi
if [[ -z "$TARGET" ]]; then
    TARGET="."
fi

# Execute command
case "$CMD" in
    audit)
        run_audit "$TARGET" "$FORMAT" "${EXTRA_ARGS[@]}"
        ;;
    scan)
        run_scan "$TARGET" "$FORMAT" "${EXTRA_ARGS[@]}"
        ;;
    nix)
        run_audit "$NIXOS_DIR" "$FORMAT" "${EXTRA_ARGS[@]}"
        ;;
    dev)
        run_scan "$DEV_DIR" "$FORMAT" "${EXTRA_ARGS[@]}"
        ;;
    score)
        run_score "$TARGET"
        ;;
    health)
        run_health "$TARGET"
        ;;
    deps)
        run_deps "$TARGET"
        ;;
    quality)
        run_quality "$TARGET"
        ;;
    compare)
        if [[ ${#EXTRA_ARGS[@]} -lt 1 ]]; then
            echo -e "${RED}Error: compare requires two paths${NC}"
            echo "Usage: intel compare <project1> <project2>"
            exit 1
        fi
        run_compare "$TARGET" "${EXTRA_ARGS[0]}"
        ;;
    *)
        echo -e "${RED}Unknown command: $CMD${NC}"
        show_help
        exit 1
        ;;
esac
