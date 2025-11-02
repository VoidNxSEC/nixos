# NixOS Services Migration & Centralization Plan

## Executive Summary

This document outlines the migration strategy for centralizing all systemd services into `modules/services/` for better organization, maintainability, and security.

---

## Current State Analysis

### Services Distribution (Before Migration)

| Service | Current Location | Lines | Type |
|---------|-----------------|-------|------|
| llamacpp | `/etc/nixos/modules/ml/llama.nix` | 163-200 | System service |
| docker-pull-images | `/etc/nixos/modules/system/services.nix` | 10-22 | Oneshot service |
| ollama (hardening) | `/etc/nixos/modules/system/services.nix` | 24-34 | Service config |
| jupyter | `/etc/nixos/modules/development/jupyter.nix` | 124-145 | User service |
| setup-system-credentials | `/etc/nixos/sec/hardening.nix` | 140-148 | Oneshot service |
| clamav-scan | `/etc/nixos/sec/hardening.nix` | 161-182 | Oneshot service |
| clamav-scan (timer) | `/etc/nixos/sec/hardening.nix` | 184-192 | Timer |
| prometheus | `/etc/nixos/modules/services/default.nix` | 10-25 | Monitoring |
| grafana | `/etc/nixos/modules/services/default.nix` | 27-35 | Visualization |

**Total: 9 primary services + 3 service enhancements + 1 timer**

---

## Target Structure

```
/etc/nixos/modules/services/
├── default.nix              # Main orchestrator with imports
├── users/                   # Service users management
│   ├── default.nix
│   └── claude-code.nix     # ✓ CREATED
├── ml/                      # Machine Learning services
│   ├── llama.nix           # llamacpp service (MIGRATE)
│   ├── ollama.nix          # ollama hardening (MIGRATE)
│   └── ollama-gpu-manager.nix  # ✓ CREATED
├── containers/              # Container-related services
│   └── docker.nix          # docker-pull-images (MIGRATE)
├── development/             # Development services
│   └── jupyter.nix         # jupyter service (MIGRATE)
├── monitoring/              # Monitoring services
│   ├── prometheus.nix      # MIGRATE from services/default.nix
│   └── grafana.nix         # MIGRATE from services/default.nix
├── security/                # Security services
│   ├── clamav.nix          # MIGRATE from sec/hardening.nix
│   ├── credentials.nix     # MIGRATE from sec/hardening.nix
│   └── sshd-hardening.nix  # EXTRACT from sec/hardening.nix
└── scripts.nix              # ✓ EXISTS (utility scripts)
```

---

## Migration Strategy

### Phase 1: Create Directory Structure ✓
```bash
mkdir -p modules/services/{users,ml,containers,development,monitoring,security}
```

### Phase 2: Create New Service Modules
**Priority: HIGH - Move services to appropriate directories**

#### 2.1 ML Services
```nix
# modules/services/ml/llama.nix
- Extract from modules/ml/llama.nix (lines 163-200)
- Add enable option: kernelcore.services.ml.llama.enable
- Keep model configuration in original location

# modules/services/ml/ollama.nix
- Extract from modules/system/services.nix (lines 24-34)
- Add enable option: kernelcore.services.ml.ollama.enable
- Merge with ollama-gpu-manager.nix for unified management
```

#### 2.2 Container Services
```nix
# modules/services/containers/docker.nix
- Extract docker-pull-images from modules/system/services.nix (lines 10-22)
- Add enable option: kernelcore.services.containers.docker-pull.enable
- Make image list configurable
```

#### 2.3 Development Services
```nix
# modules/services/development/jupyter.nix
- Extract from modules/development/jupyter.nix (lines 124-145)
- Add enable option: kernelcore.services.development.jupyter.enable
- Keep development tools configuration separate
```

#### 2.4 Monitoring Services
```nix
# modules/services/monitoring/prometheus.nix
- Extract from modules/services/default.nix (lines 10-25)
- Add enable option: kernelcore.services.monitoring.prometheus.enable

# modules/services/monitoring/grafana.nix
- Extract from modules/services/default.nix (lines 27-35)
- Add enable option: kernelcore.services.monitoring.grafana.enable
```

#### 2.5 Security Services
```nix
# modules/services/security/clamav.nix
- Extract from sec/hardening.nix (lines 150-192)
- Add enable option: kernelcore.services.security.clamav.enable
- Include both daemon and scan services

# modules/services/security/credentials.nix
- Extract from sec/hardening.nix (lines 140-148)
- Add enable option: kernelcore.services.security.credentials.enable

# modules/services/security/sshd-hardening.nix
- Extract sshd serviceConfig from sec/hardening.nix (lines 234-252)
- Add enable option: kernelcore.services.security.sshd-hardening.enable
```

### Phase 3: Update Imports
Update `/etc/nixos/modules/services/default.nix`:
```nix
{
  imports = [
    ./users
    ./ml/llama.nix
    ./ml/ollama.nix
    ./ml/ollama-gpu-manager.nix
    ./containers/docker.nix
    ./development/jupyter.nix
    ./monitoring/prometheus.nix
    ./monitoring/grafana.nix
    ./security/clamav.nix
    ./security/credentials.nix
    ./security/sshd-hardening.nix
    ./scripts.nix
  ];
}
```

### Phase 4: Update Original Files
Remove migrated services and add redirects:
```nix
# In modules/ml/llama.nix
imports = [ ../services/ml/llama.nix ];

# In modules/system/services.nix - DEPRECATE or redirect
imports = [
  ../services/ml/ollama.nix
  ../services/containers/docker.nix
];
```

### Phase 5: Update Configuration
Modify `/etc/nixos/hosts/kernelcore/configuration.nix` to use new options:
```nix
kernelcore.services = {
  ml = {
    llama.enable = true;
    ollama.enable = true;
    ollama-gpu-manager.enable = true;
  };
  containers.docker-pull.enable = true;
  development.jupyter.enable = true;
  monitoring = {
    prometheus.enable = true;
    grafana.enable = true;
  };
  security = {
    clamav.enable = true;
    credentials.enable = true;
    sshd-hardening.enable = true;
  };
  users.claude-code.enable = true;
};
```

---

## Benefits

1. **Organization**: All services in one logical location
2. **Discoverability**: Easy to find and understand service structure
3. **Maintainability**: Easier to update and modify services
4. **Consistency**: Uniform enable/disable pattern across all services
5. **Security**: Centralized security policies and auditing
6. **Documentation**: Self-documenting structure

---

## Rollback Plan

If issues arise:
1. Revert to previous NixOS generation: `sudo nixos-rebuild switch --rollback`
2. Services remain functional in original locations until fully tested
3. Gradual migration allows testing per-service

---

## Testing Checklist

- [ ] Test each migrated service individually
- [ ] Verify service dependencies are maintained
- [ ] Check journalctl for service errors
- [ ] Validate systemd service status
- [ ] Ensure GPU services have correct device permissions
- [ ] Test enable/disable toggles
- [ ] Verify services start on boot
- [ ] Check resource limits and hardening

---

## Implementation Timeline

- **Week 1**: Create directory structure and module templates
- **Week 2**: Migrate ML and container services
- **Week 3**: Migrate development and monitoring services
- **Week 4**: Migrate security services and test
- **Week 5**: Update documentation and finalize

---

## Dependencies Resolution

### Port Conflicts (RESOLVED)
- llama.cpp: `127.0.0.1:8080` ✓
- ollama: `127.0.0.1:11434` ✓
- **No conflicts detected**

### GPU Access Conflicts
- All GPU services use consistent group-based access (`video`, `nvidia`)
- No device conflicts detected
- Ollama GPU auto-offload implemented

---

## Post-Migration Validation

```bash
# Check all services status
systemctl list-units "*.service" | grep -E "(llama|ollama|jupyter|docker|clamav|prometheus|grafana)"

# Verify service dependencies
systemctl list-dependencies multi-user.target | grep -E "(llama|ollama|jupyter)"

# Check for failed services
systemctl --failed

# Monitor logs
journalctl -f -u llamacpp -u ollama -u jupyter -u clamav-daemon
```

---

## Notes

- **Backwards compatibility**: Keep old service definitions as aliases during transition
- **No breaking changes**: Existing configurations continue to work
- **Gradual migration**: Test each service before moving to next
- **Documentation**: Update all references to old paths

---

**Status**: 📋 PLANNED - Ready for implementation
**Created**: 2025-10-21
**Last Updated**: 2025-10-21
