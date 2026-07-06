# CI/CD Pipeline Setup for NixOS Configuration

This repository includes comprehensive CI/CD pipeline configurations for multiple Git platforms.

## Supported Platforms

### 1. GitHub Actions
**File:** `.github/workflows/nixos-build.yml`

**Features:**
- Flake validation
- NixOS configuration build
- Code formatting check
- Security vulnerability scanning (Trivy, vulnix)
- Cachix integration

**Setup:**
1. Enable GitHub Actions in your repository
2. Add secrets:
   - `CACHIX_AUTH_TOKEN` (optional, for caching)
3. Push to `main` or `develop` branch

### 2. GitLab CI
**File:** `.gitlab-ci.yml`

**Features:**
- Multi-stage pipeline (check → build → test → security)
- ISO image building (on main/tags)
- Security scanning
- GitLab Pages for reports

**Setup:**
1. Ensure GitLab CI/CD is enabled
2. Configure CI/CD variables (optional):
   - Caching settings
3. Push to trigger pipeline

### 3. Gitea/Codeberg Actions
**File:** `.gitea/workflows/nixos-build.yml`

**Features:**
- Compatible with Gitea Actions and Codeberg
- Similar to GitHub Actions workflow
- Lightweight security scanning

**Setup:**
1. Enable Gitea Actions on your instance
2. Configure runners
3. Push to trigger workflow

## NixOS Module: CI/CD Tools

**File:** `modules/development/cicd.nix`

### Enable in your configuration:

```nix
# In your configuration.nix or flake.nix
{
  imports = [ ./modules/development/cicd.nix ];

  kernelcore.development.cicd = {
    enable = true;

    # Enable platform-specific tools
    platforms = {
      github = true;  # Installs gh CLI
      gitlab = true;  # Installs glab CLI
      gitea = true;   # Installs tea CLI
    };

    docker = true;  # Enable Docker for local testing

    # Git hooks
    pre-commit = {
      enable = true;
      checkDirty = true;    # Warn about uncommitted changes
      formatCode = true;    # Auto-format Nix code
      runTests = false;     # Run flake check (can be slow)
      flakeCheckOnPush = true; # Keep local push guardrails (set false when relying on hosted CI)
    };
  };
}
```

### Installed Tools

When enabled, you get:

**Core Tools:**
- `git`, `git-lfs`, `git-crypt`
- `act` - Run GitHub Actions locally
- `pre-commit` - Git hooks framework
- `nixfmt-rfc-style` - Nix formatter
- `statix` - Nix linter
- `deadnix` - Find unused Nix code

**Security:**
- `trivy` - Vulnerability scanner
- `vulnix` - Nix-specific vulnerability scanner

**Platform-specific:**
- `gh` - GitHub CLI (if github enabled)
- `glab` - GitLab CLI (if gitlab enabled)
- `tea` - Gitea CLI (if gitea enabled)

**Container tools (if docker enabled):**
- `docker`, `docker-compose`
- `podman`, `buildah`

## Git Hooks

When `pre-commit.enable = true`, hooks are installed in `/etc/nixos-config-hooks/`:

### Pre-commit Hook
Runs before each commit:
- Warns about uncommitted changes (if `checkDirty = true`)
- Auto-formats Nix files (if `formatCode = true`)
- Runs flake check (if `runTests = true`)

### Pre-push Hook
Runs before pushing:
- **Blocks push** if there are uncommitted changes
- Runs `nix flake check` to validate configuration (skip when `flakeCheckOnPush = false`)
- Prevents pushing broken configurations

### Manual Hook Installation

If you want to use hooks in the `/etc/nixos` directory:

```bash
cd /etc/nixos
ln -s /etc/nixos-config-hooks .git/hooks
```

## Local Testing

### Test GitHub Actions locally
```bash
# Install act (included in cicd module)
act -l  # List workflows
act push  # Simulate push event
```

### Test NixOS build locally
```bash
nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel
```

### Run security scans
```bash
# Scan for vulnerabilities
trivy fs --security-checks vuln,config .

# Scan Nix store paths
vulnix -w $(nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel --no-link --print-out-paths)

# Scan for secrets
trivy fs --security-checks secret .
```

### Check code quality
```bash
# Format check
nix fmt -- --check .

# Format files
nix fmt

# Lint Nix code
statix check

# Find dead code
deadnix
```

## Useful Aliases

The cicd module provides these aliases:

```bash
git-scan-secrets   # Scan for leaked secrets
nix-check          # Run flake check
nix-fmt-check      # Check formatting
nix-build-test     # Dry-run build
```

## CI/CD Best Practices

1. **Always commit changes before pushing**
   - The pre-push hook will block dirty pushes
   - Prevents "Git tree is dirty" warnings

2. **Run `nix flake check` locally first**
   - Catches errors before CI
   - Saves CI minutes

3. **Format code before committing**
   - Run `nix fmt` or enable `formatCode = true`

4. **Use Cachix for faster builds**
   - Add `CACHIX_AUTH_TOKEN` secret
   - Dramatically speeds up CI builds

5. **Keep secrets out of git**
   - Use `git-scan-secrets` regularly
   - Never commit tokens/passwords

## Troubleshooting

### "Git tree is dirty" warning
**Cause:** Uncommitted changes in working directory
**Solution:** Commit or stash changes before rebuild

### "NIX_PATH entry does not exist" warning
**Cause:** Using flakes but NIX_PATH references channels
**Solution:** Already fixed in `modules/system/nix.nix` with:
```nix
nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
```

### CI failing on flake check
**Cause:** Invalid Nix syntax or missing inputs
**Solution:** Run locally: `nix flake check --show-trace`

### Pre-commit hooks not running
**Cause:** Hooks not linked in .git/hooks
**Solution:**
```bash
cd /etc/nixos
ln -sf /etc/nixos-config-hooks/* .git/hooks/
```

## Security Considerations

- Never commit secrets to git (use `sops-nix` or similar)
- Always scan for vulnerabilities before deploying
- Use minimal container images in CI
- Review security scan results regularly
- Keep Nix and nixpkgs updated

## Additional Resources

- [GitHub Actions for Nix](https://github.com/marketplace/actions/install-nix)
- [Cachix](https://cachix.org) - Nix binary cache
- [Trivy](https://github.com/aquasecurity/trivy) - Security scanner
- [Vulnix](https://github.com/nix-community/vulnix) - Nix vulnerability scanner
