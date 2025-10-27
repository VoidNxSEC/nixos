# Desktop Troubleshooting Guide

This guide covers troubleshooting for home-manager and SSH key issues on your desktop NixOS machine.

## Prerequisites

After pulling the latest changes from the repository, you'll have:
1. Enhanced Trezor module with SSH agent support
2. Home-manager diagnostics script
3. This troubleshooting guide

## Part 1: Home-Manager Diagnostics & Fixes

### Quick Diagnosis

Run the diagnostic script to check your home-manager health:

```bash
# Check only (no changes)
/etc/nixos/scripts/diagnose-home-manager.sh --check-only

# Check and apply fixes
/etc/nixos/scripts/diagnose-home-manager.sh --fix

# Deep clean (removes old generations, optimizes store)
/etc/nixos/scripts/diagnose-home-manager.sh --deep-clean
```

### Common Issues and Solutions

#### Issue 1: Home-manager can't find store paths

**Symptoms:**
- `error: path '/nix/store/...' does not exist`
- Broken symlinks in `~/.local/state/home-manager`

**Solution:**
```bash
# Run diagnostics with fix
/etc/nixos/scripts/diagnose-home-manager.sh --fix

# Rebuild home-manager via NixOS
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Verify store integrity
nix-store --verify --check-contents --repair
```

#### Issue 2: Profile generations corrupted

**Symptoms:**
- `home-manager switch` fails
- Profile symlinks broken

**Solution:**
```bash
# Remove broken profile links
rm -f ~/.local/state/nix/profiles/home-manager*

# Rebuild from scratch
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Verify it worked
ls -la ~/.local/state/nix/profiles/
```

#### Issue 3: Nix store running out of space

**Symptoms:**
- Build failures with "no space left on device"
- `/nix/store` > 85% full

**Solution:**
```bash
# Deep clean with the script
/etc/nixos/scripts/diagnose-home-manager.sh --deep-clean

# Or manually:
nix-collect-garbage -d
sudo nix-collect-garbage -d
nix-store --optimise
```

#### Issue 4: Conflicting package versions

**Symptoms:**
- Different package versions between system and home-manager
- Duplicate packages in PATH

**Current Configuration:**
- `home-manager.useGlobalPkgs = true` - Uses system nixpkgs
- `home-manager.useUserPackages = true` - Installs to user profile

This should prevent conflicts, but if you still have issues:

```bash
# Check what's in your profile
nix profile list

# Remove duplicates if needed
nix profile remove <index>

# Rebuild cleanly
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### Understanding Home-Manager in Your Setup

Your home-manager is configured as a **NixOS module** (not standalone). This means:

- Configuration: `/etc/nixos/hosts/kernelcore/home/home.nix`
- Rebuild command: `sudo nixos-rebuild switch --flake /etc/nixos#kernelcore`
- No separate `home-manager switch` needed (though it works if installed)
- Profile location: `~/.local/state/nix/profiles/home-manager`

## Part 2: Trezor SSH Agent Setup

### Step 1: Enable Trezor SSH Agent Module

Edit `/etc/nixos/hosts/kernelcore/configuration.nix` and add:

```nix
{
  # ... existing config ...

  # Add this section
  hardware.trezor = {
    enable = true;
    enableSSHAgent = true;  # <-- Add this line
  };

  # Make sure kernelcore user is in plugdev group
  users.users.kernelcore = {
    # ... existing config ...
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "nvidia"
      "docker"
      "render"
      "qemu-libvirtd"
      "libvirtd"
      "plugdev"  # <-- Add this if not present
    ];
  };
}
```

### Step 2: Rebuild Configuration

```bash
# Check flake validity
nix flake check /etc/nixos

# Rebuild system
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Verify Trezor packages are installed
which trezor-agent
which trezorctl

# Check instructions
cat /etc/trezor/ssh-setup-instructions.txt
```

### Step 3: Initialize Trezor SSH Identity

```bash
# Connect your Trezor device

# Test Trezor connection
trezorctl ping

# Initialize SSH identity (replace with your actual username@hostname)
trezor-agent kernelcore@nx -v

# This will display your SSH public key
# Example output:
# ecdsa-sha2-nistp256 AAAAE2VjZHNh... kernelcore@nx
```

### Step 4: Add SSH Key to Servers

#### For GitHub/GitLab

```bash
# Export your Trezor SSH public key
trezor-agent kernelcore@nx -v > ~/.ssh/trezor_github.pub

# Display it
cat ~/.ssh/trezor_github.pub

# Copy and add to:
# - GitHub: https://github.com/settings/keys
# - GitLab: https://gitlab.com/-/profile/keys
```

#### For Remote Servers

```bash
# Method 1: Direct copy
trezor-agent kernelcore@nx -v | ssh user@remote-server 'cat >> ~/.ssh/authorized_keys'

# Method 2: Manual copy
trezor-agent kernelcore@nx -v > ~/.ssh/trezor_server.pub
scp ~/.ssh/trezor_server.pub user@remote-server:~/.ssh/
ssh user@remote-server 'cat ~/.ssh/trezor_server.pub >> ~/.ssh/authorized_keys'
```

### Step 5: Use Trezor for SSH

#### Method A: Direct Trezor Agent Wrapper

```bash
# Connect to server
trezor-agent kernelcore@nx -- ssh user@remote-server

# Git operations
trezor-agent git@github.com -- git push origin main

# SCP/RSYNC
trezor-agent user@server -- scp file.txt user@server:/path/
trezor-agent user@server -- rsync -av /local/ user@server:/remote/
```

#### Method B: Shell Aliases (Recommended)

Add to your `~/.bashrc` or `/etc/nixos/hosts/kernelcore/home/home.nix`:

```nix
# In home.nix, under programs.bash.shellAliases:
shellAliases = {
  # Existing aliases...

  # Trezor SSH aliases
  tssh = "trezor-agent kernelcore@nx -- ssh";
  tgit = "trezor-agent git@github.com -- git";
  tscp = "trezor-agent kernelcore@nx -- scp";
  trsync = "trezor-agent kernelcore@nx -- rsync";
};
```

Then use:
```bash
tssh user@server
tgit push origin main
tscp file.txt user@server:/path/
```

#### Method C: GPG + Trezor Integration (Advanced)

This method integrates Trezor with GPG, which then provides SSH authentication:

```bash
# Initialize Trezor GPG identity
trezor-gpg init "Your Name <sec@voidnxlabs.com>"

# List GPG keys
gpg --list-keys

# Edit your key to add SSH authentication capability
gpg --expert --edit-key YOUR_KEY_ID
# In GPG prompt:
gpg> addkey
# Select: (8) RSA (set your own capabilities)
# Toggle: E (encryption off), S (signing on), A (authentication on)
# Enter key size: 4096
# Set expiration
gpg> save

# Export SSH public key from GPG
gpg --export-ssh-key YOUR_KEY_ID > ~/.ssh/trezor_gpg.pub

# Add to target server
cat ~/.ssh/trezor_gpg.pub | ssh user@server 'cat >> ~/.ssh/authorized_keys'

# Now SSH will use GPG agent automatically (already configured in your home-manager)
ssh user@server  # Will prompt on Trezor
```

### Step 6: Verify Setup

```bash
# Check if GPG agent has SSH support
echo $SSH_AUTH_SOCK
# Should output: /run/user/1000/gnupg/S.gpg-agent.ssh

# List SSH keys managed by GPG agent
ssh-add -L

# Test SSH connection
ssh -T git@github.com  # For GitHub
# Or
trezor-agent kernelcore@nx -- ssh -T git@github.com
```

## Part 3: SSH Key Consistency Strategy

### Problem: Multiple SSH Keys Causing Conflicts

You have multiple SSH keys across different machines:
- Traditional SSH keys (`~/.ssh/id_ed25519`)
- GitHub-generated keys
- GPG-based keys
- Server-specific keys

### Solution: Centralize with Trezor

**Advantages:**
- ✅ Single source of truth (Trezor device)
- ✅ Physical confirmation required for each SSH connection
- ✅ Keys never stored on disk (private key stays in Trezor)
- ✅ Works across multiple machines (just plug in Trezor)
- ✅ Backup via recovery seed

**Transition Plan:**

1. **Add Trezor key to all services** (GitHub, GitLab, servers)
2. **Test Trezor authentication works**
3. **Remove old keys from services** (once Trezor confirmed working)
4. **Backup/archive old SSH keys** (don't delete immediately)
5. **Update Git config** to use Trezor for commits

### Hybrid Approach (Recommended During Transition)

Keep traditional keys as fallback while transitioning:

```bash
# ~/.ssh/config
Host github.com
  HostName github.com
  User git
  # Trezor key will be used via gpg-agent (tried first)
  # If Trezor not connected, falls back to traditional key
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
```

## Part 4: Post-Pull Checklist

After pulling the latest changes to your desktop:

- [ ] Run home-manager diagnostics: `/etc/nixos/scripts/diagnose-home-manager.sh --fix`
- [ ] Verify Nix store integrity: `nix-store --verify --check-contents`
- [ ] Enable Trezor SSH agent in configuration.nix
- [ ] Rebuild system: `sudo nixos-rebuild switch --flake /etc/nixos#kernelcore`
- [ ] Add kernelcore to plugdev group (should be automatic)
- [ ] Test Trezor connection: `trezorctl ping`
- [ ] Initialize Trezor SSH identity: `trezor-agent kernelcore@nx -v`
- [ ] Export and add Trezor public key to GitHub/servers
- [ ] Test Trezor SSH: `trezor-agent kernelcore@nx -- ssh -T git@github.com`
- [ ] Add shell aliases for convenience
- [ ] Clean up old generations: `/etc/nixos/scripts/diagnose-home-manager.sh --deep-clean`

## Part 5: Troubleshooting Trezor SSH

### Issue: "Device not found"

```bash
# Check USB connection
lsusb | grep -i trezor

# Check udev rules
ls -la /etc/udev/rules.d/*trezor*

# Restart udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# Replug Trezor device
```

### Issue: "Permission denied"

```bash
# Verify you're in plugdev group
groups | grep plugdev

# If not, add yourself (already in config, but verify)
sudo usermod -aG plugdev $USER

# Log out and back in for group changes to take effect
```

### Issue: "Agent not responding"

```bash
# Check GPG agent status
gpgconf --list-components

# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Verify SSH support
echo $SSH_AUTH_SOCK
```

### Issue: Git push still asks for password

```bash
# Check remote URL uses SSH, not HTTPS
git remote -v
# Should show: git@github.com:user/repo.git

# If HTTPS, change to SSH:
git remote set-url origin git@github.com:VoidNxSEC/nixos.git

# Test connection
trezor-agent git@github.com -- ssh -T git@github.com
```

## Part 6: Maintenance

### Regular Maintenance Commands

```bash
# Weekly: Check home-manager health
/etc/nixos/scripts/diagnose-home-manager.sh --check-only

# Monthly: Clean old generations
/etc/nixos/scripts/diagnose-home-manager.sh --deep-clean

# After major changes: Verify store
nix-store --verify --check-contents

# Keep Trezor firmware updated
trezorctl firmware-update
```

### Backup Strategy

**Home-manager configuration:** Already in Git (`/etc/nixos`)

**Trezor recovery seed:**
- ⚠️ **CRITICAL**: Store your 24-word recovery seed securely offline
- Test recovery on a spare Trezor before relying on it
- SSH keys can be regenerated from seed

**Traditional SSH keys (transition period):**
```bash
# Backup existing keys
mkdir -p ~/Backups/ssh-keys-$(date +%Y%m%d)
cp -r ~/.ssh/* ~/Backups/ssh-keys-$(date +%Y%m%d)/
```

## Additional Resources

- Trezor Agent Documentation: https://github.com/romanz/trezor-agent
- NixOS Home Manager: https://nix-community.github.io/home-manager/
- GPG + SSH: https://wiki.archlinux.org/title/GnuPG#SSH_agent

## Support

If issues persist after following this guide:

1. Check logs: `journalctl -xe`
2. Home-manager logs: `journalctl --user -u home-manager-$USER.service`
3. Nix daemon: `sudo journalctl -u nix-daemon`
4. Review diagnostic output: `/etc/nixos/scripts/diagnose-home-manager.sh --check-only`
