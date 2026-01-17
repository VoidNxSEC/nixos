#!/usr/bin/env bash
# GitLab Duo Settings Validation Script
# Validates all GitLab Duo configuration and environment variables

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Main validation
main() {
    print_header "GitLab Duo Settings Validation"
    
    # 1. Check environment variables
    echo ""
    echo "Checking environment variables..."
    
    if [ -n "${GITLAB_DUO_ENABLED:-}" ]; then
        check_pass "GITLAB_DUO_ENABLED is set"
    else
        check_fail "GITLAB_DUO_ENABLED is not set"
    fi
    
    if [ -n "${GITLAB_DUO_ENDPOINT:-}" ]; then
        check_pass "GITLAB_DUO_ENDPOINT is set: ${GITLAB_DUO_ENDPOINT}"
    else
        check_fail "GITLAB_DUO_ENDPOINT is not set"
    fi
    
    if [ -n "${GITLAB_DUO_API_KEY:-}" ] || [ -f ~/.config/gitlab-duo/api-key ]; then
        check_pass "GitLab Duo API key is configured"
    else
        check_fail "GitLab Duo API key is not configured"
    fi
    
    # 2. Check feature flags
    echo ""
    echo "Checking feature flags..."
    
    local features=(
        "GITLAB_DUO_FEATURES_CODE_COMPLETION"
        "GITLAB_DUO_FEATURES_CODE_REVIEW"
        "GITLAB_DUO_FEATURES_SECURITY_SCANNING"
        "GITLAB_DUO_FEATURES_DOCUMENTATION"
    )
    
    for feature in "${features[@]}"; do
        if [ "${!feature:-false}" = "true" ]; then
            check_pass "$feature is enabled"
        else
            check_warn "$feature is disabled"
        fi
    done
    
    # 3. Check model configuration
    echo ""
    echo "Checking model configuration..."
    
    local models=(
        "GITLAB_DUO_MODEL_CODE_GENERATION"
        "GITLAB_DUO_MODEL_CODE_REVIEW"
        "GITLAB_DUO_MODEL_SECURITY"
    )
    
    for model in "${models[@]}"; do
        if [ -n "${!model:-}" ]; then
            check_pass "$model is set: ${!model}"
        else
            check_fail "$model is not set"
        fi
    done
    
    # 4. Check rate limiting
    echo ""
    echo "Checking rate limiting configuration..."
    
    if [ -n "${GITLAB_DUO_RATE_LIMIT_RPM:-}" ]; then
        check_pass "Rate limit (RPM) is set: ${GITLAB_DUO_RATE_LIMIT_RPM}"
    else
        check_fail "Rate limit (RPM) is not set"
    fi
    
    if [ -n "${GITLAB_DUO_RATE_LIMIT_TPM:-}" ]; then
        check_pass "Rate limit (TPM) is set: ${GITLAB_DUO_RATE_LIMIT_TPM}"
    else
        check_fail "Rate limit (TPM) is not set"
    fi
    
    # 5. Check cache configuration
    echo ""
    echo "Checking cache configuration..."
    
    if [ "${GITLAB_DUO_CACHE_ENABLED:-false}" = "true" ]; then
        check_pass "Cache is enabled"
        if [ -n "${GITLAB_DUO_CACHE_TTL:-}" ]; then
            check_pass "Cache TTL is set: ${GITLAB_DUO_CACHE_TTL}s"
        else
            check_fail "Cache TTL is not set"
        fi
    else
        check_warn "Cache is disabled"
    fi
    
    # 6. Check logging configuration
    echo ""
    echo "Checking logging configuration..."
    
    if [ -n "${GITLAB_DUO_LOG_LEVEL:-}" ]; then
        check_pass "Log level is set: ${GITLAB_DUO_LOG_LEVEL}"
    else
        check_fail "Log level is not set"
    fi
    
    if [ -n "${GITLAB_DUO_LOG_FORMAT:-}" ]; then
        check_pass "Log format is set: ${GITLAB_DUO_LOG_FORMAT}"
    else
        check_fail "Log format is not set"
    fi
    
    # 7. Check configuration files
    echo ""
    echo "Checking configuration files..."
    
    if [ -f "/etc/gitlab-duo/settings.yaml" ]; then
        check_pass "settings.yaml exists at /etc/gitlab-duo/settings.yaml"
    else
        check_fail "settings.yaml not found at /etc/gitlab-duo/settings.yaml"
    fi
    
    # 8. Check directories
    echo ""
    echo "Checking required directories..."
    
    local dirs=(
        "logs/gitlab-duo"
    )
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            check_pass "Directory exists: $dir"
        else
            check_warn "Directory missing: $dir (will be created on nix develop)"
        fi
    done
    
    # 9. Validate YAML syntax
    echo ""
    echo "Validating YAML syntax..."
    
    if command -v yq &> /dev/null; then
        if yq eval '.' "/etc/gitlab-duo/settings.yaml" > /dev/null 2>&1; then
            check_pass "settings.yaml has valid YAML syntax"
        else
            check_fail "settings.yaml has invalid YAML syntax"
        fi
    else
        check_warn "yq not found, skipping YAML validation"
    fi
    
    # Summary
    echo ""
    print_header "Validation Summary"
    echo -e "${GREEN}Passed:${NC}  $PASSED"
    echo -e "${RED}Failed:${NC}  $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Please review the configuration.${NC}"
        return 1
    fi
}

main "$@"
