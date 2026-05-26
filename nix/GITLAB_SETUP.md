# 🔐 GitLab SSH & GPG Setup for NixOS

Configuração completa para integrar chaves SSH e GPG ao GitLab em sistemas NixOS.

---

## 📋 Resumo das Chaves Geradas

### SSH Keys

| Key | Path | Purpose | Fingerprint |
|-----|------|---------|-------------|
| **GitLab** | `~/.ssh/id_ed25519_gitlab` | Dedicated GitLab access | `SHA256:ObujI4+iGKWreBk/Ki2jFM17rZL2YoyFxJ4MC1luEEc` |
| **GitHub** | `~/.ssh/id_ed25519` | Existing GitHub access | `SHA256:...` |

### GPG Keys

| Key ID | Email | Purpose | Expires |
|--------|-------|---------|---------|
| `5606AB430E95F5AD` | sec@voidnxlabs.com | Commit signing | 2026-09-29 |
| `AE2BED94191C531A` | sec@voidnx.com | Alternative | 2026-04-24 |

---

## 🚀 Quick Setup

### 1. Add SSH Key to GitLab

```bash
# Copy GitLab SSH public key to clipboard
cat ~/.ssh/id_ed25519_gitlab.pub | xclip -selection clipboard
# Or just display it
cat ~/.ssh/id_ed25519_gitlab.pub
```

**Output (add this to GitLab):**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6LqlmJqeqRDjriI9ENDlIcd09BOjL19rTJJumdV8uY cerebro-gitlab@kernelcore
```

**In GitLab:**
1. Go to https://gitlab.com/-/profile/keys
2. Click "Add new key"
3. Paste the public key
4. Title: `cerebro-nixos-workstation`
5. Expiration: Set to 1 year from now
6. Click "Add key"

### 2. Add GPG Key to GitLab

```bash
# Export your GPG public key
gpg --armor --export 5606AB430E95F5AD
```

**In GitLab:**
1. Go to https://gitlab.com/-/profile/gpg_keys
2. Click "Add new GPG key"
3. Paste the entire GPG key block (including BEGIN/END markers)
4. Click "Add key"

### 3. Test SSH Connection

```bash
# Test GitLab SSH authentication
ssh -T git@gitlab.com

# Expected output:
# Welcome to GitLab, @yourusername!
```

---

## 🔧 NixOS Integration

### Option A: System-Wide Configuration

Add to `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    /home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix
    /home/kernelcore/arch/cerebro/nix/gpg-gitlab-config.nix
  ];

  # ... rest of your config
}
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8
```

### Option B: Home Manager Configuration

Add to `~/.config/home-manager/home.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /home/kernelcore/arch/cerebro/nix/ssh-gitlab-config.nix
    /home/kernelcore/arch/cerebro/nix/gpg-gitlab-config.nix
  ];

  # ... rest of your config
}
```

Apply:
```bash
home-manager switch
```

### Option C: Per-Project (Development Shell)

Already configured in this project's `flake.nix`. Just run:

```bash
nix develop
```

---

## 🧪 Verification

### Test SSH Access

```bash
# Test GitLab
ssh -T git@gitlab.com

# Test GitHub (existing key)
ssh -T git@github.com

# Verify SSH agent is running
echo $SSH_AUTH_SOCK
ssh-add -l
```

### Test GPG Signing

```bash
# Create a test commit
cd /home/kernelcore/arch/cerebro
echo "test" > test.txt
git add test.txt
git commit -m "test: verify GPG signing"

# Verify signature
git log --show-signature -1

# Expected output:
# gpg: Signature made ...
# gpg: Good signature from "marcos (gh) <sec@voidnxlabs.com>"
```

### Test Git Operations

```bash
# Clone a GitLab repo
git clone git@gitlab.com:yourusername/test-repo.git

# Push with signed commit
cd test-repo
echo "Hello GitLab" > README.md
git add README.md
git commit -m "Initial commit"  # Auto-signed
git push origin main
```

---

## 📝 Manual Configuration (Without Nix Modules)

If you prefer manual setup:

### SSH Config (`~/.ssh/config`)

```ssh-config
# GitLab Configuration
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
  IdentitiesOnly yes
  PreferredAuthentications publickey

# GitHub Configuration
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  PreferredAuthentications publickey
```

### Git Config (`~/.gitconfig`)

```ini
[user]
    name = kernelcore
    email = sec@voidnxlabs.com
    signingkey = 5606AB430E95F5AD

[commit]
    gpgsign = true

[tag]
    gpgsign = true

[gpg]
    program = gpg

[url "git@gitlab.com:"]
    insteadOf = https://gitlab.com/
```

### GPG Agent Config (`~/.gnupg/gpg-agent.conf`)

```
enable-ssh-support
default-cache-ttl 86400
max-cache-ttl 86400
pinentry-program /run/current-system/sw/bin/pinentry-gnome3
```

Reload GPG agent:
```bash
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

---

## 🔐 Security Best Practices

### SSH Key Management

1. **Use separate keys per service** ✅ Done (GitLab vs GitHub)
2. **Set key expiration** - Recommended: 1 year
3. **Use ed25519** ✅ Done (modern, secure, fast)
4. **Protect private keys** ✅ Done (600 permissions)

### GPG Key Management

1. **Set key expiration** ✅ Done (expires 2026)
2. **Use strong passphrase** - Store in password manager
3. **Backup private keys** - Store encrypted backup offline
4. **Revocation certificate** - Generate and store securely

### Generate Revocation Certificate

```bash
# Generate revocation certificate (in case key is compromised)
gpg --output ~/.gnupg/revoke-5606AB430E95F5AD.asc \
    --gen-revoke 5606AB430E95F5AD

# Store this file securely (encrypted USB drive, password manager)
# Use it to revoke the key if needed: gpg --import revoke-*.asc
```

---

## 🐛 Troubleshooting

### SSH Agent Not Running

```bash
# Check if agent is running
pgrep ssh-agent

# If not, start manually
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519_gitlab
```

### GPG Signing Fails

```bash
# Check GPG agent
gpg-connect-agent /bye

# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Set GPG_TTY
export GPG_TTY=$(tty)

# Test signing
echo "test" | gpg --clearsign
```

### Permission Denied (GitLab)

```bash
# Verify SSH key is added
ssh-add -l | grep cerebro-gitlab

# If not listed, add it
ssh-add ~/.ssh/id_ed25519_gitlab

# Test with verbose output
ssh -vT git@gitlab.com
```

### Wrong Key Being Used

```bash
# Force specific key
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_gitlab" git clone git@gitlab.com:user/repo.git

# Or update ~/.ssh/config with IdentitiesOnly yes
```

---

## 📦 Backup Checklist

**Before making keys public, backup:**

- [ ] Private SSH key: `~/.ssh/id_ed25519_gitlab`
- [ ] Private GPG key: `gpg --export-secret-keys 5606AB430E95F5AD > private.key`
- [ ] GPG revocation certificate: `~/.gnupg/revoke-*.asc`
- [ ] SSH/GPG passphrases (in password manager)

**Backup command:**

```bash
# Create encrypted backup
tar -czf ~/keys-backup-$(date +%Y%m%d).tar.gz \
  ~/.ssh/id_ed25519_gitlab \
  ~/.ssh/id_ed25519_gitlab.pub \
  ~/.gnupg/revoke-*.asc

# Encrypt with GPG (using your key)
gpg --encrypt --recipient 5606AB430E95F5AD \
  ~/keys-backup-$(date +%Y%m%d).tar.gz

# Store the .tar.gz.gpg file in secure location
# Delete the unencrypted .tar.gz
rm ~/keys-backup-$(date +%Y%m%d).tar.gz
```

---

## 🎯 Next Steps

1. ✅ Add SSH key to GitLab
2. ✅ Add GPG key to GitLab
3. ✅ Test SSH connection
4. ✅ Test GPG commit signing
5. ✅ Import Nix modules to system config
6. ✅ Backup private keys securely
7. 🔄 Clone Cerebro to GitLab (if desired)
8. 🔄 Setup CI/CD with GitLab Runners

---

## 📚 References

- [GitLab SSH Keys Documentation](https://docs.gitlab.com/ee/user/ssh.html)
- [GitLab GPG Signed Commits](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/)
- [NixOS SSH Configuration](https://nixos.wiki/wiki/SSH)
- [GPG Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)

---

**Generated:** 2026-01-15
**Maintained by:** kernelcore
**Project:** Cerebro Knowledge Extraction Platform
