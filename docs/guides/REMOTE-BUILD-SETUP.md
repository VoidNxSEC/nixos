# Remote Build Setup Guide

## Problem

NixOS rebuilds on laptop take 60+ minutes due to:
- Heavy packages: chromium, vscodium, brave (30-90 min each)
- CUDA packages rebuilding from source
- Limited CPU/RAM on laptop

## Solution

Use a powerful desktop/server to build packages and serve them via local binary cache.

---

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Laptop (you)   │         │  Build Server    │         │  Local Cache    │
│                 │────────>│  (powerful PC)   │────────>│  192.168.15.7   │
│  nixos-rebuild  │  SSH    │  Builds packages │  Push   │  Port 5000      │
└─────────────────┘         └──────────────────┘         └─────────────────┘
         │                                                         │
         └─────────────────────────────────────────────────────────┘
                         Downloads from cache (fast!)
```

---

## Part 1: Setup Build Server

### Option A: Distributed Builds (SSH)

Laptop delegates builds to remote server automatically.

**On laptop** (`/etc/nixos/modules/system/distributed-builds.nix`):

```nix
{
  nix.buildMachines = [
    {
      hostName = "build-server.local";  # Or IP: 192.168.15.10
      systems = [ "x86_64-linux" "aarch64-linux" ];
      maxJobs = 8;  # Server CPU cores
      speedFactor = 4;  # 4x faster than laptop
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [];
    }
  ];

  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  # SSH key for build access
  programs.ssh.extraConfig = ''
    Host build-server.local
      HostName 192.168.15.10
      User nix-builder
      IdentityFile /home/kernelcore/.ssh/nix-builder-key
  '';
}
```

**On build server** (setup):

```bash
# 1. Create build user
sudo useradd -m -G nixbld nix-builder

# 2. Add laptop's SSH key
sudo -u nix-builder mkdir -p ~nix-builder/.ssh
sudo -u nix-builder sh -c 'cat > ~nix-builder/.ssh/authorized_keys' << EOF
ssh-ed25519 AAAA... kernelcore@nx  # Your laptop's public key
EOF

# 3. Trust laptop user
# /etc/nix/nix.conf
trusted-users = nix-builder
```

### Option B: Manual Build (Simple)

Manually build packages on server and push to cache.

**On build server**:

```bash
# 1. Copy build inventory
scp /etc/nixos/build-inventory.nix build-server:/tmp/

# 2. Build all packages
nix-build /tmp/build-inventory.nix -A heavy

# 3. Push to binary cache (see Part 2)
```

---

## Part 2: Setup Local Binary Cache

### Option 1: nix-serve (Simple HTTP cache)

**On cache server** (192.168.15.7):

```nix
# configuration.nix
services.nix-serve = {
  enable = true;
  secretKeyFile = "/var/keys/cache-priv-key.pem";
  port = 5000;
  openFirewall = true;
};
```

**Generate signing keys**:

```bash
# On cache server
sudo nix-store --generate-binary-cache-key cache.local \
  /var/keys/cache-priv-key.pem \
  /var/keys/cache-pub-key.pem

# Note the public key
cat /var/keys/cache-pub-key.pem
# cache.local:BASE64STRING...
```

### Option 2: attic (Modern, faster)

```nix
services.attic = {
  enable = true;
  serverConfigFile = "/etc/attic/config.toml";
};
```

---

## Part 3: Configure Laptop to Use Cache

**Edit** `/etc/nixos/sec/hardening.nix`:

```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org/"
    "http://192.168.15.7:5000"  # Local cache FIRST
    "https://nix-community.cachix.org"
  ];

  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cache.local:YOUR_PUBLIC_KEY_HERE"  # From Part 2
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  require-sigs = true;
};
```

---

## Part 4: Workflow

### One-time Setup

```bash
# On laptop: Generate SSH key for builds
ssh-keygen -t ed25519 -f ~/.ssh/nix-builder-key -C "nix-builds"

# Copy to build server
ssh-copy-id -i ~/.ssh/nix-builder-key nix-builder@build-server

# Test connection
ssh -i ~/.ssh/nix-builder-key nix-builder@build-server
```

### Regular Use

**Option A: Distributed builds (automatic)**

```bash
# On laptop - builds happen on server automatically
sudo nixos-rebuild switch
# Heavy packages build on server, results downloaded
```

**Option B: Manual pre-build**

```bash
# On build server: Build heavy packages
nix-build /path/to/build-inventory.nix -A heavy

# Push to cache
nix copy --to http://192.168.15.7:5000 $(readlink result)

# On laptop: Rebuild (downloads from cache)
sudo nixos-rebuild switch
# Fast! Everything downloads instead of compiling
```

---

## Part 5: Monitoring & Verification

### Check if builds are delegated

```bash
# On laptop during rebuild
journalctl -f -u nix-daemon
# Look for: "building on build-server.local"
```

### Check cache hits

```bash
# Before rebuild
nix-store --query --requisites /run/current-system | \
  xargs nix path-info --store http://192.168.15.7:5000 2>&1 | \
  grep -c "is not valid"
# Number of packages NOT in cache
```

### Monitor cache server

```bash
# On cache server
journalctl -f -u nix-serve
# Watch requests from laptop
```

---

## Current Package Inventory

Based on your system scan:

| Category | Count | Total Size | Build Time |
|----------|-------|------------|------------|
| **Heavy packages** | ~15 | ~10 GB | 2-3 hours |
| - chromium family | 4 | ~4 GB | 60-120 min |
| - CUDA packages | ~50 | ~2 GB | 30-60 min |
| - Electron apps | 3 | ~2 GB | 30-45 min |
| - Hyprland | 1 | ~500 MB | 15-20 min |
| **System packages** | ~4000 | ~35 GB | Variable |
| **Total** | ~4000 | ~45 GB | - |

### Top 10 Heaviest Packages

1. `python3.12-vllm` - 6.5 GB
2. `obs-studio` - 4.1 GB
3. `chromium` - ~1.5 GB
4. `brave` - ~1.2 GB
5. `vscodium` - ~1.0 GB
6. `cuda-merged-12.8` - ~800 MB
7. `hyprland` - ~500 MB
8. `gnome-shell` - ~400 MB
9. `electron` - ~350 MB
10. `vscode` - ~300 MB

---

## Expected Performance

### Before (local builds only)

- **Rebuild time:** 60-120 minutes
- **CPU:** 100% on laptop
- **Temperature:** 80-95°C
- **Usability:** Laptop unusable during build

### After (distributed builds)

- **Rebuild time:** 5-15 minutes
- **CPU:** <20% on laptop (downloading only)
- **Temperature:** 50-60°C
- **Usability:** Normal usage during rebuild

### After (with full cache)

- **Rebuild time:** 2-5 minutes
- **CPU:** <10% on laptop
- **No compilation:** Pure downloads

---

## Troubleshooting

### Distributed builds not working

```bash
# Check SSH connection
ssh -i ~/.ssh/nix-builder-key nix-builder@build-server

# Check Nix can see builder
nix store ping --store ssh://nix-builder@build-server

# Enable debug logging
sudo nixos-rebuild switch --option builders-use-substitutes true --show-trace
```

### Cache not being used

```bash
# Test cache manually
nix path-info --store http://192.168.15.7:5000 /nix/store/...

# Check signature verification
nix-store --verify --check-contents

# Verify public key is correct
nix show-config | grep trusted-public-keys
```

### Build server out of space

```bash
# On build server: Garbage collect
sudo nix-collect-garbage -d

# Only keep recent builds
sudo nix-collect-garbage --delete-older-than 7d
```

---

## Files Created

1. `/etc/nixos/build-inventory.nix` - Package list for remote builds
2. `/etc/nixos/docs/REMOTE-BUILD-SETUP.md` - This guide
3. `/etc/nixos/modules/system/distributed-builds.nix` - SSH build config (create if using Option A)

---

## Next Steps

1. **Choose setup method:**
   - Distributed builds (Option A): Automatic, more complex
   - Manual builds (Option B): Simple, manual process

2. **Setup binary cache server** (192.168.15.7 or other)

3. **Test with heavy package:**
   ```bash
   nix-build '<nixpkgs>' -A chromium
   ```

4. **Migrate to remote builds**

5. **Monitor first rebuild** and verify packages download from cache

---

## Security Notes

- **SSH keys:** Use dedicated key for builds, not your personal key
- **Cache signing:** ALWAYS sign packages, verify signatures on laptop
- **Network:** Local cache should be on trusted network only
- **Firewall:** Restrict cache port (5000) to local network (192.168.15.0/24)

---

**Generated:** 2026-01-25
**System:** kernelcore@nx
**Current rebuild time:** 60+ minutes
**Target rebuild time:** <10 minutes
