# .deb Packages Directory

This directory contains declarative configurations for .deb packages integrated into your NixOS system.

## Structure

```
packages/
├── example.nix      # Example configurations (reference)
├── my-tool.nix      # Your package definitions
└── README.md        # This file
```

## Quick Start

### 1. Add a new package

Create a new `.nix` file in this directory:

```nix
# my-tool.nix
{
  my-tool = {
    enable = true;
    method = "auto";

    source = {
      url = "https://example.com/my-tool.deb";
      sha256 = "sha256-..."; # Get with: nix-prefetch-url
    };

    sandbox.enable = true;
    audit.enable = true;
  };
}
```

### 2. Import in your configuration

Import the package in your NixOS configuration:

```nix
# In hosts/kernelcore/configuration.nix or modules/packages/deb-packages/default.nix
kernelcore.packages.deb = {
  enable = true;
  packages = import ./packages/my-tool.nix {};
};
```

### 3. Rebuild

```bash
sudo nixos-rebuild switch
```

## Using the Automation Script

The easier way is to use the `deb-add` script:

```bash
# Add a package from URL
deb-add --name my-tool --url https://example.com/my-tool.deb

# Add a package from local file
deb-add --name my-tool --deb ./my-tool.deb --storage git-lfs

# Add with sandboxing options
deb-add --name my-tool \
        --url https://example.com/my-tool.deb \
        --sandbox \
        --block-gpu \
        --memory 2G \
        --cpu 50
```

## Configuration Options

See `example.nix` for comprehensive examples of all options:

- **method**: `auto`, `fhs`, or `native`
- **source**: URL or local path with SHA256
- **sandbox**: Enable isolation, block hardware, set resource limits
- **audit**: Enable logging and monitoring
- **wrapper**: Custom wrapper configuration
- **meta**: Package metadata

## Security Best Practices

1. **Always specify SHA256**: Required for security
2. **Enable sandbox**: Isolate untrusted binaries
3. **Enable audit**: Track package usage
4. **Block unnecessary hardware**: Minimize attack surface
5. **Set resource limits**: Prevent resource exhaustion

## Storage Options

### URL-based (Recommended for public packages)

```nix
source = {
  url = "https://example.com/package.deb";
  sha256 = "...";
};
```

### Git LFS (Recommended for private/internal packages)

```nix
source = {
  path = ../storage/package.deb;
  sha256 = "...";
};
```

Store the `.deb` file in `modules/packages/deb-packages/storage/` and commit with Git LFS.

## Troubleshooting

### Check package status
```bash
systemctl status deb-package-my-tool
```

### View logs
```bash
# Systemd journal
journalctl -u deb-package-my-tool -f

# Package-specific log
tail -f /var/log/deb-packages/my-tool.log
```

### Debug build
```bash
nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages --show-trace
```

## Examples

See `example.nix` for:
- Simple package with URL source
- Package with Git LFS storage
- Strict sandboxed application
- Development tool with relaxed sandbox
