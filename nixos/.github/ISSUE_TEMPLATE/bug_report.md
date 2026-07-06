---
name: Bug Report
about: Report a bug in the NixOS configuration
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Steps to Reproduce

Steps to reproduce the behavior:

1. Run command '...'
2. Navigate to '...'
3. Check service '...'
4. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Actual Behavior

A clear and concise description of what actually happened.

## Environment

- **NixOS Version**: <!-- Run: nixos-version -->
- **Commit Hash**: <!-- Run: git rev-parse HEAD -->
- **Hardware**: <!-- CPU, GPU, RAM -->
- **Kernel Version**: <!-- Run: uname -r -->
- **Display Server**: <!-- Wayland / X11 -->

## Error Logs

Please provide relevant logs:

```bash
# System logs
journalctl -xe -n 50

# Service logs (if applicable)
systemctl status <service-name>

# Nix build logs (if applicable)
nix-build --show-trace
```

<details>
<summary>Full logs</summary>

```
Paste full logs here
```

</details>

## Configuration

Which modules are involved?

- [ ] Security (`modules/security/`)
- [ ] Containers (`modules/containers/`)
- [ ] ML (`modules/ml/`)
- [ ] Hardware (`modules/hardware/`)
- [ ] Network (`modules/network/`)
- [ ] Services (`modules/services/`)
- [ ] Other: _______________

## Attempted Solutions

What have you tried to fix this?

- [ ] Ran `sudo nixos-rebuild switch`
- [ ] Rolled back: `sudo nixos-rebuild switch --rollback`
- [ ] Checked logs: `journalctl -xe`
- [ ] Ran validation: `./scripts/post-rebuild-validate.sh`
- [ ] Other: _______________

## Additional Context

Add any other context about the problem here:

- Screenshots
- Related issues
- Recent changes

## Possible Fix

If you have suggestions on how to fix this bug, please describe:
