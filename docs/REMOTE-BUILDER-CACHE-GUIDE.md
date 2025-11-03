# Remote Builder & Binary Cache Configuration Guide

> **Created**: 2025-11-03
> **Purpose**: Complete guide for managing remote builds and binary cache with optional desktop server

---

## Table of Contents

1. [Problem Summary](#problem-summary)
2. [Architecture Overview](#architecture-overview)
3. [Quick Fix Commands](#quick-fix-commands)
4. [Configuration Modules](#configuration-modules)
5. [Enabling Remote Builds](#enabling-remote-builds)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Problem Summary

### What Happened (2025-11-03)

**Symptoms**:
- `nixos-rebuild` failed with "Failed to find a machine for remote build"
- Binary cache at `192.168.15.6:5000` returning HTTP 500 errors
- Builds stuck retrying failed cache requests
- System configured with `max-jobs = 0` (no local builds)

**Root Cause**:
- `laptop-offload-client.nix` was imported unconditionally in `flake.nix`
- Module forced remote builds to desktop server (192.168.15.6)
- Desktop was offline/unreachable
- No fallback to local builds enabled

**Solution**:
- Commented out `laptop-offload-client.nix` import in flake.nix
- Enhanced `binary-cache.nix` with non-blocking timeouts
- Used rebuild flags to override configuration temporarily

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    NixOS Build System                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐         ┌──────────────┐                   │
│  │ Local Builds│◄────────┤  max-jobs    │                   │
│  │ (This Host) │         │  Setting     │                   │
│  └─────────────┘         └──────────────┘                   │
│         │                                                     │
│         │ Fallback                                           │
│         ▼                                                     │
│  ┌─────────────┐         ┌──────────────┐                   │
│  │Remote Builder│◄────────┤   builders   │                   │
│  │ 192.168.15.6│         │   Setting    │                   │
│  └─────────────┘         └──────────────┘                   │
│                                                               │
│  ┌─────────────────────────────────────┐                    │
│  │       Binary Cache Priority         │                    │
│  ├─────────────────────────────────────┤                    │
│  │ 1. http://192.168.15.6:5000  (LAN) │◄─ Fastest          │
│  │ 2. https://cache.nixos.org   (CDN) │◄─ Fallback         │
│  └─────────────────────────────────────┘                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Key Settings

| Setting | Default | With Offload | Impact |
|---------|---------|--------------|--------|
| `max-jobs` | `auto` | `0` | Local build capacity |
| `builders` | `[]` | `ssh://...` | Remote build servers |
| `substituters` | `[cache.nixos.org]` | `[LAN, cache.nixos.org]` | Cache priority |
| `connect-timeout` | `5` | `2` | Faster failure detection |
| `fallback` | `false` | `true` | Allow local on remote fail |

---

## Quick Fix Commands

### Emergency Rebuild (When Desktop Offline)

```bash
# Option 1: Override all offload settings (RECOMMENDED)
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Option 2: Fast rebuild (skips some checks)
sudo nixos-rebuild switch --fast

# Option 3: Full override with cache optimization
sudo nixos-rebuild switch \
  --option max-jobs auto \
  --option builders "" \
  --option connect-timeout 1 \
  --option http-connections 25
```

### Check Current Configuration

```bash
# View active build settings
nix show-config | grep -E "^max-jobs|^builders|^substituters"

# Test cache connectivity
cache-status  # Available after rebuild with enhanced binary-cache.nix

# Test local build capability
nix-build '<nixpkgs>' -A hello --no-out-link
```

### Verify Remote Builder Connectivity

```bash
# Check SSH access to builder
ssh nix-builder@192.168.15.6 'echo "Builder reachable"'

# Check binary cache
curl -sf http://192.168.15.6:5000/nix-cache-info

# Full diagnostic (if offload-server enabled on desktop)
offload-status  # Only available if laptop-offload-client.nix imported
```

---

## Configuration Modules

### Module 1: `binary-cache.nix`

**Location**: `/etc/nixos/modules/system/binary-cache.nix`

**Purpose**: Configure binary cache servers with non-blocking failures

**Options**:
```nix
kernelcore.system.binary-cache = {
  enable = true;

  local = {
    enable = true;
    url = "http://192.168.15.6:5000";
    priority = 40;  # Lower = higher priority
    requireConnectivity = false;  # Don't block if unreachable
  };

  remote = {
    enable = true;
    substituers = [
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trustedPublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
};
```

**Features**:
- `connect-timeout = 2` - Fail fast on unreachable caches
- `http-connections = 25` - Limit parallel connections
- `fallback = true` - Always allow next cache
- `narinfo-cache-negative-ttl = 3600` - Cache negative lookups
- Diagnostic command: `cache-status`

**Enable in**: `configuration.nix` or `flake.nix`

---

### Module 2: `laptop-offload-client.nix`

**Location**: `/etc/nixos/modules/services/laptop-offload-client.nix`

**Purpose**: Template for configuring laptop as remote build client (UNCONDITIONAL)

**⚠️ WARNING**: This module applies settings **without** an enable option!

**Import**: Only import in `flake.nix` when you want offload **always active**

**Settings Applied**:
- `builders = ["ssh://nix-builder@192.168.15.6 ..."]`
- `substituters = ["http://192.168.15.6:5000", "https://cache.nixos.org"]`
- `max-jobs = 4` (allows local fallback)
- NFS mounts for `/nix/store-remote`

**To Use**:
```nix
# In flake.nix (uncomment when desktop is stable/always-on)
./modules/services/laptop-offload-client.nix
```

**Utilities Provided**:
- `offload-status` - Check connectivity
- `offload-test-build` - Test remote build
- `offload-mount` / `offload-unmount` - Manage NFS mounts
- `offload-setup` - Initial setup wizard

---

### Module 3: `laptop-builder-client.nix`

**Location**: `/etc/nixos/modules/services/laptop-builder-client.nix`

**Purpose**: Optional remote builder with enable flag (RECOMMENDED)

**Options**:
```nix
services.laptop-builder-client = {
  enable = true;  # ← Control when to use remote builds
  desktopIP = "192.168.15.6";
  builderKeyPath = "/etc/nix/builder_key";
  maxJobs = 4;  # Local build capacity (0 = offload only)
};
```

**Advantages over laptop-offload-client.nix**:
- ✅ Can be toggled via `enable` option
- ✅ Won't break builds when desktop offline
- ✅ Applies settings only when explicitly enabled
- ✅ Same functionality as laptop-offload-client.nix

**To Use**:
```nix
# In flake.nix (import always)
./modules/services/laptop-builder-client.nix

# In configuration.nix (enable when desktop is online)
services.laptop-builder-client.enable = true;
```

---

### Module 4: `offload-server.nix`

**Location**: `/etc/nixos/modules/services/offload-server.nix`

**Purpose**: Configure desktop as build server for laptops

**Options**:
```nix
services.offload-server = {
  enable = true;
  cachePort = 5000;
  builderUser = "nix-builder";
  cacheKeyPath = "/var/cache-priv-key.pem";
  enableNFS = false;  # Optional: share /nix/store via NFS
};
```

**Utilities Provided**:
- `offload-server-status` - Server health check
- `offload-server-test` - Test build capability
- `offload-generate-cache-keys` - Generate signing keys

**Setup on Desktop**:
```bash
# 1. Enable in configuration.nix
services.offload-server.enable = true;

# 2. Rebuild
sudo nixos-rebuild switch

# 3. Generate cache keys
offload-generate-cache-keys

# 4. Check status
offload-server-status
```

---

## Enabling Remote Builds

### Scenario 1: Desktop Always Available (Home Network)

Use `laptop-offload-client.nix` (unconditional):

```nix
# flake.nix
nixosConfigurations.kernelcore = nixpkgs.lib.nixosSystem {
  modules = [
    ./modules/services/laptop-offload-client.nix  # Uncomment
    # ... other modules
  ];
};
```

**Pros**: Simple, no enable flag needed
**Cons**: Breaks builds if desktop goes offline

---

### Scenario 2: Desktop Sometimes Offline (Recommended)

Use `laptop-builder-client.nix` (conditional):

```nix
# flake.nix (always import)
nixosConfigurations.kernelcore = nixpkgs.lib.nixosSystem {
  modules = [
    ./modules/services/laptop-builder-client.nix
    # ... other modules
  ];
};

# configuration.nix (enable only when desktop is online)
services.laptop-builder-client = {
  enable = true;  # Set to false when desktop offline
  desktopIP = "192.168.15.6";
  maxJobs = 4;  # Allow local builds as fallback
};
```

**Pros**: Graceful fallback, won't break rebuilds
**Cons**: Need to toggle enable flag manually

---

### Scenario 3: Multiple Hosts/Environments

Create host-specific configurations:

```nix
# hosts/laptop-home/configuration.nix (desktop available)
services.laptop-builder-client = {
  enable = true;
  desktopIP = "192.168.15.6";
  maxJobs = 2;
};

# hosts/laptop-mobile/configuration.nix (no desktop)
services.laptop-builder-client.enable = false;
```

Switch with:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#laptop-home
sudo nixos-rebuild switch --flake /etc/nixos#laptop-mobile
```

---

## Troubleshooting

### Problem: "Failed to find a machine for remote build"

**Symptoms**:
```
Failed to find a machine for remote build!
derivation: xyz.drv
required (system, features): (x86_64-linux, [])
```

**Diagnosis**:
```bash
nix show-config | grep -E "^max-jobs|^builders"
# If shows: max-jobs = 0, builders = ssh://...
# → Remote build is forced but desktop is unreachable
```

**Solution**:
```bash
# Immediate fix
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Permanent fix
# Comment out laptop-offload-client.nix in flake.nix
# OR disable laptop-builder-client.enable in configuration.nix
```

---

### Problem: Binary Cache HTTP 500 Errors

**Symptoms**:
```
warning: error: unable to download 'http://192.168.15.6:5000/xxx.narinfo': HTTP error 500
Internal Server Error; retrying in 270 ms
```

**Diagnosis**:
```bash
# Test cache directly
curl -v http://192.168.15.6:5000/nix-cache-info

# Check desktop nix-serve
ssh user@192.168.15.6 'systemctl status nix-serve'
```

**Solutions**:

1. **Cache server overwhelmed**:
   ```bash
   # On desktop, restart nix-serve
   sudo systemctl restart nix-serve
   ```

2. **Cache database corrupted**:
   ```bash
   # On desktop, check nix-serve logs
   journalctl -u nix-serve -n 50
   ```

3. **Too many parallel requests**:
   ```nix
   # In binary-cache.nix (already added)
   http-connections = mkDefault 25;  # Limit connections
   connect-timeout = mkDefault 2;     # Fail faster
   ```

4. **Temporarily disable cache**:
   ```bash
   sudo nixos-rebuild switch --option substituters "https://cache.nixos.org"
   ```

---

### Problem: SSH Connection Refused

**Symptoms**:
```
cannot build on 'ssh://nix-builder@192.168.15.6': error: failed to start SSH connection
```

**Diagnosis**:
```bash
# Test SSH
ssh nix-builder@192.168.15.6 'echo OK'

# Check SSH key
ls -la /etc/nix/builder_key

# Check desktop SSH
ssh user@192.168.15.6 'systemctl status sshd'
```

**Solutions**:

1. **Builder key missing**:
   ```bash
   # Copy from desktop
   scp user@192.168.15.6:~/.ssh/id_rsa /etc/nix/builder_key
   sudo chmod 600 /etc/nix/builder_key
   ```

2. **Desktop not trusted**:
   ```bash
   # On desktop, add to configuration.nix
   nix.settings.trusted-users = [ "nix-builder" ];
   sudo nixos-rebuild switch
   ```

3. **Firewall blocking**:
   ```bash
   # On desktop, check firewall
   sudo iptables -L -n | grep 22

   # Allow SSH in configuration.nix
   networking.firewall.allowedTCPPorts = [ 22 ];
   ```

---

### Problem: NFS Mounts Fail

**Symptoms**:
```
mount.nfs: Connection refused
mount.nfs: access denied by server
```

**Diagnosis**:
```bash
# Check if NFS is enabled on desktop
ssh user@192.168.15.6 'systemctl status nfs-server'

# Check exports
ssh user@192.168.15.6 'cat /etc/exports'

# Test from laptop
showmount -e 192.168.15.6
```

**Solutions**:

1. **NFS not enabled on desktop**:
   ```nix
   # On desktop configuration.nix
   services.offload-server.enableNFS = true;
   ```

2. **IP not allowed**:
   ```nix
   # On desktop, check NFS exports in offload-server.nix
   # Default allows 192.168.15.0/24
   ```

3. **Firewall blocking**:
   ```nix
   # On desktop configuration.nix
   networking.firewall.allowedTCPPorts = [ 2049 111 ];
   networking.firewall.allowedUDPPorts = [ 2049 111 ];
   ```

---

## Best Practices

### 1. Always Allow Local Builds

```nix
# Never set max-jobs = 0 unless desktop is guaranteed online
nix.settings.max-jobs = mkDefault 4;  # Or "auto"
```

**Rationale**: Prevents rebuild failures when remote builder is down

---

### 2. Use Conditional Remote Builds

```nix
# Prefer laptop-builder-client.nix over laptop-offload-client.nix
services.laptop-builder-client = {
  enable = true;  # Can toggle
  maxJobs = 4;    # Fallback to local
};
```

**Rationale**: Graceful degradation when desktop offline

---

### 3. Configure Failfast Timeouts

```nix
nix.settings = {
  connect-timeout = 2;          # Don't wait forever
  http-connections = 25;        # Limit parallel requests
  fallback = true;              # Always allow next option
  narinfo-cache-negative-ttl = 3600;  # Cache failures
};
```

**Rationale**: Faster rebuilds, less frustration

---

### 4. Monitor Cache Health

```bash
# Regular health check
cache-status

# Before large rebuilds
nix-build '<nixpkgs>' -A hello --dry-run
```

**Rationale**: Catch issues before critical rebuilds

---

### 5. Keep Builder Keys Secure

```bash
# Proper permissions
sudo chmod 600 /etc/nix/builder_key
sudo chown root:root /etc/nix/builder_key

# Use dedicated key (not your personal SSH key)
ssh-keygen -t ed25519 -f ~/.ssh/nix-builder -C "nix-builder"
```

**Rationale**: Security and key rotation

---

### 6. Document Your Setup

```nix
# In configuration.nix, always comment why
services.laptop-builder-client = {
  enable = true;  # Desktop at 192.168.15.6 always on home network
  maxJobs = 4;    # Laptop has 8 cores, reserve half for local
};
```

**Rationale**: Future you will thank you

---

### 7. Test Before Committing

```bash
# Always run before committing offload changes
nix flake check

# Test rebuild in dry-run
sudo nixos-rebuild dry-build

# Test remote build explicitly
nix-build '<nixpkgs>' -A hello \
  --builders "ssh://nix-builder@192.168.15.6 x86_64-linux /etc/nix/builder_key 2 1"
```

**Rationale**: Catch configuration errors early

---

## Summary of 2025-11-03 Fix

### Changes Made

1. **flake.nix:74** - Commented out `laptop-offload-client.nix`
   ```nix
   # ./modules/services/laptop-offload-client.nix  # DISABLED: Desktop offline
   ```

2. **binary-cache.nix:70-78** - Added non-blocking timeouts
   ```nix
   connect-timeout = mkDefault 2;
   http-connections = mkDefault 25;
   fallback = mkDefault true;
   narinfo-cache-negative-ttl = mkDefault 3600;
   ```

3. **binary-cache.nix:90-136** - Added `cache-status` diagnostic script

### Files Created

- `/etc/nixos/REBUILD-FIX.md` - Emergency rebuild instructions
- `/etc/nixos/docs/REMOTE-BUILDER-CACHE-GUIDE.md` - This guide

### Rebuild Command Used

```bash
sudo nixos-rebuild switch --option max-jobs auto --option builders ""
```

### Outcome

✅ Builds no longer fail when desktop offline
✅ Cache failures non-blocking
✅ Local builds always available
✅ System can rebuild independently

---

## Quick Reference Card

```bash
# Emergency rebuild (desktop offline)
sudo nixos-rebuild switch --option max-jobs auto --option builders ""

# Check configuration
nix show-config | grep -E "^max-jobs|^builders|^substituters"

# Test cache
cache-status  # After enhanced binary-cache.nix

# Test remote build
ssh nix-builder@192.168.15.6 'echo OK'

# Enable remote builds (configuration.nix)
services.laptop-builder-client.enable = true;

# Disable remote builds (configuration.nix)
services.laptop-builder-client.enable = false;

# Test local build
nix-build '<nixpkgs>' -A hello --no-out-link
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-03
**Maintained By**: kernelcore
**Related Docs**:
- `/etc/nixos/REBUILD-FIX.md`
- `/etc/nixos/docs/LAPTOP-BUILD-SETUP.md`
- `/etc/nixos/modules/system/binary-cache.nix`
