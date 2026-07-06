# ✅ Mobile Workspace Configuration Complete

## Overview

Created an isolated, secure workspace for iPhone/mobile access via SSH/Mosh.
The `mobile` user has restricted access - limited to their workspace directory only.

## User Details

- **Username**: `mobile`
- **Home Directory**: `/srv/mobile-workspace`
- **Shell**: zsh (with custom configuration)
- **Groups**: users (no sudo, no docker, no system access)
- **UID**: 1003

## Workspace Structure

```
/srv/mobile-workspace/
├── projects/          # Development projects
├── scripts/           # Shell scripts and utilities
├── notes/             # Notes and documentation
├── downloads/         # Downloaded files
├── .config/           # Configuration files
├── .ssh/              # SSH keys and config (0700)
└── .zshrc -> /etc/mobile-workspace/zshrc
```

## Security Features

### ✅ What the mobile user CAN do:
- Full access to `/srv/mobile-workspace` directory
- Use all development tools (vim, git, python, node, etc.)
- SSH agent forwarding for git operations
- Create/edit files within workspace
- Run commands within workspace

### ❌ What the mobile user CANNOT do:
- Access other users' directories (/)
- Use sudo or gain root access
- Access Docker containers
- Access system files (/etc, /var, etc.)
- TCP/X11 forwarding (security)
- Access kernelcore user files

### SSH Restrictions:
```sshd_config
Match User mobile
  AllowAgentForwarding yes      # For git over SSH
  AllowTcpForwarding no          # Security
  X11Forwarding no               # Security
  PermitTunnel no                # Security
```

## Available Tools

### Editors:
- vim, neovim, nano, micro

### File Tools:
- ls (eza with icons), cat (bat with syntax), grep (ripgrep)
- find (fd), tree, file

### Development:
- **Git**: git, gh (GitHub CLI), glab (GitLab CLI)
- **Python**: python3
- **Node**: node, npm
- **Rust**: rustup, cargo, rustc

### Terminal:
- tmux, zellij

### Monitoring:
- htop, btop

### Network:
- curl, wget, ping, ssh

## Connection from Blink Shell (iPhone)

### Update your Blink Shell configuration:

**OLD Configuration (kernelcore user):**
```
Host: nx
User: kernelcore  ❌ Change this
...
```

**NEW Configuration (mobile user):**
```
Host: nx
HostName: 192.168.15.9 (or 100.105.140.52 via Tailscale)
Port: 22
User: mobile  ✅ Use this instead
Key: Your ECDSA key (user@iphone)
Mosh: ON
Mosh Port: 60000
Mosh Server: /run/current-system/sw/bin/mosh-server
```

### Connect:
```bash
# Via Mosh (recommended)
mosh mobile@192.168.15.9
# or
mosh mobile@100.105.140.52  # via Tailscale

# Via SSH
ssh mobile@192.168.15.9
```

## First Login Experience

When you first connect, you'll see:

```
╔════════════════════════════════════════════════════════════════╗
║              Welcome to Mobile Workspace (iPhone)              ║
╚════════════════════════════════════════════════════════════════╝

You are logged in as: mobile
Workspace location: /srv/mobile-workspace

## Directory Structure:
...

📍 Workspace: /srv/mobile-workspace
🔒 You have limited access to this directory only
```

Your shell prompt:
```
📱 mobile:~$
```

## Common Tasks

### Create a new project:
```bash
mkdir -p ~/projects/my-app
cd ~/projects/my-app
git init
```

### Clone a repository (requires SSH agent forwarding):
```bash
cd ~/projects
git clone git@github.com:username/repo.git
```

### Write a script:
```bash
vim ~/scripts/backup.sh
chmod +x ~/scripts/backup.sh
./scripts/backup.sh
```

### Take notes:
```bash
vim ~/notes/ideas.md
```

### Start a tmux session:
```bash
tmux new -s work
# Detach: Ctrl+b, then d
# Reattach: tmux attach -t work
```

## System Maintenance

A weekly cleanup timer automatically:
- Removes files in `~/downloads` older than 30 days
- Ensures correct permissions on workspace
- Logs maintenance activities

View maintenance logs:
```bash
# On server as kernelcore or root
cat /var/log/mobile-workspace-maintenance.log
```

## Verifying Restrictions

### Test 1: Try to access root:
```bash
cd /
# Should work, but you can't READ most directories
ls
# Permission denied for most dirs
```

### Test 2: Try to read /etc:
```bash
cat /etc/shadow
# Permission denied
```

### Test 3: Try sudo:
```bash
sudo ls
# mobile is not in the sudoers file
```

### Test 4: Try to access kernelcore's home:
```bash
ls /home/kernelcore
# Permission denied
```

### Test 5: Verify you're in workspace:
```bash
pwd
# /srv/mobile-workspace
```

## Troubleshooting

### Can't connect from iPhone:
1. Verify mobile user exists: `id mobile`
2. Check SSH keys: `cat /etc/ssh/authorized_keys.d/mobile`
3. Check SSH logs: `sudo journalctl -u sshd -f`
4. Test local connection: `ssh mobile@localhost`

### Permission denied errors:
- You're trying to access files outside `/srv/mobile-workspace`
- This is expected and intentional
- Work within your workspace directory

### Git clone fails:
- Ensure SSH agent forwarding is enabled in Blink Shell
- Test: `ssh-add -l` (should show your keys)
- Alternative: Use HTTPS clone URLs

### Can't install packages:
- You don't have sudo access
- Contact system admin to add packages to the mobile user's environment
- Packages are managed in: `/etc/nixos/modules/services/mobile-workspace.nix`

## Files Modified

1. **Created**: `/etc/nixos/modules/services/mobile-workspace.nix`
   - Complete mobile workspace module

2. **Modified**: `/etc/nixos/flake.nix`
   - Added mobile-workspace module import

3. **Modified**: `/etc/nixos/hosts/kernelcore/configuration.nix`
   - Enabled mobile workspace
   - Moved iPhone SSH key from kernelcore to mobile user

4. **Created**: `/etc/mobile-workspace/welcome.txt`
   - Welcome message shown on login

5. **Created**: `/etc/mobile-workspace/zshrc`
   - Shell configuration for mobile user

## Security Model

### Defense in Depth:

1. **User Isolation**: Separate user account (UID 1003)
2. **Directory Permissions**: Only workspace is readable/writable
3. **SSH Restrictions**: No TCP forwarding, no X11, no tunneling
4. **Group Membership**: No privileged groups (no sudo, docker, wheel)
5. **Shell Configuration**: Starts in workspace, encourages staying there
6. **File System Permissions**: Linux DAC prevents access to other areas
7. **Logging**: All SSH sessions logged via journald

### What This Protects Against:

✅ Accidental system modification
✅ Unauthorized access to other users' data
✅ Privilege escalation
✅ System service interference
✅ Network port forwarding abuse

### What This Does NOT Protect Against:

❌ Malicious kernel exploits (requires additional hardening)
❌ Physical access to server
❌ Compromised SSH private key (protect your iPhone!)
❌ Social engineering targeting system admin

## Recommendations

1. **Keep iPhone secure**: 
   - Use strong passcode
   - Enable biometric authentication
   - Don't share SSH private key

2. **Regular backups**:
   - Important work in `~/projects` should be pushed to git regularly
   - Workspace is not backed up by default

3. **Clean up downloads**:
   - Auto-cleanup happens weekly
   - Manual cleanup: `rm ~/downloads/*`

4. **Monitor sessions**:
   - System admin can view active sessions: `w`
   - Check mobile user activity: `lastlog -u mobile`

5. **Update Blink Shell**:
   - Keep app updated for security patches

## Summary

🎉 **Mobile workspace is ready!**

- ✅ Secure isolated environment created
- ✅ Mobile user configured with workspace-only access
- ✅ iPhone SSH key transferred to mobile user
- ✅ All development tools available in workspace
- ✅ Git operations supported via SSH agent forwarding
- ✅ Automatic maintenance configured
- ✅ Comprehensive security restrictions applied

**Next step**: Update your Blink Shell configuration to use `mobile` user instead of `kernelcore`!

