# SECRETS Management with SOPS - Complete Guide

Este documento define o pipeline completo para gerenciamento seguro de secrets usando SOPS (Secrets OPerationS) no NixOS.

## 📋 Table of Contents

1. [Initial Setup](#initial-setup)
2. [Standard Pipeline](#standard-pipeline)
3. [Secret Templates](#secret-templates)
4. [GitHub Actions Integration](#github-actions-integration)
5. [Common Operations](#common-operations)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Initial Setup

### 1. Generate AGE Keys

```bash
# Generate your personal AGE key
age-keygen -o ~/.config/sops/age/keys.txt

# Extract the public key for .sops.yaml
cat ~/.config/sops/age/keys.txt | grep "# public key:"
```

### 2. Configure SOPS

Create `.sops.yaml` in `/etc/nixos`:

```bash
cat > /etc/nixos/.sops.yaml <<'EOF'
# SOPS Configuration - Encryption Rules
creation_rules:
  # GitHub Actions secrets
  - path_regex: secrets/github\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
      age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

  # API Keys (Anthropic, OpenAI, etc)
  - path_regex: secrets/api\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  # Database credentials
  - path_regex: secrets/database\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  # SSH Keys
  - path_regex: secrets/ssh-keys/.*\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  # AWS credentials
  - path_regex: secrets/aws\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  # Production secrets (extra protection)
  - path_regex: secrets/prod\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
      age1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz

  # Default rule for any other secrets
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
```

**Replace** `age1xxx...` with your actual public key from step 1!

### 3. Create Secrets Directory Structure

```bash
# Already configured via NixOS modules, but verify:
sudo ls -la /etc/nixos/secrets/

# Expected structure:
# /etc/nixos/secrets/
# ├── api.yaml              # API keys (Anthropic, OpenAI, etc)
# ├── github.yaml           # GitHub Actions tokens
# ├── database.yaml         # Database credentials
# ├── aws.yaml              # AWS credentials
# ├── prod.yaml             # Production secrets
# ├── ssh-keys/
# │   ├── dev.yaml
# │   ├── staging.yaml
# │   └── production.yaml
# └── ssh.yaml              # SSH general config
```

---

## 📦 Standard Pipeline - Adding New Secrets

### Step 1: Create Plaintext Template

```bash
# Create a temporary UNENCRYPTED file (NEVER commit this!)
cat > /tmp/new-secret.yaml <<'EOF'
# Description: API Keys for external services
# Service: Anthropic, OpenAI, HuggingFace
# Date: 2025-10-26

anthropic_api_key: "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
openai_api_key: "sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
huggingface_token: "hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Optional: Environment variables format
env:
  ANTHROPIC_API_KEY: "sk-ant-api03-xxxxx"
  OPENAI_API_KEY: "sk-proj-xxxxx"
  HF_TOKEN: "hf_xxxxx"
EOF
```

### Step 2: Encrypt with SOPS

```bash
# Encrypt and save to secrets directory
sops -e /tmp/new-secret.yaml > /etc/nixos/secrets/api.yaml

# Verify encryption worked
cat /etc/nixos/secrets/api.yaml
# Should show encrypted content with "sops:" metadata
```

### Step 3: Add to Git

```bash
cd /etc/nixos
git add secrets/api.yaml .sops.yaml
git commit -m "sec: add API keys for Anthropic, OpenAI, HuggingFace"
git push
```

### Step 4: Clean Up Plaintext

```bash
# CRITICAL: Remove plaintext file!
shred -vfz -n 10 /tmp/new-secret.yaml

# Or if shred not available:
rm -f /tmp/new-secret.yaml
```

### Step 5: Configure NixOS to Use Secret

Edit your NixOS module to reference the secret:

```nix
# Example: modules/services/api-service.nix
{ config, lib, pkgs, ... }:

{
  # Decrypt secret at runtime
  sops.secrets."anthropic_api_key" = {
    sopsFile = ../../secrets/api.yaml;
    owner = "myservice";
    group = "myservice";
    mode = "0440";
  };

  # Use in systemd service
  systemd.services.my-ai-service = {
    serviceConfig = {
      EnvironmentFile = config.sops.secrets."anthropic_api_key".path;
    };
  };
}
```

---

## 📝 Secret Templates

### GitHub Actions Token

File: `/etc/nixos/secrets/github.yaml`

```bash
cat > /tmp/github.yaml <<'EOF'
# GitHub Actions Self-Hosted Runner
# Generate token at: https://github.com/settings/tokens
# Required scopes: repo, workflow, admin:org (for org-level runners)

github_runner_token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Alternative: GitHub App credentials
github_app_id: "123456"
github_app_installation_id: "12345678"
github_app_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  -----END RSA PRIVATE KEY-----

# Organization/Repo info
github_org: "marcosfpina"
github_repo: "my-repo"
EOF

# Encrypt
sops -e /tmp/github.yaml > /etc/nixos/secrets/github.yaml
shred -vfz -n 10 /tmp/github.yaml
```

### API Keys (Anthropic, OpenAI, etc)

File: `/etc/nixos/secrets/api.yaml`

```bash
cat > /tmp/api.yaml <<'EOF'
# External API Keys
# Date: 2025-10-26

# AI Services
anthropic_api_key: "sk-ant-api03-xxxxx"
openai_api_key: "sk-proj-xxxxx"
groq_api_key: "gsk_xxxxx"
huggingface_token: "hf_xxxxx"

# Cloud Providers (if needed beyond AWS)
google_cloud_api_key: "AIzaSyxxxxx"
azure_api_key: "xxxxx"

# Other Services
github_api_token: "ghp_xxxxx"
gitlab_api_token: "glpat-xxxxx"
codeberg_api_token: "xxxxx"

# Monitoring/Analytics
sentry_dsn: "https://xxxxx@sentry.io/xxxxx"
datadog_api_key: "xxxxx"
EOF

sops -e /tmp/api.yaml > /etc/nixos/secrets/api.yaml
shred -vfz -n 10 /tmp/api.yaml
```

### Database Credentials

File: `/etc/nixos/secrets/database.yaml`

```bash
cat > /tmp/database.yaml <<'EOF'
# Database Credentials
# Date: 2025-10-26

postgresql:
  host: "localhost"
  port: 5432
  username: "kernelcore"
  password: "super_secure_pg_password_here"
  database: "kernelcore"
  connection_string: "postgresql://kernelcore:super_secure_pg_password_here@localhost:5432/kernelcore"

mongodb:
  host: "localhost"
  port: 27017
  username: "admin"
  password: "super_secure_mongo_password"
  database: "mydb"
  connection_string: "mongodb://admin:super_secure_mongo_password@localhost:27017/mydb"

redis:
  host: "localhost"
  port: 6379
  password: "redis_password_here"
EOF

sops -e /tmp/database.yaml > /etc/nixos/secrets/database.yaml
shred -vfz -n 10 /tmp/database.yaml
```

### AWS Credentials

File: `/etc/nixos/secrets/aws.yaml`

```bash
cat > /tmp/aws.yaml <<'EOF'
# AWS Credentials
# Date: 2025-10-26

aws_access_key_id: "AKIAXXXXXXXXXXXXXXXXX"
aws_secret_access_key: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
aws_region: "us-east-1"

# Multiple profiles support
profiles:
  default:
    access_key_id: "AKIAXXXXXXXXXXXXXXXXX"
    secret_access_key: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    region: "us-east-1"

  production:
    access_key_id: "AKIAYYYYYYYYYYYYYYYY"
    secret_access_key: "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
    region: "us-west-2"
EOF

sops -e /tmp/aws.yaml > /etc/nixos/secrets/aws.yaml
shred -vfz -n 10 /tmp/aws.yaml
```

### SSH Keys

File: `/etc/nixos/secrets/ssh-keys/production.yaml`

```bash
# Generate SSH key first
ssh-keygen -t ed25519 -C "production-deploy" -f /tmp/prod_deploy_key

cat > /tmp/ssh-prod.yaml <<EOF
# Production SSH Deploy Key
# Date: 2025-10-26
# Usage: Deployment to production servers

private_key: |
$(cat /tmp/prod_deploy_key | sed 's/^/  /')

public_key: "$(cat /tmp/prod_deploy_key.pub)"

# Server info
servers:
  - host: "prod-01.example.com"
    user: "deploy"
    port: 22
  - host: "prod-02.example.com"
    user: "deploy"
    port: 22
EOF

mkdir -p /etc/nixos/secrets/ssh-keys
sops -e /tmp/ssh-prod.yaml > /etc/nixos/secrets/ssh-keys/production.yaml
shred -vfz -n 10 /tmp/ssh-prod.yaml /tmp/prod_deploy_key /tmp/prod_deploy_key.pub
```

### VPN Credentials (NordVPN example)

File: `/etc/nixos/secrets/vpn.yaml`

```bash
cat > /tmp/vpn.yaml <<'EOF'
# VPN Credentials
# Date: 2025-10-26

nordvpn:
  username: "your-email@example.com"
  password: "your_nordvpn_password"
  service_token: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

wireguard:
  private_key: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx="
  public_key: "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy="
  endpoint: "vpn.example.com:51820"
EOF

sops -e /tmp/vpn.yaml > /etc/nixos/secrets/vpn.yaml
shred -vfz -n 10 /tmp/vpn.yaml
```

---

## 🔄 GitHub Actions Integration

### Option 1: GitHub-Hosted Runners (Recommended - Default)

**Pros:**
- No local resource usage
- Maintained by GitHub
- Faster for most workloads
- No network/firewall issues

**Setup:**

1. Add secrets to GitHub repo settings:
   - Go to: `Settings → Secrets and variables → Actions`
   - Add secrets: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.

2. Use in workflows:

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest  # GitHub-hosted

    steps:
      - uses: actions/checkout@v4

      - name: Deploy with API
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          ./scripts/deploy.sh
```

### Option 2: Self-Hosted Runner (Optional)

**When to use:**
- Need GPU access (CUDA workloads)
- Need specific hardware
- Large build artifacts (faster local storage)
- Air-gapped environments

**Enable in configuration.nix:**

```nix
services.github-runner = {
  enable = true;  # Set to true to enable self-hosted runner
  useSops = true;
  runnerName = "nixos-self-hosted";
  repoUrl = "https://github.com/marcosfpina";
  extraLabels = [ "nixos" "nix" "linux" "gpu" ];
};
```

**Setup:**

1. Generate GitHub runner token:
   ```bash
   # Go to: https://github.com/marcosfpina/REPO/settings/actions/runners/new
   # Copy the registration token
   ```

2. Add to secrets:
   ```bash
   cat > /tmp/github-runner.yaml <<'EOF'
   github_runner_token: "YOUR_REGISTRATION_TOKEN_HERE"
   github_runner_url: "https://github.com/marcosfpina"
   EOF

   sops -e /tmp/github-runner.yaml > /etc/nixos/secrets/github.yaml
   shred -vfz -n 10 /tmp/github-runner.yaml
   ```

3. Rebuild NixOS:
   ```bash
   sudo nixos-rebuild switch
   ```

4. Use in workflows:
   ```yaml
   jobs:
     build:
       runs-on: self-hosted  # Use your NixOS runner

       steps:
         - name: Build with GPU
           run: |
             nvidia-smi
             python train_model.py
   ```

---

## 🛠️ Common Operations

### View/Edit Encrypted Secret

```bash
# Edit in-place (decrypts, opens editor, re-encrypts)
sops /etc/nixos/secrets/api.yaml

# View decrypted content (read-only)
sops -d /etc/nixos/secrets/api.yaml
```

### Update Existing Secret

```bash
# Method 1: Direct edit
sops /etc/nixos/secrets/api.yaml
# Add/modify keys in your editor, save, exit

# Method 2: Re-encrypt from plaintext
cat > /tmp/api-update.yaml <<'EOF'
new_api_key: "sk-new-xxxxxx"
EOF

sops -e /tmp/api-update.yaml > /etc/nixos/secrets/api.yaml
shred -vfz -n 10 /tmp/api-update.yaml
```

### Rotate AGE Keys

```bash
# 1. Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Get new public key
NEW_KEY=$(cat ~/.config/sops/age/keys-new.txt | grep "public key:" | cut -d: -f2 | tr -d ' ')

# 3. Update .sops.yaml with new public key

# 4. Rotate each secret
for secret in /etc/nixos/secrets/*.yaml; do
  sops updatekeys -y "$secret"
done

# 5. Backup old key, use new key
mv ~/.config/sops/age/keys.txt ~/.config/sops/age/keys-old.txt.backup
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt
```

### Backup Secrets (Encrypted)

```bash
# Backup to external drive (secrets remain encrypted)
tar -czf ~/backups/nixos-secrets-$(date +%Y%m%d).tar.gz \
  /etc/nixos/secrets/ \
  /etc/nixos/.sops.yaml \
  ~/.config/sops/age/keys.txt

# Store backup in secure location (encrypted USB, password manager, etc)
```

### Share Secret with Team Member

```bash
# 1. Get their AGE public key
TEAM_MEMBER_KEY="age1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

# 2. Update .sops.yaml to include their key
# Add to relevant creation_rule:
#   age: >-
#     age1xxxxxxxxx,
#     age1zzzzzzzzz  # Team member key

# 3. Update keys for the secret
sops updatekeys /etc/nixos/secrets/api.yaml

# 4. Commit and push (they can now decrypt with their key)
```

### Use Secret in Script

```bash
#!/usr/bin/env bash
# Example: scripts/deploy.sh

# Decrypt and export as env vars
eval "$(sops -d /etc/nixos/secrets/api.yaml | \
  yq eval '.env | to_entries | .[] | "export " + .key + "=\"" + .value + "\""' -)"

# Now use the variables
echo "Using API key: ${ANTHROPIC_API_KEY:0:10}..."
curl -H "x-api-key: $ANTHROPIC_API_KEY" https://api.anthropic.com/v1/...
```

---

## 🔍 Troubleshooting

### Error: "no key could decrypt the data"

**Cause:** Your AGE key is not in the .sops.yaml configuration.

**Solution:**
```bash
# Check your public key
cat ~/.config/sops/age/keys.txt | grep "public key:"

# Verify it's in .sops.yaml
cat /etc/nixos/.sops.yaml

# If not, add it and update keys:
sops updatekeys /etc/nixos/secrets/api.yaml
```

### Error: "failed to get the data key"

**Cause:** SOPS can't find your private key.

**Solution:**
```bash
# Ensure key exists
ls -la ~/.config/sops/age/keys.txt

# Set SOPS_AGE_KEY_FILE environment variable
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Or specify explicitly:
sops --age-key-file ~/.config/sops/age/keys.txt -d secrets/api.yaml
```

### Secret Not Decrypting in NixOS Build

**Cause:** sops-nix module not properly configured.

**Solution:**
```bash
# Check if sops-nix is enabled
nix eval .#nixosConfigurations.kernelcore.config.kernelcore.secrets.sops.enable
# Should output: true

# Check if AGE key exists for system
sudo ls -la /var/lib/sops-nix/

# Manually create if missing:
sudo mkdir -p /var/lib/sops-nix
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
```

### Permission Denied When Editing Secrets

**Cause:** Secrets directory owned by root.

**Solution:**
```bash
# Option 1: Use sudo
sudo sops /etc/nixos/secrets/api.yaml

# Option 2: Change ownership (temporary)
sudo chown $USER:$USER /etc/nixos/secrets/api.yaml
sops /etc/nixos/secrets/api.yaml
sudo chown root:root /etc/nixos/secrets/api.yaml
```

---

## 📚 Best Practices

### ✅ DO

- **Always encrypt before committing** to git
- **Use strong AGE keys** (generated with `age-keygen`)
- **Backup your AGE private key** securely (password manager, encrypted USB)
- **Rotate keys periodically** (every 6-12 months)
- **Use separate secrets files** for different environments (dev, staging, prod)
- **Document what each secret is for** (comments in YAML)
- **Use meaningful secret names** (descriptive, lowercase, underscores)
- **Shred plaintext files** after encryption (`shred -vfz -n 10`)

### ❌ DON'T

- **Never commit plaintext secrets** to git
- **Never share your AGE private key** via email/chat
- **Never use weak passwords** for AGE key encryption
- **Never store AGE keys in the same repo** as secrets
- **Never use production secrets in development**
- **Never hardcode secrets in code** (use environment variables)
- **Never log decrypted secrets** (even in debug mode)
- **Never skip the shred step** when cleaning up

---

## 🎯 Quick Reference Card

```bash
# Encrypt new secret
sops -e /tmp/plaintext.yaml > /etc/nixos/secrets/encrypted.yaml

# Decrypt and view
sops -d /etc/nixos/secrets/encrypted.yaml

# Edit in-place
sops /etc/nixos/secrets/encrypted.yaml

# Update encryption keys
sops updatekeys /etc/nixos/secrets/encrypted.yaml

# Generate AGE key
age-keygen -o ~/.config/sops/age/keys.txt

# Securely delete plaintext
shred -vfz -n 10 /tmp/plaintext.yaml

# Export secret as env var
export MY_SECRET=$(sops -d /etc/nixos/secrets/api.yaml | yq '.my_key')
```

---

## 📞 Support

- **SOPS Documentation:** https://github.com/getsops/sops
- **sops-nix Documentation:** https://github.com/Mic92/sops-nix
- **AGE Documentation:** https://github.com/FiloSottile/age

---

**Last Updated:** 2025-10-26
**Maintainer:** kernelcore
**NixOS Version:** 25.05
