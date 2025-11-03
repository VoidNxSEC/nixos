# Emergency Rebuild Fix

## Problem
- `laptop-offload-client.nix` was forcing `max-jobs = 0` and remote builder to desktop
- Desktop (192.168.15.6) is offline, causing all builds to fail
- Binary cache at 192.168.15.6:5000 returns HTTP 500 errors

## Immediate Solution

### Option 1: Use --option flags (RECOMMENDED)
```bash
sudo nixos-rebuild switch --option max-jobs auto --option builders ""
```

### Option 2: Use --fast flag (allows local builds)
```bash
sudo nixos-rebuild switch --fast
```

### Option 3: Build with explicit options
```bash
sudo nixos-rebuild switch \
  --option max-jobs auto \
  --option builders "" \
  --option connect-timeout 1 \
  --option http-connections 25
```

## Changes Made

1. **Commented out `laptop-offload-client.nix`** in flake.nix:72
   - This module was forcing remote builds
   - Will be re-enabled only when desktop is available

2. **Enhanced `binary-cache.nix`**:
   - Added `connect-timeout = 2` (faster failures)
   - Added `http-connections = 25` (limit parallel requests)
   - Added `narinfo-cache-negative-ttl = 3600` (cache negative lookups)
   - Added diagnostic script: `cache-status`

## After Successful Rebuild

The new configuration will have:
- Local builds enabled (max-jobs = auto)
- No remote builder dependency
- Binary cache with non-blocking failures
- Diagnostic command: `cache-status`

## Future: Enable Remote Builds

When desktop is available, uncomment in flake.nix and use the optional module:

```nix
# In configuration.nix
services.laptop-builder-client = {
  enable = true;  # Only enable when desktop is online
  desktopIP = "192.168.15.6";
  maxJobs = 4;  # Allow local builds as fallback
};
```

## Related Files
- `/etc/nixos/flake.nix` - Line 74 (offload-client commented)
- `/etc/nixos/modules/system/binary-cache.nix` - Enhanced with timeouts
- `/etc/nixos/modules/services/laptop-offload-client.nix` - Template module
