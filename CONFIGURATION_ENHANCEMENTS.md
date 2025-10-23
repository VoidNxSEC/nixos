# NixOS Configuration Enhancements
## Applied Changes to hosts/kernelcore/configuration.nix

**Date**: 2025-10-21
**Based On**: Security & Functionality Audit Report
**Status**: ⚠️ CHANGES APPLIED - REQUIRES `nix flake check` VALIDATION

---

## SUMMARY OF CHANGES

### Total Custom Options Before: 20/76 (26.3%)
### Total Custom Options After: 33/76 (43.4%)

**Net Increase**: +13 options enabled (+17.1% coverage)

---

## HIGH PRIORITY SECURITY ENHANCEMENTS

### 1. File Integrity Monitoring (AIDE)
**Module**: `/etc/nixos/modules/security/aide.nix`

```nix
kernelcore.security.aide.enable = true;
```

**Purpose**: Advanced Intrusion Detection Environment
- Monitors critical system files for unauthorized modifications
- Creates cryptographic checksums of system binaries
- Runs daily integrity checks via systemd timer
- Alerts on file tampering, rootkits, or unauthorized changes

**Default Configuration**:
- Database: `/var/lib/aide/aide.db`
- Check Schedule: Daily
- Monitors: `/bin`, `/sbin`, `/lib`, `/usr`, `/etc`

**Action Required After Rebuild**:
```bash
# Initialize AIDE database (first time only)
sudo aide --init
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Manual integrity check
sudo aide --check
```

---

### 2. Antivirus Scanning (ClamAV)
**Module**: `/etc/nixos/modules/security/clamav.nix`

```nix
kernelcore.security.clamav.enable = true;
```

**Purpose**: Open-source antivirus engine
- Scans for malware, trojans, and malicious code
- Automatic virus definition updates
- Integrates with system file monitoring

**Default Configuration**:
- Daemon: `clamd` running on localhost
- Database updates: Automatic via `freshclam`
- Scanner: `clamdscan` available for manual scans

**Action Required After Rebuild**:
```bash
# Update virus definitions
sudo freshclam

# Scan specific directory
sudo clamdscan -r /home/kernelcore/Downloads

# Scan with infection removal
sudo clamdscan -r --remove /path/to/scan
```

---

### 3. Enhanced SSH Security Hardening
**Module**: `/etc/nixos/modules/security/ssh.nix`

```nix
kernelcore.security.ssh.enable = true;
```

**Purpose**: Hardens SSH daemon configuration beyond basic settings
- Stronger key exchange algorithms
- Modern ciphers and MACs only
- Connection rate limiting
- Fail2ban integration (if available)

**Note**: This replaces/enhances your manual SSH config at `configuration.nix:103-109`

**Current Manual Config**:
```nix
services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };
};
```

**Enhanced by Module**:
- KexAlgorithms: curve25519-sha256@libssh.org
- Ciphers: chacha20-poly1305@openssh.com, aes256-gcm@openssh.com
- MACs: hmac-sha2-512-etm@openssh.com
- MaxAuthTries: 3
- ClientAliveInterval: 300
- Compression: no (prevents attacks)

---

### 4. Kernel Security Hardening
**Module**: `/etc/nixos/modules/security/kernel.nix`

```nix
kernelcore.security.kernel.enable = true;
```

**Purpose**: System-level kernel security enhancements
- Sysctl hardening parameters
- Kernel module blacklisting (unused protocols/filesystems)
- Address Space Layout Randomization (ASLR)
- Kernel pointer protection

**Sysctl Parameters Applied**:
```
kernel.kptr_restrict = 2          # Hide kernel pointers
kernel.dmesg_restrict = 1         # Restrict dmesg access
kernel.unprivileged_bpf_disabled = 1
net.ipv4.conf.all.rp_filter = 1   # Reverse path filtering
net.ipv4.tcp_syncookies = 1       # SYN flood protection
net.ipv6.conf.all.accept_ra = 0   # Disable router advertisements
```

**Blacklisted Modules**:
- Uncommon filesystems (cramfs, freevxfs, jffs2, hfs, hfsplus, udf)
- Uncommon network protocols (dccp, sctp, rds, tipc)

---

### 5. PAM Security Hardening
**Module**: `/etc/nixos/modules/security/pam.nix`

```nix
kernelcore.security.pam.enable = true;
```

**Purpose**: Pluggable Authentication Modules hardening
- Password quality enforcement
- Account lockout after failed attempts
- Session security enhancements
- Audit logging for authentication events

**Features**:
- Minimum password length enforcement
- Password complexity requirements
- Failed login attempt tracking
- Session timeout configuration

---

### 6. Security Audit Tools Installation
**Module**: `/etc/nixos/modules/security/packages.nix`

```nix
kernelcore.security.packages.enable = true;
```

**Purpose**: Installs comprehensive security monitoring and audit tools

**Packages Installed**:
- `lynis` - Security auditing tool
- `chkrootkit` - Rootkit detector
- `rkhunter` - Rootkit Hunter
- `ossec` - Host-based intrusion detection
- `nmap` - Network scanner
- `tcpdump` - Network traffic analyzer
- `wireshark-cli` - Packet analysis
- `netcat` - Network utility
- `socat` - Advanced netcat

**Usage Examples**:
```bash
# System security audit
sudo lynis audit system

# Rootkit check
sudo chkrootkit
sudo rkhunter --check

# Network security scan
sudo nmap -sV -O localhost
```

---

## MEDIUM PRIORITY FUNCTIONALITY ENHANCEMENTS

### 7. Jupyter Nix Kernel
**Module**: `/etc/nixos/modules/development/jupyter.nix`

```nix
kernelcore.development.jupyter.kernels.nix.enable = true;
```

**Purpose**: Adds Nix language kernel to Jupyter notebooks
- Write and execute Nix code in notebooks
- Experiment with Nix expressions interactively
- Document NixOS configurations

---

### 8. CI/CD Development Tools
**Module**: `/etc/nixos/modules/development/cicd.nix`

```nix
kernelcore.development.cicd = {
  enable = true;
  platforms = {
    github = true;   # GitHub CLI (gh)
    gitlab = true;   # GitLab CLI (glab)
    gitea = true;    # Gitea CLI (tea)
  };
  pre-commit = {
    enable = true;
    formatCode = true;
    runTests = false;
  };
};
```

**Purpose**: Comprehensive CI/CD tooling for development workflow

**Tools Installed**:
- `gh` - GitHub CLI (already in user packages, now via module)
- `glab` - GitLab CLI (NEW)
- `tea` - Gitea CLI (NEW)
- `act` - Run GitHub Actions locally (NEW)
- `pre-commit` - Git hooks framework (NEW)

**Pre-commit Hooks Configured**:
- **formatCode: true** - Auto-format code before commits (nix fmt, prettier, etc.)
- **runTests: false** - Disabled by default (enable when you have test suite)

**Usage Examples**:
```bash
# GitHub operations
gh pr create --title "Feature X" --body "Description"
gh issue list

# GitLab operations
glab mr create --title "Feature X"
glab ci status

# Gitea operations (local git server)
tea login add
tea issues list

# Run GitHub Actions locally
act -l  # List workflows
act push  # Run push workflow locally

# Pre-commit
pre-commit install  # Install hooks in repo
pre-commit run --all-files  # Run all hooks manually
```

---

### 9. SOPS Secrets Management
**Module**: `/etc/nixos/modules/secrets/sops-config.nix`

```nix
kernelcore.secrets.sops = {
  enable = true;
  secretsPath = "/etc/nixos/secrets";
  ageKeyFile = "/var/lib/sops-nix/key.txt";
};
```

**Purpose**: Standardized secrets management using SOPS (Secrets OPerationS)
- Encrypt secrets in Git repository
- Decrypt at build/runtime
- AGE encryption (modern, simple alternative to GPG)

**Current Secret**: `/etc/nixos/sec/user-password` (hashedPasswordFile)

**Migration Path**:
1. Generate AGE key (after rebuild):
```bash
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
```

2. Create `.sops.yaml` in `/etc/nixos`:
```yaml
keys:
  - &admin age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *admin
```

3. Encrypt secrets:
```bash
sops secrets/user-password.yaml
sops secrets/vpn/nordvpn-credentials.yaml
sops secrets/github-runner-token.yaml
```

4. Reference in configuration:
```nix
sops.secrets.user-password = {
  sopsFile = ./secrets/user-password.yaml;
};

users.users.kernelcore.hashedPasswordFile = config.sops.secrets.user-password.path;
```

---

### 10. ML Models Storage Standardization
**Module**: `/etc/nixos/modules/ml/models-storage.nix`

```nix
kernelcore.ml.models-storage = {
  enable = true;
  baseDirectory = "/var/lib/ml-models";
};
```

**Purpose**: Centralized, standardized storage for all ML models

**Current ML Services**:
- LlamaCPP: `/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf`
- Ollama: Default storage

**Proposed Structure** (after migration):
```
/var/lib/ml-models/
├── llamacpp/
│   ├── llama3/
│   │   └── L3-8B-Stheno-v3.2-Q4_K_S.gguf
│   └── mistral/
├── ollama/
│   ├── llama3:8b/
│   └── codellama:13b/
├── stable-diffusion/
└── whisper/
```

**Migration Steps**:
1. After rebuild, directory will be created with proper permissions
2. Manually migrate existing models:
```bash
sudo mkdir -p /var/lib/ml-models/llamacpp/llama3
sudo cp /var/lib/llamacpp/models/*.gguf /var/lib/ml-models/llamacpp/llama3/
```

3. Update LlamaCPP config:
```nix
services.llamacpp.model = "/var/lib/ml-models/llamacpp/llama3/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
```

---

## VALIDATION CHECKLIST

### Before Rebuild:
```bash
# 1. Validate Nix configuration
cd /etc/nixos
nix flake check

# 2. Check for syntax errors
nix-instantiate --eval --strict flake.nix

# 3. Backup current generation
sudo nixos-rebuild list-generations
```

### After Successful Rebuild:
```bash
# 1. Check systemd services
sudo systemctl status aide.timer
sudo systemctl status clamav-daemon
sudo systemctl status clamav-freshclam

# 2. Verify security tools
which lynis chkrootkit rkhunter

# 3. Check CI/CD tools
which gh glab tea act pre-commit

# 4. Verify AIDE initialization
sudo aide --check

# 5. Update ClamAV definitions
sudo freshclam

# 6. Run security audit
sudo lynis audit system
```

### Potential Issues:

1. **AIDE Database Not Initialized**:
   - Symptom: `aide --check` fails with "database not found"
   - Fix: `sudo aide --init && sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db`

2. **ClamAV Signature Database Old**:
   - Symptom: `freshclam` warnings about outdated database
   - Fix: `sudo freshclam` (may take several minutes)

3. **SOPS Key Missing**:
   - Symptom: Build fails with "age key not found"
   - Fix: Disable `secrets.sops.enable = false;` temporarily, rebuild, then generate key

4. **Pre-commit Hooks Conflict**:
   - Symptom: Git commits failing due to hook errors
   - Fix: `pre-commit uninstall` in problematic repos, configure per-repo

5. **SSH Connection Issues**:
   - Symptom: Can't connect via SSH after rebuild
   - Fix: Check `/var/log/auth.log`, ensure your SSH key algorithm is supported
   - Fallback: Use console/GUI login, temporarily disable `ssh.enable`

---

## ROLLBACK PROCEDURE

If rebuild fails or system becomes unstable:

```bash
# List available generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
# (Available at boot time)
```

---

## NEXT STEPS

### Immediate (Post-Rebuild):
1. ✅ Run `nix flake check`
2. ✅ Rebuild: `sudo nixos-rebuild switch`
3. ✅ Initialize AIDE: `sudo aide --init`
4. ✅ Update ClamAV: `sudo freshclam`
5. ✅ Run security audit: `sudo lynis audit system`

### Short-term (This Week):
1. 🔐 Generate AGE key for SOPS: `sudo age-keygen -o /var/lib/sops-nix/key.txt`
2. 🔐 Create `.sops.yaml` configuration
3. 🔐 Migrate `user-password` to SOPS
4. 📦 Migrate ML models to `/var/lib/ml-models`
5. 🧪 Test pre-commit hooks in a development repository

### Long-term (Future Considerations):
1. 🔧 Enable automated tests in pre-commit: `cicd.pre-commit.runTests = true`
2. 🔒 Consider SSH 2FA: `security.ssh.enable2FA = true` (requires Google Authenticator setup)
3. 🌐 Evaluate NordVPN integration if VPN needed
4. 🤖 Evaluate dedicated Claude Code user: `services.users.claude-code.enable = true`
5. 🔄 Consider automated security updates: `security.auto-upgrade.enable = true` (with caution)

---

## SECURITY POSTURE IMPROVEMENT

### Before Enhancements:
- **Security Options Enabled**: 2/29 (6.9%)
- **Overall Coverage**: 20/76 (26.3%)
- **Grade**: D+ (Security), C+ (Overall)

### After Enhancements:
- **Security Options Enabled**: 8/29 (27.6%)
- **Overall Coverage**: 33/76 (43.4%)
- **Projected Grade**: B- (Security), B (Overall)

### Security Capabilities Added:
- ✅ File Integrity Monitoring (AIDE)
- ✅ Antivirus Scanning (ClamAV)
- ✅ Enhanced SSH Hardening
- ✅ Kernel Security Hardening
- ✅ PAM Security Hardening
- ✅ Security Audit Tools (Lynis, chkrootkit, rkhunter)

### Development Capabilities Added:
- ✅ Jupyter Nix Kernel
- ✅ CI/CD Tools (gh, glab, tea, act)
- ✅ Pre-commit Hooks Framework
- ✅ Standardized Secrets Management (SOPS)
- ✅ Standardized ML Model Storage

---

## DOCUMENTATION REFERENCES

- **AIDE**: /etc/nixos/modules/security/aide.nix
- **ClamAV**: /etc/nixos/modules/security/clamav.nix
- **SSH Hardening**: /etc/nixos/modules/security/ssh.nix
- **Kernel Hardening**: /etc/nixos/modules/security/kernel.nix
- **PAM Hardening**: /etc/nixos/modules/security/pam.nix
- **Security Packages**: /etc/nixos/modules/security/packages.nix
- **CI/CD Tools**: /etc/nixos/modules/development/cicd.nix
- **SOPS Config**: /etc/nixos/modules/secrets/sops-config.nix
- **ML Storage**: /etc/nixos/modules/ml/models-storage.nix

---

**Report Generated**: 2025-10-21
**Configuration File**: /etc/nixos/hosts/kernelcore/configuration.nix
**Changes Applied By**: Claude Code Security & Configuration Audit
