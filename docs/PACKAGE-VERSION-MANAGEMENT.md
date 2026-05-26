# Package Version Management Guide

**Created:** 2026-01-25
**Status:** Active
**Priority:** CRITICAL

---

## Problem Identified

System has **472 packages with multiple versions**, causing:

### Critical Duplicates

| Package | Versions | Impact |
|---------|----------|--------|
| **python3** | **19** | ⚠️ CRITICAL - Massive Python duplication |
| **gcc** | **13** | Compiler version chaos |
| util-linux | 12 | System utility conflicts |
| nix | 9 | Nix toolchain fragmentation |
| libxml2 | 8 | Library version conflicts |
| curl | 8 | Network library duplication |
| ffmpeg | 7 | Media codec conflicts |
| dbus | 7 | IPC version mismatches |

### Impact

- **Disk waste:** ~15-20 GB from duplicates
- **Rebuild time:** +20-30% slower
- **Cache misses:** Different versions can't use same cache
- **Runtime conflicts:** Library version mismatches

---

## Root Causes

### 1. No Centralized Version Pinning

**Problem:** Each flake input uses its own nixpkgs commit

```nix
# Current (BAD)
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  hyprland.url = "github:hyprwm/Hyprland";  # Uses its own nixpkgs!
  home-manager.url = "github:nix-community/home-manager";  # Different nixpkgs!
};
```

**Result:** Each input brings its own Python, gcc, etc.

### 2. Overlays Create Custom Derivations

**Files:**
- `chromium-log-suppression.nix` (lines 106-138) - Custom chromium/brave/vscodium
- `electron-tuning.nix` (lines 61-91) - Custom brave (again!)

**Problem:** `overrideAttrs` changes derivation hash → different version

### 3. No Python Version Enforcement

**Problem:** Packages freely choose python312, python313, python311

**Result:** 19 different Python interpreters in system

---

## Solutions Implemented

### 1. Automated Scripts

#### `analyze-package-versions.sh`

**Location:** `/etc/nixos/scripts/analyze-package-versions.sh`

**Usage:**
```bash
/etc/nixos/scripts/analyze-package-versions.sh [output-dir]
```

**Output:**
- `duplicate-counts.txt` - Packages with multiple versions (counts)
- `version-conflicts.txt` - Detailed version listings
- `critical-duplicates.txt` - High-priority issues
- `dependency-analysis.sh` - Tool to investigate specific packages
- `STANDARDIZATION-PLAN.md` - Step-by-step fix guide

**Example:**
```bash
# Run analysis
/etc/nixos/scripts/analyze-package-versions.sh

# Check critical issues
cat /tmp/nix-version-analysis/critical-duplicates.txt

# Investigate Python specifically
/tmp/nix-version-analysis/dependency-analysis.sh python3
```

#### `fix-version-duplicates.sh`

**Location:** `/etc/nixos/scripts/fix-version-duplicates.sh`

**Usage:**
```bash
/etc/nixos/scripts/fix-version-duplicates.sh
```

**Actions:**
1. Analyzes flake.nix for input pinning issues
2. Creates `/etc/nixos/overlays/version-pinning.nix`
3. Generates action plan at `/tmp/VERSION-FIX-PLAN.md`

### 2. Version Pinning Overlay

**File:** `/etc/nixos/overlays/version-pinning.nix`

**Enforces:**
- **Python:** Single version (python312)
- **GCC:** Single version (gcc13)
- **CUDA:** Single version (cudaPackages_12_8)
- **Electron:** Single version (electron_38)
- **FFmpeg:** Single version (ffmpeg-full)

**Example:**
```nix
final: prev: {
  python3 = prev.python312;  # Standardize on Python 3.12
  python = prev.python312;

  gcc = prev.gcc13;          # Standardize on GCC 13

  cudaPackages = prev.cudaPackages_12_8;  # CUDA 12.8
  electron = prev.electron_38;            # Electron 38
  ffmpeg = prev.ffmpeg-full;              # Full-featured FFmpeg
}
```

---

## Implementation Guide

### Phase 1: Analysis (5 minutes)

```bash
# 1. Run version analysis
/etc/nixos/scripts/analyze-package-versions.sh

# 2. Review critical duplicates
cat /tmp/nix-version-analysis/critical-duplicates.txt

# 3. Check disk waste
du -sh /nix/store
```

### Phase 2: Apply Fixes (15-30 minutes)

```bash
# 1. Generate fix configuration
/etc/nixos/scripts/fix-version-duplicates.sh

# 2. Follow action plan
cat /tmp/VERSION-FIX-PLAN.md

# 3. Import overlay in configuration.nix
# Add: nixpkgs.overlays = [ (import ../../overlays/version-pinning.nix) ];

# 4. Update flake.lock
nix flake update --commit-lock-file

# 5. Check syntax
nix flake check

# 6. Rebuild
sudo nixos-rebuild switch
```

### Phase 3: Verification (5 minutes)

```bash
# 1. Re-run analysis
/etc/nixos/scripts/analyze-package-versions.sh /tmp/nix-version-analysis-after

# 2. Compare before/after
echo "=== BEFORE ==="
head -10 /tmp/nix-version-analysis/duplicate-counts.txt

echo "=== AFTER ==="
head -10 /tmp/nix-version-analysis-after/duplicate-counts.txt

# 3. Count Python versions (should be 1-2, down from 19)
nix-store --query --requisites /run/current-system | \
  grep -E '/python3\.[0-9]+-' | \
  sed 's/-[0-9].*//' | \
  sort -u | \
  wc -l

# 4. Check disk savings
du -sh /nix/store
nix-collect-garbage -d  # Clean old versions
```

---

## Manual Steps Required

### Step 1: Import Overlay

**File:** `/etc/nixos/hosts/kernelcore/configuration.nix`

**Add:**
```nix
{
  # ... existing config

  nixpkgs.overlays = [
    (import ../../overlays/version-pinning.nix)
  ];
}
```

### Step 2: Fix flake.nix Inputs

**File:** `/etc/nixos/flake.nix`

**Ensure ALL inputs follow nixpkgs:**
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";  # ← CRITICAL

    hyprland.url = "git+https://github.com/hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";      # ← CRITICAL

    # ... repeat for ALL inputs
  };
}
```

### Step 3: Remove Conflicting Overlays

**Already planned in rebuild optimization** - these will be removed in Phase 2

---

## Expected Results

### Before Fixes

```
Total packages: 4008
Duplicate packages: 472
Python versions: 19
GCC versions: 13
Disk waste: ~15-20 GB
```

### After Fixes

```
Total packages: 4008
Duplicate packages: 50-100 (-80%)
Python versions: 1-2 (-90%)
GCC versions: 1-2 (-90%)
Disk savings: ~10-15 GB
```

### Performance Impact

- **Rebuild time:** Additional 10-20% faster
- **Cache hit rate:** +30-40%
- **Disk usage:** -10-15 GB
- **System consistency:** Much improved

---

## Maintenance Workflow

### Weekly

```bash
# Check for new duplicates
/etc/nixos/scripts/analyze-package-versions.sh

# Review critical-duplicates.txt
cat /tmp/nix-version-analysis/critical-duplicates.txt
```

### After Adding New Packages

```bash
# Before rebuild
/etc/nixos/scripts/analyze-package-versions.sh /tmp/analysis-before

# After rebuild
sudo nixos-rebuild switch

# Check for new duplicates
/etc/nixos/scripts/analyze-package-versions.sh /tmp/analysis-after

# Compare
diff /tmp/analysis-before/duplicate-counts.txt \
     /tmp/analysis-after/duplicate-counts.txt
```

### Monthly

```bash
# Update flake.lock (refresh package versions)
nix flake update --commit-lock-file

# Rebuild
sudo nixos-rebuild switch

# Clean old versions
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

---

## Troubleshooting

### Issue: "Package X has conflicting versions"

**Solution:**
```bash
# Investigate what's pulling different versions
/tmp/nix-version-analysis/dependency-analysis.sh <package-name>

# Add explicit version pin to overlays/version-pinning.nix
# Example:
# packageX = prev.packageX_version_Y;
```

### Issue: "Build fails after applying overlay"

**Solution:**
```bash
# Rollback
sudo nixos-rebuild switch --rollback

# Check which package is conflicting
nix flake check --show-trace

# Adjust overlay or remove conflicting package
```

### Issue: "Python package not found after pinning"

**Solution:**
```bash
# Check if package exists in python312
nix search nixpkgs python312Packages.<package>

# If not, temporarily allow specific Python version
# In configuration.nix:
environment.systemPackages = [
  (pkgs.python313.withPackages (ps: [ ps.specific-package ]))
];
```

---

## Related Documentation

- [REMOTE-BUILD-SETUP.md](REMOTE-BUILD-SETUP.md) - Build server configuration
- [Binary cache optimization plan](../plans/) - Rebuild performance fixes
- [NixOS manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)

---

## Files Created

| File | Purpose |
|------|---------|
| `/etc/nixos/scripts/analyze-package-versions.sh` | Detect version duplicates |
| `/etc/nixos/scripts/fix-version-duplicates.sh` | Generate fix configuration |
| `/etc/nixos/overlays/version-pinning.nix` | Centralized version enforcement |
| `/etc/nixos/docs/PACKAGE-VERSION-MANAGEMENT.md` | This guide |

---

**Status:** Ready for implementation
**Next:** Run scripts and follow implementation guide above
