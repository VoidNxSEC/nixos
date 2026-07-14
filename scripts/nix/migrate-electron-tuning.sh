#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Electron Tuning Migration Script
# ═══════════════════════════════════════════════════════════════
# Migrates from generic electron tuning to per-app configuration
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Electron Tuning Migration to Per-App Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Backup Old Configs
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}[Phase 1]${NC} Backing up old configurations..."

backup_file() {
  local file="$1"
  if [ -f "$file" ] && [ ! -f "$file.bak" ]; then
    cp "$file" "$file.bak"
    echo -e "  ${GREEN}✓${NC} Backed up: $file → $file.bak"
  elif [ -f "$file.bak" ]; then
    echo -e "  ${YELLOW}⚠${NC} Backup already exists: $file.bak"
  else
    echo -e "  ${BLUE}ℹ${NC} File not found (OK if fresh install): $file"
  fi
}

backup_file "/etc/nixos/modules/applications/electron-tuning.nix"
backup_file "/etc/nixos/hosts/kernelcore/home/electron-config.nix"

echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Disable Old Modules
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}[Phase 2]${NC} Disabling old electron-tuning module..."

# Comment out old import in modules/applications/default.nix
if grep -q "^\s*\.\/electron-tuning\.nix" /etc/nixos/modules/applications/default.nix 2>/dev/null; then
  sed -i 's|^\(\s*\)\(./electron-tuning\.nix\)|\1# \2  # MIGRATED: Now using electron-tuning-v2.nix|' \
    /etc/nixos/modules/applications/default.nix
  echo -e "  ${GREEN}✓${NC} Commented out: ./electron-tuning.nix in modules/applications/default.nix"
else
  echo -e "  ${BLUE}ℹ${NC} electron-tuning.nix already disabled or not present"
fi

# Comment out old import in home-manager
if grep -q "^\s*\.\/electron-config\.nix" /etc/nixos/hosts/kernelcore/home/home.nix 2>/dev/null; then
  sed -i 's|^\(\s*\)\(./electron-config\.nix\)|\1# \2  # MIGRATED: Now using electron-apps.nix|' \
    /etc/nixos/hosts/kernelcore/home/home.nix
  echo -e "  ${GREEN}✓${NC} Commented out: ./electron-config.nix in home.nix"
else
  echo -e "  ${BLUE}ℹ${NC} electron-config.nix already disabled or not present"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Enable New Modules
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}[Phase 3]${NC} Enabling new per-app configuration..."

# Add new import to modules/applications/default.nix if not present
if ! grep -q "electron-tuning-v2\.nix" /etc/nixos/modules/applications/default.nix 2>/dev/null; then
  # Find the imports block and add new module
  sed -i '/imports = \[/a\    ./electron-tuning-v2.nix  # Per-app Electron tuning' \
    /etc/nixos/modules/applications/default.nix
  echo -e "  ${GREEN}✓${NC} Added: ./electron-tuning-v2.nix to modules/applications/default.nix"
else
  echo -e "  ${BLUE}ℹ${NC} electron-tuning-v2.nix already enabled"
fi

# Add new import to home-manager if not present
if ! grep -q "electron-apps\.nix" /etc/nixos/hosts/kernelcore/home/home.nix 2>/dev/null; then
  sed -i '/imports = \[/a\    ./electron-apps.nix  # Per-app Electron configuration' \
    /etc/nixos/hosts/kernelcore/home/home.nix
  echo -e "  ${GREEN}✓${NC} Added: ./electron-apps.nix to home.nix"
else
  echo -e "  ${BLUE}ℹ${NC} electron-apps.nix already enabled"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Clean Hyprland Overrides
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}[Phase 4]${NC} Reviewing hyprland.nix (manual step)..."
echo -e "  ${YELLOW}⚠${NC} Review /etc/nixos/modules/desktop/hyprland.nix"
echo -e "  ${YELLOW}⚠${NC} Keep ONLY: ELECTRON_OZONE_PLATFORM_HINT and NIXOS_OZONE_WL"
echo -e "  ${YELLOW}⚠${NC} Remove: Any --enable-features or --disable-features"
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Migration Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Review changes: ${BLUE}git diff${NC}"
echo -e "  2. Rebuild system: ${BLUE}sudo nixos-rebuild switch${NC}"
echo -e "  3. Test Antigravity: ${BLUE}antigravity${NC} (should have no warnings)"
echo -e "  4. Check GPU: Open DevTools → ${BLUE}chrome://gpu${NC}"
echo ""
echo -e "Rollback (if needed):"
echo -e "  ${BLUE}mv electron-tuning.nix.bak electron-tuning.nix${NC}"
echo -e "  ${BLUE}mv electron-config.nix.bak electron-config.nix${NC}"
echo -e "  Then rebuild"
echo ""
echo -e "Documentation: ${BLUE}/etc/nixos/modules/applications/ELECTRON-MIGRATION-PLAN.md${NC}"
echo ""
