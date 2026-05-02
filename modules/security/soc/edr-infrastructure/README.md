# EDR Infrastructure

**Status:** 🚧 In-Progress (Pending Development)
**Location:** `/etc/nixos/modules/soc/edr-infrastructure/`

This module contains the infrastructure architecture for a custom Endpoint Detection and Response (EDR) system for NixOS.

> **Note:** This is a separate infrastructure project from the functional EDR modules in `/etc/nixos/modules/soc/edr/`.

> **Note:** The original documentation/reference for this project is available as a PDF in the **Downloads** directory.

## 📝 TODO: Pending Tasks

- [ ] **Core Implementation:**
    - [ ] Implement `modules/edr/agent.nix` (process monitoring, log forwarding).
    - [ ] Implement `modules/edr/server.nix` (centralized management & rule distribution).
    - [ ] Implementation of the Detection Engine in `modules/edr/detection.nix`.
    - [ ] Configure the Alerting System (Webhooks/Slack/Email).
- [ ] **Hardening:**
    - [ ] Define AppArmor profiles for critical system components.
    - [ ] Implement Seccomp filters for restricted services.
- [ ] **Rules:**
    - [ ] Port/Add Sigma rules for Linux attack patterns.
    - [ ] Add YARA rules for memory/file scanning.
    - [ ] Define Osquery scheduled queries.
- [ ] **Integration:**
    - [ ] Set up SOPS for secret management in `secrets/secrets.yaml`.
    - [ ] Configure example hosts in `hosts/`.
- [ ] **Upstream Contributions:**
    - [ ] Submit PR to `gemini-cli`: Implement session history navigation (similar to Anthropic's CLI).

---
*Created on 2026-01-05*
