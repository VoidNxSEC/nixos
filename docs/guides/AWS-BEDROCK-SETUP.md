# AWS Bedrock Setup for Claude Code - Complete Guide

This guide explains how to configure AWS Bedrock credentials for Claude Code authentication using SOPS encryption.

## 📋 Overview

AWS Bedrock provides access to Claude models through AWS infrastructure. This setup encrypts your AWS credentials using SOPS and integrates them with NixOS for secure, declarative configuration.

## ✅ What Was Configured

### 1. **Encrypted AWS Credentials**
- ✓ AWS Access Key ID
- ✓ AWS Secret Access Key
- ✓ AWS Region (us-east-1)
- ✓ Bedrock Model ID (anthropic.claude-3-sonnet-20240229-v1:0)
- ✓ Bedrock Endpoint URL

### 2. **Security**
- ✓ Credentials encrypted with SOPS using AGE encryption
- ✓ Plaintext credentials securely deleted (10-pass overwrite)
- ✓ Encrypted file safe to commit to git: [`secrets/aws.yaml`](../../secrets/aws.yaml)

### 3. **NixOS Integration**
- ✓ Created: [`modules/secrets/aws-bedrock.nix`](../../modules/secrets/aws-bedrock.nix)
- ✓ Added to: [`flake.nix`](../../flake.nix)
- ✓ Enabled in: [`hosts/kernelcore/configuration.nix`](../../hosts/kernelcore/configuration.nix)
- ✓ Helper script: `/etc/load-aws-bedrock.sh`

---

## 🚀 Usage

### Load AWS Credentials in Your Session

```bash
# Load AWS Bedrock credentials into environment
source /etc/load-aws-bedrock.sh

# Verify credentials are loaded
echo $AWS_ACCESS_KEY_ID | head -c 15
echo $AWS_REGION
echo $BEDROCK_MODEL_ID
```

### Use in Scripts

```bash
#!/usr/bin/env bash

# Load AWS credentials
source /etc/load-aws-bedrock.sh

# Use AWS CLI with Bedrock
aws bedrock-runtime invoke-model \
  --model-id "$BEDROCK_MODEL_ID" \
  --body '{"prompt": "Hello, Claude!", "max_tokens": 100}' \
  output.json

# Or use Claude Code with Bedrock authentication
export ANTHROPIC_BEDROCK_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export ANTHROPIC_BEDROCK_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export ANTHROPIC_BEDROCK_AWS_REGION="$AWS_REGION"
```

### Claude Code Integration

Claude Code automatically detects these environment variables:

```bash
# Load credentials
source /etc/load-aws-bedrock.sh

# Launch Claude Code (credentials auto-detected)
code

# Or set explicitly in VSCode settings.json:
{
  "anthropic.bedrock": {
    "enabled": true,
    "region": "us-east-1",
    "modelId": "anthropic.claude-3-sonnet-20240229-v1:0"
  }
}
```

---

## 📝 Managing Secrets

### View/Edit Encrypted Credentials

```bash
# View decrypted (read-only)
sops -d secrets/aws.yaml

# Edit (decrypts, opens editor, re-encrypts)
sops secrets/aws.yaml
```

### Update AWS Credentials

```bash
# Method 1: Direct edit with SOPS
sops secrets/aws.yaml

# Method 2: Replace with new credentials
cat > /tmp/aws-update.yaml <<'EOF'
aws_access_key_id: "AKIA_NEW_KEY_ID"
aws_secret_access_key: "new_secret_access_key"
aws_region: "us-west-2"
bedrock:
  model_id: "anthropic.claude-3-opus-20240229-v1:0"
  endpoint: "https://bedrock-runtime.us-west-2.amazonaws.com"
EOF

# Encrypt and replace
cp /tmp/aws-update.yaml secrets/aws.yaml
sops -e -i secrets/aws.yaml

# Secure cleanup
shred -vfz -n 10 /tmp/aws-update.yaml

# Rebuild to apply changes
sudo nixos-rebuild switch
```

### Add Additional AWS Profiles

```bash
# Edit secrets file
sops secrets/aws.yaml

# Add new profile:
profiles:
  default:
    access_key_id: "AKIAXXXXXXXXX"
    secret_access_key: "xxxxxxxxxx"
    region: "us-east-1"
  production:
    access_key_id: "AKIAYYYYYYYY"
    secret_access_key: "yyyyyyyyyy"
    region: "us-west-2"

# Rebuild
sudo nixos-rebuild switch
```

---

## 🔐 Security Best Practices

### ✅ DO

- **Rotate credentials regularly** (every 90 days recommended)
  ```bash
  # Generate new credentials in AWS Console
  # Update in SOPS
  sops secrets/aws.yaml
  # Rebuild
  sudo nixos-rebuild switch
  ```

- **Use least privilege IAM policies**
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        "Resource": "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-*"
      }
    ]
  }
  ```

- **Monitor AWS CloudTrail logs** for suspicious activity
- **Enable AWS MFA** for your account
- **Use different credentials for dev/prod**

### ❌ DON'T

- **Never commit plaintext credentials** to git
- **Never share AWS credentials** via email/chat
- **Never use root account credentials** (use IAM users)
- **Never hardcode credentials in code**
- **Never log decrypted credentials**

---

## 🛠 Troubleshooting

### "InvalidSignatureException" from AWS

**Cause:** Incorrect credentials or clock skew

**Solution:**
```bash
# Verify credentials are correct
sops -d secrets/aws.yaml | grep aws_access_key_id

# Check system time (AWS requires accurate time)
timedatectl status

# Sync time if needed
sudo systemctl restart systemd-timesyncd

# Reload credentials
source /etc/load-aws-bedrock.sh
```

### Credentials Not Decrypting After Rebuild

**Cause:** SOPS AGE key not available to system

**Solution:**
```bash
# Ensure AGE key exists in system location
sudo ls -la /var/lib/sops-nix/key.txt

# If missing, copy it:
sudo mkdir -p /var/lib/sops-nix
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt

# Rebuild
sudo nixos-rebuild switch
```

### "AccessDeniedException" from Bedrock

**Cause:** IAM permissions insufficient

**Solution:**
```bash
# Check IAM policy in AWS Console
# User/Role needs bedrock:InvokeModel permission

# Test with AWS CLI
aws bedrock list-foundation-models --region us-east-1

# If unauthorized, update IAM policy
```

### Environment Variables Not Loading

**Cause:** Helper script not sourced

**Solution:**
```bash
# Manual load
source /etc/load-aws-bedrock.sh

# Auto-load in shell (add to ~/.bashrc or ~/.zshrc)
echo "source /etc/load-aws-bedrock.sh 2>/dev/null" >> ~/.bashrc

# Or enable in NixOS configuration
# Edit modules/secrets/aws-bedrock.nix:
programs.bash.interactiveShellInit = mkDefault ''
  source /etc/load-aws-bedrock.sh 2>/dev/null  # Uncomment this line
'';
```

---

## 📊 File Locations

| Item | Location | Purpose |
|------|----------|---------|
| Encrypted Credentials | [`secrets/aws.yaml`](../../secrets/aws.yaml) | AWS credentials (encrypted) |
| NixOS Module | [`modules/secrets/aws-bedrock.nix`](../../modules/secrets/aws-bedrock.nix) | SOPS integration |
| Helper Script | `/etc/load-aws-bedrock.sh` | Load credentials to env |
| Decrypted Secrets | `/run/secrets/aws_*` | Runtime decrypted files |
| AGE Key | `/var/lib/sops-nix/key.txt` | Decryption key |

---

## 🎯 Quick Commands

```bash
# View encrypted file
cat secrets/aws.yaml

# View decrypted
sops -d secrets/aws.yaml

# Edit credentials
sops secrets/aws.yaml

# Load into environment
source /etc/load-aws-bedrock.sh

# Test AWS connectivity
aws sts get-caller-identity

# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1

# Rebuild after changes
sudo nixos-rebuild switch

# Check decrypted secrets
sudo ls -la /run/secrets/
```

---

## 🔄 AWS Bedrock Models

Available Claude models on Bedrock:

| Model ID | Description | Context Window | Cost |
|----------|-------------|----------------|------|
| `anthropic.claude-3-opus-20240229-v1:0` | Most capable, best for complex tasks | 200K tokens | Highest |
| `anthropic.claude-3-sonnet-20240229-v1:0` | Balanced performance and cost | 200K tokens | Medium |
| `anthropic.claude-3-haiku-20240307-v1:0` | Fastest, most cost-effective | 200K tokens | Lowest |

To change model:
```bash
sops secrets/aws.yaml
# Update bedrock.model_id
sudo nixos-rebuild switch
```

---

## 📚 Related Documentation

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Claude API on Bedrock](https://docs.anthropic.com/claude/docs/claude-on-amazon-bedrock)
- [SOPS Setup Guide](./SETUP-SOPS-FINAL.md)
- [Secrets Management Guide](./SECRETS.md)

---

## 🎉 Success Checklist

- [ ] AWS credentials encrypted in `secrets/aws.yaml`
- [ ] Module added to `flake.nix`
- [ ] Configuration enabled in `configuration.nix`
- [ ] System rebuilt: `sudo nixos-rebuild switch`
- [ ] Credentials loadable: `source /etc/load-aws-bedrock.sh`
- [ ] Environment variables set correctly
- [ ] AWS CLI can authenticate
- [ ] Claude Code can access Bedrock

---

**Last Updated:** 2024-11-24  
**Maintainer:** kernelcore  
**NixOS Version:** 25.05