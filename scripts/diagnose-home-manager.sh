#!/usr/bin/env bash
# ============================================================
# Home Manager Diagnostics and Repair Script
# ============================================================
# This script diagnoses and fixes common home-manager issues
# including Nix store inconsistencies and profile problems.
#
# Usage: ./diagnose-home-manager.sh [options]
#
# Options:
#   --check-only     Only run diagnostics, don't fix anything
#   --fix            Run diagnostics and apply fixes
#   --deep-clean     Deep clean (removes old generations, repairs store)
#   --help           Show this help message
# ============================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Parse arguments
MODE="check"
DEEP_CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --check-only)
            MODE="check"
            shift
            ;;
        --fix)
            MODE="fix"
            shift
            ;;
        --deep-clean)
            DEEP_CLEAN=true
            MODE="fix"
            shift
            ;;
        --help)
            head -n 20 "$0" | grep "^#" | sed 's/^# //'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            log_info "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "🔍 HOME MANAGER DIAGNOSTICS"

# ============================================================
# 1. Check if home-manager is available
# ============================================================
log_info "Checking home-manager installation..."

if command -v home-manager &> /dev/null; then
    HM_VERSION=$(home-manager --version 2>&1 || echo "unknown")
    log_success "home-manager is installed: $HM_VERSION"
else
    log_warning "home-manager command not found in PATH"
    log_info "home-manager is configured as NixOS module (flake-based)"
    HM_AVAILABLE=false
fi

# ============================================================
# 2. Check Nix Store Health
# ============================================================
print_header "🏪 NIX STORE DIAGNOSTICS"

log_info "Checking Nix store integrity..."
if nix-store --verify --check-contents 2>&1 | tee /tmp/nix-verify.log | grep -q "error"; then
    log_error "Nix store has integrity issues!"
    cat /tmp/nix-verify.log

    if [[ "$MODE" == "fix" ]]; then
        log_info "Attempting to repair Nix store..."
        nix-store --verify --check-contents --repair || log_error "Repair failed"
    fi
else
    log_success "Nix store integrity: OK"
fi

# Check for dead symlinks in store
log_info "Checking for dead symlinks in /nix/store..."
DEAD_LINKS=$(find /nix/store -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
if [[ "$DEAD_LINKS" -gt 0 ]]; then
    log_warning "Found $DEAD_LINKS dead symlinks in /nix/store"
    if [[ "$MODE" == "fix" ]]; then
        log_info "Removing dead symlinks..."
        find /nix/store -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
        log_success "Dead symlinks removed"
    fi
else
    log_success "No dead symlinks found"
fi

# ============================================================
# 3. Check Home Manager Profile
# ============================================================
print_header "🏠 HOME MANAGER PROFILE DIAGNOSTICS"

HM_PROFILE="$HOME/.local/state/nix/profiles/home-manager"
if [[ ! -L "$HM_PROFILE" ]]; then
    HM_PROFILE="$HOME/.nix-profile"
fi

log_info "Home manager profile: $HM_PROFILE"

if [[ -L "$HM_PROFILE" ]]; then
    PROFILE_TARGET=$(readlink -f "$HM_PROFILE")
    log_info "Profile points to: $PROFILE_TARGET"

    if [[ ! -e "$PROFILE_TARGET" ]]; then
        log_error "Profile target doesn't exist!"
        if [[ "$MODE" == "fix" ]]; then
            log_info "Rebuilding home-manager profile..."
            if command -v home-manager &> /dev/null; then
                home-manager switch || log_error "Failed to rebuild profile"
            else
                log_info "Rebuilding via NixOS configuration..."
                sudo nixos-rebuild switch --flake /etc/nixos#kernelcore || log_error "Failed to rebuild"
            fi
        fi
    else
        log_success "Profile target exists"
    fi
else
    log_warning "Home manager profile not found"
fi

# List generations
log_info "Home manager generations:"
if command -v home-manager &> /dev/null; then
    home-manager generations | head -10 || log_warning "Could not list generations"
else
    nix profile history --profile "$HM_PROFILE" 2>/dev/null | head -10 || log_warning "Could not list generations"
fi

# ============================================================
# 4. Check Home Manager State Directory
# ============================================================
print_header "📂 HOME MANAGER STATE DIAGNOSTICS"

HM_STATE_DIR="$HOME/.local/state/home-manager"
HM_GCROOTS="$HOME/.local/state/nix/gcroots/home-manager"

log_info "Checking home-manager state directory..."
if [[ -d "$HM_STATE_DIR" ]]; then
    log_success "State directory exists: $HM_STATE_DIR"

    # Check for broken symlinks
    log_info "Checking for broken symlinks in state..."
    BROKEN_STATE=$(find "$HM_STATE_DIR" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
    if [[ "$BROKEN_STATE" -gt 0 ]]; then
        log_warning "Found $BROKEN_STATE broken symlinks in state directory"
        if [[ "$MODE" == "fix" ]]; then
            log_info "Removing broken symlinks..."
            find "$HM_STATE_DIR" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
            log_success "Broken symlinks removed"
        fi
    else
        log_success "No broken symlinks in state directory"
    fi
else
    log_warning "State directory doesn't exist: $HM_STATE_DIR"
    if [[ "$MODE" == "fix" ]]; then
        log_info "Creating state directory..."
        mkdir -p "$HM_STATE_DIR"
    fi
fi

# Check GC roots
log_info "Checking GC roots..."
if [[ -L "$HM_GCROOTS" ]]; then
    GCROOT_TARGET=$(readlink -f "$HM_GCROOTS")
    if [[ -e "$GCROOT_TARGET" ]]; then
        log_success "GC root is valid: $HM_GCROOTS -> $GCROOT_TARGET"
    else
        log_error "GC root points to non-existent target!"
        if [[ "$MODE" == "fix" ]]; then
            log_info "Removing broken GC root..."
            rm -f "$HM_GCROOTS"
            log_success "Broken GC root removed (will be recreated on next rebuild)"
        fi
    fi
else
    log_warning "GC root not found (may be recreated on rebuild)"
fi

# ============================================================
# 5. Check for Common Issues
# ============================================================
print_header "🔧 COMMON ISSUE DIAGNOSTICS"

# Check disk space
log_info "Checking disk space..."
STORE_USAGE=$(df -h /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ "$STORE_USAGE" -gt 85 ]]; then
    log_warning "Nix store is using ${STORE_USAGE}% of available space"
    log_info "Consider running garbage collection: nix-collect-garbage -d"
else
    log_success "Nix store disk usage: ${STORE_USAGE}%"
fi

# Check for zombie processes
log_info "Checking for zombie nix-daemon processes..."
ZOMBIE_DAEMONS=$(ps aux | grep nix-daemon | grep -c defunct || true)
if [[ "$ZOMBIE_DAEMONS" -gt 0 ]]; then
    log_warning "Found $ZOMBIE_DAEMONS zombie nix-daemon processes"
    log_info "Consider restarting nix-daemon: sudo systemctl restart nix-daemon"
else
    log_success "No zombie processes found"
fi

# Check nix-daemon status
log_info "Checking nix-daemon status..."
if systemctl is-active --quiet nix-daemon; then
    log_success "nix-daemon is running"
else
    log_error "nix-daemon is not running!"
    if [[ "$MODE" == "fix" ]]; then
        log_info "Starting nix-daemon..."
        sudo systemctl start nix-daemon || log_error "Failed to start nix-daemon"
    fi
fi

# ============================================================
# 6. Deep Clean (if requested)
# ============================================================
if [[ "$DEEP_CLEAN" == true ]]; then
    print_header "🧹 DEEP CLEAN"

    log_warning "This will remove old generations and run garbage collection"
    log_info "Current store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"

    # Remove old home-manager generations
    log_info "Removing home-manager generations older than 7 days..."
    if command -v home-manager &> /dev/null; then
        home-manager expire-generations "-7 days" || log_warning "Could not expire generations"
    fi

    # Remove old user profile generations
    log_info "Removing user profile generations older than 7 days..."
    nix profile wipe-history --older-than 7d 2>/dev/null || true

    # Run garbage collection
    log_info "Running garbage collection..."
    nix-collect-garbage -d || log_warning "Garbage collection had warnings"

    # Optimize store
    log_info "Optimizing Nix store (deduplication)..."
    nix-store --optimise || log_warning "Store optimization had warnings"

    log_success "Deep clean complete!"
    log_info "New store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
fi

# ============================================================
# 7. Final Recommendations
# ============================================================
print_header "📋 RECOMMENDATIONS"

echo "Based on the diagnostics, here are the recommended actions:"
echo ""

if [[ "$MODE" == "check" ]]; then
    echo "  1. Run this script with --fix to apply automatic fixes"
    echo "  2. Run with --deep-clean to free up space and clean old generations"
fi

echo "  • To rebuild home-manager configuration:"
if command -v home-manager &> /dev/null; then
    echo "    $ home-manager switch"
else
    echo "    $ sudo nixos-rebuild switch --flake /etc/nixos#kernelcore"
fi

echo ""
echo "  • To clean up old generations:"
echo "    $ nix-collect-garbage -d"
echo "    $ sudo nix-collect-garbage -d  # For system-wide cleanup"
echo ""
echo "  • To verify and repair Nix store:"
echo "    $ nix-store --verify --check-contents --repair"
echo ""
echo "  • To check home-manager logs:"
echo "    $ journalctl --user -u home-manager-$USER.service"
echo ""
echo "  • To restart nix-daemon:"
echo "    $ sudo systemctl restart nix-daemon"
echo ""

print_header "✅ DIAGNOSTICS COMPLETE"

if [[ "$MODE" == "fix" ]]; then
    log_success "Fixes have been applied where possible"
    log_info "You may need to rebuild your configuration for changes to take effect"
fi
