#!/usr/bin/env bash
# Module Catalog - Comprehensive NixOS module state analyzer
# Catalogs all modules and determines: active, disabled, or orphan status
# Optimized version with single nix eval call

set -euo pipefail

FLAKE_ROOT="/etc/nixos"
MODULES_DIR="$FLAKE_ROOT/modules"
CONFIG_FILE="$FLAKE_ROOT/hosts/kernelcore/configuration.nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Stats counters
ACTIVE=0
DISABLED=0
ORPHAN=0
DECLARED_ACTIVE=0
DECLARED_DISABLED=0
TOTAL=0

echo "🔍 NixOS Module Catalog - Comprehensive State Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to extract module option path from .nix file
extract_option_path() {
    local file="$1"
    local option_path=""

    # Try multiple patterns using rg
    # Pattern 1: options.kernelcore.foo.bar
    option_path=$(rg -o 'options\.kernelcore\.[a-zA-Z0-9._-]+' "$file" 2>/dev/null | head -1 | sed 's/^options\.//' | sed 's/\s*=.*//' || true)

    # Pattern 2: cfg = config.kernelcore.foo.bar
    if [ -z "$option_path" ]; then
        option_path=$(rg -o 'config\.kernelcore\.[a-zA-Z0-9._-]+' "$file" 2>/dev/null | head -1 | sed 's/^config\.//' || true)
    fi

    echo "$option_path"
}

# Function to check if option is declared in configuration.nix
is_declared() {
    local option="$1"
    # Remove .enable suffix if present for searching
    local base_option=$(echo "$option" | sed 's/\.enable$//')

    if rg -q "^\s*${base_option}\s*=" "$CONFIG_FILE" 2>/dev/null || \
       rg -q "^\s*${base_option}\s*\{" "$CONFIG_FILE" 2>/dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}

# Function to determine state symbol
state_symbol() {
    local state="$1"
    case "$state" in
        ACTIVE)   echo -e "${GREEN}✓ ACTIVE  ${NC}" ;;
        DISABLED) echo -e "${YELLOW}○ DISABLED${NC}" ;;
        ORPHAN)   echo -e "${GRAY}✗ ORPHAN  ${NC}" ;;
        UNKNOWN)  echo -e "${RED}? UNKNOWN ${NC}" ;;
    esac
}

# Store results
declare -a MODULE_PATHS
declare -a MODULE_OPTIONS
declare -a MODULE_STATES
declare -a MODULE_DECLARED

echo "📂 Scanning modules directory: $MODULES_DIR"
echo ""

# First pass: collect all module options
declare -a ALL_OPTIONS
while IFS= read -r -d '' module_file; do
    # Skip default.nix aggregators
    if [[ "$(basename "$module_file")" == "default.nix" ]]; then
        continue
    fi

    option_path=$(extract_option_path "$module_file")

    if [ -n "$option_path" ]; then
        # Remove .enable suffix if present
        option_base=$(echo "$option_path" | sed 's/\.enable$//')
        ALL_OPTIONS+=("$option_base")
    fi
done < <(find "$MODULES_DIR" -type f -name "*.nix" -print0)

echo "⚙️  Found ${#ALL_OPTIONS[@]} modules with options"
echo "🔬 Evaluating configuration (this may take a moment)..."
echo ""

# Single nix eval to get all config (much faster!)
CONFIG_JSON=$(nix eval --json "$FLAKE_ROOT#nixosConfigurations.kernelcore.config.kernelcore" 2>/dev/null || echo "{}")

# Second pass: analyze each module
while IFS= read -r -d '' module_file; do
    if [[ "$(basename "$module_file")" == "default.nix" ]]; then
        continue
    fi

    rel_path="${module_file#$MODULES_DIR/}"
    option_path=$(extract_option_path "$module_file")

    if [ -z "$option_path" ]; then
        continue
    fi

    # Remove .enable suffix
    option_base=$(echo "$option_path" | sed 's/\.enable$//')

    # Check if declared
    declared=$(is_declared "$option_base")

    # Determine state by parsing JSON or checking declaration
    state="ORPHAN"

    # Try to extract value from JSON
    if [ "$CONFIG_JSON" != "{}" ]; then
        # Navigate JSON path (e.g., kernelcore.soc.enable -> .soc.enable)
        json_path=$(echo "$option_base" | sed 's/^kernelcore\.//')

        # Try to get enable value
        enable_value=$(echo "$CONFIG_JSON" | jq -r ".${json_path}.enable // \"null\"" 2>/dev/null || echo "null")

        if [ "$enable_value" == "true" ]; then
            state="ACTIVE"
        elif [ "$enable_value" == "false" ]; then
            state="DISABLED"
        elif [ "$declared" == "yes" ]; then
            # Declared but no enable option found - might be always on
            state="ACTIVE"
        fi
    else
        # Fallback: check declaration
        if [ "$declared" == "yes" ]; then
            # Try to parse from config file
            if rg -q "${option_base}.*enable\s*=\s*true" "$CONFIG_FILE" 2>/dev/null; then
                state="ACTIVE"
            elif rg -q "${option_base}.*enable\s*=\s*false" "$CONFIG_FILE" 2>/dev/null; then
                state="DISABLED"
            else
                state="ACTIVE"  # Declared without explicit enable = assumed active
            fi
        fi
    fi

    # Store results
    MODULE_PATHS+=("$rel_path")
    MODULE_OPTIONS+=("$option_base")
    MODULE_STATES+=("$state")
    MODULE_DECLARED+=("$declared")

    # Update counters
    ((TOTAL++))
    case "$state" in
        ACTIVE)
            ((ACTIVE++))
            [ "$declared" == "yes" ] && ((DECLARED_ACTIVE++))
            ;;
        DISABLED)
            ((DISABLED++))
            [ "$declared" == "yes" ] && ((DECLARED_DISABLED++))
            ;;
        ORPHAN)   ((ORPHAN++)) ;;
    esac

done < <(find "$MODULES_DIR" -type f -name "*.nix" -print0)

# Print results table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-45s %-45s %-12s %-10s\n" "MODULE PATH" "OPTION" "STATE" "DECLARED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for i in "${!MODULE_PATHS[@]}"; do
    path="${MODULE_PATHS[$i]}"
    option="${MODULE_OPTIONS[$i]}"
    state="${MODULE_STATES[$i]}"
    declared="${MODULE_DECLARED[$i]}"

    # Truncate long paths
    if [ ${#path} -gt 43 ]; then
        path="...${path: -40}"
    fi
    if [ ${#option} -gt 43 ]; then
        option="...${option: -40}"
    fi

    printf "%-45s %-45s " "$path" "$option"
    state_symbol "$state"
    printf " %-10s\n" "$([ "$declared" == "yes" ] && echo -e "${BLUE}yes${NC}" || echo -e "${GRAY}no${NC}")"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary statistics
echo "📊 Summary Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total modules found:     ${BLUE}$TOTAL${NC}"
echo ""
echo -e "  ${GREEN}✓ ACTIVE:${NC}             $ACTIVE ($(awk "BEGIN {printf \"%.1f\", $ACTIVE/$TOTAL*100}")%)"
echo -e "    └─ Declared:         $DECLARED_ACTIVE"
echo -e "    └─ Default (orphan): $((ACTIVE - DECLARED_ACTIVE))"
echo ""
echo -e "  ${YELLOW}○ DISABLED:${NC}           $DISABLED ($(awk "BEGIN {printf \"%.1f\", $DISABLED/$TOTAL*100}")%)"
echo -e "    └─ Explicitly set:   $DECLARED_DISABLED"
echo ""
echo -e "  ${GRAY}✗ ORPHAN:${NC}             $ORPHAN ($(awk "BEGIN {printf \"%.1f\", $ORPHAN/$TOTAL*100}")%)"
echo -e "    └─ Using defaults, not in config.nix"
echo ""

# Recommendations
if [ $ORPHAN -gt 5 ]; then
    echo "💡 Recommendations:"
    echo "   • $ORPHAN modules are using default values"
    echo "   • Consider declaring critical modules explicitly for clarity"
    echo "   • Review orphan list below to ensure defaults are acceptable"
    echo ""
fi

# List key modules by category
echo "📋 Module Status by Category:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Group by category (security, network, development, etc.)
for category in security network development containers soc ml applications hardware virtualization; do
    found=false
    for i in "${!MODULE_OPTIONS[@]}"; do
        if [[ "${MODULE_OPTIONS[$i]}" == kernelcore.$category* ]]; then
            if [ "$found" == false ]; then
                echo -e "\n${BLUE}${category^^}:${NC}"
                found=true
            fi
            printf "  %-50s " "${MODULE_OPTIONS[$i]}"
            state_symbol "${MODULE_STATES[$i]}"
            echo ""
        fi
    done
done

echo ""
echo "✅ Module catalog complete!"
echo ""
echo "💾 To save this report: ./scripts/surgical/module-catalog.sh > module-status-report.txt"
