#!/usr/bin/env bash
# foundation-inspector.sh - Deep system environment audit

set -euo pipefail

OUTPUT_DIR="/tmp/foundation-audit-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "🔬 Foundation Inspector - Deep System Audit"
echo "Output: $OUTPUT_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════
# LAYER 1: Shell Environment Consistency
# ═══════════════════════════════════════════════════════════════

echo "📊 Layer 1: Shell Environment Comparison"

# Capture bash environment
bash -c 'declare -p' >"$OUTPUT_DIR/env-bash.txt"
bash --login -c 'declare -p' >"$OUTPUT_DIR/env-bash-login.txt"

# Capture zsh environment
zsh -c 'declare -p' >"$OUTPUT_DIR/env-zsh.txt"
zsh --login -c 'declare -p' >"$OUTPUT_DIR/env-zsh-login.txt"

# Compare PATH specifically
echo "PATH differences between shells:" | tee "$OUTPUT_DIR/path-comparison.txt"
echo "" | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "=== BASH PATH ===" | tee -a "$OUTPUT_DIR/path-comparison.txt"
bash -c 'echo $PATH | tr ":" "\n"' | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "" | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "=== ZSH PATH ===" | tee -a "$OUTPUT_DIR/path-comparison.txt"
zsh -c 'echo $PATH | tr ":" "\n"' | tee -a "$OUTPUT_DIR/path-comparison.txt"

# LD_LIBRARY_PATH comparison
echo "" | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "=== BASH LD_LIBRARY_PATH ===" | tee -a "$OUTPUT_DIR/path-comparison.txt"
bash -c 'echo ${LD_LIBRARY_PATH:-EMPTY} | tr ":" "\n"' | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "" | tee -a "$OUTPUT_DIR/path-comparison.txt"
echo "=== ZSH LD_LIBRARY_PATH ===" | tee -a "$OUTPUT_DIR/path-comparison.txt"
zsh -c 'echo ${LD_LIBRARY_PATH:-EMPTY} | tr ":" "\n"' | tee -a "$OUTPUT_DIR/path-comparison.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 2: Symlink Health Check
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 2: Symlink Integrity"

# Check critical symlinks
echo "Critical symlink status:" >"$OUTPUT_DIR/symlinks.txt"

check_symlink() {
  local path=$1
  if [ -L "$path" ]; then
    local target=$(readlink -f "$path")
    if [ -e "$target" ]; then
      echo "✓ $path -> $target (valid)" >>"$OUTPUT_DIR/symlinks.txt"
    else
      echo "✗ $path -> $target (BROKEN!)" >>"$OUTPUT_DIR/symlinks.txt"
    fi
  elif [ -e "$path" ]; then
    echo "○ $path (not a symlink)" >>"$OUTPUT_DIR/symlinks.txt"
  else
    echo "✗ $path (MISSING!)" >>"$OUTPUT_DIR/symlinks.txt"
  fi
}

# Critical system paths
check_symlink /bin/sh
check_symlink /usr/bin/env
check_symlink /run/current-system
check_symlink ~/.nix-profile
check_symlink ~/.config

# Find ALL broken symlinks in home
echo "" >>"$OUTPUT_DIR/symlinks.txt"
echo "Broken symlinks in HOME:" >>"$OUTPUT_DIR/symlinks.txt"
find ~ -maxdepth 3 -type l ! -exec test -e {} \; -print 2>/dev/null >>"$OUTPUT_DIR/symlinks.txt" || true

cat "$OUTPUT_DIR/symlinks.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 3: Dynamic Linker Investigation
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 3: Dynamic Linker Analysis"

# ld.so configuration
echo "=== ld.so search paths ===" >"$OUTPUT_DIR/ld-config.txt"
ldconfig -p | head -20 >>"$OUTPUT_DIR/ld-config.txt"

# Check for LD_LIBRARY_PATH pollution
echo "" >>"$OUTPUT_DIR/ld-config.txt"
echo "=== Current LD_LIBRARY_PATH ===" >>"$OUTPUT_DIR/ld-config.txt"
echo "${LD_LIBRARY_PATH:-EMPTY}" | tr ':' '\n' >>"$OUTPUT_DIR/ld-config.txt"

# Test binary dependency resolution
echo "" >>"$OUTPUT_DIR/ld-config.txt"
echo "=== Sample binary dependencies ===" >>"$OUTPUT_DIR/ld-config.txt"

# Pick a few common binaries to test
for binary in /bin/bash "$(which node 2>/dev/null || echo /usr/bin/env)" "$(which python3 2>/dev/null || echo /usr/bin/env)"; do
  if [ -x "$binary" ]; then
    echo "--- $binary ---" >>"$OUTPUT_DIR/ld-config.txt"
    ldd "$binary" 2>&1 | grep -E "not found|=>" | head -5 >>"$OUTPUT_DIR/ld-config.txt"
  fi
done

cat "$OUTPUT_DIR/ld-config.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 4: Nix Profile Conflicts
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 4: Nix Profile Layering"

echo "Nix profile generations:" >"$OUTPUT_DIR/nix-profiles.txt"
nix-env --list-generations >>"$OUTPUT_DIR/nix-profiles.txt"

echo "" >>"$OUTPUT_DIR/nix-profiles.txt"
echo "Profile symlink chain:" >>"$OUTPUT_DIR/nix-profiles.txt"
ls -la ~/.nix-profile >>"$OUTPUT_DIR/nix-profiles.txt"

echo "" >>"$OUTPUT_DIR/nix-profiles.txt"
echo "System profile:" >>"$OUTPUT_DIR/nix-profiles.txt"
ls -la /run/current-system >>"$OUTPUT_DIR/nix-profiles.txt"

# Check for conflicting packages
echo "" >>"$OUTPUT_DIR/nix-profiles.txt"
echo "Potentially conflicting packages:" >>"$OUTPUT_DIR/nix-profiles.txt"
nix-store --query --references ~/.nix-profile 2>/dev/null | grep -E "node|python|bash|zsh" >>"$OUTPUT_DIR/nix-profiles.txt" || true

cat "$OUTPUT_DIR/nix-profiles.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 5: FHS Environment Leakage
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 5: FHS Environment Leakage"

echo "Checking for FHS-specific paths in current environment:" >"$OUTPUT_DIR/fhs-leakage.txt"

# Common FHS paths that shouldn't be in pure Nix
fhs_paths=(
  "/usr/local/lib"
  "/usr/lib"
  "/lib"
  "/opt"
  "/usr/local/bin"
  "/usr/bin"
)

for fhs_path in "${fhs_paths[@]}"; do
  if echo "$PATH" | grep -q "$fhs_path"; then
    echo "⚠️  PATH contains FHS: $fhs_path" >>"$OUTPUT_DIR/fhs-leakage.txt"
  fi
  if echo "${LD_LIBRARY_PATH:-}" | grep -q "$fhs_path"; then
    echo "⚠️  LD_LIBRARY_PATH contains FHS: $fhs_path" >>"$OUTPUT_DIR/fhs-leakage.txt"
  fi
done

# Check for /usr/bin/env abuse
echo "" >>"$OUTPUT_DIR/fhs-leakage.txt"
echo "Scripts using /usr/bin/env (should use /nix/store):" >>"$OUTPUT_DIR/fhs-leakage.txt"
find ~/.local/bin ~/bin -type f -exec grep -l "^#!/usr/bin/env" {} \; 2>/dev/null | head -10 >>"$OUTPUT_DIR/fhs-leakage.txt" || true

cat "$OUTPUT_DIR/fhs-leakage.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 6: Build Environment Test
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 6: Build Environment Sanity"

# Test if nix-shell gives consistent environment
echo "Testing nix-shell environment purity:" >"$OUTPUT_DIR/build-env.txt"

# Pure shell test
nix-shell --pure -p hello --run 'echo $PATH' >"$OUTPUT_DIR/build-env-pure.txt" 2>&1

# Impure shell test
nix-shell -p hello --run 'echo $PATH' >"$OUTPUT_DIR/build-env-impure.txt" 2>&1

echo "Pure vs Impure nix-shell PATH:" >>"$OUTPUT_DIR/build-env.txt"
diff -u "$OUTPUT_DIR/build-env-pure.txt" "$OUTPUT_DIR/build-env-impure.txt" >>"$OUTPUT_DIR/build-env.txt" || true

cat "$OUTPUT_DIR/build-env.txt"

# ═══════════════════════════════════════════════════════════════
# LAYER 7: Shell RC Files Audit
# ═══════════════════════════════════════════════════════════════

echo ""
echo "📊 Layer 7: Shell RC Files"

echo "Shell initialization files:" >"$OUTPUT_DIR/shell-rc.txt"

rc_files=(
  ~/.bashrc
  ~/.bash_profile
  ~/.profile
  ~/.zshrc
  ~/.zprofile
  ~/.zshenv
)

for rc in "${rc_files[@]}"; do
  if [ -f "$rc" ]; then
    echo "=== $rc ===" >>"$OUTPUT_DIR/shell-rc.txt"
    grep -E "PATH|LD_LIBRARY_PATH|export|source" "$rc" | head -20 >>"$OUTPUT_DIR/shell-rc.txt"
    echo "" >>"$OUTPUT_DIR/shell-rc.txt"
  fi
done

cat "$OUTPUT_DIR/shell-rc.txt"

# ═══════════════════════════════════════════════════════════════
# SUMMARY & ANALYSIS
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📋 Foundation Audit Complete"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Results saved to: $OUTPUT_DIR"
echo ""
echo "🎯 Critical Issues to Look For:"
echo ""
echo "1. PATH Inconsistencies:"
echo "   → Different PATH between bash/zsh"
echo "   → FHS paths (/usr/bin) mixed with Nix paths"
echo ""
echo "2. Broken Symlinks:"
echo "   → Any ✗ markers in symlinks.txt"
echo "   → Especially ~/.nix-profile or /run/current-system"
echo ""
echo "3. LD_LIBRARY_PATH Pollution:"
echo "   → Non-empty LD_LIBRARY_PATH in pure builds"
echo "   → FHS paths in library search"
echo ""
echo "4. Shell RC Conflicts:"
echo "   → Manual PATH modifications"
echo "   → Sourcing non-Nix environments"
echo ""
echo "Next steps:"
echo "  1. Review: less $OUTPUT_DIR/summary.txt"
echo "  2. Compare: diff $OUTPUT_DIR/env-{bash,zsh}.txt"
echo "  3. Fix: Based on findings"
echo ""
