# Systemd Services Inventory Report
## NixOS Configuration Repository

**Generated:** October 21, 2025
**Repository Location:** `/etc/nixos`
**Task:** Centralizing all systemd services into `modules/services/` folder

---

## Executive Summary

The NixOS configuration repository contains **7 systemd service definitions**, **1 systemd timer**, and **3 systemd tmpfiles rules** distributed across **8 different files** in various module directories. This report identifies all services and provides a centralization plan for the `modules/services/` directory.

---

## Files Containing Systemd Definitions

### Overview Table

| File Path | Service Count | Timer Count | Tmpfiles | Category |
|-----------|---------------|-------------|----------|----------|
| `/etc/nixos/modules/ml/llama.nix` | 1 | 0 | 0 | ML/AI |
| `/etc/nixos/modules/system/services.nix` | 2 | 0 | 0 | System |
| `/etc/nixos/modules/development/jupyter.nix` | 1 (user) | 0 | 0 | Development |
| `/etc/nixos/sec/hardening.nix` | 3 | 1 | 1 | Security |
| `/etc/nixos/modules/security/hardening.nix` | 0 | 0 | 0 | Security |
| `/etc/nixos/modules/hardware/nvidia.nix` | 0 | 0 | 1 | Hardware |
| `/etc/nixos/modules/virtualization/vms.nix` | 0 | 0 | 1 | Virtualization |
| `/etc/nixos/modules/shell/default.nix` | 1 (commented) | 0 | 0 | Shell (Optional) |
| **TOTAL** | **7+1** | **1** | **3** | |

---

## Detailed Service Definitions

### 1. ML/AI Services

#### File: `/etc/nixos/modules/ml/llama.nix`

**Service Name:** `llamacpp`
- **Description:** Llama.cpp server for LLM inference
- **Type:** Simple service
- **Start After:** network.target
- **Wanted By:** multi-user.target
- **Key Config:**
  - ExecStart: `llama-server` with configurable parameters
  - Restart: always with 10s restart delay
  - Host: 127.0.0.1 (default)
  - Port: 8080 (default)
  - GPU Support: Optional n_gpu_layers parameter
- **Configurable Options:** 
  - Thread count, batch size, context size
  - Temperature, sampling parameters
  - NUMA support, memory mapping, mlock
  - LoRA adapter path support

**Status:** Active service definition with extensive configuration options

---

### 2. System Services

#### File: `/etc/nixos/modules/system/services.nix`

**Service 1: `docker-pull-images`**
- **Description:** Pre-pull Docker images on system start
- **Type:** oneshot
- **After:** docker.service
- **Wanted By:** multi-user.target
- **Behavior:** RemainAfterExit = true (marks as active after completion)
- **Actions:**
  - Pulls: `nvcr.io/nvidia/pytorch:25.09-py3`
  - Pulls: `ghcr.io/huggingface/text-generation-inference:latest`

**Service 2: `ollama` (Service Config Enhancement)**
- **Description:** Ollama AI model server (enhanced config only)
- **Type:** Enhanced existing service (not a new service definition)
- **GPU Device Access:**
  - `/dev/nvidia0 rw`
  - `/dev/nvidiactl rw`
  - `/dev/nvidia-uvm rw`
- **Supplementary Groups:** video, nvidia

**Status:** Both services active; second one enhances existing ollama service

---

### 3. Development Services

#### File: `/etc/nixos/modules/development/jupyter.nix`

**Service Name:** `jupyter` (User service)
- **Description:** JupyterLab Server
- **Scope:** User-level service (`systemd.user.services`)
- **Type:** simple
- **After:** network.target
- **ExecStart:** `jupyter-lab --ip=127.0.0.1 --no-browser`
- **Restart:** on-failure
- **GPU Access:**
  - `/dev/nvidia0 rw`
  - `/dev/nvidiactl rw`
  - Supplementary Group: nvidia
- **Security Hardening:**
  - PrivateTmp: true
  - ProtectSystem: strict
  - NoNewPrivileges: true
- **Credentials:** LoadCredential for jupyter-token from `/etc/credstore/jupyter-token`
- **Conditionally Enabled:** Based on `config.kernelcore.development.jupyter.service.enable`

**Status:** User-level service with security hardening

---

### 4. Security Services

#### File: `/etc/nixos/sec/hardening.nix`

**Service 1: `setup-system-credentials`**
- **Description:** Setup system credential storage
- **Type:** oneshot
- **Wanted By:** multi-user.target
- **RemainAfterExit:** true
- **Action:** Creates `/etc/credstore` with 700 permissions

**Service 2: `clamav-scan`**
- **Description:** ClamAV system scan
- **Type:** oneshot
- **Nice Level:** 19 (low priority)
- **IO Scheduling:** idle
- **Scope:** Scans `/home` directory
- **Excludes:** /sys, /proc, /dev, /run, /nix/store
- **Limits:** 
  - Max file size: 100M
  - Max scan size: 300M
- **Output:** Log at `/var/log/clamav/scan.log`
- **Triggered By:** `clamav-scan` timer (see below)

**Service 3: SSHD Enhanced Config**
- **Description:** SSH service hardening (not a new service, config enhancement)
- **Type:** Enhanced existing service
- **Security Additions:**
  - PrivateTmp: true
  - ProtectSystem: strict
  - ProtectHome: true
  - NoNewPrivileges: true
  - ProtectKernelTunables: true
  - ProtectKernelModules: true
  - ProtectControlGroups: true
  - RestrictNamespaces: true
  - RestrictRealtime: true
  - RestrictSUIDSGID: true
  - RemoveIPC: true
  - PrivateMounts: true
  - SystemCallFilter: @system-service
  - CapabilityBoundingSet: CAP_NET_BIND_SERVICE, CAP_DAC_READ_SEARCH

**Service 4: ClamAV Daemon Enhanced Config**
- **Description:** Enhanced ClamAV daemon configuration
- **Type:** Enhanced existing service
- **Security Config:**
  - ProtectSystem: strict
  - ProtectHome: read-only
  - ReadWritePaths: /var/lib/clamav, /var/log/clamav

---

### 5. Security Timers

#### File: `/etc/nixos/sec/hardening.nix`

**Timer Name:** `clamav-scan`
- **Description:** Weekly ClamAV scan
- **Wanted By:** timers.target
- **Schedule:** OnCalendar = "weekly"
- **Randomized Delay:** 2 hours (to avoid system overload)
- **Persistent:** true (runs missed scans on boot if needed)
- **Triggers Service:** `clamav-scan`

---

### 6. Temporary File Rules (systemd.tmpfiles)

#### File: `/etc/nixos/sec/hardening.nix`

```
d /var/log/clamav 0755 clamav clamav -
```
- Creates ClamAV log directory with proper permissions

#### File: `/etc/nixos/modules/hardware/nvidia.nix`

```
d /var/cache/cuda 0770 root nvidia -
L+ /var/tmp/cuda-cache - - - - /var/cache/cuda
```
- Creates secure CUDA cache directory
- Creates symlink for temporary CUDA cache

#### File: `/etc/nixos/modules/virtualization/vms.nix`

```
d /srv/vms/shared 0755 root libvirtd -
```
- Creates shared VM directory for libvirt

---

### 7. Optional/Commented Services

#### File: `/etc/nixos/modules/shell/default.nix`

**Service Name:** `gpu-monitor-daemon` (COMMENTED OUT)
- **Description:** GPU Monitor Daemon (optional for continuous monitoring)
- **Status:** Currently disabled
- **Type:** Intended for background GPU monitoring
- **Restart:** always with 10s restart delay
- **Location in Code:** Lines 186-194

**To Enable:** Uncomment lines 186-194 in the file

---

## Current Module Structure

```
/etc/nixos/modules/services/
├── default.nix        # Prometheus & Grafana configuration
└── scripts.nix        # Docker build script aliases (NOT related to systemd)
```

### Current default.nix Contents

**Services configured in `default.nix`:**
1. **Prometheus** (monitoring service)
   - Port: 9090
   - Exporters: node (port 9100)

2. **Grafana** (visualization service)
   - Port: 4000
   - Domain: localhost

---

## Systemd Services Distribution Map

```
ACTIVE SERVICES (7):
├── llamacpp (ml/llama.nix) - LLM inference server
├── docker-pull-images (system/services.nix) - Pre-pull Docker images
├── ollama.serviceConfig (system/services.nix) - Enhanced existing service
├── jupyter (development/jupyter.nix) - User-level JupyterLab
├── setup-system-credentials (sec/hardening.nix) - Credential setup
├── clamav-scan (sec/hardening.nix) - Antivirus scanner
└── sshd + clamav-daemon (sec/hardening.nix) - Enhanced existing services

TIMERS (1):
├── clamav-scan - Weekly scan scheduler

TMPFILES RULES (3):
├── ClamAV log directory (sec/hardening.nix)
├── CUDA cache directory (hardware/nvidia.nix)
└── VM shared directory (virtualization/vms.nix)

OPTIONAL SERVICES:
├── gpu-monitor-daemon (shell/default.nix) - Commented out
```

---

## Centralization Plan for `modules/services/`

### Recommended File Structure

```
/etc/nixos/modules/services/
├── default.nix                 # Main orchestrator
├── monitoring.nix              # Prometheus & Grafana (move from default.nix)
├── docker.nix                  # Docker-related services
├── ml/
│   └── llama.nix               # LLM services (move from ml/llama.nix)
├── security/
│   ├── hardening.nix           # Security services (move from sec/hardening.nix)
│   ├── clamav.nix              # ClamAV services & timers
│   └── sshd.nix                # SSH service hardening
├── development/
│   └── jupyter.nix             # Jupyter service (move from development/jupyter.nix)
└── system/
    └── init.nix                # System init services (credentials, etc.)
```

---

## Migration Checklist

### Phase 1: Assessment (Completed)
- [x] Identify all systemd services
- [x] Identify all systemd timers
- [x] Identify all tmpfiles rules
- [x] Document service purposes
- [x] Map dependencies

### Phase 2: Module Creation
- [ ] Create new service modules in `modules/services/`
- [ ] Create `modules/services/ml/llama.nix` (move from `modules/ml/`)
- [ ] Create `modules/services/security/clamav.nix` (extract from `sec/hardening.nix`)
- [ ] Create `modules/services/development/jupyter.nix` (move from `modules/development/`)
- [ ] Create `modules/services/docker.nix` (move from `modules/system/services.nix`)
- [ ] Update `modules/services/monitoring.nix` (move from default.nix)

### Phase 3: Module Integration
- [ ] Create new `modules/services/default.nix` orchestrator
- [ ] Import all service submodules in new orchestrator
- [ ] Update `flake.nix` to import new modules
- [ ] Test each service

### Phase 4: Cleanup
- [ ] Remove service definitions from original files
- [ ] Keep only configurable options in original files if needed
- [ ] Remove redundant imports
- [ ] Verify no orphaned references

### Phase 5: Validation
- [ ] Run `nixos-rebuild switch` successfully
- [ ] Verify all services start correctly
- [ ] Check `systemctl status` for each service
- [ ] Review journalctl for errors

---

## Dependencies & Relationships

```
DEPENDENCY GRAPH:

docker-pull-images
  ├── depends on: docker.service
  ├── depends on: network.target
  └── pulls images for: llamacpp, TGI, PyTorch

llamacpp
  ├── depends on: network.target
  └── provides: LLM inference API

jupyter
  ├── depends on: network.target
  ├── requires: GPU devices (/dev/nvidia0)
  └── needs: credentials (/etc/credstore/jupyter-token)

ollama
  ├── enhanced by: docker-pull-images
  └── requires: GPU devices (/dev/nvidia0)

clamav-scan
  ├── triggered by: clamav-scan timer
  ├── requires: clamav package
  └── logs to: /var/log/clamav/scan.log

clamav-scan timer
  ├── runs weekly
  └── triggers: clamav-scan service

sshd (enhanced)
  └── security hardening applied

setup-system-credentials
  ├── creates: /etc/credstore
  └── required by: jupyter (optional)
```

---

## Security Considerations

### Current Security Measures in Services:

1. **Jupyter Service:**
   - PrivateTmp isolation
   - ProtectSystem strict
   - NoNewPrivileges enforced
   - GPU access controlled via group membership

2. **SSHD Service:**
   - PrivateTmp, ProtectSystem, ProtectHome
   - Capability bounding set (NET_BIND_SERVICE, DAC_READ_SEARCH)
   - SystemCall filtering
   - RestrictRealtime, RestrictNamespaces, RestrictSUIDSGID

3. **ClamAV:**
   - Low priority (nice=19)
   - Idle IO scheduling
   - File size/scan size limits
   - Excluded system directories

4. **GPU Access:**
   - Controlled via nvidia group membership
   - Device allowlist in services
   - Udev rules in `/etc/udev/rules.d/`

---

## Notes & Observations

1. **Module Organization:** Services are currently scattered across functional modules (ml/, development/, security/, system/) rather than being centralized.

2. **Service Types:**
   - Simple services: 5
   - Oneshot services: 2
   - User services: 1

3. **Auto-restart:**
   - llamacpp: always (production service)
   - jupyter: on-failure (development service)
   - docker-pull-images: no (oneshot)

4. **GPU Services:** 3 services explicitly configured for GPU access:
   - jupyter
   - ollama (enhanced)
   - llamacpp (optional)

5. **Security Focus:** `/sec/hardening.nix` is the most service-dense file with 3+ services/enhancements and timer

6. **Optional Services:** gpu-monitor-daemon is commented out, suggesting it's experimental or conditional

7. **Monitoring:** Prometheus and Grafana already in `modules/services/default.nix` for infrastructure monitoring

---

## Recommendations

1. **Immediately Centralize:**
   - [ ] Move all service definitions to `modules/services/`
   - [ ] Create subdirectories for logical grouping (ml/, security/, development/)

2. **Standardize:**
   - [ ] Create consistent service templates
   - [ ] Document all GPU-requiring services
   - [ ] Standardize logging paths

3. **Enhance:**
   - [ ] Add health checks for critical services
   - [ ] Implement service interdependencies
   - [ ] Add service monitoring/alerting

4. **Document:**
   - [ ] Create README for each service module
   - [ ] Document all configuration options
   - [ ] Add troubleshooting guides

---

**End of Report**
