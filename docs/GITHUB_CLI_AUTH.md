# GitHub CLI Authentication Setup

This guide covers how to authenticate the GitHub CLI (`gh`) for use in your NixOS CI/CD workflows.

## Prerequisites

- GitHub CLI installed (included in `kernelcore.development.cicd` module)
- GitHub account with appropriate permissions

## Authentication Methods

### Method 1: Interactive Login (Recommended for Desktop)

```bash
# Login with GitHub.com
gh auth login

# Follow the prompts:
# 1. Choose "GitHub.com"
# 2. Choose "HTTPS" or "SSH" (HTTPS recommended)
# 3. Choose "Login with a web browser"
# 4. Copy the one-time code
# 5. Press Enter to open browser
# 6. Paste code and authorize
```

### Method 2: Personal Access Token (PAT)

1. **Generate a PAT on GitHub**:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes:
     - `repo` (Full control of private repositories)
     - `workflow` (Update GitHub Action workflows)
     - `admin:org` (if managing organization runners)
     - `admin:public_key` (for SSH key management)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again!)

2. **Authenticate with the token**:
   ```bash
   # Store token in SOPS (recommended)
   sops secrets/github.yaml
   # Add: github.cli.token: "ghp_xxxxxxxxxxxx"

   # Or authenticate directly
   echo "ghp_xxxxxxxxxxxx" | gh auth login --with-token
   ```

### Method 3: Using SOPS for Automated Authentication

1. **Add GitHub token to SOPS secrets**:
   ```bash
   cd /etc/nixos
   sops secrets/github.yaml
   ```

2. **Add the following structure**:
   ```yaml
   github:
     cli:
       token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     runner:
       token: YOUR_RUNNER_TOKEN_HERE
   ```

3. **Configure shell to auto-authenticate**:
   Add to your shell config:
   ```bash
   # In ~/.bashrc or ~/.zshrc
   if [ -f /run/secrets/github/cli/token ]; then
     export GITHUB_TOKEN=$(cat /run/secrets/github/cli/token)
   fi
   ```

4. **Update your NixOS configuration** (optional):
   ```nix
   # In configuration.nix
   sops.secrets."github/cli/token" = {
     sopsFile = ./secrets/github.yaml;
     owner = "kernelcore";
     mode = "0400";
   };

   environment.sessionVariables = {
     GITHUB_TOKEN = "$(cat ${config.sops.secrets."github/cli/token".path})";
   };
   ```

## Verifying Authentication

```bash
# Check authentication status
gh auth status

# Expected output:
# github.com
#   ✓ Logged in to github.com as YourUsername (keyring)
#   ✓ Git operations for github.com configured to use https protocol.
#   ✓ Token: *******************

# Test API access
gh api user
gh repo list
```

## Token Scopes Reference

| Scope | Description | Required For |
|-------|-------------|--------------|
| `repo` | Repository access | Creating PRs, managing issues, workflows |
| `workflow` | GitHub Actions | Triggering/managing workflows |
| `admin:org` | Organization management | Managing org runners, teams |
| `admin:public_key` | SSH keys | Managing SSH keys |
| `admin:repo_hook` | Webhooks | Managing webhooks |
| `gist` | Gists | Creating/managing gists |
| `notifications` | Notifications | Reading notifications |
| `read:org` | Read org data | Reading org info (minimal) |

## CI/CD Integration

### For GitHub Actions Runner

The GitHub Actions runner uses a separate registration token. To configure:

1. **Get a runner token**:
   - Go to: `https://github.com/YOUR_ORG/YOUR_REPO/settings/actions/runners/new`
   - Copy the registration token
   - **Important**: This token expires after 1 hour

2. **For persistent runners, use a PAT with `admin:org` scope instead**:
   ```bash
   # Add to secrets/github.yaml
   sops secrets/github.yaml
   ```

   ```yaml
   github:
     runner:
       token: ghp_xxxxxxxxxxxx  # PAT with admin:org scope
   ```

3. **Enable SOPS in configuration**:
   ```nix
   # In configuration.nix
   services.github-runner = {
     enable = true;
     useSops = true;  # Enable SOPS secret management
     runnerName = "nixos-self-hosted";
     repoUrl = "https://github.com/YOUR_ORG/YOUR_REPO";
   };
   ```

### For GitHub CLI in Workflows

Add `GITHUB_TOKEN` to your workflow:

```yaml
jobs:
  example:
    runs-on: [self-hosted, nixos]
    steps:
      - name: Use GitHub CLI
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh pr list
          gh issue create --title "Automated issue"
```

## Troubleshooting

### "authentication failed" Error

```bash
# Re-authenticate
gh auth logout
gh auth login

# Check token validity
gh auth status -t
```

### Token Expired

PATs don't expire unless you set an expiration date. To check:

```bash
gh api user -i | grep x-oauth-scopes
```

### SOPS Decryption Issues

```bash
# Verify AGE key exists
ls -la /var/lib/sops-nix/key.txt

# Or check SSH key
ls -la /etc/ssh/ssh_host_ed25519_key

# Test SOPS decryption
sops -d secrets/github.yaml
```

### Runner Registration Issues

```bash
# Check runner service status
systemctl status actions-runner.service

# View logs
journalctl -u actions-runner.service -f

# Verify token in SOPS
sudo cat /run/secrets/github/runner/token
```

## Security Best Practices

1. **Use SOPS for token storage** - Never commit plaintext tokens
2. **Limit token scopes** - Only grant necessary permissions
3. **Rotate tokens regularly** - Generate new tokens every 90 days
4. **Use separate tokens** - Different tokens for CLI, runners, CI
5. **Enable 2FA** - Protect your GitHub account
6. **Review token usage** - Check GitHub settings for active tokens

## Quick Reference

```bash
# Common gh commands
gh auth status              # Check authentication
gh auth refresh             # Refresh credentials
gh auth logout              # Logout
gh repo list                # List your repos
gh pr create                # Create PR
gh issue create             # Create issue
gh workflow run             # Trigger workflow
gh workflow list            # List workflows
gh run list                 # List workflow runs
gh run watch                # Watch current workflow run
```

## Additional Resources

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub Token Scopes](https://docs.github.com/en/developers/apps/scopes-for-oauth-apps)
- [Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [SOPS Documentation](https://github.com/mozilla/sops)
