# Tar Packages Module

> **Declarative management of .tar.gz binary packages on NixOS**

## Overview

This module provides declarative integration of pre-compiled binary tarballs into NixOS, following the same architecture as `deb-packages/`. It's designed as a **staging area for upstream contributions** to nixpkgs.

## Use Cases

1. **Testing newer versions** - Package versions newer than nixpkgs (e.g., Zellij v0.43.1 vs nixpkgs v0.40.0)
2. **Unmaintained packages** - Packages poorly maintained or broken in nixpkgs
3. **Custom builds** - Proprietary or custom-compiled binaries
4. **Upstream staging** - Test packages locally before submitting to nixpkgs

## Quick Start

### 1. Add a Package

```nix
kernelcore.packages.tar = {
  enable = true;
  packages = {
    zellij = {
      enable = true;
      source = {
        path = ./tar-packages/storage/zellij-v0.43.1.tar.gz;
        sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
      };
      wrapper.executable = "zellij";
      sandbox.enable = false;
    };
  };
};
```

### 2. Calculate SHA256

```bash
nix-hash --type sha256 --flat ./storage/package.tar.gz
```

### 3. Rebuild

```bash
nix flake check && sudo nixos-rebuild switch
```

## Configuration Reference

### Build Methods

- **`auto`** (default) - Automatically detect best method
- **`fhs`** - Use `buildFHSUserEnv` for complex binaries with many dependencies
- **`native`** - Extract and patch with `patchelf` for direct Nix integration

### Sandbox Options

```nix
sandbox = {
  enable = true;                    # Enable bubblewrap isolation
  allowedPaths = ["/tmp" "$HOME"];  # Accessible paths
  blockHardware = ["gpu" "camera"]; # Block hardware access
  resourceLimits = {
    memory = "2G";                  # Memory limit
    cpu = 50;                       # CPU quota (50%)
    tasks = 1024;                   # Max threads
  };
};
```

### Desktop Integration

```nix
desktopEntry = {
  name = "My Application";
  comment = "Description here";
  categories = ["Development" "Utility"];
  icon = "myapp";
};
```

## Architecture

```
tar-packages/
├── default.nix       # Module with options
├── builder.nix       # Build system (extract, FHS, native, patch)
├── README.md         # This file
├── storage/          # Git LFS storage for tar.gz files
└── packages/         # Package configurations
```

## Workflow: Test → Upstream

```bash
# 1. Test locally with tar-packages
kernelcore.packages.tar.my-package.enable = true;
sudo nixos-rebuild switch

# 2. Iterate and refine

# 3. When stable, create proper nixpkgs derivation
# Write a derivation in nixpkgs format

# 4. Submit PR to nixpkgs
# Meanwhile, keep using your local version

# 5. Once merged, remove from tar-packages
kernelcore.packages.tar.my-package.enable = false;
```

## Security

- **Checksums required** - All packages must have SHA256 hash
- **Optional sandboxing** - Bubblewrap isolation with bubblewrap
- **Resource limits** - CPU, memory, task limits via systemd
- **Audit support** - Optional audit logging for executions

## Examples

### Simple Binary (Zellij)

```nix
zellij = {
  enable = true;
  source.path = ./storage/zellij-v0.43.1.tar.gz;
  source.sha256 = "sha256-...";
  wrapper.executable = "zellij";
};
```

### Complex Application with Sandbox

```nix
proprietary-tool = {
  enable = true;
  method = "fhs";
  source.url = "https://vendor.com/tool.tar.gz";
  source.sha256 = "sha256-...";
  wrapper = {
    executable = "bin/tool";
    environmentVariables = {
      "TOOL_HOME" = "$HOME/.tool";
    };
  };
  sandbox = {
    enable = true;
    blockHardware = ["camera" "bluetooth"];
    resourceLimits.memory = "4G";
  };
};
```

## Troubleshooting

### Build Fails

```bash
# Check extraction
nix-build -E 'with import <nixpkgs> {}; runCommand "test" {} "tar -tzf ${./storage/package.tar.gz} > $out"'

# Try different method
method = "fhs";  # or "native"
```

### Runtime Errors

```bash
# Check with ldd
ldd ./result/bin/binary

# Check environment
./result/bin/binary --version
```

### Sandbox Issues

```bash
# Disable sandbox temporarily
sandbox.enable = false;

# Check bubblewrap
bwrap --version
```

## Version

**Version**: 1.0.0
**Created**: 2025-11-03
**Author**: kernelcore
