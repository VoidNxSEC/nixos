# Declarative .deb Package Management for NixOS

> **Status**: Production Ready
> **Version**: 1.0.0
> **Author**: kernelcore
> **Last Updated**: 2025-11-03

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Quick Start](#quick-start)
5. [Configuration Reference](#configuration-reference)
6. [Security Model](#security-model)
7. [Usage Examples](#usage-examples)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Maintenance](#maintenance)

---

## Overview

This module provides a declarative, secure, and flexible way to integrate `.deb` packages into your NixOS system while maintaining the Nix philosophy of reproducibility and isolation.

### Why This Module?

- **Declarative Configuration**: All packages defined in Nix configuration
- **Security First**: Mandatory checksums, sandboxing, and audit logging
- **Flexible Integration**: Multiple methods (FHS, native, auto-detection)
- **Resource Control**: CPU, memory, and hardware access restrictions
- **Full Auditability**: Track when and how packages are used
- **Version Control**: Store packages with Git LFS or reference by URL

### Use Cases

- ✅ Proprietary software only available as `.deb`
- ✅ Internal tools not in nixpkgs
- ✅ Outdated packages in nixpkgs needing newer versions
- ✅ Custom-built binaries requiring specific environments
- ✅ Third-party tools requiring strict isolation

---

## Features

### Core Features

- **Hybrid Integration Methods**
  - FHS User Environment for complex binaries
  - Native Nix integration with patchelf
  - Automatic detection of best method

- **Multi-Layer Security**
  - SHA256 checksum validation (mandatory)
  - Bubblewrap sandboxing with configurable isolation
  - Hardware device blocking (GPU, audio, USB, camera, bluetooth)
  - Systemd resource limits (memory, CPU, tasks)
  - Linux audit daemon integration
  - Per-package systemd service monitoring

- **Flexible Storage**
  - URL-based with automatic downloading
  - Git LFS for version-controlled binaries
  - Local file system paths
  - Built-in caching

- **Comprehensive Auditing**
  - Three logging levels: minimal, standard, verbose
  - Systemd journal integration
  - Per-package log files with rotation
  - Resource usage tracking
  - Execution timeline and exit code logging

- **Automation Tools**
  - `deb-add` script for easy package addition
  - Automatic configuration generation
  - SHA256 hash calculation
  - Template-based manual configuration

---

## Architecture

### Module Structure

```
modules/packages/deb-packages/
├── default.nix          # Main module with options and interface
├── builder.nix          # Build functions (FHS, native, auto)
├── sandbox.nix          # Sandboxing and systemd integration
├── audit.nix            # Audit logging and monitoring
├── packages/            # Package definitions
│   ├── example.nix
│   └── README.md
└── storage/             # Git LFS storage for .deb files
    ├── .gitattributes
    └── README.md

scripts/
└── deb-add              # Automation script
```

### Integration Flow

```
┌─────────────────┐
│ NixOS Config    │
│ (packages attr) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Builder         │
│ (fetch + build) │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌──────────┐
│  FHS  │ │  Native  │
└───┬───┘ └────┬─────┘
    │          │
    └────┬─────┘
         ▼
┌─────────────────┐
│ Sandbox Wrapper │
│ (bubblewrap)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Systemd Service │
│ (monitoring)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Audit Logging   │
│ (journal + log) │
└─────────────────┘
```

---

## Quick Start

### 1. Enable the Module

```nix
# In your configuration.nix or flake.nix
kernelcore.packages.deb = {
  enable = true;

  packages = {
    # Your package definitions here
  };
};
```

### 2. Add a Package (Automated)

Using the `deb-add` script:

```bash
# From URL
deb-add --name my-tool \
        --url https://example.com/my-tool.deb \
        --description "My custom tool"

# From local file
deb-add --name my-tool \
        --deb ./my-tool.deb \
        --storage git-lfs

# With security restrictions
deb-add --name untrusted-app \
        --url https://example.com/app.deb \
        --block-gpu \
        --block-audio \
        --memory 2G \
        --cpu 50
```

### 3. Add a Package (Manual)

Create a configuration file:

```nix
# modules/packages/deb-packages/packages/my-tool.nix
{
  my-tool = {
    enable = true;
    method = "auto";

    source = {
      url = "https://example.com/my-tool.deb";
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = true;
      blockHardware = [ "gpu" ];
      resourceLimits = {
        memory = "2G";
        cpu = 50;
      };
    };

    audit = {
      enable = true;
      logLevel = "standard";
    };

    meta = {
      description = "My custom tool";
      homepage = "https://example.com";
      license = "MIT";
    };
  };
}
```

Import in your configuration:

```nix
kernelcore.packages.deb = {
  enable = true;
  packages = import ./modules/packages/deb-packages/packages/my-tool.nix {};
};
```

### 4. Rebuild

```bash
# Validate configuration
nix flake check

# Apply changes
sudo nixos-rebuild switch
```

---

## Configuration Reference

### Module Options

#### `kernelcore.packages.deb.enable`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable declarative .deb package management

#### `kernelcore.packages.deb.packages`

- **Type**: `attrsOf packageType`
- **Default**: `{}`
- **Description**: Attribute set of .deb packages to manage

#### `kernelcore.packages.deb.auditByDefault`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable audit logging by default for all packages

#### `kernelcore.packages.deb.storageDir`

- **Type**: `path`
- **Default**: `/etc/nixos/modules/packages/deb-packages/storage`
- **Description**: Directory for storing .deb files with Git LFS

#### `kernelcore.packages.deb.cacheDir`

- **Type**: `path`
- **Default**: `/var/cache/deb-packages`
- **Description**: Runtime cache directory for extracted packages

### Package Options

#### `enable`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable this package

#### `method`

- **Type**: `enum ["auto" "fhs" "native"]`
- **Default**: `"auto"`
- **Description**: Integration method
  - `auto`: Automatically detect best method
  - `fhs`: Use buildFHSUserEnv (for complex binaries)
  - `native`: Extract and patch with patchelf

#### `source`

- **Type**: `submodule`
- **Description**: Source configuration

##### `source.url`

- **Type**: `nullOr str`
- **Default**: `null`
- **Description**: URL to download .deb file

##### `source.path`

- **Type**: `nullOr path`
- **Default**: `null`
- **Description**: Local path to .deb file (for Git LFS)

##### `source.sha256`

- **Type**: `str`
- **Required**: Yes
- **Description**: SHA256 hash of the .deb file

#### `sandbox`

- **Type**: `submodule`
- **Description**: Sandboxing and isolation configuration

##### `sandbox.enable`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable sandboxing with bubblewrap

##### `sandbox.allowedPaths`

- **Type**: `listOf str`
- **Default**: `[]`
- **Description**: Paths accessible from within sandbox
- **Example**: `["/tmp" "/home/user/data"]`

##### `sandbox.blockHardware`

- **Type**: `listOf (enum ["gpu" "audio" "usb" "camera" "bluetooth"])`
- **Default**: `[]`
- **Description**: Hardware devices to block access to

##### `sandbox.resourceLimits.memory`

- **Type**: `nullOr str`
- **Default**: `null`
- **Description**: Maximum memory (systemd format)
- **Example**: `"2G"`, `"512M"`

##### `sandbox.resourceLimits.cpu`

- **Type**: `nullOr int`
- **Default**: `null`
- **Description**: CPU quota percentage (0-100)

##### `sandbox.resourceLimits.tasks`

- **Type**: `nullOr int`
- **Default**: `null`
- **Description**: Maximum number of tasks/threads

#### `audit`

- **Type**: `submodule`
- **Description**: Audit and monitoring configuration

##### `audit.enable`

- **Type**: `bool`
- **Default**: `cfg.auditByDefault`
- **Description**: Enable audit logging for this package

##### `audit.logLevel`

- **Type**: `enum ["minimal" "standard" "verbose"]`
- **Default**: `"standard"`
- **Description**: Audit logging verbosity
  - `minimal`: Only log executions
  - `standard`: Log executions, file access, resource usage
  - `verbose`: Log everything including syscalls and resources

#### `wrapper`

- **Type**: `submodule`
- **Description**: Wrapper configuration

##### `wrapper.name`

- **Type**: `str`
- **Default**: Package name
- **Description**: Name of the wrapper executable

##### `wrapper.extraArgs`

- **Type**: `listOf str`
- **Default**: `[]`
- **Description**: Extra arguments to pass to the binary

##### `wrapper.environmentVariables`

- **Type**: `attrsOf str`
- **Default**: `{}`
- **Description**: Environment variables for the binary

#### `meta`

- **Type**: `submodule`
- **Description**: Package metadata

##### `meta.description`

- **Type**: `str`
- **Default**: `""`
- **Description**: Package description

##### `meta.homepage`

- **Type**: `nullOr str`
- **Default**: `null`
- **Description**: Package homepage

##### `meta.license`

- **Type**: `nullOr str`
- **Default**: `null`
- **Description**: Package license

---

## Security Model

### Multi-Layer Security

This module implements defense-in-depth with multiple security layers:

#### Layer 1: Checksum Verification

- **SHA256 mandatory**: Every package MUST have a valid SHA256 hash
- **Build-time validation**: Hash verified during Nix build
- **Assertion enforcement**: Build fails if hash missing or invalid

#### Layer 2: Sandboxing (Bubblewrap)

- **Filesystem isolation**: Limited host filesystem access
- **Namespace isolation**: Separate user, IPC, PID, UTS, cgroup namespaces
- **Capability dropping**: All capabilities dropped by default
- **Device blocking**: Selective hardware device blocking

#### Layer 3: Systemd Hardening

- **Resource limits**: CPU, memory, tasks controlled by systemd
- **System call filtering**: Restricted syscalls via SecComp
- **Filesystem protection**: Read-only system directories
- **Device restrictions**: Limited device access

#### Layer 4: Linux Audit

- **Execution logging**: All executions logged to audit daemon
- **File access monitoring**: Track file reads/writes
- **Syscall auditing**: Monitor critical syscalls (optional)

#### Layer 5: Application Monitoring

- **Systemd journal**: All activity logged to journal
- **Per-package logs**: Individual log files with rotation
- **Resource tracking**: CPU and memory usage monitoring

### Security Profiles

#### Minimal (Default)

```nix
sandbox.enable = true;
sandbox.blockHardware = [];
sandbox.resourceLimits = {};
audit.enable = true;
audit.logLevel = "standard";
```

#### Strict (Untrusted)

```nix
sandbox.enable = true;
sandbox.allowedPaths = [];  # No host access
sandbox.blockHardware = ["gpu" "audio" "camera" "usb" "bluetooth"];
sandbox.resourceLimits = {
  memory = "1G";
  cpu = 25;
  tasks = 256;
};
audit.enable = true;
audit.logLevel = "verbose";
```

#### Development (Relaxed)

```nix
sandbox.enable = true;
sandbox.allowedPaths = ["/home/user/projects"];
sandbox.blockHardware = [];
sandbox.resourceLimits = {
  memory = "8G";
  cpu = 100;
};
audit.enable = true;
audit.logLevel = "minimal";
```

### Security Best Practices

1. **Always enable sandbox**: Disable only for trusted, well-tested packages
2. **Use strict profiles for untrusted sources**: Maximum isolation for unknown binaries
3. **Enable audit logging**: Track all package usage
4. **Block unnecessary hardware**: Minimize attack surface
5. **Set resource limits**: Prevent resource exhaustion attacks
6. **Review logs regularly**: Monitor for suspicious activity
7. **Keep packages updated**: Regenerate with new checksums when upstream updates
8. **Document source provenance**: Track where packages came from

---

## Usage Examples

### Example 1: Public Tool from URL

```nix
{
  google-chrome = {
    enable = true;
    method = "fhs";

    source = {
      url = "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb";
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = true;
      allowedPaths = ["/home/user/Downloads"];
      blockHardware = [];
      resourceLimits = {
        memory = "4G";
      };
    };

    audit = {
      enable = true;
      logLevel = "standard";
    };

    meta = {
      description = "Google Chrome web browser";
      homepage = "https://www.google.com/chrome/";
      license = "Proprietary";
    };
  };
}
```

### Example 2: Internal Tool with Git LFS

```nix
{
  company-tool = {
    enable = true;
    method = "auto";

    source = {
      path = ../storage/company-tool_1.0.0_amd64.deb;
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = true;
      allowedPaths = [
        "/home/user/workspace"
        "/tmp"
      ];
      blockHardware = ["gpu"];
      resourceLimits = {
        memory = "2G";
        cpu = 75;
      };
    };

    audit = {
      enable = true;
      logLevel = "verbose";
    };

    wrapper = {
      extraArgs = ["--config" "/etc/company-tool/config.yaml"];
      environmentVariables = {
        TOOL_HOME = "/var/lib/company-tool";
      };
    };

    meta = {
      description = "Internal company development tool";
      homepage = "https://internal.company.com/tools";
      license = "Proprietary";
    };
  };
}
```

### Example 3: Untrusted Application

```nix
{
  untrusted-binary = {
    enable = true;
    method = "fhs";

    source = {
      url = "https://untrusted-source.com/app.deb";
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = true;
      allowedPaths = [];  # No filesystem access
      blockHardware = ["gpu" "audio" "camera" "usb" "bluetooth"];
      resourceLimits = {
        memory = "512M";
        cpu = 10;
        tasks = 64;
      };
    };

    audit = {
      enable = true;
      logLevel = "verbose";
    };

    meta = {
      description = "Untrusted binary requiring maximum isolation";
      license = "Unknown";
    };
  };
}
```

### Example 4: Development CLI Tool

```nix
{
  custom-cli = {
    enable = true;
    method = "native";

    source = {
      path = ../storage/custom-cli.deb;
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = false;  # Trusted development tool
    };

    audit = {
      enable = true;
      logLevel = "minimal";
    };

    wrapper = {
      name = "custom-cli";
      environmentVariables = {
        CLI_CONFIG = "$HOME/.config/custom-cli";
      };
    };

    meta = {
      description = "Custom CLI development tool";
      homepage = "https://github.com/user/custom-cli";
      license = "MIT";
    };
  };
}
```

---

## Troubleshooting

### Common Issues

#### 1. SHA256 Mismatch

**Error**: "hash mismatch in fixed-output derivation"

**Solution**:
```bash
# Recalculate hash
nix-prefetch-url https://example.com/package.deb

# Or for local file
nix-prefetch-url file:///path/to/package.deb

# Update sha256 in configuration
```

#### 2. Build Fails with "No such file or directory"

**Cause**: Binary dependencies not found

**Solution**: Use `fhs` method instead of `native`:
```nix
method = "fhs";  # Change from "native" or "auto"
```

#### 3. Sandbox Blocks Required Paths

**Error**: Application can't access files

**Solution**: Add required paths to `allowedPaths`:
```nix
sandbox.allowedPaths = [
  "/home/user/data"
  "/tmp"
];
```

#### 4. Package Doesn't Start

**Debug**:
```bash
# Check systemd service status
systemctl status deb-package-my-tool

# View logs
journalctl -u deb-package-my-tool -f

# Check package log
tail -f /var/log/deb-packages/my-tool.log
```

#### 5. Resource Limits Too Restrictive

**Symptom**: Package crashes or fails

**Solution**: Increase limits:
```nix
sandbox.resourceLimits = {
  memory = "4G";  # Increase memory
  cpu = 100;      # Remove CPU limit
  tasks = 2048;   # Increase task limit
};
```

### Debugging Commands

```bash
# Check flake syntax
nix flake check --show-trace

# Build specific package
nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages

# Test in VM
nix build .#vm-image
./result/bin/run-*-vm

# Check bubblewrap
bwrap --version

# Test binary extraction
dpkg-deb -x package.deb /tmp/test-extract

# Monitor resource usage
systemd-cgtop
```

---

## Best Practices

### 1. Package Organization

- **One package per file**: Keep configurations modular
- **Descriptive names**: Use clear, consistent naming
- **Version in filename**: `tool-name_1.0.0.nix`
- **Group by category**: Organize by purpose or source

### 2. Security Configuration

- **Enable sandbox by default**: Disable only when necessary
- **Start strict, relax as needed**: Begin with maximum isolation
- **Document why security is relaxed**: Comment reasoning
- **Regular security reviews**: Audit configurations periodically

### 3. Source Management

- **Prefer URLs for public packages**: Easier updates
- **Use Git LFS for internal packages**: Version control
- **Keep checksums updated**: Verify on each update
- **Document package source**: Track provenance

### 4. Audit and Monitoring

- **Enable audit logging**: Always track usage
- **Review logs regularly**: Check for anomalies
- **Set up alerts**: Monitor for suspicious activity
- **Archive old logs**: Maintain audit trail

### 5. Maintenance

- **Update checksums regularly**: Keep packages current
- **Test in VM first**: Verify before production
- **Document changes**: Maintain changelog
- **Version control everything**: Track all configuration

---

## Maintenance

### Updating Packages

#### Update from URL

```bash
# Get new hash
nix-prefetch-url https://example.com/new-version.deb

# Update configuration
# Change sha256 and/or URL

# Rebuild
sudo nixos-rebuild switch
```

#### Update Git LFS Package

```bash
# Replace file
cp new-version.deb /etc/nixos/modules/packages/deb-packages/storage/package.deb

# Get new hash
nix-prefetch-url file://$(pwd)/modules/packages/deb-packages/storage/package.deb

# Update sha256 in configuration

# Commit
git add modules/packages/deb-packages/storage/package.deb
git commit -m "Update package to new version"
```

### Log Management

```bash
# View logs
tail -f /var/log/deb-packages/my-tool.log

# Manually rotate logs
systemctl start deb-package-my-tool-log-rotation

# Clean old logs (keeps last 5)
find /var/log/deb-packages -name "*.log.*" -type f | sort -r | tail -n +6 | xargs rm -f
```

### Monitoring

```bash
# Check resource usage
systemctl status deb-package-my-tool

# View journal
journalctl -u deb-package-my-tool -f

# Monitor all deb packages
journalctl -t "deb-package-*" -f

# Audit logs
ausearch -k deb_exec_my-tool
```

### Cleanup

```bash
# Remove package
# 1. Disable in configuration
enable = false;

# 2. Rebuild
sudo nixos-rebuild switch

# 3. Clean Nix store
nix-collect-garbage -d

# 4. Remove configuration file
rm /etc/nixos/modules/packages/deb-packages/packages/my-tool.nix

# 5. Remove from Git LFS (if applicable)
git rm /etc/nixos/modules/packages/deb-packages/storage/my-tool.deb
git commit -m "Remove my-tool package"
```

---

## Conclusion

This module provides a comprehensive, secure, and maintainable solution for integrating `.deb` packages into NixOS. By combining declarative configuration, strong isolation, and thorough auditing, you can safely use external binaries while maintaining the Nix philosophy.

For questions, issues, or contributions, please refer to the repository documentation or open an issue.

**Happy Hacking! 🚀**
