# NixOS Configuration - Claude Instructions

## Build & Environment
**All shell, build, and test commands MUST run inside the nix dev environment:**
```bash
nix develop --command <cmd>
# or
nix develop -c <cmd>
```
Never run `cargo`, `rustc`, `npm`, `python`, or any toolchain binary directly on the host. If a command fails outside the dev shell, enter it first — never work around it.

## Diagnosis Principles
1. **Verify root cause against actual source code before acting.** Read the file, grep the error, check the real build log.
2. **Trust source code over markdown docs, ROADMAPs, and ADRs.** Docs rot; code is truth.
3. **Never make unverified claims** about kernel options, security flags, CVE numbers, or package versions. Check nixpkgs source or the actual config file first.
4. **State the root cause and evidence before proposing a fix.** If uncertain, say so and ask.

## Testing & Debugging
- **Never add mocks, stubs, or `fakeHash`** to make tests or builds pass. Fix the real root cause.
- **Never weaken a test** to make it green. If a test can't pass, stop and explain why.
- **Never dismiss a build error as pre-existing** without confirming it was there before the current change.
- Trace `fakeHash` / hash mismatch errors to the actual broken upstream source or vendor dir — not the hash itself.

## Safety / Network
- **Never run a command that could drop the active connection** (WiFi, hotspot, SSH) without:
  1. Explicitly warning what it risks
  2. Waiting for user confirmation
- Prefer reversible, rollback-capable changes for network/firewall config.
- If in doubt about connectivity impact, ask before running.

## File Safety
- **Never overwrite `MEMORY.md`** or any user-maintained context/index file. Append new entries or ask first.
- When adding memory entries: write the individual `.md` file first, then append one line to `MEMORY.md`.

## Editing Conventions
- **Prefer additive fixes.** Do not remove features, options, or modules to resolve a build error unless explicitly asked.
- When a build breaks after adding something, fix the addition — don't delete it.
- Use Edit for existing files, Write only for new files.

---

## Environment Context
- **System**: NixOS (declarative Linux distribution)
- **Config Location**: `/etc/nixos`
- **Build Command**: `sudo nixos-rebuild switch`
- **Validation**: `nix flake check` before rebuild

## Working Patterns

### 1. Configuration Changes
When modifying NixOS configuration:
1. Read the relevant module files first
2. Make changes using Edit tool (never Write for existing files)
3. Run `nix flake check` to validate
4. If check passes, user will run `sudo nixos-rebuild switch`
5. Check `journalctl -xe` for runtime errors if needed

### 2. Module Development
- Use `mkEnableOption` for toggleable features
- Use `mkDefault` for values that should be overridable
- Place security modules last in import order (highest priority)
- Document why configs exist (security, performance, etc.)

### 3. Conflict Resolution
- Use `mkDefault` in reusable modules
- Use `mkForce` only when necessary
- Check for duplicate definitions across modules
- Prefer modular configs over monolithic files

### 4. Testing Strategy
- Always run `nix flake check` before rebuild
- Test VM builds: `nix build .#vm-image`
- Test ISO builds: `nix build .#iso`
- Use `--show-trace` for detailed errors

## Common Tasks

### Adding New Packages
```nix
# In configuration.nix or relevant module
environment.systemPackages = with pkgs; [
  package-name
];
```

### Creating New Module
```nix
{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    kernelcore.feature.enable = mkEnableOption "Feature description";
  };

  config = mkIf config.kernelcore.feature.enable {
    # Configuration here
  };
}
```

### Debugging Build Errors
1. `nix flake check --show-trace` - Full stack trace
2. `nix-instantiate --eval --strict` - Evaluate expressions
3. `nix repl` - Interactive Nix REPL
4. `journalctl -xe` - System logs after rebuild

## Known Issues & TODOs

### Current Known Issues
1. **nvidia-container-toolkit**: Disabled in VM variant due to driver assertion
   - Location: `/etc/nixos/modules/hardware/nvidia.nix:32`
   - Workaround: Commented out for now
   - TODO: Fix VM variant compatibility

2. **Compiler hardening overlay**: Disabled due to Nix 2.18+ compatibility
   - Location: `/etc/nixos/modules/security/compiler-hardening.nix:12-28`
   - Issue: `withCFlags` causes env attribute conflicts
   - TODO: Migrate to per-package hardening flags

3. **Docker image deprecation warnings**: `contents` parameter deprecated
   - Location: `/etc/nixos/lib/packages.nix`
   - Suggestion: Use `copyToRoot = buildEnv { ... }` instead

### Progress Tracker Template
When working on multi-step tasks, use TodoWrite to track:
```markdown
- [ ] Read current configuration
- [ ] Identify changes needed
- [ ] Implement changes
- [ ] Run nix flake check
- [ ] Document changes
```

## File Structure
```
/etc/nixos/
├── flake.nix                 # Flake entry point
├── hosts/
│   └── kernelcore/          # Host-specific configs
├── modules/
│   ├── hardware/            # Hardware configs (NVIDIA, etc.)
│   ├── security/            # Security hardening
│   ├── development/         # Dev environments
│   ├── containers/          # Docker, NixOS containers
│   └── ...
├── lib/
│   ├── packages.nix         # Custom packages & images
│   └── shells.nix           # Dev shells
└── sec/
    └── hardening.nix        # Final security overrides (highest priority)
```

## Best Practices
1. **Always validate before rebuild**: Run `nix flake check`
2. **Use mkDefault liberally**: Makes configs more flexible
3. **Document security decisions**: Explain why hardening is needed
4. **Keep secrets out of store**: Use sops-nix for secrets
5. **Test in VM first**: Use vm-image for risky changes
6. **Modular over monolithic**: One concern per module
7. **Comment TODOs**: Track known issues and future work

## Security Considerations
- Security modules imported last (highest priority)
- Use `mkForce` in `sec/hardening.nix` for final overrides
- Secrets managed via sops-nix (encrypted in repo)
- Immutable users (`users.mutableUsers = false`)
- Minimal attack surface (blacklist unused kernel modules)

## Quick Reference
- **Rebuild**: `sudo nixos-rebuild switch`
- **Check flake**: `nix flake check`
- **Update inputs**: `nix flake update`
- **Build VM**: `nix build .#vm-image`
- **Build ISO**: `nix build .#iso`
- **Show generations**: `nix-env --list-generations --profile /nix/var/nix/profiles/system`
- **Rollback**: `sudo nixos-rebuild switch --rollback`
