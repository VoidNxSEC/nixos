# GitHub Actions CI/CD for NixOS

Professional CI/CD infrastructure for NixOS projects with reusable actions, workflows, and templates.

## 🚀 Quick Start

### For This Repository

Workflows are automatically triggered on push/PR. No setup required!

### For Other Projects

Use our reusable workflows:

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  validate:
    uses: VoidNxSEC/nixos/.github/workflows/pr-validation.yml@main
    secrets: inherit
```

## 📋 Available Composite Actions

### 1. setup-nix-env
Configure Nix with flakes, cachix, and optimizations.

```yaml
- uses: VoidNxSEC/nixos/.github/actions/setup-nix-env@main
  with:
    cachix-name: 'my-cache'
    cachix-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
    enable-flakes: true
```

**Outputs**:
- `nix-version`: Installed Nix version
- `cache-hit`: Whether cache was hit

### 2. build-nixos
Build NixOS configuration with validation.

```yaml
- uses: VoidNxSEC/nixos/.github/actions/build-nixos@main
  with:
    config-path: '.#nixosConfigurations.myhost.config.system.build.toplevel'
    enable-tests: true
    cachix-push: true
```

**Outputs**:
- `build-path`: Path to build result
- `closure-size`: Closure size in MB
- `build-time`: Build time in seconds

### 3. notify
Send notifications to Discord, Slack, or GitHub issues.

```yaml
- uses: VoidNxSEC/nixos/.github/actions/notify@main
  with:
    status: 'failure'
    title: 'Build Failed'
    message: 'CI pipeline failed'
    discord-webhook: ${{ secrets.DISCORD_WEBHOOK }}
    create-issue-on-failure: true
```

## 🔄 Available Workflows

### PR Validation
Validates pull requests with formatting, flake checks, builds, and security scans.

```yaml
jobs:
  validate:
    uses: VoidNxSEC/nixos/.github/workflows/pr-validation.yml@main
    with:
      config-path: '.#nixosConfigurations.myhost.config.system.build.toplevel'
      skip-tests: false
    secrets: inherit
```

### Rollback System
Manual workflow for system rollback with health checks.

```yaml
# Trigger manually via GitHub UI or gh CLI:
gh workflow run rollback.yml \
  -f generation="" \
  -f reason="Critical bug in latest deployment" \
  -f notify-team=true
```

### SOPS Setup
Reusable workflow for decrypting SOPS secrets.

```yaml
jobs:
  secrets:
    uses: VoidNxSEC/nixos/.github/workflows/setup-sops.yml@main
    secrets: inherit
  
  build:
    needs: secrets
    runs-on: ubuntu-latest
    steps:
      - run: echo ${{ needs.secrets.outputs.cachix_token }}
```

## 🎨 Templates

### Basic NixOS CI

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    uses: VoidNxSEC/nixos/.github/workflows/pr-validation.yml@main
    secrets: inherit
```

### Full CI/CD with Deploy

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:

env:
  CACHIX_NAME: my-cache

jobs:
  # PR Validation
  pr-check:
    if: github.event_name == 'pull_request'
    uses: VoidNxSEC/nixos/.github/workflows/pr-validation.yml@main
    secrets: inherit

  # Main branch deployment
  deploy:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Nix
        uses: VoidNxSEC/nixos/.github/actions/setup-nix-env@main
        with:
          cachix-name: ${{ env.CACHIX_NAME }}
          cachix-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
      
      - name: Build
        uses: VoidNxSEC/nixos/.github/actions/build-nixos@main
        with:
          config-path: '.#nixosConfigurations.prod.config.system.build.toplevel'
      
      - name: Deploy
        run: sudo nixos-rebuild switch --flake .#prod
      
      - name: Notify Success
        if: success()
        uses: VoidNxSEC/nixos/.github/actions/notify@main
        with:
          status: success
          title: "Deployment Successful"
          discord-webhook: ${{ secrets.DISCORD_WEBHOOK }}
```

## 🔐 Required Secrets

Configure in repository settings → Secrets and variables → Actions:

### Essential
- `AGE_SECRET_KEY`: Age key for SOPS decryption
- `CACHIX_AUTH_TOKEN`: Cachix authentication token

### Optional
- `DISCORD_WEBHOOK`: Discord webhook URL for notifications
- `SLACK_WEBHOOK`: Slack webhook URL for notifications
- `GITHUB_TOKEN`: Automatically provided, used for creating issues

### Setup Commands

```bash
# Generate AGE key
age-keygen -o age.key

# Add to GitHub secrets
gh secret set AGE_SECRET_KEY < age.key

# Add Cachix token
gh secret set CACHIX_AUTH_TOKEN

# Add Discord webhook (optional)
gh secret set DISCORD_WEBHOOK
```

## 🛠️ Local Development

### Test Actions Locally

Use [act](https://github.com/nektos/act) to test workflows locally:

```bash
# Install act
nix-env -iA nixpkgs.act

# List available workflows
act -l

# Run PR validation workflow
act pull_request -W .github/workflows/pr-validation.yml

# Run with secrets
act -s CACHIX_AUTH_TOKEN=your-token
```

### Validate Workflow Syntax

```bash
# Using actionlint
nix-shell -p actionlint --run "actionlint .github/workflows/*.yml"

# Using GitHub CLI
gh workflow list
gh workflow view pr-validation.yml
```

## 📊 Monitoring

### View Workflow Runs

```bash
# List recent runs
gh run list

# Watch a specific run
gh run watch

# View logs
gh run view --log
```

### Build Reports

All workflows generate detailed summaries in the GitHub Actions UI:
- Build times and closure sizes
- Test results
- Security scan findings
- Health check status

## 🎯 Best Practices

### Commits
- ✅ Small, focused commits
- ✅ Descriptive commit messages
- ✅ Test locally before pushing

### Pull Requests
- ✅ Always create PR before merging to main
- ✅ Wait for CI checks to pass
- ✅ Review security scan results
- ✅ Address all feedback

### Deployment
- ✅ Deploy only from main branch
- ✅ Use rollback workflow if issues occur
- ✅ Monitor system health after deployment
- ✅ Keep backups of working configurations

### Caching
- ✅ Use Cachix for Nix builds
- ✅ Push successful builds to cache
- ✅ Configure cache retention policies
- ✅ Monitor cache hit rates

## 🔧 Troubleshooting

### Workflow Not Triggering

```bash
# Check workflow syntax
actionlint .github/workflows/your-workflow.yml

# Check GitHub Actions tab for errors
gh run list --limit 5
```

### Build Failing

```bash
# Replicate locally
nix build .#nixosConfigurations.yourhost.config.system.build.toplevel --show-trace

# Check logs
gh run view --log

# Check cache
cachix watch-exec your-cache -- nix build
```

### Secrets Not Working

```bash
# List configured secrets
gh secret list

# Update secret
gh secret set SECRET_NAME

# Verify SOPS configuration
sops -d secrets/github.yaml
```

## 📚 Additional Resources

- [Architecture Documentation](../docs/CI-CD-ARCHITECTURE.md)
- [GitHub Actions Runner Setup](../docs/GITHUB-ACTIONS-RUNNER-FIX.md)
- [Runner Configuration Examples](../docs/GITHUB-ACTIONS-RUNNER-CONFIG-EXAMPLES.md)

## 🤝 Contributing

### Adding New Actions

1. Create directory: `.github/actions/your-action/`
2. Add `action.yml` with metadata and steps
3. Document inputs/outputs
4. Test with act or in PR
5. Update this README

### Adding New Workflows

1. Create `.github/workflows/your-workflow.yml`
2. Follow existing patterns
3. Use reusable workflows when possible
4. Document in this README
5. Test thoroughly

## 📝 License

MIT License - See repository LICENSE file

## 👥 Maintainers

- [@VoidNxSEC](https://github.com/VoidNxSEC)

---

**Last Updated**: 2025-11-28  
**Version**: 1.0.0