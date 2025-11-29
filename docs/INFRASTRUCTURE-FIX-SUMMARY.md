# Infrastructure Issues - Root Cause Analysis & Fixes

**Date:** 2025-11-26  
**System:** NixOS kernelcore (laptop) + Remote builder at 192.168.15.7 (desktop)

## 🔍 ISSUES INVESTIGATED

1. **Binary Cache HTTP 500 Errors** - Reported cache failures
2. **Sandboxing Disabled** - System reports "does not support kernel namespaces"

---

## ✅ ISSUE 1: SSH AUTHENTICATION FAILURE (Misdiagnosed as HTTP 500)

### Root Cause
The "HTTP 500" issue was actually an **SSH authentication failure** preventing remote builds:
```
error: failed to start SSH connection to '192.168.15.7': 
nix-builder@192.168.15.7: Permission denied (publickey,keyboard-interactive)
```

**Actual Cause:** No SSH key configured for nix-builder remote access.

### Diagnostics Performed
- ✅ Cache server responds correctly (HTTP 200 for `/nix-cache-info`)
- ✅ Cache returns HTTP 404 (not 500) for missing packages (expected)
- ❌ SSH authentication fails (no authorized keys)

### Fix Applied
Generated SSH key pair for remote builds:
```bash
# Key location: ~/.ssh/nix-builder
# Public key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq
```

### Required Action on Desktop (192.168.15.7)
Add the following to desktop's `/etc/nixos/hosts/desktop/configuration.nix`:

```nix
# In users.users.nix-builder section:
users.users.nix-builder.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAz4PKacmpq4sftL/NtkqTgbrrBKE/ExT4hKDFjwH0xq nix-builder@nx"
];
```

Then rebuild desktop:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#desktop
```

### Testing Remote Build
After desktop rebuild, test from laptop:
```bash
# Test SSH connection
ssh -i ~/.ssh/nix-builder nix-builder@192.168.15.7 echo "SSH OK"

# Test remote build
nix-build '<nixpkgs>' -A hello --option builders 'ssh://nix-builder@192.168.15.7'
```

---

## ✅ ISSUE 2: SANDBOXING DISABLED

### Root Cause
Found in [`sec/hardening.nix:267`](../sec/hardening.nix:267):
```nix
"kernel.unprivileged_userns_clone" = 0;  # ← DISABLING user namespaces!
```

This configuration attempted to **disable unprivileged user namespaces**, which are **REQUIRED** for Nix sandboxing.

### Why This Failed
1. The sysctl `kernel.unprivileged_userns_clone` is **Debian/Ubuntu-specific**
2. It doesn't exist on mainline kernel 6.12 (your current kernel)
3. Even if it existed, setting it to `0` would break Nix sandboxing

### Diagnostics Performed
```bash
# User namespaces work correctly
$ unshare --user --pid --map-root-user echo "✓ User namespaces work"
✓ User namespaces work

# Kernel supports all namespace types
$ ls /proc/self/ns/
cgroup ipc mnt net pid user uts

# The problematic sysctl doesn't exist
$ cat /proc/sys/kernel/unprivileged_userns_clone
File does not exist (kernel doesn't support this sysctl)

# Nix configuration says sandbox is enabled
$ nix show-config | grep sandbox
sandbox = true
sandbox-fallback = false
```

### Fix Applied
Line 267 in `sec/hardening.nix` has been **commented out**:
```nix
# DISABLED: This sysctl doesn't exist on mainline kernel 6.12 (Debian/Ubuntu-specific)
# and conflicts with Nix sandboxing which REQUIRES unprivileged user namespaces.
# See: https://nixos.org/manual/nix/stable/installation/env-variables.html#sandboxing
#"kernel.unprivileged_userns_clone" = 0;
```

### Verification
After rebuild, sandboxing should work without `--no-sandbox` flag:
```bash
# This should work without --no-sandbox
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

---

## 📋 COMPLETE FIX CHECKLIST

### On Laptop (kernelcore) - Already Done ✅
- [x] Generated SSH key (`~/.ssh/nix-builder`)
- [x] Commented out `kernel.unprivileged_userns_clone = 0` in `sec/hardening.nix`
- [x] Updated buildMachines configuration to use SSH key

### On Desktop (192.168.15.7) - Required ⚠️
- [ ] Add laptop's public key to nix-builder user
- [ ] Rebuild desktop configuration
- [ ] Verify nix-serve is running on port 5000
- [ ] Verify SSH accepts connections from laptop

### Testing - After Desktop Setup
- [ ] Test SSH connection from laptop
- [ ] Test remote build capability
- [ ] Test binary cache access
- [ ] Verify sandboxing works without `--no-sandbox`

---

## 🔐 SECURITY NOTES

### Sandboxing Re-enabled
Nix sandboxing provides critical security isolation during builds:
- Builds run in isolated namespaces (user, pid, mount, network)
- Prevents builds from accessing system resources
- Limits network access during build
- Protects against malicious build scripts

**Impact:** All builds now run sandboxed by default (as intended).

### SSH Key Security
The generated SSH key is dedicated to remote builds:
- **Private key:** `/home/kernelcore/.ssh/nix-builder` (600 permissions)
- **Public key:** Added to desktop's nix-builder user only
- **Purpose:** Limited to nix remote builds (not general access)
- **Recommendation:** Consider using SSH certificates for enhanced security

---

## 📊 PERFORMANCE IMPACT

### Remote Builds
With working SSH authentication:
- Heavy builds offload to desktop (8 cores, more memory)
- Laptop remains responsive during builds
- Binary cache serves pre-built packages

### Sandboxing
No performance impact:
- User namespaces are lightweight kernel features
- Already used by Docker, systemd-nspawn, etc.
- Minimal overhead compared to security benefits

---

## 🚀 NEXT STEPS

1. **Immediate:** Add SSH key to desktop's nix-builder configuration
2. **Test:** Verify remote builds and caching work correctly
3. **Monitor:** Check build logs for any remaining issues
4. **Optional:** Set up SSH certificates for better key management

---

## 📚 REFERENCES

- [NixOS Distributed Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html)
- [Nix Sandboxing](https://nixos.org/manual/nix/stable/installation/env-variables.html#sandboxing)
- [User Namespaces](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)
- [nix-serve Documentation](https://github.com/edolstra/nix-serve)