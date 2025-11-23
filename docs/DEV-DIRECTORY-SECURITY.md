# ~/dev Directory Security Hardening

> **Objetivo**: Proteger código-fonte sensível, secrets e workspaces de desenvolvimento
> **Localização**: `/home/kernelcore/dev/`
> **Nível de Segurança**: HIGH (8 camadas de proteção)

---

## 🎯 Threat Model

### Assets Protegidos
1. **Código-fonte**: Rust/TypeScript (propriedade intelectual)
2. **Secrets**: API keys, tokens, certificates
3. **Build artifacts**: Binários compilados
4. **Git credentials**: SSH keys, tokens
5. **Knowledge databases**: Dados sensíveis do MCP

### Ameaças Identificadas
| Ameaça | Probabilidade | Impacto | Mitigação |
|--------|---------------|---------|-----------|
| Acesso não autorizado | Média | Alto | Permissions 0700 + Audit |
| Vazamento de secrets | Alta | Crítico | git-crypt + SOPS |
| Ransomware | Baixa | Crítico | Backups encrypted |
| Supply chain attack | Média | Alto | File integrity (AIDE) |
| Insider threat | Baixa | Alto | Audit logging |
| Malware | Baixa | Médio | Access monitoring |

---

## 🛡️ Camadas de Proteção

### Layer 1: Filesystem Permissions ✅

**Implementação**: Strict UNIX permissions

```bash
~/dev/                    0700 kernelcore:kernelcore
├── securellm-bridge/     0700 kernelcore:kernelcore
├── ml-offload-api/       0700 kernelcore:kernelcore
└── .secrets/             0700 kernelcore:kernelcore
```

**Benefício**:
- Zero acesso para group/others
- Apenas kernelcore pode ler/escrever
- Proteção contra acesso local não autorizado

**Teste**:
```bash
# Como outro usuário:
ls ~/dev/  # Permission denied ✅

# Como kernelcore:
ls ~/dev/  # Funciona ✅
```

---

### Layer 2: Encryption at Rest (Opcional) 🔒

**Opção A: eCryptfs** (Recommended para ~/dev)

```bash
# Setup (one-time)
ecryptfs-setup-private --nopwcheck
mv ~/Private ~/dev
ecryptfs-mount-private

# Daily usage
# Auto-mount on login (via PAM)
# Auto-unmount on logout
```

**Benefícios**:
- Transparente (mount on login)
- Per-file encryption
- Proteção contra cold boot attacks
- Proteção se disco for roubado

**Opção B: LUKS** (Full disk encryption)

Se ~/dev está em partição separada:
```bash
cryptsetup luksFormat /dev/sdXY
cryptsetup open /dev/sdXY dev-encrypted
mkfs.ext4 /dev/mapper/dev-encrypted
```

**Opção C: git-crypt** (Repository-level)

Para repositories específicos:
```bash
cd ~/dev/securellm-bridge
git-crypt init
echo "config/secrets.toml filter=git-crypt diff=git-crypt" >> .gitattributes
git-crypt lock
```

---

### Layer 3: Audit Logging ✅

**Implementação**: Linux auditd

**Rules Configuradas**:
```bash
# All access (read/write/execute/attr changes)
-w /home/kernelcore/dev -p rwxa -k dev-access

# Secret access
-w /home/kernelcore/dev/.secrets -p rwxa -k dev-secrets-access

# Git operations
-w /home/kernelcore/dev -p wa -k dev-git-ops -F path~.git

# Cargo builds
-w /home/kernelcore/dev -p wa -k dev-cargo-build -F exe=/usr/bin/cargo
```

**Query Logs**:
```bash
# All dev access
sudo ausearch -k dev-access

# Secret access
sudo ausearch -k dev-secrets-access

# Today only
sudo ausearch -k dev-access -ts today

# By process
sudo ausearch -k dev-access -x /usr/bin/code
```

---

### Layer 4: File Integrity Monitoring ✅

**Implementação**: AIDE (Advanced Intrusion Detection Environment)

**Configuration**:
```
# Monitor everything in ~/dev
/home/kernelcore/dev p+i+n+u+g+s+b+m+c+md5+sha256

# Exclude noisy directories
!/home/kernelcore/dev/.*/target
!/home/kernelcore/dev/.*/node_modules
!/home/kernelcore/dev/.*/build
```

**Usage**:
```bash
# Initialize database
sudo aide --init
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Daily check (automated via timer)
sudo aide --check

# Manual check
sudo aide --check

# Update database after intentional changes
sudo aide --update
```

**Alerts on**:
- Modified files (timestamps, hashes)
- New files
- Deleted files
- Permission changes
- Ownership changes

---

### Layer 5: Automated Encrypted Backups ✅

**Implementação**: systemd timer + GPG encryption

**Schedule**: Daily (configurable: hourly/daily/weekly)

**Process**:
1. Tar ~/dev (excluding build artifacts)
2. Encrypt with GPG
3. Store in /backup/dev-backups/
4. Rotate (keep last 30)

**Backup Script**:
```bash
# Automated (daily)
sudo systemctl status dev-backup.timer

# Manual backup
sudo systemctl start dev-backup

# List backups
ls -lh /backup/dev-backups/

# Restore
gpg --decrypt /backup/dev-backups/dev-backup-20251122.tar.gz.gpg \
  | tar -xzf - -C /tmp/restore/
```

**Exclusions**:
- `*/target/` (Rust build artifacts)
- `*/node_modules/` (NPM dependencies)
- `*/build/` (Output directories)
- `*/.git/objects/` (Git objects - use git clone instead)
- `*.db`, `*.db-*` (Databases - backed up separately)

---

### Layer 6: Access Monitoring ✅

**Implementação**: Real-time audit log monitoring

**Monitora**:
- Unusual processes accessing ~/dev
- Secret directory access
- Git operations
- Build processes

**Allowed Processes** (whitelist):
```
cargo, rustc, node, npm, git, nix, nix-build, nix-shell
code, codium, nvim, vim
bash, zsh, fish
```

**Alerts**:
```bash
# Logged to journal
journalctl -t dev-security

# Example alert
"Unusual process accessing ~/dev: /usr/bin/suspicious-app"
```

**Integration**: Pode ser integrado com notificações desktop

---

### Layer 7: Git Security ✅

**Implementação**: Git credential helper + GPG signing

**Features**:

1. **Credential Caching** (1 hour timeout)
   ```bash
   GIT_CREDENTIAL_HELPER="cache --timeout=3600"
   ```

2. **GPG Commit Signing** (alias)
   ```bash
   git-dev commit -m "msg"  # Automatically GPG signed
   ```

3. **Pre-commit Secret Detection**
   ```bash
   git-commit-safe  # Checks for .env, .key, .pem files
   ```

4. **Recommended .gitignore**:
   ```
   # Secrets
   *.env
   *.key
   *.pem
   *.p12
   *.pfx
   config/secrets.toml

   # Build artifacts
   target/
   node_modules/
   build/

   # Databases
   *.db
   *.db-wal
   *.db-shm
   ```

---

### Layer 8: Emergency Response ✅

**Implementação**: Panic script

**Command**: `sudo dev-lockdown`

**Actions**:
1. Remove all permissions (chmod 000)
2. Kill all processes accessing ~/dev
3. Create emergency encrypted backup
4. Log critical security event

**Usage**:
```bash
# If suspicious activity detected
sudo dev-lockdown

# Output:
🚨 LOCKING DOWN ~/dev DIRECTORY...
✅ Lockdown complete. Emergency backup: /backup/emergency-dev-20251122.tar.gz.gpg
```

**Recovery**:
```bash
# Restore permissions
chmod -R 700 ~/dev

# Investigate
sudo ausearch -k dev-access -i
journalctl -t dev-security
```

---

## 📊 Security Metrics

### Monitoring Dashboard

```bash
# Check all security status
~/dev-security-status.sh

# Expected output:
✅ Permissions: 0700
✅ Audit logging: Active
✅ AIDE: Last check 2025-11-22 20:00
✅ Backup: Last backup 2025-11-22 19:30 (1.2GB)
✅ Access monitor: Running
⚠️ Encryption: Not enabled (optional)
```

### Weekly Security Checklist

- [ ] Review audit logs: `sudo ausearch -k dev-access -ts week`
- [ ] Check file integrity: `sudo aide --check`
- [ ] Verify backups: `ls -lh /backup/dev-backups/`
- [ ] Test restore: Restore one backup to /tmp
- [ ] Review access monitor: `journalctl -t dev-security`
- [ ] Scan for secrets: `git-secrets --scan ~/dev/`

---

## 🚀 Habilitação

### NixOS Configuration

```nix
# /etc/nixos/configuration.nix
{
  kernelcore.security.dev-directory = {
    enable = true;
    user = "kernelcore";
    path = "/home/kernelcore/dev";

    # Opções
    enableEncryption = false;  # Set true for eCryptfs
    enableAudit = true;
    enableBackup = true;
    backupInterval = "daily";  # hourly/daily/weekly

    # Processos permitidos (whitelist)
    allowedProcesses = [
      "cargo" "rustc" "node" "npm" "git" "nix"
      "code" "codium" "nvim"
      "bash" "zsh"
    ];
  };
}
```

### Rebuild

```bash
sudo nixos-rebuild switch
```

### Validação

```bash
# 1. Check permissions
ls -ld ~/dev/  # Should be drwx------ kernelcore kernelcore

# 2. Check audit
sudo ausearch -k dev-access

# 3. Check backup timer
systemctl status dev-backup.timer

# 4. Check access monitor
systemctl status dev-access-monitor

# 5. Check AIDE
sudo aide --check

# 6. Test lockdown (CAREFUL!)
# sudo dev-lockdown  # Only in emergency!
```

---

## 🔍 Incident Response

### Suspicious Activity Detected

**Scenario**: Alert "Unusual process accessing ~/dev"

**Steps**:

1. **Investigate**:
   ```bash
   # Check what happened
   sudo ausearch -k dev-access -i | tail -50

   # Identify process
   ps aux | grep [suspicious-pid]
   ```

2. **Assess**:
   - Legitimate process? (new dev tool?)
   - Malware? (unknown binary)
   - User error? (wrong user)

3. **Contain** (if malicious):
   ```bash
   # Lockdown immediately
   sudo dev-lockdown

   # Kill process
   sudo kill -9 [pid]

   # Check file integrity
   sudo aide --check
   ```

4. **Recover**:
   ```bash
   # Restore from backup if needed
   gpg --decrypt /backup/emergency-dev-*.tar.gz.gpg | tar -xzf - -C /tmp/

   # Compare with AIDE database
   sudo aide --compare
   ```

5. **Document**:
   - Save logs
   - Write incident report
   - Update allowedProcesses if false positive

---

## 📚 Best Practices

### Development Workflow

1. **Start of day**:
   ```bash
   # If encrypted, mount
   ecryptfs-mount-private

   # Verify integrity
   sudo aide --check
   ```

2. **During work**:
   ```bash
   # Use git-dev for commits (GPG signed)
   git-dev commit -m "feat: add feature"

   # Check before pushing
   git-commit-safe
   ```

3. **End of day**:
   ```bash
   # Trigger backup
   sudo systemctl start dev-backup

   # If encrypted, unmount
   ecryptfs-umount-private
   ```

### Secret Management

1. **Never commit secrets**:
   ```bash
   # Use git-crypt
   git-crypt init
   echo "*.env filter=git-crypt diff=git-crypt" >> .gitattributes
   ```

2. **Use SOPS for config**:
   ```bash
   # Encrypt config
   sops -e config/secrets.toml > config/secrets.enc.toml

   # Decrypt on use
   sops -d config/secrets.enc.toml > /tmp/secrets.toml
   ```

3. **Environment variables**:
   ```bash
   # Use .env files (gitignored)
   echo "API_KEY=secret" > .env
   echo ".env" >> .gitignore
   ```

---

## 🎓 Training & Awareness

### Common Mistakes to Avoid

❌ **Don't**:
- Commit .env files
- Share API keys in code
- Push secrets to GitHub
- Use weak file permissions
- Ignore audit alerts
- Skip backups

✅ **Do**:
- Use git-crypt/SOPS
- Review diffs before commit
- GPG sign commits
- Monitor audit logs
- Test backup restores
- Update AIDE database

---

## 📞 Support

**Documentation**: `/etc/nixos/dev-security-guide.md`
**Module**: `/etc/nixos/modules/security/dev-directory-hardening.nix`
**Logs**: `/var/log/audit/audit.log`
**Backups**: `/backup/dev-backups/`

**Commands**:
- Security status: `dev-security-status`
- Emergency: `sudo dev-lockdown`
- Audit: `sudo ausearch -k dev-access`
- Integrity: `sudo aide --check`
- Backup: `sudo systemctl start dev-backup`

---

**Status**: ✅ Production Ready
**Version**: 1.0.0
**Last Updated**: 2025-11-22
**Maintainer**: kernelcore
