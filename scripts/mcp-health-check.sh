#!/usr/bin/env bash
# MCP Server Health Check Script
# Tests the SecureLLM Bridge MCP server health and functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MCP_SERVER_DIR="${MCP_SERVER_DIR:-modules/ml/integration/mcp/server/src/index.ts}"
REPORT_FILE="${REPORT_FILE:-/tmp/mcp-health-report-$(date +%Y%m%d-%H%M%S).txt}"

# Counters
PASS=0
FAIL=0
WARN=0

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$REPORT_FILE"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$REPORT_FILE"
  ((PASS++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1" | tee -a "$REPORT_FILE"
  ((FAIL++))
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$REPORT_FILE"
  ((WARN++))
}

section() {
  echo "" | tee -a "$REPORT_FILE"
  echo -e "${BLUE}===================================================${NC}" | tee -a "$REPORT_FILE"
  echo -e "${BLUE}$1${NC}" | tee -a "$REPORT_FILE"
  echo -e "${BLUE}===================================================${NC}" | tee -a "$REPORT_FILE"
}

# Initialize report
echo "MCP Server Health Check Report" >"$REPORT_FILE"
echo "Generated: $(date)" >>"$REPORT_FILE"
echo "Host: $(hostname)" >>"$REPORT_FILE"
echo "" >>"$REPORT_FILE"

section "1. ENVIRONMENT CHECK"

# Check if we're in the right directory
if [ ! -d "$MCP_SERVER_DIR" ]; then
  log_fail "MCP server directory not found: $MCP_SERVER_DIR"
  exit 1
fi
log_pass "MCP server directory exists: $MCP_SERVER_DIR"

# Check Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  log_pass "Node.js installed: $NODE_VERSION"
else
  log_fail "Node.js not found in PATH"
fi

# Check npm
if command -v npm &>/dev/null; then
  NPM_VERSION=$(npm --version)
  log_pass "npm installed: $NPM_VERSION"
else
  log_fail "npm not found in PATH"
fi

section "2. PACKAGE CONFIGURATION"

cd "$MCP_SERVER_DIR"

# Check package.json
if [ -f "package.json" ]; then
  log_pass "package.json exists"

  # Validate JSON
  if jq empty package.json 2>/dev/null; then
    log_pass "package.json is valid JSON"
  else
    log_fail "package.json is invalid JSON"
  fi

  # Check key fields
  PKG_NAME=$(jq -r '.name' package.json)
  PKG_VERSION=$(jq -r '.version' package.json)
  log_info "Package: $PKG_NAME@$PKG_VERSION"
else
  log_fail "package.json not found"
fi

# Check dependencies
section "3. DEPENDENCIES"

if [ -d "node_modules" ]; then
  log_pass "node_modules directory exists"

  # Check critical dependencies
  DEPS=("@modelcontextprotocol/sdk" "better-sqlite3" "typescript")
  for dep in "${DEPS[@]}"; do
    if [ -d "node_modules/$dep" ]; then
      log_pass "Dependency installed: $dep"
    else
      log_fail "Missing dependency: $dep"
    fi
  done
else
  log_warn "node_modules not found - run 'npm install'"
fi

# List installed packages
log_info "Installed packages:"
npm list --depth=0 2>/dev/null | tee -a "$REPORT_FILE" || true

section "4. BUILD CHECK"

# Check if TypeScript config exists
if [ -f "tsconfig.json" ]; then
  log_pass "tsconfig.json exists"
else
  log_fail "tsconfig.json not found"
fi

# Check if source files exist
if [ -d "src" ]; then
  log_pass "src directory exists"
  SRC_COUNT=$(find src -name "*.ts" | wc -l)
  log_info "TypeScript source files: $SRC_COUNT"
else
  log_fail "src directory not found"
fi

# Check if build directory exists
if [ -d "build" ]; then
  log_pass "build directory exists"
  JS_COUNT=$(find build -name "*.js" | wc -l)
  log_info "Built JavaScript files: $JS_COUNT"

  # Check if main entry point exists
  if [ -f "build/index.js" ]; then
    log_pass "Main entry point exists: build/index.js"

    # Check if executable
    if [ -x "build/index.js" ]; then
      log_pass "build/index.js is executable"
    else
      log_warn "build/index.js is not executable"
    fi
  else
    log_fail "Main entry point missing: build/index.js"
  fi
else
  log_warn "build directory not found - run 'npm run build'"
fi

# Try to build
log_info "Attempting to build..."
if npm run build >/tmp/mcp-build.log 2>&1; then
  log_pass "Build successful"
else
  log_fail "Build failed - check /tmp/mcp-build.log"
  cat /tmp/mcp-build.log >>"$REPORT_FILE"
fi

section "5. FUNCTIONALITY TEST"

# Test MCP protocol
log_info "Testing MCP protocol..."

# Test tools/list
TOOLS_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node build/index.js 2>&1 | grep -v "^\[" || true)

if echo "$TOOLS_RESPONSE" | jq -e '.result.tools' >/dev/null 2>&1; then
  log_pass "MCP protocol responding correctly"

  # Count tools
  TOOL_COUNT=$(echo "$TOOLS_RESPONSE" | jq '.result.tools | length')
  log_info "Total tools available: $TOOL_COUNT"

  # Check expected tools
  EXPECTED_TOOLS=(
    "provider_test"
    "security_audit"
    "rate_limit_check"
    "build_and_test"
    "provider_config_validate"
    "crypto_key_generate"
    "create_session"
    "save_knowledge"
    "search_knowledge"
    "load_session"
    "list_sessions"
    "get_recent_knowledge"
  )

  for tool in "${EXPECTED_TOOLS[@]}"; do
    if echo "$TOOLS_RESPONSE" | jq -e ".result.tools[] | select(.name==\"$tool\")" >/dev/null; then
      log_pass "Tool available: $tool"
    else
      log_fail "Tool missing: $tool"
    fi
  done
else
  log_fail "MCP protocol not responding correctly"
fi

section "6. KNOWLEDGE DATABASE"

# Check if knowledge database initializes
if echo "$TOOLS_RESPONSE" | grep -q "Database initialized"; then
  log_pass "Knowledge database initialized"
else
  log_warn "Knowledge database may not be initialized"
fi

# Check for knowledge.db file
if [ -f "knowledge.db" ]; then
  log_info "Knowledge database file exists"
  DB_SIZE=$(du -h knowledge.db | cut -f1)
  log_info "Database size: $DB_SIZE"
else
  log_info "Knowledge database not yet created (will be created on first use)"
fi

section "7. CODE QUALITY"

# Check for TypeScript errors (if tsc is available)
if command -v npx &>/dev/null; then
  log_info "Running TypeScript compiler check..."
  if npx tsc --noEmit >/tmp/mcp-tsc.log 2>&1; then
    log_pass "No TypeScript errors"
  else
    ERROR_COUNT=$(grep -c "error TS" /tmp/mcp-tsc.log || echo "0")
    if [ "$ERROR_COUNT" -gt 0 ]; then
      log_warn "TypeScript errors found: $ERROR_COUNT"
    else
      log_pass "TypeScript check passed"
    fi
  fi
fi

# Check source file structure
log_info "Source file structure:"
if [ -d "src" ]; then
  tree -L 3 src 2>/dev/null | tee -a "$REPORT_FILE" || find src -type f -name "*.ts" | sort | tee -a "$REPORT_FILE"
fi

section "8. CONFIGURATION FILES"

# Check for required config files
CONFIG_FILES=("package.json" "tsconfig.json" "README.md")
for config in "${CONFIG_FILES[@]}"; do
  if [ -f "$config" ]; then
    log_pass "Config file exists: $config"
  else
    log_warn "Config file missing: $config"
  fi
done

# Check mcp-server-config.json
if [ -f "../mcp-server-config.json" ]; then
  log_pass "MCP server config exists"
  if jq empty ../mcp-server-config.json 2>/dev/null; then
    log_pass "MCP server config is valid JSON"
  else
    log_warn "MCP server config may be invalid JSON"
  fi
else
  log_info "MCP server config not found (optional)"
fi

section "9. SUMMARY"

echo "" | tee -a "$REPORT_FILE"
echo -e "${BLUE}Test Results:${NC}" | tee -a "$REPORT_FILE"
echo -e "  ${GREEN}PASSED: $PASS${NC}" | tee -a "$REPORT_FILE"
echo -e "  ${RED}FAILED: $FAIL${NC}" | tee -a "$REPORT_FILE"
echo -e "  ${YELLOW}WARNINGS: $WARN${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}✓ MCP Server is HEALTHY${NC}" | tee -a "$REPORT_FILE"
  EXIT_CODE=0
elif [ $FAIL -lt 3 ]; then
  echo -e "${YELLOW}⚠ MCP Server has minor issues${NC}" | tee -a "$REPORT_FILE"
  EXIT_CODE=1
else
  echo -e "${RED}✗ MCP Server has critical issues${NC}" | tee -a "$REPORT_FILE"
  EXIT_CODE=2
fi

echo "" | tee -a "$REPORT_FILE"
echo "Full report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"

exit $EXIT_CODE

