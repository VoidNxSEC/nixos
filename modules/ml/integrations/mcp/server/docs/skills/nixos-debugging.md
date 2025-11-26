# NixOS Debugging Skills
tags: [nixos, debugging, troubleshooting, systemd]

Expert techniques for debugging NixOS configurations and services.

## Quick Diagnostics

### System State
```bash
# Check generation
nixos-version
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# Current config
readlink /run/current-system

# Failed services
systemctl --failed

# Boot issues
journalctl -b -p err
```

### Service Debugging
```bash
# Service status
systemctl status myservice

# Recent logs
journalctl -u myservice -n 50 --no-pager

# Follow logs
journalctl -u myservice -f

# Service dependencies
systemctl list-dependencies myservice
```

### Build Debugging
```bash
# Test build without switching
sudo nixos-rebuild test --flake .#kernelcore

# Dry run
sudo nixos-rebuild dry-build --flake .#kernelcore

# Show trace on error
sudo nixos-rebuild switch --flake .#kernelcore --show-trace

# Verbose output
sudo nixos-rebuild switch --flake .#kernelcore -vvv
```

## Common Issues

**Issue**: "attribute not found"
**Debug**: Check module imports, verify file paths, use `--show-trace`

**Issue**: Service fails to start
**Debug**: Check `journalctl -u service`, verify paths, check permissions

**Issue**: Build takes too long
**Debug**: Check cache status, use `nix-store --verify`, clear `/tmp`

**Issue**: Module conflict
**Debug**: Check load order in flake.nix, use `mkForce` for overrides

## Advanced Techniques

### Inspect Derivation
```bash
nix show-derivation /nix/store/...-mypackage
nix-store -q --tree /nix/store/...-mypackage
```

### Find Configuration
```bash
# Where is option defined?
nix repl
:l <nixpkgs>
:p (config.services.myservice)
```

### Trace Evaluation
```nix
{
  # Add to config
  warnings = [ (builtins.trace "DEBUG: value = ${toString myValue}" myValue) ];
}
```

## Performance Profiling

```bash
# Build time
time sudo nixos-rebuild switch --flake .#kernelcore

# Store size
nix-store --optimize
nix-store --gc --print-dead

# Service startup time
systemd-analyze blame
systemd-analyze critical-chain
```

## Emergency Recovery

```bash
# Boot previous generation
# At boot: select older generation in bootloader

# Rollback
sudo nixos-rebuild switch --rollback

# Fix broken system
sudo nixos-rebuild switch --flake .#kernelcore --fast