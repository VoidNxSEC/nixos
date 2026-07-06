# Git Workflow, Testing & Secrets Management - Improvement Plan

> **Status**: Analysis Complete - Ready for Implementation
> **Created**: 2025-11-09
> **Objective**: Modernize git workflow, implement comprehensive testing, integrate GitHub Secrets with SOPS

---

## Executive Summary

Este documento apresenta uma análise completa do estado atual do repositório NixOS em três áreas críticas:
1. **Git Workflow** - Processo de desenvolvimento e CI/CD
2. **Testing Framework** - Testes automatizados e validação
3. **Secrets Management** - Gerenciamento seguro de credenciais

A análise identificou pontos fortes existentes e oportunidades significativas de melhoria.

---

## 1. Git Workflow - Estado Atual

### ✅ Pontos Fortes

#### 1.1 Branch Structure
```
main                    # Production branch (stable)
backup-pre-rollback-*   # Safety backups
```
- ✅ Git history limpo e bem documentado
- ✅ Commits descritivos com contexto
- ✅ Padrão de commit message estabelecido

#### 1.2 CI/CD Pipelines

**GitHub Actions** (`.github/workflows/nixos-build.yml`):
```yaml
Jobs:
  ✅ check         # Flake validation, metadata, eval errors
  ✅ build         # Matrix: toplevel, iso, vm-image
  ✅ test-modules  # Dev shells, Docker images, systemd services
  ✅ security      # Vulnix, nix-store audit, secrets grep
  ✅ format        # nixfmt formatting check
  ✅ deploy        # Auto-deploy on main (optional)
  ✅ report        # Build summary & notifications

Features:
  - Self-hosted runner
  - Cachix integration
  - Matrix builds (3 variants)
  - Artifact storage
  - Build summaries
```

**GitLab CI** (`.gitlab-ci.yml`):
```yaml
Stages:
  ✅ check     # Flake check, format check
  ✅ build     # kernelcore, ISO
  ✅ test      # Module tests (placeholder)
  ✅ security  # Vulnix, Trivy scans
  ✅ pages     # Report publishing

Features:
  - Multi-stage pipeline
  - Trivy security scanning
  - Artifact caching
  - GitLab Pages for reports
```

### ❌ Gaps Identificados

#### 1.3 Git Workflow Gaps

1. **Sem Git Hooks Customizados**
   - Apenas samples em `.git/hooks/`
   - Sem validação pré-commit (fmt, syntax)
   - Sem validação pré-push (tests)
   - Sem automatic linting

2. **Sem Branch Protection**
   - Branch `main` não está protegido
   - Sem requirement de PR reviews
   - Sem status checks obrigatórios
   - Permite force push

3. **Sem PR Templates**
   - Sem `.github/pull_request_template.md`
   - Sem guidelines para contribuição
   - Sem checklist padrão

4. **Sem Issue Templates**
   - Sem `.github/ISSUE_TEMPLATE/`
   - Dificulta bug reports estruturados
   - Sem template para feature requests

5. **Sem CODEOWNERS**
   - Sem `.github/CODEOWNERS`
   - Sem automatic reviewer assignment
   - Sem ownership claro de módulos

---

## 2. Testing Framework - Estado Atual

### ✅ Testes Existentes

#### 2.1 Flake Checks Básicos
```nix
checks.${system} = {
  fmt        = nixfmt --check .
  iso        = build ISO image
  vm         = build VM image
  docker-app = build Docker app image
};
```

#### 2.2 Validation Scripts

**modules/debug/test-init.nix**:
```bash
test-nixos-config    # Flake validation, dry-run build
test-nixos-vm        # Build test VM
backup-nixos-config  # Create config backup
```

**scripts/post-rebuild-validate.sh** (369 linhas):
```bash
Checks:
  ✅ Critical system services (dbus, logind, accounts-daemon)
  ✅ Display services (display-manager, gnome-shell)
  ✅ Network services (NetworkManager, sshd, connectivity)
  ✅ Container services (docker, libvirtd)
  ✅ Security services (firewall, fail2ban, apparmor)
  ✅ System health (nix store, failed units)
  ✅ Essential commands (nix, systemctl, git)

Features:
  - --fix mode (auto-repair)
  - --verbose mode
  - Color-coded output
  - Service restart capability
```

#### 2.3 TypeScript Tests (ML Modules)

**modules/ml/unified-llm/mcp-server/tests/**:
```
circuit-breaker.test.ts     # Circuit breaker pattern tests
error-classifier.test.ts    # Error classification tests
metrics-collector.test.ts   # Metrics collection tests
retry-strategy.test.ts      # Retry logic tests
```

**modules/ml/Security-Architect/tests/**:
- Unit tests para Security-Architect module

### ❌ Testing Gaps

#### 2.4 Missing Test Types

1. **NixOS Module Tests**
   - ❌ Sem `makeTest`/`nixosTest` tests
   - ❌ Sem testes de integração entre módulos
   - ❌ Testes no CI são placeholders vazios:
   ```yaml
   test:modules:
     script:
       - echo "Running NixOS module tests"
       # Add your tests here  # ← VAZIO
   ```

2. **Integration Tests**
   - ❌ Sem testes de interação entre serviços
   - ❌ Sem testes de networking
   - ❌ Sem testes de segurança automatizados

3. **Regression Tests**
   - ❌ Sem proteção contra regressões
   - ❌ Sem baseline de performance
   - ❌ Sem tracking de build times

4. **Coverage Tracking**
   - ❌ Sem métricas de cobertura
   - ❌ Sem relatórios de coverage
   - ❌ Sem tracking de quality metrics

5. **Test Infrastructure**
   - ❌ Sem diretório `tests/`
   - ❌ Sem framework de testes consistente
   - ❌ post-rebuild-validate.sh não integrado no CI

---

## 3. Secrets Management - Estado Atual

### ✅ SOPS Implementation

#### 3.1 SOPS Configuration (`.sops.yaml`)

```yaml
Encryption Rules: 11 regras
  ✅ secrets/api.yaml              # AI/ML API keys
  ✅ secrets/github.yaml           # GitHub tokens
  ✅ secrets/database.yaml         # DB credentials
  ✅ secrets/aws.yaml              # AWS credentials
  ✅ secrets/ssh-keys/*.yaml       # SSH keys
  ✅ secrets/prod.yaml             # Production secrets
  ✅ MCP OAuth tokens              # encrypted JSON
  ✅ Default catch-all             # Fallback

AGE Keys: 2 chaves configuradas
  - age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn
  - age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
```

#### 3.2 Secrets Files

```bash
secrets/
├── api.yaml              # 3.9KB - API keys (populated)
├── github.yaml           # 2.8KB - GitHub tokens (populated)
├── secrets.yaml          # 2.2KB - General secrets
├── aws.yaml              # 0B - Empty (template)
├── database.yaml         # 0B - Empty (template)
├── prod.yaml             # 0B - Empty (template)
├── ssh.yaml              # 0B - Empty (template)
└── ssh-keys/
    ├── production.yaml   # SSH keys
    ├── staging.yaml
    └── dev.yaml
```

#### 3.3 NixOS Integration

**modules/secrets/sops-config.nix**:
- Configura estrutura de diretórios
- Configura permissões
- Fornece templates

**modules/secrets/api-keys.nix**:
```nix
Secrets Decrypted to /run/secrets/:
  ✅ anthropic_api_key
  ✅ openai_api_key, openai_project_id
  ✅ deepseek_api_key
  ✅ gemini_api_key
  ✅ openrouter_api_key
  ✅ replicate_api_key
  ✅ mistral_api_key
  ✅ groq_api_key, groq_project_id
  ✅ nvidia_api_key
  ✅ github_token
```

**Environment Helper** (`/etc/load-api-keys.sh`):
```bash
# Load decrypted secrets into environment variables
source /etc/load-api-keys.sh
```

#### 3.4 Scripts

```bash
scripts/add-secret.sh              # Add new SOPS secret
scripts/migrate-sec-to-sops.sh     # Migrate existing secrets
scripts/fix-secrets-permissions.sh # Fix permissions
```

### ❌ Secrets Management Gaps

#### 3.5 GitHub Secrets Integration

**Current State**:
```yaml
# .github/workflows/nixos-build.yml
secrets.CACHIX_AUTH_TOKEN  # ← GitHub Secrets UI (manual)
secrets.GITHUB_TOKEN       # ← Built-in GitHub secret
```

**Problems**:
1. ❌ GitHub Actions usa GitHub Secrets UI (separado do SOPS)
2. ❌ Não há sincronização entre `secrets/*.yaml` e GitHub Secrets
3. ❌ Secrets duplicados em dois sistemas
4. ❌ Sem source of truth único
5. ❌ GitHub runner tokens não em SOPS

#### 3.6 Secrets Rotation

- ❌ Sem automated secrets rotation
- ❌ Sem expiration tracking
- ❌ Sem audit log de acesso

#### 3.7 Multi-Environment Support

- ⚠️ Arquivos vazios (dev, staging, prod)
- ⚠️ Sem clara separação dev/staging/prod
- ⚠️ Sem environment-specific configs

---

## 4. Improvement Plan - Detailed

### Phase 1: Git Workflow Improvements (Week 1)

#### 4.1 Git Hooks Implementation

**Create `.githooks/` directory**:
```bash
.githooks/
├── pre-commit           # Format check, syntax validation
├── pre-push            # Run tests before push
├── commit-msg          # Validate commit message format
└── post-merge          # Update dependencies after merge
```

**pre-commit hook**:
```bash
#!/usr/bin/env bash
# Check Nix formatting
echo "🔍 Checking Nix formatting..."
nix fmt -- --check . || {
  echo "❌ Formatting check failed. Run: nix fmt"
  exit 1
}

# Validate flake syntax
echo "🔍 Validating flake syntax..."
nix flake check --no-build || {
  echo "❌ Flake check failed"
  exit 1
}

echo "✅ Pre-commit checks passed"
```

**pre-push hook**:
```bash
#!/usr/bin/env bash
# Run quick tests before push
echo "🧪 Running tests before push..."

# Run flake check with timeout
timeout 120 nix flake check || {
  echo "❌ Tests failed or timed out"
  exit 1
}

echo "✅ Pre-push checks passed"
```

**Setup script** (`scripts/setup-git-hooks.sh`):
```bash
#!/usr/bin/env bash
# Install git hooks
git config core.hooksPath .githooks
chmod +x .githooks/*
echo "✅ Git hooks installed"
```

#### 4.2 PR & Issue Templates

**`.github/pull_request_template.md`**:
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] `nix flake check` passes
- [ ] Tested on NixOS
- [ ] Added/updated tests
- [ ] Updated documentation

## Security Checklist
- [ ] No hardcoded secrets
- [ ] SOPS used for sensitive data
- [ ] Security implications documented

## Screenshots (if applicable)

## Related Issues
Fixes #(issue number)
```

**`.github/ISSUE_TEMPLATE/bug_report.md`**:
```markdown
---
name: Bug Report
about: Report a bug in NixOS configuration
title: '[BUG] '
labels: bug
---

## Bug Description
Clear description of the bug

## Steps to Reproduce
1. ...
2. ...

## Expected Behavior

## Actual Behavior

## Environment
- NixOS version:
- Commit hash:
- Hardware:

## Logs
```

**`.github/ISSUE_TEMPLATE/feature_request.md`**:
```markdown
---
name: Feature Request
about: Suggest a new feature
title: '[FEATURE] '
labels: enhancement
---

## Feature Description

## Use Case

## Proposed Implementation

## Alternatives Considered

## Additional Context
```

#### 4.3 Branch Protection Rules

**GitHub Settings → Branches → Add rule**:
```yaml
Branch name pattern: main

Require pull request reviews before merging: ✅
  Required approving reviews: 1
  Dismiss stale reviews: ✅

Require status checks to pass: ✅
  Required checks:
    - check / Check Nix flake
    - build / Build NixOS configuration (toplevel)
    - test-modules / Test NixOS modules
    - security / Security checks
    - format / Check formatting

Require conversation resolution: ✅
Do not allow bypassing: ✅
Require linear history: ✅
```

#### 4.4 CODEOWNERS

**`.github/CODEOWNERS`**:
```
# Global ownership
* @kernelcore

# Security modules
/modules/security/ @kernelcore
/sec/ @kernelcore

# Secrets management
/secrets/ @kernelcore
/modules/secrets/ @kernelcore
/.sops.yaml @kernelcore

# CI/CD
/.github/ @kernelcore
/.gitlab-ci.yml @kernelcore

# ML infrastructure
/modules/ml/ @kernelcore

# Hardware configs
/modules/hardware/ @kernelcore
```

---

### Phase 2: Testing Framework (Week 2)

#### 4.5 NixOS Module Tests

**Create `tests/` directory structure**:
```
tests/
├── default.nix              # Main test aggregator
├── integration/
│   ├── security-hardening.nix
│   ├── docker-services.nix
│   ├── networking.nix
│   └── nvidia-gpu.nix
├── modules/
│   ├── test-security-modules.nix
│   ├── test-container-modules.nix
│   └── test-ml-modules.nix
├── vm/
│   ├── basic-vm-test.nix
│   └── gpu-vm-test.nix
└── lib/
    └── test-helpers.nix
```

**Example: `tests/integration/security-hardening.nix`**:
```nix
{ pkgs, ... }:

import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "security-hardening";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../../modules/security
      ../../sec/hardening.nix
    ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Test firewall is active
    machine.succeed("systemctl is-active firewall.service")

    # Test kernel hardening
    machine.succeed("sysctl kernel.dmesg_restrict | grep '= 1'")
    machine.succeed("sysctl kernel.kptr_restrict | grep '= 2'")

    # Test AppArmor
    machine.succeed("systemctl is-active apparmor.service")

    # Test no SUID binaries in /tmp
    machine.fail("find /tmp -perm -4000 -type f")

    # Test failed login attempts limited
    machine.succeed("grep -q 'maxretry = 5' /etc/fail2ban/jail.conf")
  '';
})
```

**Example: `tests/integration/docker-services.nix`**:
```nix
{ pkgs, ... }:

import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "docker-services";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../../modules/containers/docker.nix
    ];
  };

  testScript = ''
    machine.wait_for_unit("docker.service")

    # Test Docker is running
    machine.succeed("docker info")

    # Test Docker compose is available
    machine.succeed("docker-compose --version")

    # Test Docker networks
    machine.succeed("docker network ls | grep bridge")

    # Test can pull and run a simple container
    machine.succeed("docker run --rm hello-world")
  '';
})
```

**`tests/default.nix`**:
```nix
{ pkgs ? import <nixpkgs> {} }:

{
  # Integration tests
  security = import ./integration/security-hardening.nix { inherit pkgs; };
  docker = import ./integration/docker-services.nix { inherit pkgs; };
  networking = import ./integration/networking.nix { inherit pkgs; };

  # Module tests
  securityModules = import ./modules/test-security-modules.nix { inherit pkgs; };
  containerModules = import ./modules/test-container-modules.nix { inherit pkgs; };

  # VM tests
  basicVM = import ./vm/basic-vm-test.nix { inherit pkgs; };
}
```

#### 4.6 Enhanced Flake Checks

**Update `flake.nix`**:
```nix
checks.${system} = {
  # Existing
  fmt = ...;
  iso = ...;
  vm = ...;
  docker-app = ...;

  # NEW: Import all tests
  tests = import ./tests { inherit pkgs; };

  # NEW: Security validation
  security-audit = pkgs.runCommand "security-audit" {} ''
    # Run security checks
    ${pkgs.vulnix}/bin/vulnix ${config.system.build.toplevel} > $out
  '';

  # NEW: Documentation build
  docs = pkgs.runCommand "build-docs" {} ''
    mkdir -p $out
    # Build documentation
    cp -r ${./docs}/* $out/
  '';

  # NEW: Module syntax validation
  module-syntax = pkgs.runCommand "validate-modules" {} ''
    # Validate all .nix files parse
    find ${./modules} -name "*.nix" -exec nix-instantiate --parse {} \;
    touch $out
  '';
};
```

#### 4.7 Integrate post-rebuild-validate in CI

**Update `.github/workflows/nixos-build.yml`**:
```yaml
test-post-rebuild:
  name: Post-rebuild validation
  runs-on: [self-hosted, nixos]
  needs: build
  steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Run post-rebuild validation
      run: |
        chmod +x scripts/post-rebuild-validate.sh
        ./scripts/post-rebuild-validate.sh --verbose

    - name: Upload validation report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: post-rebuild-validation-report
        path: validation-report.log
```

#### 4.8 Coverage & Metrics

**Create `scripts/test-coverage.sh`**:
```bash
#!/usr/bin/env bash
# Generate test coverage report

echo "📊 Generating test coverage report..."

# Count total modules
TOTAL_MODULES=$(find modules -name "*.nix" | wc -l)

# Count modules with tests
TESTED_MODULES=$(find tests -name "test-*.nix" | wc -l)

# Coverage percentage
COVERAGE=$(echo "scale=2; $TESTED_MODULES / $TOTAL_MODULES * 100" | bc)

cat > coverage-report.md <<EOF
# Test Coverage Report
Generated: $(date)

## Summary
- **Total Modules**: $TOTAL_MODULES
- **Tested Modules**: $TESTED_MODULES
- **Coverage**: ${COVERAGE}%

## Module Breakdown
$(find modules -type d -mindepth 1 -maxdepth 1 | while read dir; do
  name=$(basename "$dir")
  count=$(find "$dir" -name "*.nix" | wc -l)
  echo "- **$name**: $count modules"
done)
EOF

echo "✅ Coverage report generated: coverage-report.md"
```

---

### Phase 3: GitHub Secrets via SOPS (Week 3)

#### 4.9 Strategy Overview

**Goal**: Use SOPS as single source of truth for ALL secrets, including GitHub Actions.

**Approach**:
1. Store GitHub secrets in SOPS (`secrets/github.yaml`)
2. Use GitHub Actions to decrypt SOPS secrets at runtime
3. Export decrypted secrets as environment variables
4. Use in workflow steps

#### 4.10 SOPS Structure for GitHub

**Update `secrets/github.yaml`** (encrypted):
```yaml
# GitHub tokens and secrets for CI/CD
github:
  # Personal Access Token
  personal_access_token: "ghp_xxxxxxxxxxxxxxxxxxxx"

  # Cachix authentication
  cachix_auth_token: "ey.........................."

  # Self-hosted runner registration
  runner_token: "ABCD.........................."
  runner_registration_url: "https://github.com/user/repo"

  # Deploy keys (if needed)
  deploy_key_private: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

**Update `.sops.yaml`**:
```yaml
creation_rules:
  # GitHub secrets (including CI/CD tokens)
  - path_regex: secrets/github\.yaml$
    encrypted_regex: ^(github|data|stringData)$
    age: >-
      age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn,
      age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
```

#### 4.11 GitHub Actions Integration

**Create `.github/workflows/setup-sops.yml`** (reusable workflow):
```yaml
name: Setup SOPS and Decrypt Secrets

on:
  workflow_call:
    outputs:
      cachix_token:
        description: "Decrypted Cachix token"
        value: ${{ jobs.decrypt.outputs.cachix_token }}

jobs:
  decrypt:
    runs-on: [self-hosted, nixos]
    outputs:
      cachix_token: ${{ steps.decrypt.outputs.cachix_token }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup AGE key
        env:
          AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
        run: |
          mkdir -p ~/.config/sops/age
          echo "$AGE_SECRET_KEY" > ~/.config/sops/age/keys.txt
          chmod 600 ~/.config/sops/age/keys.txt

      - name: Decrypt SOPS secrets
        id: decrypt
        run: |
          # Decrypt github.yaml
          CACHIX_TOKEN=$(nix run nixpkgs#sops -- -d secrets/github.yaml | \
            nix run nixpkgs#yq -- -r '.github.cachix_auth_token')

          # Export as output
          echo "cachix_token=$CACHIX_TOKEN" >> $GITHUB_OUTPUT

          # Also export as env for current job
          echo "CACHIX_AUTH_TOKEN=$CACHIX_TOKEN" >> $GITHUB_ENV

      - name: Cleanup
        if: always()
        run: rm -f ~/.config/sops/age/keys.txt
```

**Update main workflow** (`.github/workflows/nixos-build.yml`):
```yaml
name: NixOS Build & Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  setup-secrets:
    name: Decrypt SOPS secrets
    uses: ./.github/workflows/setup-sops.yml
    secrets: inherit

  check:
    name: Check Nix flake
    needs: setup-secrets
    runs-on: [self-hosted, nixos]
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: kernelcore
          authToken: ${{ needs.setup-secrets.outputs.cachix_token }}
          pushFilter: '(-source$|-env$)'

      # ... rest of workflow
```

**Alternative: Direct SOPS in Workflow**:
```yaml
check:
  name: Check Nix flake
  runs-on: [self-hosted, nixos]
  steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup AGE and decrypt secrets
      env:
        AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
      run: |
        # Setup AGE key
        mkdir -p ~/.config/sops/age
        echo "$AGE_SECRET_KEY" > ~/.config/sops/age/keys.txt
        chmod 600 ~/.config/sops/age/keys.txt

        # Decrypt and export secrets
        export CACHIX_AUTH_TOKEN=$(nix run nixpkgs#sops -- -d secrets/github.yaml | \
          nix run nixpkgs#yq -- -r '.github.cachix_auth_token')

        # Make available to next steps
        echo "CACHIX_AUTH_TOKEN=$CACHIX_AUTH_TOKEN" >> $GITHUB_ENV

    - name: Setup Cachix
      uses: cachix/cachix-action@v15
      with:
        name: kernelcore
        authToken: ${{ env.CACHIX_AUTH_TOKEN }}

    - name: Cleanup secrets
      if: always()
      run: rm -f ~/.config/sops/age/keys.txt
```

#### 4.12 Required GitHub Secrets

**Only ONE secret needed in GitHub UI**:
```
AGE_SECRET_KEY = <content of ~/.config/sops/age/keys.txt>
```

All other secrets managed via SOPS in `secrets/github.yaml`.

#### 4.13 Secrets Sync Script

**Create `scripts/sync-github-secrets.sh`**:
```bash
#!/usr/bin/env bash
# Sync SOPS secrets to GitHub Secrets
# Usage: ./scripts/sync-github-secrets.sh

set -euo pipefail

REPO="user/repo"  # Update with your repo

echo "🔐 Syncing SOPS secrets to GitHub..."

# Decrypt secrets
CACHIX_TOKEN=$(sops -d secrets/github.yaml | yq -r '.github.cachix_auth_token')

# Update GitHub secret using gh CLI
gh secret set CACHIX_AUTH_TOKEN --body "$CACHIX_TOKEN" --repo "$REPO"

echo "✅ Secrets synced to GitHub"
echo "⚠️  This script is deprecated - use SOPS directly in workflows instead"
```

#### 4.14 Documentation

**Create `docs/GITHUB-SOPS-INTEGRATION.md`**:
```markdown
# GitHub Actions + SOPS Integration

## Overview
All secrets are managed via SOPS and decrypted at runtime in GitHub Actions.

## Setup

### 1. Add AGE Secret Key to GitHub
```bash
# Get your AGE private key
cat ~/.config/sops/age/keys.txt

# Add to GitHub Secrets:
# Settings → Secrets and variables → Actions → New repository secret
# Name: AGE_SECRET_KEY
# Value: <paste key>
```

### 2. Store Secrets in SOPS
```bash
# Edit GitHub secrets
sops secrets/github.yaml

# Add your secrets:
github:
  cachix_auth_token: "ey..."
  personal_access_token: "ghp_..."
```

### 3. Use in Workflow
```yaml
- name: Decrypt secrets
  env:
    AGE_SECRET_KEY: ${{ secrets.AGE_SECRET_KEY }}
  run: |
    echo "$AGE_SECRET_KEY" > ~/.config/sops/age/keys.txt
    export TOKEN=$(sops -d secrets/github.yaml | yq -r '.github.cachix_auth_token')
```

## Benefits
- ✅ Single source of truth (SOPS)
- ✅ Version controlled (encrypted)
- ✅ Auditable (git history)
- ✅ No manual GitHub UI updates
- ✅ Works across multiple repos
```

---

## 5. Implementation Timeline

### Week 1: Git Workflow (Days 1-7)
- [ ] Day 1-2: Create git hooks (pre-commit, pre-push, commit-msg)
- [ ] Day 2-3: Create PR/Issue templates
- [ ] Day 3-4: Setup CODEOWNERS
- [ ] Day 4-5: Configure branch protection rules
- [ ] Day 5-6: Update documentation
- [ ] Day 7: Test workflow with sample PR

### Week 2: Testing Framework (Days 8-14)
- [ ] Day 8-9: Create tests/ directory structure
- [ ] Day 9-10: Implement NixOS module tests (security, docker, networking)
- [ ] Day 10-11: Enhance flake checks
- [ ] Day 11-12: Integrate post-rebuild-validate in CI
- [ ] Day 12-13: Implement coverage reporting
- [ ] Day 13-14: Documentation and validation

### Week 3: GitHub Secrets via SOPS (Days 15-21)
- [ ] Day 15-16: Update secrets/github.yaml structure
- [ ] Day 16-17: Create reusable SOPS workflow
- [ ] Day 17-18: Update all workflows to use SOPS
- [ ] Day 18-19: Add AGE_SECRET_KEY to GitHub
- [ ] Day 19-20: Test CI/CD with SOPS integration
- [ ] Day 20-21: Documentation and cleanup

---

## 6. Success Metrics

### Git Workflow
- ✅ All commits pass pre-commit hooks
- ✅ No commits to main without PR
- ✅ All PRs require 1 approval
- ✅ 100% of PRs use template
- ✅ All CI checks pass before merge

### Testing
- ✅ >80% module coverage with tests
- ✅ All integration tests pass
- ✅ post-rebuild-validate integrated
- ✅ Zero failed tests in CI
- ✅ Coverage report generated

### Secrets Management
- ✅ Zero secrets in GitHub UI (except AGE_SECRET_KEY)
- ✅ All workflows use SOPS
- ✅ secrets/github.yaml populated
- ✅ CI passes with SOPS integration
- ✅ Documentation complete

---

## 7. Rollback Strategy

### Git Hooks
```bash
# Disable hooks
git config --unset core.hooksPath
```

### Tests
```bash
# Skip tests temporarily
git commit --no-verify
git push --no-verify
```

### SOPS Integration
```bash
# Fallback to GitHub Secrets UI
# Revert workflow changes
git revert <commit-hash>
```

---

## 8. Next Steps

1. **Review this plan** with stakeholders
2. **Prioritize phases** based on urgency
3. **Create GitHub project board** for tracking
4. **Begin Phase 1** after approval
5. **Schedule weekly review** during implementation

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-09
**Maintained By**: kernelcore
**Review Schedule**: Weekly during implementation
