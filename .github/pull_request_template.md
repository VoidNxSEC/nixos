## Description

Brief description of the changes in this PR.

## Type of Change

Please select the relevant option(s):

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Configuration change
- [ ] Refactoring (no functional changes)

## Testing

Please confirm the following:

- [ ] `nix flake check` passes without errors
- [ ] Tested on NixOS system (specify version: ____________)
- [ ] Added/updated tests for the changes
- [ ] Updated documentation (if applicable)
- [ ] Ran `sudo nixos-rebuild switch` successfully

## Testing Details

Describe how you tested these changes:

```
# Example:
# nix flake check
# sudo nixos-rebuild switch --flake .#kernelcore
# Verified service X is running: systemctl status X
```

## Security Checklist

- [ ] No hardcoded secrets in code
- [ ] SOPS used for all sensitive data
- [ ] Security implications documented (if applicable)
- [ ] No new vulnerabilities introduced
- [ ] Firewall rules reviewed (if network changes)

## Module Impact

Which modules are affected by this change?

- [ ] Security modules (`modules/security/`, `sec/`)
- [ ] Container modules (`modules/containers/`)
- [ ] ML modules (`modules/ml/`)
- [ ] Hardware modules (`modules/hardware/`)
- [ ] Network modules (`modules/network/`)
- [ ] Services (`modules/services/`)
- [ ] Other: _______________

## Screenshots / Logs

If applicable, add screenshots or relevant log output:

```
# Paste logs or screenshots here
```

## Related Issues

Fixes #(issue number)
Relates to #(issue number)

## Additional Context

Add any other context about the pull request here:

---

## Reviewer Checklist

For reviewers:

- [ ] Code follows NixOS best practices
- [ ] Security implications reviewed
- [ ] No secrets in repository
- [ ] Documentation is clear and complete
- [ ] Tests are adequate
- [ ] CI/CD passes
