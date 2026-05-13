# 🎉 SOPS Migration Complete! - Final Steps

## ✅ What Was Done

### 1. **Encrypted All API Keys**
- ✓ SEC.sh → `secrets/api.yaml` (encrypted)
- ✓ 11 API keys migrated:
  - Anthropic (Claude)
  - OpenAI
  - DeepSeek
  - Google Gemini
  - OpenRouter
  - Replicate
  - Mistral
  - Groq
  - NVIDIA
- ✓ GitHub token → `secrets/github.yaml` (encrypted)

### 2. **Security**
- ✓ SEC.sh plaintext **securely deleted** (overwritten + removed)
- ✓ All temporary files deleted
- ✓ AGE key generated: `~/.config/sops/age/keys.txt`
- ✓ SOPS configuration: `.sops.yaml`

### 3. **NixOS Integration**
- ✓ Created: `modules/secrets/api-keys.nix`
- ✓ Added to: `flake.nix`
- ✓ Enabled in: `configuration.nix`
- ✓ Helper script: `/etc/load-api-keys.sh`

---

## 🚀 Final Steps (Run These Now)

### Step 1: Copy AGE Key to System

```bash
# Copy AGE key for system use
sudo mkdir -p /var/lib/sops-nix
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt
```

### Step 2: Add to Git

```bash
cd /etc/nixos

# Add encrypted secrets (safe to commit!)
git add secrets/api.yaml secrets/github.yaml
git add modules/secrets/api-keys.nix
git add flake.nix hosts/kernelcore/configuration.nix

# Commit
git commit -m "sec: migrate to SOPS encrypted secrets

- Migrated 11 API keys from SEC.sh to SOPS
- Encrypted with AGE (secrets/api.yaml, secrets/github.yaml)
- Created api-keys.nix module for NixOS integration
- Securely deleted plaintext SEC.sh
"
```

### Step 3: Rebuild NixOS

```bash
# Rebuild to activate secrets
sudo nixos-rebuild switch
```

### Step 4: Verify Secrets Are Decrypted

```bash
# Check decrypted secrets in /run/secrets/
sudo ls -la /run/secrets/

# Should see:
# - anthropic_api_key
# - openai_api_key
# - groq_api_key
# - github_token
# ... etc
```

### Step 5: Load API Keys in Your Session

```bash
# Load all API keys into environment
source /etc/load-api-keys.sh

# Verify
echo $ANTHROPIC_API_KEY | head -c 20
echo $OPENAI_API_KEY | head -c 20
```

---

## 📝 Daily Usage

### View/Edit Secrets

```bash
# View decrypted (read-only)
sops -d secrets/api.yaml

# Edit (decrypts, opens editor, re-encrypts)
sops secrets/api.yaml
```

### Add New API Key

```bash
# Edit the encrypted file
sops secrets/api.yaml

# Add your new key:
# new_service_key: "your-api-key-here"

# Rebuild NixOS
sudo nixos-rebuild switch
```

### Use in Scripts

```bash
#!/usr/bin/env bash

# Load API keys
source /etc/load-api-keys.sh

# Use them
curl -H "x-api-key: $ANTHROPIC_API_KEY" https://api.anthropic.com/...
```

---

## 🔄 GitHub Actions Integration

### Option 1: GitHub-Hosted Runners (Default - Recommended)

**Current status:** ✅ Enabled by default

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest  # GitHub-hosted

    steps:
      - name: Use API
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: ./deploy.sh
```

**Setup:**
1. Go to: `https://github.com/YOUR_REPO/settings/secrets/actions`
2. Add secrets manually or use GitHub CLI:

```bash
# Load keys from SOPS
source /etc/load-api-keys.sh

# Add to GitHub repo secrets
gh secret set ANTHROPIC_API_KEY --body "$ANTHROPIC_API_KEY"
gh secret set OPENAI_API_KEY --body "$OPENAI_API_KEY"
gh secret set GROQ_API_KEY --body "$GROQ_API_KEY"
```

### Option 2: Self-Hosted Runner (Optional - For GPU/Local Resources)

**Current status:** ⏸ Disabled (enable when needed)

**When to enable:**
- Need CUDA/GPU for ML workloads
- Large build artifacts (faster with local storage)
- Air-gapped environments

**Enable:**

```nix
# In hosts/kernelcore/configuration.nix:
services.github-runner.enable = true;  # Change from false to true
```

**Then rebuild:**

```bash
sudo nixos-rebuild switch
```

The runner will automatically use the decrypted `github_token` from SOPS!

---

## 🔐 Security Best Practices

### ✅ DO

- **Backup your AGE key** securely:
  ```bash
  # Backup to encrypted USB or password manager
  cp ~/.config/sops/age/keys.txt /path/to/secure/backup/
  ```

- **Rotate keys periodically** (every 6-12 months):
  ```bash
  # Generate new AGE key
  age-keygen -o ~/.config/sops/age/keys-new.txt

  # Update .sops.yaml with new public key
  # Then update all secrets:
  for f in secrets/*.yaml; do sops updatekeys "$f"; done
  ```

- **Use different secrets for dev/prod**:
  ```bash
  # Create separate files
  sops secrets/dev-api.yaml
  sops secrets/prod-api.yaml
  ```

### ❌ DON'T

- **Never commit plaintext secrets** (even temporarily)
- **Never share your AGE private key** via email/chat
- **Never hardcode secrets in code** (use environment variables)
- **Never log decrypted secrets** (even in debug mode)

---

## 🛠 Troubleshooting

### "no key could decrypt the data"

**Solution:**
```bash
# Verify your public key is in .sops.yaml
cat ~/.config/sops/age/keys.txt | grep "public key:"
cat .sops.yaml

# If not matching, update keys:
sops updatekeys secrets/api.yaml
```

### Secrets not decrypting after rebuild

**Solution:**
```bash
# Ensure AGE key is in system location
sudo ls -la /var/lib/sops-nix/key.txt

# If missing, copy it:
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
```

### GitHub runner not starting

**Solution:**
```bash
# Check if token is decrypted
sudo cat /run/secrets/github_token

# Check runner service status
systemctl status github-runner

# View logs
journalctl -u github-runner -f
```

---

## 📊 Summary

| Item | Status | Location |
|------|--------|----------|
| API Keys | ✅ Encrypted | `secrets/api.yaml` |
| GitHub Token | ✅ Encrypted | `secrets/github.yaml` |
| AGE Private Key | ✅ Generated | `~/.config/sops/age/keys.txt` |
| System AGE Key | ⏳ **Needs sudo** | `/var/lib/sops-nix/key.txt` |
| NixOS Module | ✅ Created | `modules/secrets/api-keys.nix` |
| SEC.sh Plaintext | ✅ Deleted | ❌ (securely wiped) |
| Git Commit | ⏳ Pending | Run Step 2 above |
| NixOS Rebuild | ⏳ Pending | Run Step 3 above |

---

## 🎯 Quick Commands

```bash
# View all secrets
sudo ls -la /run/secrets/

# Load into environment
source /etc/load-api-keys.sh

# Edit API keys
sops secrets/api.yaml

# Edit GitHub settings
sops secrets/github.yaml

# Rebuild after changes
sudo nixos-rebuild switch

# Test secret decryption
sops -d secrets/api.yaml | grep anthropic_api_key
```

---

**Next:** Run the 5 steps above to complete the setup!

**WiFi:** Don't forget - you also have the WiFi optimization module ready! After SOPS setup, you can test:

```bash
# Test WiFi latency
curl -w "\nTempo: %{time_total}s\n" -o /dev/null -s https://1.1.1.1

# Use WiFi diagnostics
/etc/wifi-diagnostics.sh
```

---

**Last Updated:** 2025-10-26
**Maintainer:** kernelcore
