# Electron Tuning Migration Plan

## Problem Analysis

### Identified Conflicts

1. **ELECTRON_OZONE_PLATFORM_HINT** defined in:
   - `modules/applications/electron-tuning.nix:66`
   - `modules/desktop/hyprland.nix:164`
   - **Conflict**: Duplicate definition

2. **--ozone-platform-hint** passed as flag in:
   - `modules/applications/electron-tuning.nix:62` via `wrapProgram --add-flags`
   - **Issue**: This method generates warnings - Chromium doesn't recognize these as command-line argv

3. **--enable-features** defined in:
   - `modules/applications/electron-tuning.nix:63` (WaylandWindowDecorations,VaapiVideoDecodeLinuxGL)
   - `hosts/kernelcore/home/electron-config.nix:12` (VaapiVideoDecodeLinuxGL,VaapiVideoEncoder)
   - **Conflict**: Different values, both applied

4. **--disable-features** duplicated in:
   - `modules/applications/electron-tuning.nix:64`
   - `hosts/kernelcore/home/electron-config.nix:13`

5. **electron-flags.conf** (line 10):
   - **Issue**: Most Electron apps don't read this file - they use argv.json instead

### Root Causes

1. **Generic tuning**: One config affects ALL Electron apps (Antigravity, VSCode, Brave, etc.)
2. **Wrong delivery method**: Using `wrapProgram --add-flags` instead of argv.json
3. **Scope confusion**: Mixing Wayland platform detection with performance tuning
4. **Ownership unclear**: System-wide (modules) + user-level (home-manager) both modifying same apps

## Solution Architecture

### New System: Per-App Tuning Profiles

```
modules/applications/
├── electron-tuning-v2.nix         # NEW: Profile definitions + options
└── electron-tuning.nix            # OLD: TO BE DEPRECATED

hosts/kernelcore/home/
├── electron-apps.nix              # NEW: Per-app argv.json configs
└── electron-config.nix            # OLD: TO BE REMOVED

modules/desktop/
└── hyprland.nix                   # KEEP: Only Wayland platform vars
```

### Separation of Concerns

| Responsibility | Module | Method |
|----------------|--------|--------|
| Wayland platform detection | `hyprland.nix` | Environment variables ONLY |
| Performance tuning | `electron-apps.nix` | Per-app argv.json |
| App isolation | Per-app configs | Individual argv.json per app |

### Correct Flag Delivery Methods

| Method | Use Case | Example |
|--------|----------|---------|
| Environment variables | Platform detection | `ELECTRON_OZONE_PLATFORM_HINT=auto` |
| argv.json | Performance tuning | `{"renderer-process-limit": 4}` |
| ~~wrapProgram --add-flags~~ | ❌ DON'T USE | Generates warnings |

## Migration Steps

### Phase 1: Create New System (✅ Done)

- [x] Create `electron-tuning-v2.nix` with profile system
- [x] Create `electron-apps.nix` with per-app configs
- [x] Document migration plan

### Phase 2: Clean Old Configs

```bash
# Disable old modules
# modules/applications/electron-tuning.nix -> rename to .bak
# hosts/kernelcore/home/electron-config.nix -> rename to .bak
```

### Phase 3: Update Imports

```nix
# modules/applications/default.nix
imports = [
  # ./electron-tuning.nix  # OLD - commented out
  ./electron-tuning-v2.nix  # NEW
];

# hosts/kernelcore/home/home.nix
imports = [
  # ./electron-config.nix  # OLD - commented out
  ./electron-apps.nix       # NEW
];
```

### Phase 4: Remove Antigravity Overlay

```nix
# modules/applications/electron-tuning.nix lines 53-84
# DELETE: nixpkgs.overlays for antigravity/brave
# Reason: Flags now delivered via argv.json, not wrapProgram
```

### Phase 5: Hyprland - Keep Only Platform Vars

```nix
# modules/desktop/hyprland.nix
# KEEP ONLY:
environment.sessionVariables = {
  ELECTRON_OZONE_PLATFORM_HINT = "auto";  # Platform detection
  NIXOS_OZONE_WL = "1";                   # Wayland enablement
};

# REMOVE: All --enable-features, --disable-features (moved to argv.json)
```

## Testing Plan

### Test 1: Antigravity Warnings
```bash
# Before: Warnings about unknown flags
antigravity

# After: Clean startup, no warnings
antigravity
```

### Test 2: GPU Acceleration
```bash
# Verify GPU is used
antigravity
# In DevTools: chrome://gpu
# Expected: Hardware acceleration enabled
```

### Test 3: Wayland Native
```bash
# Verify Wayland backend
echo $ELECTRON_OZONE_PLATFORM_HINT  # Should be "auto"
antigravity
# In DevTools: check window.navigator.platform
```

## Rollback Plan

If issues occur:
```bash
# Restore old configs
mv electron-tuning.nix.bak electron-tuning.nix
mv electron-config.nix.bak electron-config.nix

# Rebuild
sudo nixos-rebuild switch
```

## Benefits

1. ✅ **No conflicts**: Each app has isolated configuration
2. ✅ **No warnings**: Correct flag delivery method (argv.json)
3. ✅ **Clear ownership**: System handles platform, user handles tuning
4. ✅ **Maintainable**: Easy to add new apps or modify existing ones
5. ✅ **Documented**: Clear separation of concerns

## Future Enhancements

1. Add more apps: Discord, Slack, Teams, etc.
2. Create tuning profiles: gaming, work, low-power
3. Auto-detect app and apply profile
4. Integration with home-manager options
