# Security Operations Center (SOC) Modules

This directory contains NixOS modules for Security Operations Center infrastructure and tooling.

## 📁 Structure

### Core EDR & Detection
- **`edr/`** - Endpoint Detection & Response (Production)
  - `edr.nix` - EDR configuration with process monitoring, network tracking
  - `fim.nix` - File Integrity Monitoring (FIM)

- **`edr-infrastructure/`** - EDR Infrastructure Project (In Development)
  - Standalone EDR server/agent architecture
  - Detection engine, alerting, hardening profiles
  - See `edr-infrastructure/README.md` for TODO list

### Network Security
- **`ids/`** - Intrusion Detection System
  - Suricata/Snort configuration

- **`network/`** - Network monitoring and analysis
  - Traffic analysis, anomaly detection

### Logging & Analytics
- **`siem/`** - Security Information and Event Management
  - Log aggregation and correlation

- **`alerting/`** - Alert management and routing
  - Webhooks, Slack, email notifications

### Visualization & Integration
- **`dashboards/`** - Security dashboards
  - Grafana, Kibana configurations

- **`anduril/`** - Anduril integration
  - Enterprise security platform integration

## 🔧 Usage

Import the SOC module in your configuration:

```nix
{
  imports = [
    ./modules/soc
  ];

  kernelcore.soc = {
    enable = true;
    profile = "enterprise";  # or "basic"

    edr.enable = true;
    ids.enable = true;
    siem.enable = true;
  };
}
```

## 📊 Module Overview

| Module | Status | Description |
|--------|--------|-------------|
| `edr/` | ✅ Production | Process monitoring, network tracking, FIM |
| `edr-infrastructure/` | 🚧 Development | Infrastructure project for distributed EDR |
| `ids/` | ✅ Production | Intrusion detection with Suricata |
| `siem/` | ✅ Production | Log aggregation and correlation |
| `network/` | ✅ Production | Network monitoring |
| `alerting/` | ✅ Production | Alert routing and management |
| `dashboards/` | ✅ Production | Security visualization |
| `anduril/` | 🚧 Integration | Enterprise platform integration |

## 🔗 Related Modules

- `/etc/nixos/modules/security/` - System hardening and security policies
- `/etc/nixos/modules/network/` - Network configuration
- `/etc/nixos/modules/virtualization/` - VM and container security

---

**Maintained by:** kernelcore
**Last updated:** 2026-01-10
