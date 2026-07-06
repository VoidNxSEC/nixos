# OS Keyring Setup Guide

> **Purpose**: Complete guide for setting up and using the OS keyring with gnome-keyring and KeePassXC integration on Hyprland
> **Created**: 2025-11-08
> **Status**: Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [What is an OS Keyring?](#what-is-an-os-keyring)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Initial Setup](#initial-setup)
6. [KeePassXC Integration](#keepassxc-integration)
7. [Application Integration](#application-integration)
8. [Troubleshooting](#troubleshooting)
9. [Security Considerations](#security-considerations)

---

## Overview

This guide covers the OS keyring implementation for NixOS with Hyprland window manager. The keyring provides secure credential storage using the **Secret Service API** (freedesktop.org standard), allowing applications to store passwords, tokens, and certificates securely.

### What Was Implemented

- **gnome-keyring**: Secret Service API daemon
- **Seahorse**: GUI for keyring management
- **KeePassXC integration**: Optional integration with KeePassXC database
- **PAM integration**: Auto-unlock keyring on login
- **Systemd service**: Auto-start with Hyprland session

---

## What is an OS Keyring?

An **OS keyring** (also called **credential store** or **secret service**) is a system service that securely stores sensitive data like:

- Passwords (browser, email, applications)
- API tokens and authentication keys
- SSH keys and certificates
- WiFi passwords
- OAuth tokens
- GPG passphrases

### Why Do You Need It?

**Without a keyring:**
- Applications store credentials in plain text files
- Each app has its own insecure storage method
- Credentials scattered across filesystem
- No centralized security policy

**With a keyring:**
- ✅ Encrypted credential storage
- ✅ Single unlock (login password unlocks all)
- ✅ Standardized API (Secret Service)
- ✅ Per-application access control
- ✅ Audit trail of credential access

### Secret Service API

The **Secret Service API** is a D-Bus interface defined by freedesktop.org that allows applications to:

1. Store secrets (passwords, tokens, etc.)
2. Retrieve secrets when needed
3. Search for stored credentials
4. Lock/unlock keyrings
5. Receive notifications of keyring changes

**Supported by:**
- Chromium/Chrome (native support)
- Firefox (via `libsecret`)
- VSCode/VSCodium
- Git credential helper
- Network Manager
- Thunderbird
- Evolution
- Many other Linux applications

---

## Architecture

### Component Stack

```
┌─────────────────────────────────────────────┐
│         Applications (Browsers, etc.)       │
│    Brave, Firefox, VSCode, Git, etc.        │
└──────────────────┬──────────────────────────┘
                   │
                   │ Secret Service API
                   │ (D-Bus Interface)
                   │
        ┌──────────▼──────────┐
        │   gnome-keyring     │ ◄──── Primary Provider
        │  (Secret Service    │
        │   Implementation)   │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │  Encrypted Storage  │
        │  ~/.local/share/    │
        │    keyrings/        │
        └─────────────────────┘

        ┌─────────────────────┐
        │    KeePassXC        │ ◄──── Alternative Provider
        │ (Optional Secret    │       (can replace or coexist)
        │  Service Provider)  │
        └─────────────────────┘
```

### How It Works

1. **Application needs credential** → Calls Secret Service API via D-Bus
2. **gnome-keyring responds** → Checks if keyring is unlocked
3. **If locked** → Prompts for password (or auto-unlocked via PAM)
4. **If unlocked** → Returns encrypted credential to application
5. **Application uses credential** → Keyring logs access

### File Locations

```
/etc/nixos/modules/security/keyring.nix  # Module configuration
~/.local/share/keyrings/                 # Encrypted keyring storage
  ├── default.keyring                    # Default keyring
  ├── login.keyring                      # Auto-unlocked keyring
  └── *.keyring                          # Custom keyrings
/run/user/$UID/keyring/                  # Runtime sockets
  ├── control                            # Control socket
  └── ssh                                # SSH agent socket
```

---

## Installation

### Verify Module is Enabled

The keyring module is already enabled in your configuration:

**File: `/etc/nixos/hosts/kernelcore/configuration.nix`**

```nix
kernelcore.security.keyring = {
  enable = true;                      # Enable OS keyring
  enableGUI = true;                   # Seahorse GUI
  enableKeePassXCIntegration = true;  # KeePassXC support
  autoUnlock = true;                  # Auto-unlock on login
};
```

### Rebuild System

```bash
# Rebuild to apply keyring configuration
sudo nixos-rebuild switch

# Reboot (recommended for clean PAM initialization)
sudo reboot
```

---

## Initial Setup

### Step 1: Verify gnome-keyring is Running

After reboot, verify the keyring daemon started:

```bash
# Check systemd service status
systemctl --user status gnome-keyring

# Expected output:
# ● gnome-keyring.service - GNOME Keyring daemon
#      Loaded: loaded (/etc/systemd/user/gnome-keyring.service)
#      Active: active (running) since ...
```

If not running:

```bash
# Start manually
systemctl --user start gnome-keyring

# Enable for future sessions
systemctl --user enable gnome-keyring
```

### Step 2: Verify Secret Service is Available

Check that the Secret Service API is accessible:

```bash
# Check D-Bus service
dbus-send --print-reply --session \
  --dest=org.freedesktop.secrets \
  /org/freedesktop/secrets \
  org.freedesktop.DBus.Introspectable.Introspect | head -20

# Expected: XML output describing the Secret Service interface
```

If you get "service not available":

```bash
# Restart D-Bus user session
systemctl --user restart dbus

# Restart gnome-keyring
systemctl --user restart gnome-keyring
```

### Step 3: Launch Seahorse (Keyring GUI)

```bash
# Launch Seahorse
seahorse &

# Or from application menu: "Passwords and Keys"
```

**First Launch:**

1. **No password prompt** - Keyring should already be unlocked (auto-unlock via PAM)
2. **Default keyring created** - Named "Default" or "Login"
3. **Empty keyring** - No passwords stored yet

### Step 4: Set Keyring Password (Optional)

By default, the keyring password is your **login password** (auto-unlock via PAM).

**To set a different password:**

1. Open Seahorse
2. Right-click "Login" keyring → **Change Password**
3. Enter old password (your login password)
4. Enter new password
5. Confirm

**Warning:** If you change the keyring password, auto-unlock will stop working. You'll need to unlock manually after each login.

---

## KeePassXC Integration

KeePassXC can act as a **Secret Service provider** alongside (or instead of) gnome-keyring.

### Benefits of KeePassXC Integration

- ✅ All credentials in one encrypted database
- ✅ Cross-platform (KeePassXC database portable)
- ✅ Advanced features (TOTP, attachments, notes)
- ✅ Browser extensions (KeePassXC-Browser)
- ✅ More granular access control

### Setup KeePassXC Secret Service

#### Step 1: Open KeePassXC Settings

```bash
keepassxc &
```

1. Open your KeePassXC database (or create new one)
2. Go to: **Tools → Settings**
3. Navigate to: **Secret Service Integration**

#### Step 2: Enable Secret Service

1. ✅ **Enable KeePassXC Freedesktop.org Secret Service integration**
2. Select **which database** to expose:
   - Choose your main database
   - Or create a dedicated "System Keyring" database

3. **Configure exposed groups** (recommended):
   - Create a group called `System/Keyring` in your database
   - Configure KeePassXC to only expose this group
   - This prevents all passwords from being accessible via Secret Service

#### Step 3: Configure Access Control

1. **Expose entire database** (less secure):
   - Any app can request any credential
   - You'll be prompted to approve each request

2. **Expose specific groups** (recommended):
   - Only credentials in selected groups are accessible
   - Create groups like:
     - `System/Keyring/Browsers`
     - `System/Keyring/Git`
     - `System/Keyring/Applications`

#### Step 4: Test Integration

```bash
# Test with secret-tool (libsecret CLI)
secret-tool store --label='Test Credential' service test username testuser
# Enter password when prompted

# Retrieve credential
secret-tool lookup service test username testuser
# Should print the password

# Check in KeePassXC
# New entry should appear in exposed group

# Delete test credential
secret-tool clear service test username testuser
```

### Coexistence: gnome-keyring + KeePassXC

Both can run simultaneously:

- **gnome-keyring**: Stores system credentials (WiFi, etc.)
- **KeePassXC**: Stores user credentials (browsers, apps)

**Priority:** First service to claim the Secret Service D-Bus name wins.

**To prefer KeePassXC:**
1. Disable gnome-keyring Secret Service component:
   ```nix
   # In keyring.nix config (advanced)
   systemd.user.services.gnome-keyring.serviceConfig.ExecStart =
     "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=ssh,pkcs11";
   # Note: removed 'secrets' component
   ```

2. Start KeePassXC before gnome-keyring
3. Enable Secret Service in KeePassXC first

---

## Application Integration

### Browsers

#### Chromium / Brave / Chrome

**Native support** - no configuration needed.

1. Open browser
2. Save a password (e.g., login to a website)
3. **First time:** Keyring unlock prompt may appear
4. Password stored in keyring

**Verify:**

```bash
# List browser credentials in keyring
secret-tool search service chrome
# or
secret-tool search service chromium
```

**View in Seahorse:**
- Open Seahorse
- Expand "Login" keyring
- Look for "Chrome Safe Storage" or similar entries

#### Firefox

Firefox uses its own password manager by default, but can use the system keyring.

**Enable system keyring in Firefox:**

1. Install `libsecret` integration:
   ```bash
   # Already included in keyring module
   # No action needed
   ```

2. Firefox may prompt to use system keyring on first password save
3. Or configure manually:
   - Go to `about:preferences#privacy`
   - **Passwords** → Use system keyring (if available)

### Git Credential Helper

**Configure Git to use keyring:**

```bash
# Set credential helper to libsecret
git config --global credential.helper /run/current-system/sw/libexec/git-core/git-credential-libsecret

# Or if path differs:
git config --global credential.helper libsecret
```

**Test:**

```bash
# Clone a private repo (prompts for credentials)
git clone https://github.com/your-private-repo.git

# Credentials stored in keyring
# Next clone won't prompt for password

# View stored credentials
secret-tool search protocol https
```

### VSCode / VSCodium

**Automatic** - VSCode/VSCodium detects Secret Service API.

**Stored credentials:**
- GitHub tokens
- GitLab tokens
- Azure DevOps credentials
- Extension marketplace tokens

**View in Seahorse:**
- Look for entries labeled "Visual Studio Code" or "VSCodium"

### Network Manager (WiFi Passwords)

**Automatic** - Network Manager uses Secret Service by default.

**Stored credentials:**
- WiFi passwords (WPA/WPA2)
- VPN credentials
- Mobile broadband PINs

**View in Seahorse:**
- Expand "Login" keyring
- Look for entries like:
  - `802-11-wireless-security / SSID_NAME`
  - `vpn / VPN_NAME`

### SSH Keys (via gnome-keyring SSH agent)

gnome-keyring includes an SSH agent component.

**Add SSH key to keyring:**

```bash
# Add key with passphrase
ssh-add ~/.ssh/id_rsa

# Passphrase stored in keyring
# Next login: key auto-loaded (if using default keyring)
```

**Check loaded keys:**

```bash
ssh-add -l
```

**Note:** If you prefer `gpg-agent` for SSH, disable gnome-keyring SSH agent:

```nix
# In keyring.nix (advanced)
# Remove "ssh" from components in ExecStart
```

### Thunderbird (Email)

**Automatic** - Thunderbird uses Secret Service for email passwords.

**Stored credentials:**
- IMAP/POP3 passwords
- SMTP passwords
- OAuth tokens (Gmail, Outlook)

---

## Troubleshooting

### Keyring Not Unlocking Automatically

**Symptoms:**
- Prompted for keyring password after login
- "Unlock Keyring" dialog appears

**Cause:** PAM integration not working.

**Solution:**

1. Verify PAM configuration:
   ```bash
   cat /etc/pam.d/login | grep keyring
   # Should contain: auth optional pam_gnome_keyring.so
   ```

2. Ensure keyring password matches login password:
   ```bash
   # In Seahorse:
   # Right-click "Login" keyring → Change Password
   # Set to your current login password
   ```

3. Rebuild and reboot:
   ```bash
   sudo nixos-rebuild switch
   sudo reboot
   ```

### Secret Service Not Available

**Symptoms:**
- Applications can't save passwords
- `dbus-send` to Secret Service fails

**Cause:** gnome-keyring not running or D-Bus registration failed.

**Solution:**

1. Check service status:
   ```bash
   systemctl --user status gnome-keyring
   ```

2. Check D-Bus registration:
   ```bash
   busctl --user list | grep secrets
   # Should show: org.freedesktop.secrets
   ```

3. Restart services:
   ```bash
   systemctl --user restart dbus
   systemctl --user restart gnome-keyring
   ```

4. Check logs:
   ```bash
   journalctl --user -u gnome-keyring -b
   ```

### KeePassXC Secret Service Conflicts

**Symptoms:**
- Both gnome-keyring and KeePassXC claim Secret Service
- Credentials saved to wrong keyring

**Cause:** D-Bus name conflict.

**Solution:**

**Option A: Prefer KeePassXC**
1. Disable gnome-keyring secrets component:
   ```bash
   systemctl --user stop gnome-keyring
   systemctl --user disable gnome-keyring
   ```

2. Only start KeePassXC Secret Service

**Option B: Prefer gnome-keyring**
1. Disable KeePassXC Secret Service:
   - KeePassXC Settings → Secret Service Integration
   - ✅ Disable integration

**Option C: Use both with priorities**
- Start preferred service first
- Second service will fail to claim D-Bus name (expected)

### Passwords Not Syncing Between Devices

**Symptoms:**
- KeePassXC passwords available, but not keyring passwords
- Or vice versa

**Explanation:**
- gnome-keyring stores credentials locally (`~/.local/share/keyrings/`)
- KeePassXC stores credentials in database file (can be synced)

**Solution for sync:**
1. Use KeePassXC Secret Service exclusively
2. Store KeePassXC database in synced location:
   - Nextcloud
   - Syncthing
   - Git repository (encrypted)
   - Cloud storage (Dropbox, Google Drive, etc.)

### SSH Agent Conflicts

**Symptoms:**
- SSH keys not loading
- Multiple SSH agents running

**Cause:** Both gnome-keyring and gpg-agent providing SSH agent.

**Solution:**

Check which SSH agent is active:

```bash
echo $SSH_AUTH_SOCK
# Outputs something like:
# /run/user/1000/keyring/ssh  (gnome-keyring)
# /run/user/1000/gnupg/S.gpg-agent.ssh  (gpg-agent)
```

**Choose one:**

**Use gnome-keyring SSH agent:**
```nix
# Disable gpg-agent SSH support in home.nix
services.gpg-agent.enableSshSupport = false;
```

**Use gpg-agent SSH agent:**
```nix
# In keyring.nix, modify ExecStart to remove ssh component
# Or set in your shell config:
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
```

### Seahorse Shows No Keyrings

**Symptoms:**
- Seahorse opens but shows empty
- No "Login" or "Default" keyring

**Cause:** Keyrings not created yet.

**Solution:**

1. Create default keyring:
   ```bash
   # Using secret-tool to trigger creation
   secret-tool store --label='Initial' test test
   # Enter password when prompted
   secret-tool clear test test
   ```

2. Restart Seahorse:
   ```bash
   killall seahorse
   seahorse &
   ```

3. Manual creation:
   - Seahorse → File → New → Password Keyring
   - Name: "Login" or "Default"
   - Set password to your login password (for auto-unlock)

---

## Security Considerations

### Keyring Encryption

- **Default keyring:** Encrypted with your login password
- **Custom keyrings:** Encrypted with password you set
- **Encryption algorithm:** AES-256 (via libgcrypt)
- **Key derivation:** PBKDF2 with salt

### Auto-Unlock Security

**Auto-unlock via PAM:**
- ✅ Convenient (no extra password prompt)
- ⚠️ Keyring unlocked when you log in
- ⚠️ Anyone with your login password can access keyring

**If you need higher security:**
1. Disable `autoUnlock` in configuration:
   ```nix
   kernelcore.security.keyring.autoUnlock = false;
   ```

2. Set different keyring password:
   - Seahorse → Right-click "Login" → Change Password
   - Set strong, unique password

3. You'll be prompted to unlock keyring after login

### Per-Application Access Control

Applications requesting credentials trigger a prompt:

**Example prompt:**
```
Application "Brave Browser" wants to access
"Password for google.com"

[ Deny ]  [ Allow Once ]  [ Allow Always ]
```

**Best practices:**
- Review application names carefully
- Use "Allow Once" for unknown apps
- Use "Allow Always" only for trusted apps
- Periodically review access in Seahorse:
  - Seahorse → Right-click entry → Access Control
  - View which apps have access
  - Revoke unnecessary access

### KeePassXC Security

**Advantages:**
- ✅ Encrypted database file (portable)
- ✅ Strong encryption (AES-256, ChaCha20)
- ✅ Key file support (two-factor)
- ✅ TOTP integration
- ✅ Audit log

**Considerations:**
- ⚠️ Database file must be protected
- ⚠️ Database password is master key
- ⚠️ Compromised database file = offline attack possible

**Recommendations:**
1. Use strong master password (20+ chars)
2. Enable key file (store separately)
3. Set database timeout (auto-lock after inactivity)
4. Regular backups (encrypted)
5. Don't expose entire database via Secret Service (use groups)

### Network Exposure

**gnome-keyring:**
- ✅ Local only (D-Bus session bus)
- ✅ No network exposure
- ✅ Per-user isolation

**Ensure D-Bus security:**
- D-Bus session bus is user-specific
- No remote connections
- Access control via Unix permissions

---

## Advanced Configuration

### Custom Keyrings

Create separate keyrings for different purposes:

```bash
# Create work keyring
seahorse → File → New → Password Keyring
Name: "Work"
Password: <strong_password>

# Store credential in work keyring
secret-tool store --label='Work Email' \
  --collection=Work \
  service email username work@company.com
```

### Keyring Timeout

Configure keyring to auto-lock after inactivity:

**Via Seahorse:**
1. Right-click keyring → Properties
2. ✅ Lock keyring after period of inactivity
3. Set timeout (e.g., 30 minutes)

**Via command line:**
```bash
# Lock keyring immediately
gnome-keyring-daemon --lock
```

### Backup Keyrings

```bash
# Backup keyring directory
tar -czf keyring-backup-$(date +%Y%m%d).tar.gz \
  ~/.local/share/keyrings/

# Restore
tar -xzf keyring-backup-*.tar.gz -C ~/
```

**Note:** Backups contain encrypted data, but protect the archive.

### Scripting with secret-tool

```bash
# Store credential
secret-tool store --label='API Token' \
  service myapi \
  username myuser \
  token mytoken

# Retrieve credential
secret-tool lookup service myapi username myuser

# Search credentials
secret-tool search service myapi

# Clear credential
secret-tool clear service myapi username myuser
```

---

## Configuration Reference

### Module Options

**File: `/etc/nixos/modules/security/keyring.nix`**

```nix
kernelcore.security.keyring = {
  # Enable OS keyring
  enable = mkEnableOption "OS keyring support with gnome-keyring and KeePassXC integration";

  # Enable Seahorse GUI for keyring management
  enableGUI = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Seahorse GUI for keyring management";
  };

  # Enable KeePassXC Secret Service API integration
  enableKeePassXCIntegration = mkOption {
    type = types.bool;
    default = true;
    description = "Enable KeePassXC Secret Service API integration";
  };

  # Automatically unlock keyring on login using PAM
  autoUnlock = mkOption {
    type = types.bool;
    default = true;
    description = "Automatically unlock keyring on login using PAM";
  };
};
```

### Installed Packages

- `gnome-keyring` - Secret Service daemon
- `libsecret` - Secret Service API library
- `libgnome-keyring` - Legacy compatibility
- `seahorse` - GUI keyring manager (if `enableGUI = true`)
- `keepassxc` - Password manager with Secret Service support

### Systemd Services

**User service:** `gnome-keyring.service`

```bash
# Status
systemctl --user status gnome-keyring

# Logs
journalctl --user -u gnome-keyring -f

# Restart
systemctl --user restart gnome-keyring
```

### Environment Variables

```bash
# Secret Service control socket
GNOME_KEYRING_CONTROL=/run/user/$UID/keyring

# SSH agent socket (if using gnome-keyring SSH agent)
SSH_AUTH_SOCK=/run/user/$UID/keyring/ssh
```

---

## References

### Documentation

- **Secret Service API Specification**: https://specifications.freedesktop.org/secret-service/
- **gnome-keyring Manual**: `man gnome-keyring-daemon`
- **secret-tool Manual**: `man secret-tool`
- **KeePassXC Documentation**: https://keepassxc.org/docs/
- **Seahorse Help**: `yelp help:seahorse` or https://wiki.gnome.org/Apps/Seahorse

### Related NixOS Modules

- **This module**: `/etc/nixos/modules/security/keyring.nix`
- **PAM configuration**: `/etc/nixos/modules/security/pam.nix`
- **Hyprland desktop**: `/etc/nixos/modules/desktop/hyprland.nix`

### Useful Commands

```bash
# Check Secret Service availability
busctl --user list | grep secrets

# Introspect Secret Service API
dbus-send --print-reply --session \
  --dest=org.freedesktop.secrets \
  /org/freedesktop/secrets \
  org.freedesktop.DBus.Introspectable.Introspect

# List all stored credentials
secret-tool search --all

# Monitor D-Bus Secret Service calls
dbus-monitor --session "interface='org.freedesktop.Secret.Service'"

# Check SSH agent
ssh-add -l
```

---

## Conclusion

You now have a fully functional OS keyring system with:

- ✅ Secure credential storage (encrypted)
- ✅ Auto-unlock on login (PAM integration)
- ✅ GUI management (Seahorse)
- ✅ Browser integration (Chromium, Firefox)
- ✅ Git credential storage
- ✅ KeePassXC integration support
- ✅ SSH agent support

**Next Steps:**

1. Rebuild system: `sudo nixos-rebuild switch`
2. Reboot for clean initialization
3. Open Seahorse and verify keyring created
4. Configure KeePassXC Secret Service (optional)
5. Test with browser password save

**Need Help?**

- Check [Troubleshooting](#troubleshooting) section
- Review logs: `journalctl --user -u gnome-keyring`
- Test Secret Service: `secret-tool store/lookup`

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-08
**Maintained By**: kernelcore
**Module Location**: `/etc/nixos/modules/security/keyring.nix`
