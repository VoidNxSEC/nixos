#!/usr/bin/env bash

# Post-Rebuild Validation Script
# Validates critical services and system components after NixOS rebuild
# Usage: post-rebuild-validate.sh [--fix] [--verbose]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Options
FIX_MODE=false
VERBOSE=false
FAILED_CHECKS=0
TOTAL_CHECKS=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --fix)
            FIX_MODE=true
            ;;
        --verbose|-v)
            VERBOSE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--fix] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --fix       Attempt to fix failed services"
            echo "  --verbose   Show detailed output"
            echo "  --help      Show this help message"
            exit 0
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}═══ $1 ═══${NC}"
}

check_service() {
    local service=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if systemctl is-active --quiet "$service"; then
        log_success "$description ($service) is running"
        return 0
    else
        log_error "$description ($service) is NOT running"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))

        if $VERBOSE; then
            systemctl status "$service" --no-pager -l || true
        fi

        if $FIX_MODE; then
            log_info "Attempting to restart $service..."
            if sudo systemctl restart "$service"; then
                log_success "$service restarted successfully"
                FAILED_CHECKS=$((FAILED_CHECKS - 1))
            else
                log_error "Failed to restart $service"
            fi
        fi
        return 1
    fi
}

check_command() {
    local cmd=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command -v "$cmd" &> /dev/null; then
        log_success "$description ($cmd) is available"
        return 0
    else
        log_error "$description ($cmd) is NOT available"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_path() {
    local path=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -e "$path" ]]; then
        log_success "$description exists at $path"
        return 0
    else
        log_error "$description NOT found at $path"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_network() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Try multiple methods to verify network connectivity
    local network_ok=false

    # Method 1: Check if we have an active network interface with IP
    if ip addr show | grep -q "inet .* scope global"; then
        network_ok=true
        if $VERBOSE; then
            log_info "Network interface has IP address"
        fi
    fi

    # Method 2: Try ping if network interface looks good
    if $network_ok && ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        log_success "Network connectivity is working (ping test)"
        return 0
    fi

    # Method 3: Try curl as fallback (more reliable than ping)
    if $network_ok && command -v curl &> /dev/null; then
        if curl -s --connect-timeout 2 --max-time 5 https://www.google.com &> /dev/null; then
            log_success "Network connectivity is working (HTTP test)"
            return 0
        fi
    fi

    # Method 4: Check if NetworkManager shows active connection
    if nmcli -t -f STATE general | grep -q "connected"; then
        log_success "Network connectivity is working (NetworkManager reports connected)"
        return 0
    fi

    # If we got here, network is likely down
    log_error "Network connectivity FAILED"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))

    if $VERBOSE; then
        log_info "Attempting diagnostic information:"
        ip addr show | head -10 || true
        nmcli general status || true
    fi

    if $FIX_MODE; then
        log_info "Attempting to restart NetworkManager..."
        if sudo systemctl restart NetworkManager; then
            sleep 3
            # Retry connectivity check
            if ping -c 1 -W 2 8.8.8.8 &> /dev/null || nmcli -t -f STATE general | grep -q "connected"; then
                log_success "Network restored"
                FAILED_CHECKS=$((FAILED_CHECKS - 1))
                return 0
            fi
        fi
    fi
    return 1
}

# Main validation
main() {
    echo -e "${BOLD}${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║   NixOS Post-Rebuild Validation                  ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    if $FIX_MODE; then
        log_warning "Running in FIX mode - will attempt to repair failed services"
    fi

    # 1. Critical System Services
    log_section "Critical System Services"
    check_service "dbus.service" "D-Bus System Message Bus"
    check_service "systemd-logind.service" "User Login Management"
    check_service "accounts-daemon.service" "Accounts Service"

    # 2. Display and Desktop Services
    log_section "Display and Desktop Services"
    check_service "display-manager.service" "Display Manager"

    # Check for desktop services (may not all be present)
    if systemctl list-units --type=service --all | grep -q "gnome-shell"; then
        check_service "gnome-shell-wayland.service" "GNOME Shell" || true
    fi

    # 3. Network Services
    log_section "Network Services"
    check_service "NetworkManager.service" "Network Manager"
    check_service "sshd.service" "SSH Daemon"
    check_network

    # 4. Container Services
    log_section "Container and Virtualization Services"
    check_service "docker.service" "Docker Engine"

    if systemctl list-units --type=service --all | grep -q "libvirtd"; then
        check_service "libvirtd.service" "Libvirt Daemon" || true
    fi

    # 5. Security Services
    log_section "Security Services"

    # Check firewall status
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if systemctl is-active --quiet firewall.service; then
        log_success "Firewall service is running"

        # Check nftables rules
        if command -v nft &> /dev/null; then
            RULE_COUNT=$(sudo nft list ruleset 2>/dev/null | grep -c "^[[:space:]]*rule" || echo "0")
            if [[ $RULE_COUNT -gt 0 ]]; then
                log_success "Firewall has $RULE_COUNT active nftables rules"
                if $VERBOSE; then
                    sudo nft list ruleset | head -20
                fi
            else
                log_warning "Firewall is running but has no nftables rules"
            fi
        fi

        # Check iptables rules as fallback
        if command -v iptables &> /dev/null; then
            IPTABLES_RULES=$(sudo iptables -L -n 2>/dev/null | grep -c "^Chain" | tr -d '[:space:]' || echo "0")
            if [[ "$IPTABLES_RULES" =~ ^[0-9]+$ ]] && [[ $IPTABLES_RULES -gt 0 ]]; then
                log_info "Found $IPTABLES_RULES iptables chains"
            fi
        fi
    else
        log_error "Firewall service is NOT running - this is critical!"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))

        if $FIX_MODE; then
            log_info "Attempting to start firewall..."
            if sudo systemctl start firewall.service; then
                log_success "Firewall started successfully"
                FAILED_CHECKS=$((FAILED_CHECKS - 1))
            else
                log_error "Failed to start firewall"
            fi
        else
            log_warning "Many services depend on firewall being active!"
        fi
    fi

    # Check fail2ban if present
    if systemctl list-units --type=service --all | grep -q "fail2ban"; then
        check_service "fail2ban.service" "Fail2Ban" || true
    fi

    # Check AppArmor if present
    if systemctl list-units --type=service --all | grep -q "apparmor"; then
        check_service "apparmor.service" "AppArmor" || true
    fi

    # 6. System Health
    log_section "System Health Checks"

    # Check Nix store integrity
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if nix-store --verify --check-contents &> /dev/null; then
        log_success "Nix store integrity verified"
    else
        log_warning "Nix store has issues (running repair may help)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))

        if $FIX_MODE; then
            log_info "Running nix-store --repair..."
            sudo nix-store --verify --check-contents --repair || true
        fi
    fi

    # Check for failed systemd units
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_UNITS=$(systemctl list-units --failed --no-pager --no-legend | wc -l)
    if [[ $FAILED_UNITS -eq 0 ]]; then
        log_success "No failed systemd units"
    else
        log_warning "$FAILED_UNITS failed systemd unit(s) detected"

        if $VERBOSE; then
            systemctl list-units --failed --no-pager
        fi

        # Don't count this as a critical failure
    fi

    # 7. Essential Commands
    log_section "Essential Commands"
    check_command "nix" "Nix package manager"
    check_command "systemctl" "Systemd control"
    check_command "journalctl" "System logging"
    check_command "bash" "Bash shell"
    check_command "git" "Git version control"

    # 8. Display environment check
    log_section "Display Environment"

    if [[ -n "${DISPLAY:-}" ]]; then
        log_success "DISPLAY is set: $DISPLAY"
    else
        log_warning "DISPLAY is not set (normal for console session)"
    fi

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log_success "WAYLAND_DISPLAY is set: $WAYLAND_DISPLAY"
    fi

    if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
        log_info "Session type: $XDG_SESSION_TYPE"
    fi

    # Final report
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""

    PASSED=$((TOTAL_CHECKS - FAILED_CHECKS))

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${BOLD}${GREEN}✓ All checks passed!${NC} ($TOTAL_CHECKS/$TOTAL_CHECKS)"
        echo -e "${GREEN}System is healthy and ready to use.${NC}"
        exit 0
    else
        echo -e "${BOLD}${YELLOW}⚠ Some checks failed${NC} ($PASSED/$TOTAL_CHECKS passed, $FAILED_CHECKS failed)"

        if ! $FIX_MODE; then
            echo -e "${YELLOW}Run with --fix to attempt automatic repairs${NC}"
        fi

        echo ""
        echo -e "${CYAN}To investigate further:${NC}"
        echo "  journalctl -xe          # View system logs"
        echo "  systemctl --failed      # List failed units"
        echo "  $0 --fix                # Attempt automatic fixes"
        echo "  $0 --verbose            # Show detailed output"
        exit 1
    fi
}

# Run main function
main "$@"
