# vmctl - Lightweight VM Manager

A CLI-first virtual machine manager that directly interfaces with QEMU for simple and efficient VM management.

## Features

- **Direct QEMU execution** - No libvirt overhead for simple use cases
- **CLI-first design** - Essential commands: `list`, `start`, `stop`, `status`
- **Optional GTK4 GUI** - Launch with `vmctl --gui` for graphical interface
- **TOML configuration** - Simple, readable configuration format
- **VirtioFS support** - Fast host-guest file sharing

## Quick Start

```bash
# List configured VMs
vmctl list

# Start a VM (opens QEMU window)
vmctl start wazuh

# Check VM status
vmctl status

# Stop a VM
vmctl stop wazuh

# Create a new disk
vmctl create-disk myvm 50G
```

## Configuration

Create `~/.config/vmctl/config.toml`:

```toml
[vm.myvm]
enabled = true
image = "/var/lib/vm-images/myvm.qcow2"
memory = "4G"
cpus = 2
network = "user"
display = "gtk"
```

See [configs/example.toml](configs/example.toml) for full options.

## Display Modes

| Mode | Description |
|------|-------------|
| `gtk` | GTK window (default) |
| `sdl` | SDL window |
| `spice` | SPICE remote display |
| `none` | Headless mode |

## Network Options

| Format | Description |
|--------|-------------|
| `user` | NAT via QEMU user networking (default) |
| `bridge:br0` | Bridge to physical network |

## Building

```bash
# Enter development shell
nix develop

# Build
go build ./cmd/vmctl

# Or use Nix
nix build
```

## License

MIT
