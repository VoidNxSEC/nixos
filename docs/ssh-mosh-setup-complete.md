# ✅ SSH & Mosh Configuration Complete

## What was configured:

### 1. Mosh Server Setup
- **Installed**: Mosh 1.4.0
- **Ports**: UDP 60000-61000 (automatically opened in firewall)
- **Status**: Active and ready for connections

### 2. SSH Security - Fixed for Mobile Compatibility
**Issues Found and Fixed:**
- ✅ Added ECDSA support to `HostKeyAlgorithms`
- ✅ Generated ECDSA host key for server
- ✅ Added ECDH algorithms to `KexAlgorithms` for mobile fallback

**Current Cryptographic Configuration:**
```
Ciphers: chacha20-poly1305, aes256-gcm, aes128-gcm
MACs: hmac-sha2-512-etm, hmac-sha2-256-etm
KexAlgorithms: curve25519-sha256, ecdh-sha2-nistp256/384/521
HostKeyAlgorithms: ssh-ed25519, ecdsa-sha2-nistp256/384/521, rsa-sha2-512/256
```

**Security Maintained:**
- Strong modern ciphers only
- Public key authentication only (no passwords)
- Root login disabled
- MaxAuthTries: 3
- Comprehensive logging (VERBOSE)

### 3. iPhone SSH Key
**Added**: `ecdsa-sha2-nistp256` key for user@iphone
**Fingerprint**: `SHA256:keKOqZQrNCJqj9DJp9ar4gzDc/ok8ju9HoQXWucxHew`
**Location**: `/etc/ssh/authorized_keys.d/kernelcore`

### 4. Server Host Keys
```
ED25519:  SHA256:... (primary, most secure)
ECDSA:    SHA256:K88Pwg68CLhY9/0lyUJWMN8ufwc29u6oIRAatVclBWM (mobile compatible)
RSA-4096: SHA256:... (legacy fallback)
```

## Files Modified:
1. `/etc/nixos/modules/security/ssh.nix` - Added ECDSA support and host keys
2. `/etc/nixos/sec/hardening.nix` - Updated crypto algorithms
3. `/etc/nixos/modules/services/mosh.nix` - Created Mosh module
4. `/etc/nixos/flake.nix` - Added Mosh module import
5. `/etc/nixos/hosts/kernelcore/configuration.nix` - Enabled Mosh + added iPhone key

## Blink Shell Connection Guide:

### Step 1: Configure Host in Blink
Open Blink Shell on your iPhone:
```
config → Hosts → +
```

**Configuration:**
- Host alias: `nx`
- HostName: `YOUR_SERVER_IP_OR_DOMAIN`
- Port: `22`
- User: `kernelcore`
- Key: Select your ECDSA key (user@iphone)
- **Mosh**: Toggle ON ✓
- Mosh Port: `60000`
- Mosh Server: `/run/current-system/sw/bin/mosh-server`

### Step 2: Connect

**Via Mosh (recommended for mobile):**
```bash
mosh kernelcore@YOUR_SERVER_IP
# or using the alias
mosh nx
```

**Via SSH (to test first):**
```bash
ssh kernelcore@YOUR_SERVER_IP
# or
ssh nx
```

## Network Requirements:

### Local Network:
- No additional configuration needed
- SSH: TCP 22
- Mosh: UDP 60000-61000

### Remote Access (Internet):
Port forward on your router:
- **TCP 22** → Server IP (SSH)
- **UDP 60000-61000** → Server IP (Mosh)

### Recommended: Tailscale
For secure remote access without port forwarding:
```bash
# Already installed and enabled on your system
tailscale status
```

## Troubleshooting:

### Test SSH first:
```bash
ssh -v kernelcore@YOUR_SERVER_IP
```
Look for:
- ✅ "Authenticating with public key..."
- ✅ "Authentication succeeded"

### Test Mosh connection:
```bash
mosh --server=/run/current-system/sw/bin/mosh-server kernelcore@YOUR_SERVER_IP
```

### Check server logs:
```bash
sudo journalctl -u sshd -f
```

### Verify iPhone key:
```bash
cat /etc/ssh/authorized_keys.d/kernelcore
ssh-keygen -lf /etc/ssh/authorized_keys.d/kernelcore
```

### Test local connection first:
```bash
# From the server itself
mosh kernelcore@localhost
```

## Security Notes:

✅ **What we maintained:**
- Strong encryption (ChaCha20, AES-256-GCM)
- Modern key exchange (Curve25519)
- Public key authentication only
- No root login
- Comprehensive audit logging

✅ **What we added for compatibility:**
- ECDSA support (widely used by mobile clients)
- ECDH fallback algorithms (industry standard)
- Still maintains excellent security posture

❌ **What we DO NOT allow:**
- Password authentication
- Weak ciphers (DES, RC4, etc.)
- Weak MACs (MD5, SHA1)
- Root login
- Empty passwords

## Documentation:

Full setup guide:
```bash
cat /etc/mosh/setup-instructions.txt
```

SSH troubleshooting:
```bash
cat /etc/nixos-ssh/README.md
```

## Next Steps:

1. Find your server's IP address:
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```

2. Configure Blink Shell on your iPhone (see Step 1 above)

3. Test SSH connection first

4. Switch to Mosh for mobile roaming and low-latency

5. (Optional) Set up Tailscale for secure remote access

## Summary:

🎉 **All systems configured and ready!**

- ✅ Mosh server installed and firewall configured
- ✅ SSH hardening with mobile compatibility
- ✅ iPhone ECDSA key added and verified
- ✅ ECDSA host key generated
- ✅ Crypto algorithms optimized for security + compatibility

You can now connect from Blink Shell on your iPhone!

