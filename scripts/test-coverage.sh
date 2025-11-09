#!/usr/bin/env bash
# Generate test coverage report for NixOS modules

set -euo pipefail

echo "📊 Generating test coverage report..."

# Count total modules
TOTAL_MODULES=$(find modules -name "*.nix" -type f | wc -l)

# Count tests
TOTAL_TESTS=$(find tests -name "*.nix" -type f ! -name "default.nix" ! -name "test-helpers.nix" | wc -l)

# Analyze module coverage by category
declare -A module_counts
declare -A test_counts

# Count modules per category
for category in $(find modules -mindepth 1 -maxdepth 1 -type d | xargs basename -a); do
  count=$(find "modules/$category" -name "*.nix" -type f | wc -l)
  module_counts[$category]=$count
done

# Count tests per category
for test_file in tests/integration/*.nix; do
  if [[ -f "$test_file" ]]; then
    category=$(basename "$test_file" .nix)
    test_counts[$category]=1
  fi
done

# Calculate coverage
COVERAGE=0
if [[ $TOTAL_MODULES -gt 0 ]]; then
  COVERAGE=$(echo "scale=2; $TOTAL_TESTS / $TOTAL_MODULES * 100" | bc)
fi

# Generate report
cat > coverage-report.md <<EOF
# Test Coverage Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

## Summary

| Metric | Value |
|--------|-------|
| **Total Modules** | $TOTAL_MODULES |
| **Total Tests** | $TOTAL_TESTS |
| **Coverage** | ${COVERAGE}% |

## Coverage Status

EOF

# Add coverage badge
if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
  echo "![Coverage](https://img.shields.io/badge/coverage-${COVERAGE}%25-brightgreen)" >> coverage-report.md
elif (( $(echo "$COVERAGE >= 50" | bc -l) )); then
  echo "![Coverage](https://img.shields.io/badge/coverage-${COVERAGE}%25-yellow)" >> coverage-report.md
else
  echo "![Coverage](https://img.shields.io/badge/coverage-${COVERAGE}%25-red)" >> coverage-report.md
fi

cat >> coverage-report.md <<EOF

## Module Breakdown

| Category | Modules | Tests | Status |
|----------|---------|-------|--------|
EOF

# Add module breakdown
for category in "${!module_counts[@]}"; do
  count=${module_counts[$category]}
  tests=${test_counts[$category]:-0}
  status="❌ No tests"

  if [[ $tests -gt 0 ]]; then
    status="✅ Tested"
  fi

  echo "| **$category** | $count | $tests | $status |" >> coverage-report.md
done | sort

cat >> coverage-report.md <<EOF

## Integration Tests

| Test | Description | Status |
|------|-------------|--------|
EOF

# List integration tests
for test_file in tests/integration/*.nix; do
  if [[ -f "$test_file" ]]; then
    test_name=$(basename "$test_file" .nix)
    description=$(grep -m 1 "description = " "$test_file" | sed 's/.*description = "\(.*\)";/\1/' || echo "No description")
    echo "| **$test_name** | $description | ✅ Implemented |" >> coverage-report.md
  fi
done

cat >> coverage-report.md <<EOF

## Test Execution

### Run All Tests

\`\`\`bash
nix build -f tests allTests --print-build-logs
\`\`\`

### Run Individual Tests

\`\`\`bash
# Security tests
nix build -f tests security --print-build-logs

# Docker tests
nix build -f tests docker --print-build-logs

# Network tests
nix build -f tests networking --print-build-logs
\`\`\`

## Uncovered Modules

### High Priority (Core System)

EOF

# List high-priority uncovered modules
echo "Modules without tests:" >> coverage-report.md
echo "" >> coverage-report.md

for category in security containers hardware; do
  if [[ ${test_counts[$category]:-0} -eq 0 ]]; then
    echo "- **$category/** (${module_counts[$category]:-0} modules)" >> coverage-report.md
  fi
done

cat >> coverage-report.md <<EOF

### Medium Priority

EOF

for category in ml services applications; do
  if [[ ${test_counts[$category]:-0} -eq 0 ]]; then
    echo "- **$category/** (${module_counts[$category]:-0} modules)" >> coverage-report.md
  fi
done

cat >> coverage-report.md <<EOF

## Coverage Goals

| Timeframe | Target Coverage | Status |
|-----------|----------------|--------|
| **Week 1** | 30% (Core modules) | $(if (( $(echo "$COVERAGE >= 30" | bc -l) )); then echo "✅ Met"; else echo "🔄 In Progress"; fi) |
| **Week 2** | 50% (+ Integration) | $(if (( $(echo "$COVERAGE >= 50" | bc -l) )); then echo "✅ Met"; else echo "⏳ Planned"; fi) |
| **Week 3** | 80% (Comprehensive) | $(if (( $(echo "$COVERAGE >= 80" | bc -l) )); then echo "✅ Met"; else echo "⏳ Planned"; fi) |

## Next Steps

1. ✅ Create test framework structure
2. ✅ Implement integration tests for core modules
3. 🔄 Add module-specific unit tests
4. ⏳ Integrate tests into CI/CD
5. ⏳ Achieve 80% coverage goal

## Contributing

When adding new modules:

1. Create corresponding test in \`tests/\`
2. Run this script to update coverage
3. Ensure coverage doesn't decrease
4. Add tests to CI/CD pipeline

---

**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')
**Maintainer**: kernelcore
EOF

echo "✅ Coverage report generated: coverage-report.md"
echo ""
echo "Summary:"
echo "  Total Modules: $TOTAL_MODULES"
echo "  Total Tests:   $TOTAL_TESTS"
echo "  Coverage:      ${COVERAGE}%"
