# NixOS Critical Rebuild Failure - Forensic Investigation Protocol

## MISSION BRIEFING
Investigate and resolve catastrophic NixOS rebuild failures characterized by:
- Extreme I/O bottleneck causing system freeze
- CPU maxed out but no thermal throttling
- RAM exhaustion (memory leak suspected)
- Intermittent crashes during nixos-rebuild
- Post-aggressive-cleanup corruption

## INCIDENT TIMELINE

### Phase 1: Disk Space Crisis
**Action Taken:** Aggressive cleanup script `/etc/nixos/scripts/limpeza-agressiva.sh`
**Result:** Recovered 150GB from `/var/log`
**Side Effect:** Likely deleted critical system logs and potentially corrupted journald

### Phase 2: Cascade Failures
**Symptoms:**
- nixos-rebuild hangs indefinitely (>2 hours)
- I/O wait critical despite normal temperatures
- CPU at 100% usage
- GPU idle (~0% usage, normal temps)
- RAM usage spiking to maximum (memory leak pattern)
- System freezes without kernel panic initially
- Eventually: kernel panic on generation 1, only generation 2 boots

### Phase 3: Mitigation Attempts
**Changes Applied:**
- `nix-daemon.nix` modifications (max-jobs=4, cores=3)
- Commented unified-llm modules (avoiding 7GB+ Rust compilation)
- ZRAM aggressive compression enabled
- Kernel memory tuning parameters
- Swap management optimization
- Log rotation services added
- Memory pressure relief systemd service

**Status:** Problem persists despite optimizations

## CRITICAL DIAGNOSTIC QUESTIONS

### 1. ROOT CAUSE HYPOTHESIS MATRIX
```
┌─────────────────────────┬──────────────┬─────────────┐
│ Hypothesis              │ Probability  │ Test Method │
├─────────────────────────┼──────────────┼─────────────┤
│ Corrupted Nix Store     │ HIGH         │ verify-store│
│ Memory Leak in Builder  │ HIGH         │ memtrace    │
│ Infinite Loop in Eval   │ MEDIUM       │ strace-eval │
│ Disk Hardware Failure   │ MEDIUM       │ smartctl    │
│ LVM/LUKS Corruption     │ MEDIUM       │ fsck-all    │
│ Zombie Build Processes  │ LOW          │ ps-tree     │
│ OOM Killer Disabled     │ LOW          │ sysctl-check│
└─────────────────────────┴──────────────┴─────────────┘
```

### 2. SMOKING GUN INDICATORS

**Check These First:**
```bash
# 1. Nix store integrity (CRITICAL)
sudo nix-store --verify --check-contents --repair 2>&1 | tee /tmp/store-verify.log

# 2. Active build processes
ps auxf | grep -E "nix-daemon|nix-build|nixos-rebuild" | grep -v grep

# 3. Memory leak detection
cat /proc/$(pgrep nix-daemon | head -1)/status | grep -E "VmSize|VmRSS|VmData"
watch -n 1 'cat /proc/$(pgrep nix-daemon | head -1)/status | grep VmRSS'

# 4. I/O bottleneck identification
sudo iotop -oPa -d 2 -n 10 > /tmp/io-culprits.log
iostat -x 2 10 > /tmp/iostat.log

# 5. Disk health SMART check
sudo smartctl -a /dev/nvme0n1 > /tmp/smart-report.log
sudo smartctl -H /dev/nvme0n1  # Quick health

# 6. Strace the evaluation phase
sudo strace -f -e trace=open,read,write -p $(pgrep nix-daemon | head -1) 2>&1 | head -1000 > /tmp/nix-strace.log

# 7. Check for infinite recursion in flake
nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel --show-trace 2>&1 | tee /tmp/eval-trace.log

# 8. Memory pressure indicators
cat /proc/pressure/memory
cat /proc/pressure/io

# 9. Systemd failed units
systemctl --failed
journalctl -p err -b -n 500 --no-pager > /tmp/systemd-errors.log

# 10. LVM/LUKS status
sudo lvs -a -o +devices
sudo cryptsetup status cryptroot
```

## ADVANCED FORENSICS PROTOCOL

### Stage 1: Data Collection (NON-DESTRUCTIVE)
```bash
#!/usr/bin/env bash
# forensics-collect.sh

REPORT_DIR="/tmp/nixos-forensics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "🔍 Collecting forensic data..."

# System state snapshot
uname -a > "$REPORT_DIR/kernel.txt"
df -h > "$REPORT_DIR/disk-usage.txt"
free -h > "$REPORT_DIR/memory.txt"
lsblk -f > "$REPORT_DIR/block-devices.txt"

# Nix state
nix-store --verify --check-contents 2>&1 | head -1000 > "$REPORT_DIR/store-verify.txt"
nix-channel --list > "$REPORT_DIR/channels.txt"
nix flake metadata > "$REPORT_DIR/flake-metadata.txt" 2>&1 || true

# Process tree
ps auxf > "$REPORT_DIR/processes.txt"
pstree -p > "$REPORT_DIR/process-tree.txt"

# Memory analysis
cat /proc/meminfo > "$REPORT_DIR/meminfo.txt"
for pid in $(pgrep nix); do
  echo "=== PID $pid ===" >> "$REPORT_DIR/nix-memory.txt"
  cat /proc/$pid/status 2>/dev/null >> "$REPORT_DIR/nix-memory.txt" || true
done

# I/O stats
iostat -x 1 5 > "$REPORT_DIR/iostat.txt"
cat /proc/diskstats > "$REPORT_DIR/diskstats.txt"

# Logs
journalctl -b -n 1000 --no-pager > "$REPORT_DIR/journal.txt"
dmesg > "$REPORT_DIR/dmesg.txt"

# Configuration snapshot
cp -r /etc/nixos "$REPORT_DIR/nixos-config/" 2>/dev/null || true

# SMART data
sudo smartctl -a /dev/nvme0n1 > "$REPORT_DIR/smart.txt" 2>&1 || true

# Generation comparison
nix-env --list-generations --profile /nix/var/nix/profiles/system > "$REPORT_DIR/generations.txt"

echo "✅ Forensic data collected at: $REPORT_DIR"
tar czf "$REPORT_DIR.tar.gz" "$REPORT_DIR"
echo "📦 Archive: $REPORT_DIR.tar.gz"
```

### Stage 2: Controlled Rebuild Test
```bash
#!/usr/bin/env bash
# rebuild-controlled-test.sh

set -e

echo "🧪 Starting controlled rebuild test..."

# Pre-flight checks
echo "Pre-flight: Clearing caches..."
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

echo "Pre-flight: Stopping non-essential services..."
sudo systemctl stop docker containerd postgresql redis nginx 2>/dev/null || true

# Memory baseline
BASELINE_MEM=$(free -m | awk 'NR==2{print $3}')
echo "Baseline memory usage: ${BASELINE_MEM}MB"

# Start rebuild with monitoring
echo "Starting rebuild with verbose logging..."

# Monitor in background
(
  while sleep 5; do
    CURRENT_MEM=$(free -m | awk 'NR==2{print $3}')
    MEM_DELTA=$((CURRENT_MEM - BASELINE_MEM))
    
    IO_AWAIT=$(iostat -x 1 1 | grep nvme0n1 | awk '{print $10}' | cut -d. -f1)
    
    echo "[$(date +%T)] MEM: ${CURRENT_MEM}MB (+${MEM_DELTA}MB) | I/O await: ${IO_AWAIT}ms"
    
    # Circuit breaker: memory leak detection
    if [ $MEM_DELTA -gt 10000 ]; then
      echo "🚨 MEMORY LEAK DETECTED: +${MEM_DELTA}MB"
      pkill -TERM nixos-rebuild
      exit 1
    fi
    
    # Circuit breaker: I/O death spiral
    if [ "${IO_AWAIT:-0}" -gt 1000 ]; then
      echo "🚨 I/O BOTTLENECK: ${IO_AWAIT}ms await"
      pkill -TERM nixos-rebuild
      exit 1
    fi
  done
) &
MONITOR_PID=$!

# Actual rebuild
sudo nixos-rebuild dry-build --show-trace --verbose 2>&1 | tee /tmp/rebuild-test.log || {
  kill $MONITOR_PID 2>/dev/null
  echo "❌ Rebuild failed"
  exit 1
}

kill $MONITOR_PID 2>/dev/null
echo "✅ Dry-build successful"
```

## HYPOTHESIS TESTING MATRIX

### Hypothesis 1: Corrupted Nix Store
**Test:**
```bash
sudo nix-store --verify --check-contents --repair
nix-store --optimise  # Deduplicate, might reveal corruption
```

**If Confirmed:**
```nix
# Add to configuration.nix
{
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
  
  nix.settings = {
    auto-optimise-store = true;
    
    # Fallback to binary cache aggressively
    fallback = true;
    connect-timeout = 5;
  };
}
```

### Hypothesis 2: Memory Leak in Nix Evaluation
**Test:**
```bash
# Trace memory during eval
valgrind --leak-check=full nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel 2>&1 | tee /tmp/valgrind.log

# Or simpler:
/usr/bin/time -v nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel
```

**If Confirmed:**
```nix
# Limit eval memory
{
  nix.extraOptions = ''
    eval-cache = true
    max-silent-time = 300
  '';
  
  # Split large imports
  # Review flake.nix for circular imports or massive recursion
}
```

### Hypothesis 3: Infinite Loop in Flake Evaluation
**Test:**
```bash
# Timeout-protected eval
timeout 60 nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel --show-trace

# Trace recursion depth
NIX_SHOW_TRACE=1 NIX_SHOW_TRACE_VERBOSE=1 nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel 2>&1 | tee /tmp/recursion-trace.log
```

**Look for:**
- Repeating patterns in trace
- `infinite recursion` errors
- Circular imports

**If Confirmed:**
```nix
# Add to flake.nix
{
  # Break circular dependencies
  nixpkgs.overlays = lib.mkBefore [];  # Clear overlays if suspected
  
  # Simplify imports
  imports = lib.mkBefore [
    # Only essential modules
  ];
}
```

### Hypothesis 4: Disk Hardware Failure
**Test:**
```bash
sudo smartctl -a /dev/nvme0n1 | grep -E "health|error|warning"
sudo badblocks -sv /dev/nvme0n1p3  # NON-DESTRUCTIVE read test
```

**If Confirmed:**
- BACKUP IMMEDIATELY
- Replace disk
- No software fix possible

### Hypothesis 5: LVM/LUKS Performance Degradation
**Test:**
```bash
# Test raw disk speed
sudo hdparm -Tt /dev/nvme0n1

# Test encrypted volume speed
sudo cryptsetup benchmark

# Check LVM metadata
sudo vgck vg
sudo lvs -a -o +devices,seg_pe_ranges
```

**If Confirmed:**
```bash
# Rebuild LVM cache
sudo lvchange --refresh vg

# Check LUKS header
sudo cryptsetup luksDump /dev/nvme0n1p3
```

### Hypothesis 6: Zombie Build Processes
**Test:**
```bash
ps aux | awk '$8=="Z" {print}'  # Zombie processes
ps aux | grep nix-build | wc -l  # Orphaned builders

# Check for leaked file descriptors
sudo lsof | grep nix-daemon | wc -l
```

**If Confirmed:**
```bash
# Kill all nix processes
sudo pkill -9 nix-daemon
sudo systemctl restart nix-daemon

# Add to config:
{
  systemd.services.nix-daemon.serviceConfig = {
    LimitNOFILE = 65536;
    OOMScoreAdjust = -500;  # Protect from OOM killer
  };
}
```

## EMERGENCY RECOVERY PROCEDURES

### Procedure A: Minimal Viable Rebuild
```nix
# minimal-config.nix - GUARANTEED BOOTABLE
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Absolute minimum
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  
  services.openssh.enable = true;
  users.users.root.initialPassword = "emergency";

  # AGGRESSIVE RESOURCE LIMITS
  nix.settings = {
    max-jobs = 1;  # SINGLE JOB ONLY
    cores = 2;
    
    # Force binary cache
    substitute = true;
    builders-use-substitutes = true;
    
    # Timeouts
    connect-timeout = 10;
    stalled-download-timeout = 30;
  };

  # Memory protection
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 2;  # Don't allow overcommit
    "vm.overcommit_ratio" = 80;
  };

  # Disable everything else
  services.xserver.enable = lib.mkForce false;
  hardware.opengl.enable = lib.mkForce false;
  
  environment.systemPackages = with pkgs; [ vim git htop ];
  
  system.stateVersion = "24.05";
}
```

**Deploy:**
```bash
sudo nixos-rebuild boot -I nixos-config=./minimal-config.nix --show-trace
sudo reboot
```

### Procedure B: Nix Store Surgical Repair
```bash
#!/usr/bin/env bash
# nix-store-repair.sh

echo "🔧 Starting Nix store repair..."

# 1. Verify and repair
sudo nix-store --verify --check-contents --repair

# 2. Clear derivation cache
sudo rm -rf /nix/var/nix/db/db.sqlite-*
sudo nix-store --init

# 3. Re-register store paths
sudo nix-store --load-db < <(sudo nix-store --dump-db)

# 4. Optimize and deduplicate
sudo nix-store --optimise

# 5. Garbage collect broken references
sudo nix-collect-garbage -d

# 6. Verify again
sudo nix-store --verify --check-contents

echo "✅ Repair complete"
```

### Procedure C: Binary Cache Bootstrap
```nix
# force-cache-only.nix
{
  nix.settings = {
    # NEVER build from source
    fallback = false;
    
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    
    # Abort if not in cache
    require-sigs = true;
  };
}
```

## DECISION TREE
```
START: nixos-rebuild hangs
│
├─> Verify Nix store integrity
│   ├─ Corrupted? → Repair procedure B
│   └─ OK? → Continue
│
├─> Check memory usage pattern
│   ├─ Constant leak? → Hypothesis 2 (eval leak)
│   └─ Spiky? → Continue
│
├─> Monitor I/O await times
│   ├─ >500ms consistently? → Hypothesis 4 (disk failure)
│   └─ <500ms? → Continue
│
├─> Test minimal config
│   ├─ Fails? → Hardware issue (Hyp 4/5)
│   └─ Works? → Configuration issue
│
├─> Bisect configuration
│   ├─ Disable modules one-by-one
│   └─ Find culprit
│
└─> Deploy fix
```

## INSTRUMENTATION CODE

### Memory Leak Detector Service
```nix
# Add to configuration.nix
{
  systemd.services.nix-daemon-leak-detector = {
    description = "Detect memory leaks in nix-daemon";
    after = [ "nix-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      
      ExecStart = pkgs.writeShellScript "leak-detector" ''
        while true; do
          for pid in $(pgrep nix-daemon); do
            MEM=$(cat /proc/$pid/status | grep VmRSS | awk '{print $2}')
            
            if [ "$MEM" -gt 8388608 ]; then  # 8GB
              echo "🚨 nix-daemon PID $pid using ''${MEM}KB (>8GB)"
              echo "Killing leaking process..."
              kill -TERM $pid
              
              systemctl restart nix-daemon
            fi
          done
          
          sleep 30
        done
      '';
    };
  };
}
```

### I/O Circuit Breaker
```nix
{
  systemd.services.io-circuit-breaker = {
    description = "Kill rebuilds if I/O hangs";
    
    serviceConfig = {
      Type = "simple";
      
      ExecStart = pkgs.writeShellScript "io-breaker" ''
        while true; do
          AWAIT=$(iostat -x 1 1 | grep nvme0n1 | awk '{print $10}' | cut -d. -f1)
          
          if [ "''${AWAIT:-0}" -gt 2000 ]; then
            echo "🚨 I/O CRITICAL: ''${AWAIT}ms await"
            
            if pgrep nixos-rebuild >/dev/null; then
              echo "Killing nixos-rebuild..."
              pkill -TERM nixos-rebuild
            fi
          fi
          
          sleep 10
        done
      '';
    };
  };
}
```

## NEXT STEPS FOR BEDROCK CLAUDE

1. **Execute forensics-collect.sh** → Upload results
2. **Run rebuild-controlled-test.sh** → Identify exact failure point
3. **Test each hypothesis** → Systematic elimination
4. **Deploy appropriate fix** → Based on confirmed hypothesis
5. **Validate with minimal config** → Ensure bootability
6. **Gradually restore features** → One module at a time

## CRITICAL DATA TO COLLECT
```bash
# Run these and provide outputs:
sudo nix-store --verify --check-contents 2>&1 | head -100
free -h
df -h
iostat -x 2 5
ps aux | grep nix | head -20
journalctl -b -n 200 --no-pager | grep -iE "error|fail|panic"
nix flake show 2>&1 | head -50
```

## SUCCESS CRITERIA

- [ ] nixos-rebuild completes in <10 minutes
- [ ] Memory usage stays <50% during rebuild
- [ ] I/O await times <100ms
- [ ] CPU usage reasonable (<80% average)
- [ ] No zombie processes
- [ ] All generations bootable
- [ ] Nix store verified clean

---

**Priority:** CRITICAL  
**Complexity:** HIGH  
**Risk:** MEDIUM (rollback available)  
**Estimated Debug Time:** 2-4 hours

Good luck, Bedrock Claude. Hunt well. 🎯