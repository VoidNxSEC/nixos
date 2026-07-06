# GitHub Actions Self-Hosted Runner Setup

## Overview
This guide walks you through setting up a self-hosted GitHub Actions runner on your NixOS system with SOPS secret management.

## Prerequisites
- NixOS system with the configuration from this repository
- Age key generated (already done: `~/.config/sops/age/keys.txt`)
- Access to your GitHub repository settings

---

## Step 1: Generate GitHub Runner Token

1. Go to your repository settings:
   ```
   https://github.com/VoidNxSEC/nixos/settings/actions/runners/new
   ```

2. Click **"New self-hosted runner"**

3. Select **Linux** as the OS and **x64** as the architecture

4. **Copy the registration token** that appears (looks like: `BGNJEPYD...`)
   - ⚠️ This token expires in 1 hour, so proceed quickly!

---

## Step 2: Encrypt the Token with SOPS

1. **Create the secret file** with the runner token:
   ```bash
   cat > /tmp/github-runner.yaml << EOF
   github:
     runner:
       token: "PASTE_YOUR_TOKEN_HERE"
   EOF
   ```

2. **Encrypt it with SOPS**:
   ```bash
   cd /etc/nixos
   sops -e /tmp/github-runner.yaml > secrets/github.yaml
   ```

3. **Verify the encryption**:
   ```bash
   # Should show encrypted content
   cat secrets/github.yaml
   
   # Should show decrypted content
   sops -d secrets/github.yaml
   ```

4. **Clean up the plaintext**:
   ```bash
   rm /tmp/github-runner.yaml
   ```

---

## Step 3: Enable the GitHub Runner Module

1. **Add the configuration** to your NixOS config (if not already present):

   Edit `/etc/nixos/hosts/kernelcore/configuration.nix` and add:
   ```nix
   kernelcore.services.github-runner = {
     enable = true;
     useSops = true;  # Use SOPS for token (recommended)
     runnerName = "nixos-self-hosted";
     repoUrl = "https://github.com/VoidNxSEC/nixos";
     extraLabels = [ "nixos" "nix" "gpu" ];  # Add custom labels
   };
   ```

2. **Enable SOPS secrets** (if not already enabled):
   ```nix
   kernelcore.secrets.sops.enable = true;
   ```

---

## Step 4: Build and Deploy

1. **Check for syntax errors**:
   ```bash
   cd /etc/nixos
   nix flake check --show-trace
   ```

2. **Build the configuration**:
   ```bash
   nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel
   ```

3. **Deploy to your system**:
   ```bash
   sudo nixos-rebuild switch --flake .#kernelcore
   ```

---

## Step 5: Verify the Runner

1. **Check the systemd service status**:
   ```bash
   systemctl status actions-runner.service
   ```

2. **View the logs**:
   ```bash
   journalctl -u actions-runner.service -f
   ```

3. **Check in GitHub UI**:
   - Go to: `https://github.com/VoidNxSEC/nixos/settings/actions/runners`
   - You should see your runner listed as **"Idle"** (green)

---

## Step 6: Test the Runner

1. **Trigger a workflow manually**:
   - Go to: `https://github.com/VoidNxSEC/nixos/actions`
   - Select **"NixOS Build & Test"**
   - Click **"Run workflow"** → select `main` branch → **"Run workflow"**

2. **Watch it run on your self-hosted runner!**

---

## Troubleshooting

### Runner fails to start
```bash
# Check logs
journalctl -u actions-runner.service -n 50

# Check if SOPS secret is accessible
sudo ls -la /run/secrets/github/runner/token

# Manually test decryption
sops -d secrets/github.yaml
```

### Token expired
If you see "Invalid token" errors:
1. Generate a new token from GitHub
2. Re-encrypt the secret:
   ```bash
   sops secrets/github.yaml  # Opens editor, update the token
   ```
3. Restart the service:
   ```bash
   sudo systemctl restart actions-runner.service
   ```

### Runner not appearing in GitHub
- Verify the `repoUrl` matches your repository
- Check network connectivity
- Ensure the service is running: `systemctl status actions-runner`

### Permission issues
```bash
# Fix ownership
sudo chown -R actions:actions /var/lib/actions-runner

# Restart service
sudo systemctl restart actions-runner.service
```

---

## Security Notes

✅ **Best practices:**
- Token is encrypted with SOPS and stored securely
- Token is only readable by the `actions` user
- Service runs as unprivileged `actions` user
- Secrets are in `/run/secrets` (tmpfs, memory-only)

⚠️ **Important:**
- Never commit unencrypted tokens to Git
- Rotate tokens periodically
- Review runner logs for suspicious activity
- Limit runner access with `extraGroups` carefully

---

## Configuration Options

You can customize the runner in `configuration.nix`:

```nix
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;               # Use SOPS (recommended)
  runnerName = "my-runner";     # Custom runner name
  repoUrl = "https://github.com/user/repo";  # Your repo
  extraLabels = [               # Custom labels for targeting
    "nixos"
    "gpu"
    "large-memory"
  ];
};
```

### Useful systemd commands:
```bash
# Start runner
sudo systemctl start actions-runner.service

# Stop runner
sudo systemctl stop actions-runner.service

# Restart runner
sudo systemctl restart actions-runner.service

# View status
sudo systemctl status actions-runner.service

# View logs (live)
journalctl -u actions-runner.service -f

# View recent logs
journalctl -u actions-runner.service -n 100
```

---

## Workflow Configuration

Your workflows are already configured to use the self-hosted runner in:
`.github/workflows/nixos-build.yml`

Jobs use: `runs-on: [self-hosted, nixos]`

This ensures they run on your NixOS machine instead of GitHub's hosted runners.

---

## Next Steps

1. ✅ Set up the runner (follow steps above)
2. ✅ Test with a workflow run
3. ⚠️ Consider adding more runners for parallel jobs
4. 🔒 Set up Cachix for faster builds (optional)
5. 📊 Monitor runner usage and resource consumption

---

## Additional Resources

- [GitHub Actions Self-hosted Runners Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [NixOS SOPS Integration](https://github.com/Mic92/sops-nix)

---

**Need help?** Check the logs first, then review this guide. Most issues are token-related or permissions.
