# Mosh Connection Setup - iPhone Configuration Complete ✓

## Server Status
- ✅ Mosh server installed (v1.4.0)
- ✅ SSH server running with hardened security
- ✅ Firewall configured (UDP 60000-61000)
- ✅ iPhone SSH key added to authorized_keys

## iPhone SSH Key Details
**Fingerprint**: SHA256:keKOqZQrNCJqj9DJp9ar4gzDc/ok8ju9HoQXWucxHew
**Type**: ECDSA-256
**User**: user@iphone
**Location**: /etc/ssh/authorized_keys.d/kernelcore

## Connection Instructions for Blink Shell (iOS)

### 1. Configure Host in Blink
Open Blink Shell and type:
```
config
```

Tap "Hosts" → "+" and configure:
- **Host alias**: nx (or any name you prefer)
- **HostName**: <YOUR_SERVER_IP>
- **Port**: 22
- **User**: kernelcore
- **Key**: Select your iPhone ECDSA key
- **Mosh**: Toggle ON
- **Mosh Port**: 60000
- **Mosh Server**: /run/current-system/sw/bin/mosh-server

### 2. Test SSH Connection First
```bash
ssh kernelcore@<YOUR_SERVER_IP>
```

If SSH works, proceed to Mosh.

### 3. Connect via Mosh
```bash
mosh kernelcore@<YOUR_SERVER_IP>
```

Or using the saved host:
```bash
mosh nx
```

## Server Information
- **Hostname**: nx
- **SSH Port**: 22 (TCP)
- **Mosh Ports**: 60000-61000 (UDP)
- **User**: kernelcore

## Firewall Ports (if connecting remotely)
Make sure these ports are forwarded on your router:
- TCP 22 (SSH)
- UDP 60000-61000 (Mosh)

## Troubleshooting

### Test commands on server:
```bash
# Check Mosh is installed
which mosh-server

# Check SSH service
systemctl status sshd

# Check firewall rules (requires sudo)
sudo nft list ruleset | grep 60000

# View authorized keys
cat /etc/ssh/authorized_keys.d/kernelcore

# Test local Mosh connection
mosh kernelcore@localhost
```

### Common issues:

**"Permission denied (publickey)"**
- Make sure you're using the correct ECDSA key in Blink
- The key fingerprint should match: SHA256:keKOqZQrNCJqj9DJp9ar4gzDc/ok8ju9HoQXWucxHew

**"Connection timed out"**
- Check if UDP ports 60000-61000 are open on your firewall
- Verify router port forwarding for UDP if connecting remotely

**"mosh-server not found"**
- Use full path in Blink: /run/current-system/sw/bin/mosh-server

## Full Documentation
For complete setup instructions:
```bash
cat /etc/mosh/setup-instructions.txt
```

## Security Notes
- SSH uses public key authentication only (no passwords)
- Mosh uses encrypted UDP (AES-128-OCB)
- All connections are logged and monitored
- 2FA is available (currently disabled)

