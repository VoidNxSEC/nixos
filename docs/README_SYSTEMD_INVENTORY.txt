================================================================================
                    SYSTEMD SERVICES INVENTORY - README
                             Quick Start Guide
================================================================================

SEARCH COMPLETED: October 21, 2025
REPOSITORY: /etc/nixos
TASK: Comprehensive inventory of all systemd services for centralization

================================================================================
DOCUMENTATION FILES CREATED
================================================================================

All files are located in: /etc/nixos/

1. SYSTEMD_SERVICES_INVENTORY.md
   - Full comprehensive analysis (13.3 KB)
   - 50+ detailed sections
   - Service definitions with line numbers
   - Dependency graphs
   - Security analysis
   - Migration checklist
   - START HERE for complete technical details

2. SYSTEMD_SERVICES_SUMMARY.txt
   - Quick one-page reference (9.5 KB)
   - Services at a glance
   - File locations
   - Statistics
   - START HERE for quick overview

3. SYSTEMD_CENTRALIZATION_INDEX.md
   - Navigation guide (6.8 KB)
   - File location tables
   - Recommended structure
   - Usage instructions
   - START HERE for navigation

4. SERVICES_VISUAL_MAP.txt
   - ASCII diagrams and flowcharts (14.1 KB)
   - Service distribution maps
   - Dependency flow diagrams
   - GPU services visualization
   - Security hardening levels
   - START HERE for visual reference

5. README_SYSTEMD_INVENTORY.txt
   - This file (quick start guide)

================================================================================
HOW TO USE THESE DOCUMENTS
================================================================================

To get started:
  1. Read SYSTEMD_SERVICES_SUMMARY.txt (2 min)
  2. Review SERVICES_VISUAL_MAP.txt (3 min)
  3. Consult SYSTEMD_CENTRALIZATION_INDEX.md (5 min)
  4. Dive into SYSTEMD_SERVICES_INVENTORY.md (30+ min)

By file type:

TECHNICAL DETAILS:
  → SYSTEMD_SERVICES_INVENTORY.md

QUICK REFERENCE:
  → SYSTEMD_SERVICES_SUMMARY.txt

NAVIGATION:
  → SYSTEMD_CENTRALIZATION_INDEX.md

VISUAL OVERVIEW:
  → SERVICES_VISUAL_MAP.txt

================================================================================
INVENTORY SNAPSHOT
================================================================================

TOTAL SERVICES FOUND:        7 primary + 2 enhancements
TIMERS:                      1 (clamav-scan weekly)
TMPFILES RULES:              3 (directories/symlinks)
OPTIONAL SERVICES:           1 (gpu-monitor-daemon - commented)
FILES CONTAINING DEFINITIONS: 9

PRIMARY SERVICES:
  1. llamacpp                   (ML/AI - /etc/nixos/modules/ml/llama.nix)
  2. docker-pull-images         (Docker - /etc/nixos/modules/system/services.nix)
  3. jupyter                    (Development - /etc/nixos/modules/development/jupyter.nix)
  4. setup-system-credentials   (Security - /etc/nixos/sec/hardening.nix)
  5. clamav-scan                (Security - /etc/nixos/sec/hardening.nix)
  6. Prometheus                 (Monitoring - /etc/nixos/modules/services/default.nix)
  7. Grafana                    (Monitoring - /etc/nixos/modules/services/default.nix)

SERVICE ENHANCEMENTS:
  1. ollama (GPU config)        (/etc/nixos/modules/system/services.nix)
  2. sshd (hardening)           (/etc/nixos/sec/hardening.nix)
  3. clamav-daemon (hardening)  (/etc/nixos/sec/hardening.nix)

GPU-ENABLED SERVICES:
  - llamacpp         (optional layers)
  - jupyter          (explicit /dev/nvidia0 access)
  - ollama (enhanced)(explicit /dev/nvidia0 access)

================================================================================
FILES CONTAINING SYSTEMD DEFINITIONS
================================================================================

1. /etc/nixos/modules/ml/llama.nix
   - llamacpp service (lines 163-200)

2. /etc/nixos/modules/system/services.nix
   - docker-pull-images service (lines 10-22)
   - ollama enhancement (lines 24-34)

3. /etc/nixos/modules/development/jupyter.nix
   - jupyter user service (lines 124-145)

4. /etc/nixos/modules/services/default.nix
   - Prometheus service
   - Grafana service

5. /etc/nixos/sec/hardening.nix
   - setup-system-credentials service (lines 140-148)
   - clamav-scan service (lines 161-182)
   - clamav-scan timer (lines 184-192)
   - sshd enhancement (lines 234-252)
   - clamav-daemon enhancement (lines 254-262)
   - ClamAV log tmpfile (line 158)

6. /etc/nixos/modules/hardware/nvidia.nix
   - CUDA cache tmpfiles (lines 69-71)

7. /etc/nixos/modules/virtualization/vms.nix
   - VM shared directory tmpfile (line 69)

8. /etc/nixos/modules/shell/default.nix
   - gpu-monitor-daemon (commented, lines 186-194)

9. /etc/nixos/modules/security/hardening.nix
   - No systemd definitions

================================================================================
RECOMMENDED CENTRALIZATION STRUCTURE
================================================================================

After centralization, services will be organized as:

/etc/nixos/modules/services/
├── default.nix                    # Main orchestrator
├── docker.nix                     # Docker services
├── ml/
│   └── llama.nix                  # LLM services
├── security/
│   ├── hardening.nix              # Security base
│   ├── clamav.nix                 # ClamAV services
│   └── sshd.nix                   # SSH hardening
├── development/
│   └── jupyter.nix                # Jupyter service
└── system/
    └── init.nix                   # System initialization

================================================================================
NEXT STEPS
================================================================================

Phase 1: Assessment (COMPLETED)
  ✓ Identified all systemd definitions
  ✓ Documented locations and purposes
  ✓ Created inventory reports

Phase 2: Module Creation (READY TO BEGIN)
  [ ] Create new modules/services/ subdirectories
  [ ] Extract services into category-specific modules
  [ ] Create new orchestrator default.nix

Phase 3: Integration (PENDING)
  [ ] Update flake.nix imports
  [ ] Test all services
  [ ] Verify dependencies

Phase 4: Cleanup (PENDING)
  [ ] Remove service definitions from original files
  [ ] Verify no orphaned references

Phase 5: Validation (PENDING)
  [ ] Run: nixos-rebuild switch
  [ ] Check: systemctl status servicename
  [ ] Review: journalctl logs

================================================================================
KEY FINDINGS
================================================================================

HIGHEST SERVICE DENSITY:
  /etc/nixos/sec/hardening.nix (3 services + 2 enhancements + 1 timer)

CRITICAL SERVICES:
  - clamav-scan (weekly antivirus)
  - clamav-daemon (runtime protection)
  - sshd (SSH hardening)

GPU SERVICES:
  - 43% of services have GPU support or access
  - Access controlled via 'nvidia' group
  - Device allowlists defined per service

AUTO-RESTART POLICIES:
  - llamacpp: always (production)
  - jupyter: on-failure (development)
  - Others: oneshot or no restart

SECURITY LEVELS:
  Level 1 (Minimal):    1 service
  Level 2 (Basic):      2 services
  Level 3 (Hardened):   1 service
  Level 4 (Maximum):    2 services

================================================================================
COMMANDS TO CHECK SERVICES
================================================================================

List all services:
  systemctl list-units --type=service --all

List all timers:
  systemctl list-timers

Check specific service:
  systemctl status llamacpp
  systemctl status jupyter@user
  systemctl status clamav-daemon

View service logs:
  journalctl -u llamacpp -n 50
  journalctl -u jupyter -n 50

Run a single service:
  systemctl start llamacpp
  systemctl restart clamav-scan

Check timer status:
  systemctl status clamav-scan.timer
  systemctl list-timers clamav-scan*

================================================================================
SECURITY CONSIDERATIONS
================================================================================

GPU Access:
  - Controlled via 'nvidia' group membership
  - Each service has explicit DeviceAllow rules
  - Udev rules configure device permissions

Hardening:
  - jupyter: PrivateTmp, ProtectSystem strict, NoNewPrivileges
  - sshd: SystemCallFilter, CapabilityBoundingSet
  - clamav: Low priority (nice=19), idle IO

Credentials:
  - Stored in /etc/credstore (700 permissions)
  - LoadCredential for jupyter-token
  - Separate from main configuration

================================================================================
DEPENDENCIES MAP
================================================================================

Startup order:
  multi-user.target
    ├─ network.target
    │   ├─ llamacpp
    │   ├─ jupyter
    │   └─ setup-system-credentials
    ├─ docker.service
    │   └─ docker-pull-images
    └─ timers.target
        └─ clamav-scan.timer -> clamav-scan service

Services with dependencies:
  - jupyter: requires setup-system-credentials, network.target
  - docker-pull-images: requires docker.service, multi-user.target
  - clamav-scan: triggered by clamav-scan.timer

================================================================================
TROUBLESHOOTING
================================================================================

If a service fails to start:
  journalctl -xe

To check service configuration:
  systemctl cat servicename

To edit service runtime settings:
  systemctl edit servicename

To reset a service:
  systemctl reset-failed servicename

To see what a timer will run:
  systemctl list-timers --all
  systemctl status clamav-scan.timer

================================================================================
SUPPORT & NEXT ACTIONS
================================================================================

For more information:
  1. See SYSTEMD_SERVICES_INVENTORY.md for comprehensive guide
  2. See SYSTEMD_CENTRALIZATION_INDEX.md for navigation
  3. See SERVICES_VISUAL_MAP.txt for visual diagrams

To begin centralization:
  1. Review all documentation
  2. Create new modules/services/ subdirectories
  3. Extract services into category modules
  4. Test with: nixos-rebuild switch

For security hardening validation:
  - Review /etc/udev/rules.d/ for GPU access
  - Check /etc/credstore permissions
  - Verify service isolation with: systemd-analyze security servicename

================================================================================
DOCUMENT METADATA
================================================================================

Generated:     October 21, 2025
Repository:    /etc/nixos
Status:        Complete (Phase 1)
Files Created: 5 documentation files (~44 KB total)
Service Count: 7 primary + 2 enhancements + 1 timer
Next Phase:    Module creation and centralization

================================================================================
END OF README
================================================================================

For questions or issues, refer to:
  - SYSTEMD_SERVICES_INVENTORY.md (comprehensive)
  - SYSTEMD_SERVICES_SUMMARY.txt (quick ref)
  - SERVICES_VISUAL_MAP.txt (diagrams)

