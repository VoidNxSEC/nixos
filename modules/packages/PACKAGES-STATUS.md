# Package Management Status

This document tracks the status of custom packages managed through the declarative package system in `modules/packages/*`.

## Package Categories

### 1. JS Packages (`modules/packages/js-packages/`)
Managed via `kernelcore.packages.js.packages.*`

#### gemini-cli
- **Status**: ⚠️ Needs hash update
- **Location**: [`modules/packages/js-packages/gemini-cli.nix`](js-packages/gemini-cli.nix)
- **Source**: https://github.com/google-gemini/gemini-cli
- **Version**: v0.15.0-nightly.20251107.cd27cae8
- **Build Type**: Node.js (`buildNpmPackage`)
- **Enable**: Set `kernelcore.packages.js.packages.gemini-cli.enable = true;`
- **Agent Service**: [`modules/services/users/gemini-agent.nix`](../services/users/gemini-agent.nix)

**Before using:**
```bash
# Get source hash
nix-prefetch-git https://github.com/google-gemini/gemini-cli v0.15.0-nightly.20251107.cd27cae8

# Update sha256 in gemini-cli.nix

# Build to get npmDepsHash (first build will fail with correct hash)
# Update npmDepsHash in gemini-cli.nix
```

---

### 2. Tar Packages (`modules/packages/tar-packages/`)
Managed via `kernelcore.packages.tar.packages.*`

#### codex
- **Status**: ✅ Configured (check hash validity)
- **Location**: [`modules/packages/tar-packages/packages/codex.nix`](tar-packages/packages/codex.nix)
- **Source**: https://github.com/openai/codex/releases/download/rust-v0.56.0/codex-x86_64-unknown-linux-gnu.tar.gz
- **Version**: 0.56.0 (rust-v0.56.0)
- **Build Method**: native (tar extraction + wrapper)
- **Enable**: Already enabled in config
- **Agent Service**: [`modules/services/users/codex-agent.nix`](../services/users/codex-agent.nix)

**Configuration:**
```nix
codex = {
  enable = true;
  method = "native";
  source = {
    url = "https://github.com/openai/codex/releases/download/rust-v0.56.0/codex-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "3aafd4ea76f3d72c15877ae372da072377c58477547606b05228abc6b8bb1114";
  };
  wrapper.executable = "codex-x86_64-unknown-linux-gnu";
  sandbox.enable = false;
};
```

#### lynis
- **Status**: ✅ Ready to use
- **Location**: [`modules/packages/tar-packages/packages/lynis.nix`](tar-packages/packages/lynis.nix)
- **Source**: Local storage + GitHub (CISOfy/lynis)
- **Version**: 3.1.6
- **Build Method**: native (shell script based)
- **Enable**: Already enabled in config
- **Storage**: [`modules/packages/tar-packages/storage/lynis-3.1.6.tar.gz`](tar-packages/storage/lynis-3.1.6.tar.gz)

**Usage:**
```bash
# Run system audit
sudo lynis audit system

# Show version
lynis --version

# Check specific areas
sudo lynis audit system --tests-from-group security
```

---

## Enabling Packages

### Method 1: Through Configuration
Add to your NixOS configuration:

```nix
{
  # Enable gemini-cli
  kernelcore.packages.js.packages.gemini-cli.enable = true;
  
  # Tar packages are auto-loaded from packages/*.nix files
  # codex and lynis are already enabled by default
}
```

### Method 2: Using Agent Services

The agent services automatically include their respective packages:

```nix
{
  # Enable Gemini agent (includes gemini-cli)
  kernelcore.services.users.gemini-agent.enable = true;
  
  # Enable Codex agent (includes codex binary)
  kernelcore.services.users.codex-agent.enable = true;
}
```

---

## Package System Architecture

```
modules/packages/
├── default.nix              # Main aggregator
├── DOCUMENTATION.md         # System documentation
├── README.md                # User guide
├── SETUP.md                 # Setup instructions
├── PACKAGES-STATUS.md       # This file
│
├── deb-packages/            # .deb package management
│   ├── default.nix
│   ├── builder.nix
│   └── packages/
│
├── tar-packages/            # .tar.gz package management
│   ├── default.nix
│   ├── builder.nix
│   ├── packages/
│   │   ├── codex.nix       ✅
│   │   ├── lynis.nix       ✅
│   │   └── zellij.nix
│   └── storage/
│       └── lynis-3.1.6.tar.gz
│
└── js-packages/             # Node.js/npm package management
    ├── default.nix
    ├── js-packages.nix
    └── gemini-cli.nix      ⚠️ Needs hash update
```

---

## Agent Services

### Gemini Agent
- **Service**: `systemd.services.gemini-agent` (not yet created)
- **User**: `gemini-agent`
- **Home**: `/var/lib/gemini-agent`
- **Package**: `gemini-cli`
- **Config**: [`modules/services/users/gemini-agent.nix`](../services/users/gemini-agent.nix:1)

### Codex Agent
- **Service**: `systemd.services.codex-agent`
- **User**: `codex`
- **Home**: `/var/lib/codex`
- **Package**: `codex`
- **Config**: [`modules/services/users/codex-agent.nix`](../services/users/codex-agent.nix:1)

---

## Next Steps

1. **Update gemini-cli hashes**:
   ```bash
   nix-prefetch-git https://github.com/google-gemini/gemini-cli v0.15.0-nightly.20251107.cd27cae8
   ```

2. **Verify codex binary**:
   Check if the URL and hash are still valid for the codex release

3. **Test lynis**:
   ```bash
   sudo lynis audit system
   ```

4. **Enable services**:
   Add to configuration and rebuild

---

## Related Documentation

- [Package System Documentation](DOCUMENTATION.md)
- [Setup Guide](SETUP.md)
- [Tar Packages README](tar-packages/README.md)
- [Deb Packages Guide](deb-packages/README.md)

---

## Troubleshooting

### Hash Mismatch Errors

If you see hash mismatch errors:
1. Use `nix-prefetch-git` or `nix-prefetch-url` to get correct hash
2. Update the hash in the package definition
3. Rebuild

### Package Not Found

If package isn't available after enabling:
1. Check that the module is imported in [`default.nix`](default.nix:1)
2. Verify the enable option is set correctly
3. Run `sudo nixos-rebuild switch --flake .#kernelcore`

### Build Failures

Check logs:
```bash
journalctl -xe | grep -i <package-name>
```

---

Last Updated: 2025-11-07