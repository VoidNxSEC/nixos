# vmctl - VM Management CLI

## Quick Reference

### Basic Commands

```bash
# List all registered VMs
vmctl list

# Ensure VM is defined in libvirt (creates if needed)
vmctl ensure wazuh

# Start a VM
vmctl start wazuh

# Stop a VM
vmctl stop wazuh

# Restart a VM
vmctl restart wazuh

# Attach console (serial or virt-viewer)
vmctl console wazuh

# Force stop and undefine VM
vmctl destroy wazuh
```

### Image Management

```bash
# Convert OVA to qcow2 in /var/lib/vm-images/
vmctl convert-ova /path/to/image.ova [optional-name]

# Import image into /var/lib/vm-images/
vmctl import-image /path/to/image.qcow2 [optional-name]

# Create blank disk in /srv/vms/images/
vmctl create-disk myvm 50  # 50 GiB
```

### Interactive Setup

```bash
# Launch interactive wizard to generate VM configuration
vmctl wizard
```

## Bash Completion

After rebuilding, bash completion is automatically enabled. Try:

```bash
vmctl <TAB>           # Shows available commands
vmctl start <TAB>     # Shows available VMs
```

## VM Configuration Example

In `configuration.nix`:

```nix
kernelcore.virtualization = {
  enable = true;
  virt-manager = true;
  libvirtdGroup = [ "kernelcore" ];
  virtiofs.enable = true;

  vmBaseDir = "/srv/vms/images";
  sourceImageDir = "/var/lib/vm-images";

  vms = {
    wazuh = {
      enable = true;
      sourceImage = "wazuh-4.14.0.qcow2";  # In /var/lib/vm-images/
      imageFile = null;  # Defaults to /srv/vms/images/wazuh.qcow2
      memoryMiB = 4096;
      vcpus = 2;
      network = "bridge";
      bridgeName = "br0";
      sharedDirs = [
        {
          path = "/srv/vms/shared";
          tag = "hostshare";
          driver = "virtiofs";
          readonly = false;
          create = true;
        }
      ];
      autostart = false;
      extraVirtInstallArgs = [
        "--graphics vnc,listen=0.0.0.0"
      ];
    };
  };
};
```

## Network Modes

### NAT (Default)
- VM gets private IP on libvirt's default network (192.168.122.0/24)
- Access host and internet via NAT
- Not directly accessible from LAN

```nix
network = "nat";
```

### Bridge
- VM gets IP on your LAN (e.g., 192.168.15.0/24)
- Directly accessible from other devices on network
- Requires `br0` bridge configured

```nix
network = "bridge";
bridgeName = "br0";
```

## Shared Directories

### VirtioFS (Recommended)
- Best performance
- Requires QEMU 5.0+

```nix
sharedDirs = [
  {
    path = "/srv/vms/shared";
    tag = "hostshare";
    driver = "virtiofs";
    readonly = false;
  }
];
```

Mount in guest (Linux):
```bash
sudo mount -t virtiofs hostshare /mnt/shared
```

### 9p (Fallback)
- Works with older QEMU
- Slightly lower performance

```nix
driver = "9p";
```

Mount in guest (Linux):
```bash
sudo mount -t 9p -o trans=virtio hostshare /mnt/shared
```

## Troubleshooting

### VM won't start
```bash
# Check VM status
virsh dominfo wazuh

# Check VM definition
virsh dumpxml wazuh

# Check libvirt logs
journalctl -u libvirtd -f
```

### Image not found
```bash
# Check if image exists
ls -la /var/lib/vm-images/
ls -la /srv/vms/images/

# Manually create symlink
sudo mkdir -p /srv/vms/images
sudo ln -s /var/lib/vm-images/wazuh-4.14.0.qcow2 /srv/vms/images/wazuh.qcow2
```

### Network issues
```bash
# Check br0 exists
ip addr show br0

# Check libvirt default network
virsh net-info default
virsh net-start default
virsh net-autostart default

# Check VM network config
virsh domiflist wazuh
```

### Permission denied
Make sure your user is in the `libvirtd` group:
```bash
groups  # Should show 'libvirtd'
```

If not, add yourself (already configured in NixOS):
```bash
sudo usermod -aG libvirtd $USER
# Log out and back in
```

## Directory Structure

```
/etc/vm-registry.json          # VM registry (auto-generated)
/var/lib/vm-images/            # Source images (OVA, QCOW2)
/srv/vms/images/               # Active VM disks (symlinks or copies)
/srv/vms/shared/               # Shared directory for VMs
```

## Advanced Usage

### Multiple VMs
```nix
vms = {
  wazuh = { ... };
  monitoring = { ... };
  database = { ... };
};
```

### Fixed MAC Address
```nix
macAddress = "52:54:00:12:34:56";
```

### Autostart on Boot
```nix
autostart = true;
```

### Extra virt-install Arguments
```nix
extraVirtInstallArgs = [
  "--graphics vnc,listen=0.0.0.0,port=5900"
  "--features kvm_hidden=on"
];
```
