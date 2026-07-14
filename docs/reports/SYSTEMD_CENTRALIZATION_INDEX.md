# Systemd Services Centralization Index

## Quick Navigation

This directory contains the complete inventory and plans for centralizing all systemd services.

### Documentation Files

1. **SYSTEMD_SERVICES_INVENTORY.md** (Primary Document)
   - Comprehensive 50+ page report
   - Detailed analysis of all services
   - Dependency graphs
   - Security considerations
   - Migration checklist
   - Recommendations

2. **SYSTEMD_SERVICES_SUMMARY.txt** (Quick Reference)
   - One-page executive summary
   - Service quick list
   - File locations
   - Current vs. recommended structure
   - Migration phases

3. **SYSTEMD_CENTRALIZATION_INDEX.md** (This File)
   - Navigation guide
   - File locations table
   - Key statistics

---

## Service Inventory at a Glance

### Total Count
- **Primary Services**: 7
- **Service Enhancements**: 2 (sshd, clamav-daemon)
- **Timers**: 1 (clamav-scan)
- **Tmpfiles Rules**: 3
- **Optional Services**: 1 (gpu-monitor-daemon - commented)

### Service Categories

| Category | Services | File Location |
|----------|----------|---------------|
| ML/AI | llamacpp | `/etc/nixos/modules/ml/llama.nix` |
| Containers | docker-pull-images, ollama* | `/etc/nixos/modules/system/services.nix` |
| Development | jupyter | `/etc/nixos/modules/development/jupyter.nix` |
| Security | setup-system-credentials, clamav-scan | `/etc/nixos/sec/hardening.nix` |
| Monitoring | Prometheus, Grafana | `/etc/nixos/modules/services/default.nix` |

*ollama service enhancement only

---

## File Locations Summary

### Current Service Definitions

| File Path | Line Range | Service Name | Type |
|-----------|-----------|--------------|------|
| `/etc/nixos/modules/ml/llama.nix` | 163-200 | llamacpp | system |
| `/etc/nixos/modules/system/services.nix` | 10-22 | docker-pull-images | system |
| `/etc/nixos/modules/system/services.nix` | 24-34 | ollama* | enhancement |
| `/etc/nixos/modules/development/jupyter.nix` | 124-145 | jupyter | user |
| `/etc/nixos/sec/hardening.nix` | 140-148 | setup-system-credentials | system |
| `/etc/nixos/sec/hardening.nix` | 161-182 | clamav-scan | system |
| `/etc/nixos/sec/hardening.nix` | 184-192 | clamav-scan | timer |
| `/etc/nixos/sec/hardening.nix` | 234-252 | sshd* | enhancement |
| `/etc/nixos/sec/hardening.nix` | 254-262 | clamav-daemon* | enhancement |
| `/etc/nixos/modules/services/default.nix` | 10-25 | prometheus, grafana | system |

*Enhancement to existing service, not a new service definition

### Tmpfiles Rules

| File Path | Line | Rule | Purpose |
|-----------|------|------|---------|
| `/etc/nixos/sec/hardening.nix` | 158 | ClamAV log dir | Antivirus logging |
| `/etc/nixos/modules/hardware/nvidia.nix` | 69-71 | CUDA cache | GPU cache storage |
| `/etc/nixos/modules/virtualization/vms.nix` | 69 | VM shared dir | Libvirt shared storage |

### Optional/Commented

| File Path | Lines | Service Name | Status |
|-----------|-------|--------------|--------|
| `/etc/nixos/modules/shell/default.nix` | 186-194 | gpu-monitor-daemon | COMMENTED OUT |

---

## Key Service Details

### Service Types Distribution
- **Simple Services**: 5 (llamacpp, jupyter, etc.)
- **Oneshot Services**: 2 (docker-pull-images, clamav-scan)
- **User Services**: 1 (jupyter)
- **Timers**: 1 (clamav-scan)

### GPU-Enabled Services
1. llamacpp - Optional via `n_gpu_layers` parameter
2. jupyter - Explicit `/dev/nvidia0` access
3. ollama - Enhanced with GPU device access

### Auto-Restart Policies
- **Always**: llamacpp (production)
- **On-Failure**: jupyter (development)
- **None**: docker-pull-images (oneshot)

---

## Recommended Centralization Structure

```
/etc/nixos/modules/services/
├── default.nix                    # Orchestrator + monitoring
├── docker.nix                     # Docker-related services
├── ml/
│   └── llama.nix                  # LLM inference (move from ../ml/)
├── security/
│   ├── hardening.nix              # Base hardening
│   ├── clamav.nix                 # ClamAV scan + timer
│   └── sshd.nix                   # SSH hardening
├── development/
│   └── jupyter.nix                # Jupyter (move from ../development/)
└── system/
    └── init.nix                   # System initialization
```

---

## Migration Steps

### Phase 1: Assessment ✓ COMPLETED
- [x] Identified all systemd definitions
- [x] Documented locations and purposes
- [x] Mapped dependencies
- [x] Created inventory reports

### Phase 2: Module Creation
- [ ] Create directory structure
- [ ] Extract services into new modules
- [ ] Create orchestrator default.nix

### Phase 3: Integration
- [ ] Update flake.nix imports
- [ ] Test all services
- [ ] Verify functionality

### Phase 4: Cleanup
- [ ] Remove service definitions from original files
- [ ] Keep only configuration options
- [ ] Verify no orphaned references

### Phase 5: Validation
- [ ] Run `nixos-rebuild switch`
- [ ] Check `systemctl` for all services
- [ ] Review journalctl logs

---

## Dependencies Map

```
Startup Order:
1. network.target (foundation)
   ├── llamacpp (waits for network)
   ├── jupyter (waits for network)
   └── setup-system-credentials (waits for multi-user.target)
       └── jupyter (uses credentials)

2. docker.service
   └── docker-pull-images (waits for docker)
       ├── images for llamacpp
       ├── images for TGI
       └── images for PyTorch

3. clamav-daemon
   └── clamav-scan (triggered by timer)
       └── clamav-scan timer (runs weekly)
```

---

## Security Summary

### Hardened Services
1. **jupyter** - PrivateTmp, ProtectSystem strict, NoNewPrivileges
2. **sshd** - Multiple isolation mechanisms, capability bounding
3. **clamav** - Low priority, idle IO, excluded system dirs

### GPU Access Control
- Group-based: `nvidia` group membership
- Device allowlist per service
- Udev rules for access management

### Secret Management
- Credentials stored in `/etc/credstore` (700 permissions)
- LoadCredential for jupyter-token
- Separate storage from main configuration

---

## Usage Guide

### To Review Full Inventory
```bash
cat /etc/nixos/SYSTEMD_SERVICES_INVENTORY.md
```

### To See Quick Summary
```bash
cat /etc/nixos/SYSTEMD_SERVICES_SUMMARY.txt
```

### To Check Service Status
```bash
systemctl status servicename
journalctl -u servicename
```

### To List All Services
```bash
systemctl list-units --type=service --all
systemctl list-timers
```

---

## Next Steps

1. Review both documentation files
2. Proceed with Phase 2 (Module Creation)
3. Create new modules in `modules/services/`
4. Test changes before deployment
5. Update flake.nix imports

---

## Document Generated
Date: October 21, 2025
Scope: /etc/nixos
Purpose: Centralizing systemd services into modules/services/ folder

For detailed information, see SYSTEMD_SERVICES_INVENTORY.md
For quick reference, see SYSTEMD_SERVICES_SUMMARY.txt
