# Security Hardening Guide
tags: [security, hardening, nixos, best-practices]

Essential security hardening practices for NixOS systems with GPU and AI workloads.

## Quick Reference

### Critical Configurations

**SSH Hardening**:
- Root login: DISABLED (`PermitRootLogin = "no"`)
- Password auth: DISABLED (`PasswordAuthentication = false`)
- Max auth tries: 3
- Strong ciphers: chacha20-poly1305, aes256-gcm

**Kernel Protection**:
```nix
boot.kernelParams = [
  "lockdown=confidentiality"
  "init_on_alloc=1"
  "init_on_free=1"
  "pti=on"
  "module.sig_enforce=1"
];
```

**Firewall Rules**:
- Default: SSH only (port 22)
- Services: Bind to localhost (127.0.0.1)
- Docker: Remove trustedInterfaces bypass

### GPU Access Control

**Restrict GPU Devices**:
```nix
services.udev.extraRules = ''
  KERNEL=="nvidia[0-9]*", GROUP="nvidia", MODE="0660"
  KERNEL=="nvidiactl", GROUP="nvidia", MODE="0660"
'';

users.groups.nvidia = {};
```

**Service GPU Access**:
```nix
systemd.services.myservice.serviceConfig = {
  DeviceAllow = [
    "/dev/nvidia0 rw"
    "/dev/nvidiactl rw"
  ];
  SupplementaryGroups = [ "nvidia" ];
};
```

## Secrets Management

**CRITICAL**: Never commit plaintext secrets!

**Setup SOPS**:
```bash
# Generate AGE key
age-keygen -o ~/.config/sops/age/keys.txt

# Configure .sops.yaml
cat > .sops.yaml <<EOF
keys:
  - &admin age1...
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age: [*admin]
EOF

# Encrypt secrets
sops secrets/api.yaml
```

## Network Security

**Nix Sandbox**:
```nix
nix.settings = {
  sandbox = true;
  sandbox-fallback = false;  # No bypass!
  restrict-eval = true;
};
```

**Service Isolation**:
```nix
systemd.services.myservice.serviceConfig = {
  PrivateTmp = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  NoNewPrivileges = true;
  RestrictNamespaces = true;
};
```

## Monitoring & Auditing

**GPU Access Audit**:
```nix
security.audit.rules = [
  "-w /dev/nvidia0 -p rwa -k gpu_access"
];
```

**Check Logs**:
```bash
sudo ausearch -k gpu_access
sudo journalctl -u myservice --no-pager
```

## Quick Checks

```bash
# Firewall status
sudo iptables -L INPUT -n -v | grep ACCEPT

# Service bindings
ss -tlnp | grep -E "11434|8888|5432"

# Nix sandbox
nix show-config | grep sandbox

# GPU permissions
ls -l /dev/nvidia*
```

## Common Pitfalls

1. **Firewall bypass**: Remove `trustedInterfaces = [ "docker0" ]`
2. **Global GPU exposure**: Don't set `CUDA_VISIBLE_DEVICES` globally
3. **Sandbox fallback**: Set `sandbox-fallback = false`
4. **Plaintext secrets**: Use SOPS for all sensitive data

## Reference

- Full audit: `/etc/nixos/docs/SECURITY-HARDENING-STATUS.md`
- SSH config: `/etc/nixos/modules/security/ssh.nix`
- Kernel hardening: `/etc/nixos/modules/security/kernel.nix`