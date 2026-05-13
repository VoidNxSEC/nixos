# GitHub Actions CI/CD for NixOS

CI/CD infrastructure for the NixOS configuration repository with composite actions, reusable workflows, and observability.

## Composite Actions

### `setup-nix-env`
Configures Nix with flakes, Cachix, and build optimizations.

```yaml
- uses: ./.github/actions/setup-nix-env
  with:
    cachix-name: 'my-cache'
    cachix-token: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

**Outputs**: `nix-version`, `cache-hit`

### `build-nixos`
Builds a NixOS configuration with validation and optional Cachix push.

```yaml
- uses: ./.github/actions/build-nixos
  with:
    config-path: '.#nixosConfigurations.kernelcore.config.system.build.toplevel'
    enable-tests: true
    cachix-push: true
```

**Outputs**: `build-path`, `closure-size`, `build-time`

### `notify`
Sends notifications to Discord, Slack, or GitHub Issues.

```yaml
- uses: ./.github/actions/notify
  with:
    status: 'failure'
    title: 'Build Failed'
    message: 'CI pipeline failed'
    discord-webhook: ${{ secrets.DISCORD_WEBHOOK }}
    create-issue-on-failure: true
```

---

## Workflows

### `ci.yml` — Main CI
Triggered on push and pull requests. Runs `nix flake check` then builds the `kernelcore` system closure. This is the primary workflow that must pass before merging.

### `pr-validation.yml` — PR Validation (reusable)
Reusable workflow for PR checks: formatting, flake check, build, and security scans.

```yaml
jobs:
  validate:
    uses: ./.github/workflows/pr-validation.yml
    secrets: inherit
```

### `nixos-build.yml` — NixOS Build & Test
Builds and tests the NixOS configuration. Supports optional tmate debug sessions.

```yaml
jobs:
  build:
    uses: ./.github/workflows/nixos-build.yml
    with:
      enable-tmate: false
      tmate-on-failure: true
    secrets: inherit
```

### `ci-observability.yml` — Observability & Debug (reusable)
Reusable workflow with full build observability: structured metrics, JSON reports, Discord/Telegram/Slack notifications, and tmate remote debug.

```yaml
jobs:
  my-build:
    uses: ./.github/workflows/ci-observability.yml
    with:
      enable-tmate: false
      tmate-on-failure: true
    secrets:
      DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
      TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
      TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

### `deploy.yml` — Deploy (manual)
Manual workflow for deploying to a host. Requires `workflow_dispatch`. Runs on the target host directly.

```bash
gh workflow run deploy.yml -f host=kernelcore
```

### `rollback.yml` — Rollback System (manual)
Manual workflow to roll back to a previous NixOS generation with optional team notification.

```bash
gh workflow run rollback.yml \
  -f generation="" \
  -f reason="Regression in latest deployment" \
  -f notify-team=true
```

### `setup-sops.yml` — SOPS Secrets (reusable)
Reusable workflow that decrypts SOPS-encrypted secrets for use in dependent jobs.

```yaml
jobs:
  secrets:
    uses: ./.github/workflows/setup-sops.yml
    secrets: inherit
```

### `update-lock.yml` — Update Flake Lock
Runs every Monday at 06:00 UTC (or manually) to update `flake.lock` and open a PR with the changes.

---

## Required Secrets

| Secret | Purpose | Required |
|--------|---------|----------|
| `AGE_SECRET_KEY` | Age key for SOPS decryption | Yes |
| `CACHIX_AUTH_TOKEN` | Cachix binary cache auth | Yes |
| `DISCORD_WEBHOOK` | Discord notifications | No |
| `TELEGRAM_BOT_TOKEN` | Telegram notifications | No |
| `TELEGRAM_CHAT_ID` | Telegram chat target | No |
| `SLACK_WEBHOOK` | Slack notifications | No |

```bash
# Set secrets via gh CLI
gh secret set AGE_SECRET_KEY < age.key
gh secret set CACHIX_AUTH_TOKEN
gh secret set DISCORD_WEBHOOK
```

---

## Local Testing

```bash
# Validate workflow syntax
nix-shell -p actionlint --run "actionlint .github/workflows/*.yml"

# Test with act
nix-shell -p act --run "act pull_request -W .github/workflows/pr-validation.yml"

# Monitor recent runs
gh run list --limit 10
gh run watch
gh run view --log
```

---

## Archived Workflows

Previously removed workflows are preserved in `.github/archived-workflows/` for reference.

---

**Last Updated**: 2026-05-13
**Maintained by**: kernelcore
