# VM Clipboard Sharing Setup

## Overview

Clipboard sharing between host and guest VMs is now enabled via SPICE protocol.

## Host Configuration (Already Done ✅)

The NixOS host is already configured with:
- SPICE packages (spice-gtk, spice-protocol)
- SPICE USB redirection enabled
- VM configuration using SPICE graphics with clipboard support

## Guest Configuration (Do This Inside VM)

### For Ubuntu/Debian-based VMs:
```bash
# Install spice-vdagent
sudo apt update
sudo apt install spice-vdagent

# Enable and start the service
sudo systemctl enable spice-vdagent
sudo systemctl start spice-vdagent

# Verify it's running
sudo systemctl status spice-vdagent
```

### For Fedora/RHEL-based VMs:
```bash
# Install spice-vdagent
sudo dnf install spice-vdagent

# Enable and start the service
sudo systemctl enable spice-vdagent
sudo systemctl start spice-vdagent
```

### For Arch-based VMs:
```bash
# Install spice-vdagent
sudo pacman -S spice-vdagent

# Enable and start the service
sudo systemctl enable spice-vdagentd
sudo systemctl start spice-vdagentd
```

### For Windows VMs:
1. Download SPICE Guest Tools from: https://www.spice-space.org/download.html
2. Run the installer
3. Reboot the VM
4. Clipboard sharing should work automatically

## Testing Clipboard

After installing spice-vdagent in the guest:

1. **Host → Guest**: Copy text on host, paste in guest terminal/editor
2. **Guest → Host**: Copy text in guest, paste on host

## Troubleshooting

### Clipboard Not Working

1. **Check spice-vdagent is running in guest:**
   ```bash
   ps aux | grep spice-vdagent
   ```

2. **Restart the agent:**
   ```bash
   sudo systemctl restart spice-vdagent
   ```

3. **Check VM is using SPICE graphics:**
   ```bash
   virsh dumpxml wazuh | grep -A5 "graphics"
   ```
   Should show: `<graphics type='spice'...>`

4. **Reconnect to VM:**
   - Close virt-viewer
   - Reopen: `virt-viewer wazuh`

### Check SPICE Channel

Inside the guest, verify SPICE channel device exists:
```bash
ls -l /dev/vport*
# Should show: /dev/vport0p1, /dev/vport1p1, etc.
```

## VM Configuration

Enable clipboard for any VM in configuration.nix:

```nix
kernelcore.virtualization.vms = {
  myvm = {
    enable = true;
    enableClipboard = true;  # ← Enable clipboard sharing
    # ... other options
  };
};
```

Clipboard is **enabled by default** for all VMs. To disable:

```nix
enableClipboard = false;  # Disable clipboard sharing
```

## Technical Details

### What Was Configured:

1. **SPICE Graphics**: VMs use SPICE protocol instead of VNC
   - Better performance
   - Bidirectional clipboard
   - USB redirection support

2. **QXL Video Driver**: Optimized for SPICE
   - Better graphics performance in guest
   - Lower CPU usage

3. **SPICE Channel**: Virtio channel for clipboard data
   - `com.redhat.spice.0` channel for clipboard/agent communication

### Architecture:

```
Host (NixOS)                    Guest (VM)
┌──────────────┐               ┌──────────────┐
│              │               │              │
│  Clipboard   │               │  Clipboard   │
│      ↕       │               │      ↕       │
│  spice-gtk   │ ←──SPICE───→ │ spice-vdagent│
│              │   Protocol   │              │
└──────────────┘               └──────────────┘
```

## Performance Notes

- SPICE protocol adds minimal overhead
- Clipboard sharing is secure (localhost only by default)
- QXL driver improves graphics performance in guest

## Security Considerations

- SPICE listens on 127.0.0.1 (localhost only)
- No network exposure by default
- Clipboard data transmitted over local UNIX socket
- For remote access, use SSH tunneling or VPN

## Next Steps

1. Rebuild NixOS configuration: `sudo nixos-rebuild switch`
2. Delete and recreate existing VMs (to apply SPICE config)
3. Install spice-vdagent in guest OS
4. Test clipboard sharing

## Deleting and Recreating VM

If you have an existing VM without SPICE:

```bash
# Shutdown VM
virsh shutdown wazuh

# Delete VM definition (keeps disk image)
virsh undefine wazuh

# Rebuild to recreate with SPICE
sudo nixos-rebuild switch
```

The VM will be recreated automatically with SPICE graphics and clipboard support.
