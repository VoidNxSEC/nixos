# GitHub Actions + SOPS Integration

> **Single Source of Truth**: All secrets managed via SOPS, decrypted at runtime in CI/CD

---

## Overview

This integration eliminates the need for manual secret management in GitHub's UI. All secrets are stored encrypted in the repository using SOPS and decrypted automatically during CI/CD runs.

### Benefits

- ✅ **Version Control**: Secrets (encrypted) tracked in git
- ✅ **Audit Trail**: Git history shows all secret changes
- ✅ **Single Source**: SOPS is the only place to manage secrets
- ✅ **No Manual Updates**: No GitHub UI secret management
- ✅ **Multi-Repo**: Reuse same secrets across repositories
- ✅ **Secure**: AGE encryption with hardware key support

---

## Architecture

```
┌─────────────────┐
│   Developer     │
│   Machine       │
└────────┬────────┘
         │
         │ 1. Edit secrets
         │ sops secrets/github.yaml
         │
         ▼
┌─────────────────┐
│   Git Repo      │
│ (encrypted)     │
│                 │
│ secrets/        │
│ └─ github.yaml  │ ← Encrypted with SOPS
└────────┬────────┘
         │
         │ 2. Push to GitHub
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
│                 │
│ 1. Checkout     │
│ 2. Setup AGE    │ ← Only 1 secret: AGE_SECRET_KEY
│ 3. Decrypt      │ ← sops -d secrets/github.yaml
│ 4. Use Secrets  │ ← All secrets available
└─────────────────┘
```

---

## Setup Instructions

### Step 1: Prepare SOPS Secrets

#### 1.1 Update `secrets/github.yaml`

```bash
# Edit encrypted file
sops secrets/github.yaml
```

Add the following structure:

```yaml
github:
  # Cachix authentication token
  cachix_auth_token: "ey..."

  # GitHub Personal Access Token (for gh CLI, etc.)
  personal_access_token: "ghp_..."

  # Self-hosted runner registration (if applicable)
  runner_token: "ABCD..."
  runner_registration_url: "https://github.com/user/repo"

  # Deploy keys (optional)
  deploy_key_private: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

Save and close (SOPS will re-encrypt automatically).

#### 1.2 Verify Encryption

```bash
# Verify file is encrypted
cat secrets/github.yaml

# Should see encrypted content like:
# github:
#     cachix_auth_token: ENC[AES256_GCM,data:...,iv:...,tag:...]
```

#### 1.3 Test Decryption

```bash
# Decrypt to verify
sops -d secrets/github.yaml

# Should see plain-text secrets
```

---

### Step 2: Add AGE Secret Key to GitHub

**IMPORTANT**: This is the ONLY secret you need to add to GitHub UI.

#### 2.1 Get Your AGE Private Key

```bash
# Display your AGE private key
cat ~/.config/sops/age/keys.txt
```

Output will look like:

```
# created: 2025-09-30T19:58:57-01:00
# public key: age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

#### 2.2 Add to GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AGE_SECRET_KEY`
5. Value: **Paste the entire contents** of `keys.txt` (all 3 lines)
6. Click **Add secret**

**Verification**:
- ✅ GitHub now has 1 secret: `AGE_SECRET_KEY`
- ✅ This secret contains your AGE private key
- ✅ This is the ONLY secret in GitHub UI

---

### Step 3: Update GitHub Workflows

#### 3.1 Use Reusable Workflow (Recommended)

Update `.github/workflows/nixos-build.yml`:

```yaml
name: NixOS Build & Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  # NEW: Decrypt SOPS secrets first
  setup-secrets:
    name: Decrypt SOPS secrets
    uses: ./.github/workflows/setup-sops.yml
    secrets: inherit

  check:
    name: Check Nix flake
    needs: setup-secrets
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: kernelcore
          authToken: ${{ needs.setup-secrets.outputs.cachix_token }}
          pushFilter: '(-source$|-env$)'

      - name: Check flake
        run: nix flake check --show-trace
```

#### 3.2 Alternative: Inline SOPS Decryption

If you prefer not to use a reusable workflow:

```yaml
check:
  name: Check Nix flake
  runs-on: [self-hosted, nixos]
  steps:
    - uses: actions/checkout@v4

    - name: Decrypt SOPS secrets
      env:
        AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
      run: |
        # Setup AGE key
        mkdir -p ~/.config/sops/age
        echo "$AGE_SECRET_KEY" > ~/.config/sops/age/keys.txt
        chmod 600 ~/.config/sops/age/keys.txt

        # Decrypt and export secrets
        export CACHIX_AUTH_TOKEN=$(sops -d secrets/github.yaml | \
          nix run nixpkgs#yq -- -r '.github.cachix_auth_token')

        # Make available to next steps
        echo "CACHIX_AUTH_TOKEN=$CACHIX_AUTH_TOKEN" >> $GITHUB_ENV

        # Mask secret in logs
        echo "::add-mask::$CACHIX_AUTH_TOKEN"

    - name: Setup Cachix
      uses: cachix/cachix-action@v15
      with:
        name: kernelcore
        authToken: ${{ env.CACHIX_AUTH_TOKEN }}

    - name: Cleanup
      if: always()
      run: rm -f ~/.config/sops/age/keys.txt
```

---

## Usage Examples

### Example 1: Cachix Integration

```yaml
- name: Decrypt secrets
  uses: ./.github/workflows/setup-sops.yml
  id: secrets
  secrets: inherit

- name: Setup Cachix
  uses: cachix/cachix-action@v15
  with:
    name: kernelcore
    authToken: ${{ steps.secrets.outputs.cachix_token }}
```

### Example 2: GitHub CLI (gh)

```yaml
- name: Authenticate GitHub CLI
  env:
    GH_TOKEN: ${{ needs.setup-secrets.outputs.github_token }}
  run: |
    gh auth status
    gh repo list
```

### Example 3: Deploy Keys

```yaml
- name: Setup deploy key
  env:
    AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
  run: |
    # Decrypt deploy key
    DEPLOY_KEY=$(sops -d secrets/github.yaml | \
      nix run nixpkgs#yq -- -r '.github.deploy_key_private')

    # Configure SSH
    mkdir -p ~/.ssh
    echo "$DEPLOY_KEY" > ~/.ssh/deploy_key
    chmod 600 ~/.ssh/deploy_key

    # Use in git
    GIT_SSH_COMMAND="ssh -i ~/.ssh/deploy_key" git clone ...
```

---

## Security Best Practices

### 1. Secret Masking

Always mask secrets in GitHub Actions logs:

```yaml
- name: Decrypt
  run: |
    SECRET=$(sops -d secrets/github.yaml | yq -r '.github.secret')
    echo "::add-mask::$SECRET"  # ← Mask in logs
    echo "SECRET=$SECRET" >> $GITHUB_ENV
```

### 2. Cleanup

Always cleanup AGE keys after use:

```yaml
- name: Cleanup
  if: always()
  run: rm -f ~/.config/sops/age/keys.txt
```

### 3. Minimal Exposure

Only decrypt secrets when needed:

```yaml
# ❌ Bad: Decrypt all secrets upfront
- run: sops -d secrets/github.yaml > /tmp/secrets.yaml

# ✅ Good: Decrypt only what you need
- run: |
    TOKEN=$(sops -d secrets/github.yaml | yq -r '.github.cachix_auth_token')
```

### 4. Use Outputs

Prefer workflow outputs over environment variables:

```yaml
# ✅ Good: Use outputs (isolated)
outputs:
  token: ${{ steps.decrypt.outputs.token }}

# ⚠️  Caution: Environment variables (shared)
env:
  TOKEN: ${{ steps.decrypt.outputs.token }}
```

---

## Troubleshooting

### Issue: "Failed to decrypt"

**Cause**: AGE key mismatch or incorrect format

**Solution**:
1. Verify AGE key in GitHub matches local key:
   ```bash
   cat ~/.config/sops/age/keys.txt
   ```
2. Ensure you copied ALL 3 lines (comment + public key + secret key)
3. Re-add secret to GitHub

### Issue: "sops: command not found"

**Cause**: SOPS not available on runner

**Solution**:
```yaml
- name: Install SOPS
  run: nix-env -iA nixpkgs.sops
```

### Issue: "yq: command not found"

**Cause**: yq not available for YAML parsing

**Solution**:
```yaml
# Use nix run for yq
- run: |
    VALUE=$(sops -d secrets/github.yaml | \
      nix run nixpkgs#yq -- -r '.path.to.value')
```

### Issue: Secrets not decrypting

**Debug**:
```yaml
- name: Debug SOPS
  env:
    AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
  run: |
    # Check AGE key is valid
    echo "$AGE_SECRET_KEY" | grep -q "AGE-SECRET-KEY" || echo "Invalid key"

    # Check SOPS config
    cat .sops.yaml

    # Try decrypting
    sops -d secrets/github.yaml || echo "Decryption failed"
```

---

## Migration from GitHub Secrets UI

### Current State (Manual GitHub Secrets)

```
GitHub Settings → Secrets:
  - CACHIX_AUTH_TOKEN
  - GITHUB_TOKEN
  - RUNNER_TOKEN
  - DEPLOY_KEY
```

### After Migration (SOPS Only)

```
GitHub Settings → Secrets:
  - AGE_SECRET_KEY  ← Only this one!

secrets/github.yaml:  ← All others here (encrypted)
  github:
    cachix_auth_token: "..."
    personal_access_token: "..."
    runner_token: "..."
    deploy_key_private: "..."
```

### Migration Steps

1. **Export existing secrets from GitHub**:
   ```bash
   gh secret list
   gh secret view CACHIX_AUTH_TOKEN
   ```

2. **Add to SOPS**:
   ```bash
   sops secrets/github.yaml
   # Add secrets in YAML format
   ```

3. **Update workflows** to use SOPS

4. **Test in CI/CD**

5. **Delete old GitHub secrets** (except AGE_SECRET_KEY)

---

## Reference

### SOPS Commands

```bash
# Edit encrypted file
sops secrets/github.yaml

# Decrypt and view
sops -d secrets/github.yaml

# Update encryption keys
sops updatekeys secrets/github.yaml

# Encrypt new file
sops -e secrets/new.yaml > secrets/new.yaml.enc
```

### AGE Commands

```bash
# Generate new AGE key
age-keygen -o ~/.config/sops/age/keys.txt

# View public key
age-keygen -y ~/.config/sops/age/keys.txt
```

### Workflow Testing

```bash
# Test workflow locally with act
act -s AGE_SECRET_KEY="$(cat ~/.config/sops/age/keys.txt)" -j check

# Test SOPS decryption
nix shell nixpkgs#sops -c sops -d secrets/github.yaml
```

---

## Additional Resources

- [SOPS Documentation](https://github.com/mozilla/sops)
- [AGE Encryption](https://github.com/FiloSottile/age)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [NixOS SOPS Module](https://github.com/Mic92/sops-nix)

---

**Last Updated**: 2025-11-09
**Maintainer**: kernelcore
