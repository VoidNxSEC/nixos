# Auditd Boot Investigation Instructions

## Current Status
- **Service Status**: ✅ Running (active since boot at 11:47:40)
- **Issues Found**:
  - ⚠️ Kernel queue overflow warnings during boot
  - ⚠️ filter.conf line 2 too long warning
  - ⚠️ Symlink error in audit config

## Investigation Steps

### 1. Check Kernel Audit Messages (Requires Root)
```bash
sudo dmesg | grep -i audit
```
**What to look for**:
- "kauditd hold queue overflow" messages
- "audit: backlog limit" messages
- Any audit initialization errors

### 2. Find and Inspect filter.conf
```bash
# Find the actual filter.conf being used
find /etc/audit /nix/store -name "filter.conf" 2>/dev/null | head -5

# Read the problematic file
cat $(find /nix/store -name "filter.conf" -type f | head -1)
```
**What to look for**:
- Line 2 that's causing "too long" warning
- Check if line exceeds 1024 characters

### 3. Check Audit Rules Loading
```bash
# List currently loaded audit rules
sudo auditctl -l

# Check audit system status
sudo auditctl -s
```
**What to look for**:
- All rules from /etc/nixos/modules/security/audit.nix:30-48 are loaded
- Backlog limit shows 8192 (from kernel parameter)
- Enable flag = 2 (immutable) or 1 (enabled)

### 4. Check Audit Configuration Files
```bash
# Main auditd config
cat /etc/audit/auditd.conf

# Audit rules file
cat /etc/audit/audit.rules

# Check for symlink issues
ls -la /etc/audit/
```
**What to look for**:
- Symlinks pointing to /nix/store locations
- Any broken symlinks
- Configuration mismatches

### 5. Check Boot Timeline
```bash
# When did auditd start relative to other services?
systemctl show auditd -p ExecMainStartTimestamp

# Check what services started before auditd
journalctl -b --no-pager | grep "Started" | grep -B5 "auditd"

# Check audit-related systemd dependencies
systemctl list-dependencies auditd --all
```
**What to look for**:
- Is auditd starting too late?
- Are there missing dependencies causing delayed start?

### 6. Check Queue Overflow Details
```bash
# Full boot logs for audit service
journalctl -u auditd -b --no-pager -o verbose

# Kernel messages from boot (if accessible)
sudo journalctl -k -b | grep -i audit

# Check audit buffer size
cat /proc/sys/kernel/audit_backlog_limit
```
**What to look for**:
- Current backlog limit (should be 8192 from audit.nix:23)
- Whether overflow happened before or after auditd started
- Number of events lost

### 7. Test Audit Rules
```bash
# Generate a test event
sudo touch /etc/passwd

# Check if it was logged
sudo ausearch -k passwd_changes -ts recent

# Check audit log directly
sudo tail -20 /var/log/audit/audit.log
```
**What to look for**:
- Events are being captured correctly
- Rules are working after boot completes

## Known Issues from Logs

### Issue 1: Queue Overflow During Boot
```
audit: kauditd hold queue overflow (3 times)
```
**Current mitigation**: `audit_backlog_limit=8192` in audit.nix:23
**Question**: Is 8192 enough, or do we need more during boot?

### Issue 2: filter.conf Line Too Long
```
auditd[1157]: Skipping line 2 in filter.conf: too long
```
**Investigation needed**: What's on line 2? Is it critical?

### Issue 3: Symlink Error
```
auditd[4517]: Error opening config file (Too many levels of symbolic links)
```
**Question**: What config file? When does this happen (after initial start)?

## Configuration Location
- **Module**: /etc/nixos/modules/security/audit.nix
- **Kernel params**: audit.nix:21-24
- **Rules**: audit.nix:30-48

## Expected Behavior
✅ Auditd should start early in boot via systemd
✅ Kernel audit=1 enables auditing at kernel level
✅ Backlog of 8192 should handle boot-time events
✅ Rules should load automatically

## Root Cause Analysis - 2025-10-21

### **PRIMARY ISSUE IDENTIFIED**: Missing Module Imports in flake.nix

**Problem**: Five security modules were not being imported in `flake.nix`, including the audit module.

**Impact**:
- Auditd configuration from `/etc/nixos/modules/security/audit.nix` was not being applied
- Boot process lacked proper audit initialization
- Verbose boot logs were being skipped/suppressed
- Kernel audit parameters were not being set during boot

**Resolution**: ✅ Module imports have been corrected in flake.nix

**Affected modules** (now properly imported):
1. `/etc/nixos/modules/security/audit.nix` - Main auditd configuration
2. (Plus 4 other modules - to be documented)

### Secondary Finding: Duplicate Auditd Rules

**Location of Duplicates**:
- `/etc/nixos/modules/security/hardening-template.nix:188`
- `/etc/nixos/modules/security/audit.nix:32`

**Duplicate Rule**:
```nix
"-a exit,always -F arch=b64 -S execve"
```

**Status**: ⚠️ Non-critical (template files not imported by flake)
- Files with `-template` suffix are reference examples only
- Not actively used in system configuration
- No action required

### Boot Behavior Before Fix

**Symptoms**:
- Boot process appeared to skip verbose logging phase
- Audit messages not displayed during boot
- Auditd started but without proper kernel-level audit support
- Queue overflow warnings due to missing `audit_backlog_limit` kernel parameter

**Expected Behavior After Fix**:
- Kernel audit enabled at boot via `audit=1` parameter
- Backlog limit set to 8192 via `audit_backlog_limit=8192`
- Comprehensive audit rules loaded automatically
- Proper boot-time audit event capture

### Configuration Verification

**Active Audit Configuration** (`/etc/nixos/modules/security/audit.nix`):
- Kernel parameters: `audit=1`, `audit_backlog_limit=8192` (lines 22-23)
- Auditd daemon enabled (line 27)
- Security audit rules enabled (line 28)
- Comprehensive rule set (lines 30-48):
  - execve syscall monitoring
  - Critical file change monitoring (/etc/passwd, /etc/shadow, /etc/sudoers)
  - Login attempt monitoring
  - Unauthorized access monitoring
  - File deletion tracking

**Template Files** (not imported, safe to ignore):
- `/etc/nixos/modules/security/hardening-template.nix`
- `/etc/nixos/hosts/kernelcore/configurations-template.nix`

## Next Steps for Verification

After next rebuild, verify:

1. **Kernel parameters applied**:
   ```bash
   cat /proc/cmdline | grep audit
   # Expected: audit=1 audit_backlog_limit=8192
   ```

2. **Backlog limit set correctly**:
   ```bash
   cat /proc/sys/kernel/audit_backlog_limit
   # Expected: 8192
   ```

3. **Audit rules loaded**:
   ```bash
   sudo auditctl -l
   # Expected: All rules from audit.nix:30-48
   ```

4. **Boot logs show audit initialization**:
   ```bash
   sudo dmesg | grep -i audit
   # Should show early audit initialization messages
   ```

5. **No more queue overflow warnings**:
   ```bash
   journalctl -b | grep "queue overflow"
   # Should return no results or significantly reduced occurrences
   ```

## Report Back
Please run these commands and share:
1. Output of kernel audit messages (`sudo dmesg | grep audit`)
2. Contents of filter.conf if found
3. Output of `sudo auditctl -s` (audit system status)
4. Contents of `/proc/sys/kernel/audit_backlog_limit`
5. Any new errors or warnings you discover

This will help identify if:
- Queue overflow is still occurring despite backlog increase
- filter.conf warning is harmless or critical
- Symlink issue affects functionality
- Rules are loading correctly
