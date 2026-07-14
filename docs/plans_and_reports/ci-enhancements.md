# CI/CD Pipeline Enhancements - Sugestões Profissionais

## 📊 Categoria 1: Métricas e Monitoramento

### 1.1 Build Performance Metrics
**Prioridade**: Alta | **Complexidade**: Baixa
```yaml
- name: Track build metrics
  run: |
    echo "## 📊 Build Metrics" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY

    # Build time
    BUILD_START=$(date +%s)
    nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))

    echo "- ⏱️ Build Time: ${BUILD_TIME}s" >> $GITHUB_STEP_SUMMARY

    # Closure size
    SIZE=$(nix path-info -Sh .#nixosConfigurations.kernelcore.config.system.build.toplevel | awk '{print $2}')
    echo "- 📦 Closure Size: $SIZE" >> $GITHUB_STEP_SUMMARY

    # Dependencies count
    DEPS=$(nix-store -q --requisites ./result | wc -l)
    echo "- 🔗 Dependencies: $DEPS packages" >> $GITHUB_STEP_SUMMARY
```

### 1.2 Cachix Hit Rate
**Prioridade**: Média | **Complexidade**: Baixa
```yaml
- name: Monitor cache efficiency
  run: |
    # Track cache hits vs misses
    echo "## 🎯 Cache Performance" >> $GITHUB_STEP_SUMMARY
    CACHE_HITS=$(grep "copying path.*from.*cache.nixos.org" /tmp/build.log | wc -l || echo "0")
    TOTAL_PATHS=$(grep "copying path" /tmp/build.log | wc -l || echo "1")
    HIT_RATE=$((CACHE_HITS * 100 / TOTAL_PATHS))
    echo "- Cache Hit Rate: ${HIT_RATE}%" >> $GITHUB_STEP_SUMMARY
```

### 1.3 Security Score Tracking
**Prioridade**: Alta | **Complexidade**: Média
```yaml
- name: Security score report
  run: |
    echo "## 🔒 Security Score" >> $GITHUB_STEP_SUMMARY

    # Vulnerability count
    VULNS=$(nix run nixpkgs#vulnix -- -w ./result 2>&1 | grep -c "CVE-" || echo "0")

    # Calculate score (100 - vulnerabilities)
    SCORE=$((100 - VULNS))
    echo "- Security Score: ${SCORE}/100" >> $GITHUB_STEP_SUMMARY
    echo "- Vulnerabilities Found: $VULNS" >> $GITHUB_STEP_SUMMARY

    # Fail if score too low
    if [ $SCORE -lt 80 ]; then
      echo "::warning::Security score below threshold (80)"
    fi
```

---

## 🚀 Categoria 2: Otimização e Performance

### 2.1 Parallel Job Optimization
**Prioridade**: Alta | **Complexidade**: Baixa
```yaml
# Já usa matrix, mas pode adicionar fail-fast
strategy:
  fail-fast: false  # Continue outros jobs se um falhar
  max-parallel: 3   # Limita jobs simultâneos
  matrix:
    target: [toplevel, iso, vm-image]
```

### 2.2 Incremental Builds
**Prioridade**: Média | **Complexidade**: Média
```yaml
- name: Check if rebuild needed
  id: check_changes
  run: |
    # Skip rebuild se apenas docs mudaram
    CHANGED_FILES=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }})
    if echo "$CHANGED_FILES" | grep -qE '\.nix$|flake.lock'; then
      echo "rebuild_needed=true" >> $GITHUB_OUTPUT
    else
      echo "rebuild_needed=false" >> $GITHUB_OUTPUT
      echo "::notice::No Nix files changed, skipping build"
    fi

- name: Build (conditional)
  if: steps.check_changes.outputs.rebuild_needed == 'true'
  run: nix build ...
```

### 2.3 Build Artifact Caching
**Prioridade**: Baixa | **Complexidade**: Média
```yaml
- name: Cache Nix store
  uses: actions/cache@v4
  with:
    path: |
      /nix/store
      ~/.cache/nix
    key: nix-${{ runner.os }}-${{ hashFiles('flake.lock') }}
    restore-keys: |
      nix-${{ runner.os }}-
```

---

## 📦 Categoria 3: Relatórios e Documentação

### 3.1 Dependency Diff Report
**Prioridade**: Alta | **Complexidade**: Média
```yaml
- name: Generate dependency diff
  if: github.event_name == 'pull_request'
  run: |
    echo "## 📦 Dependency Changes" >> $GITHUB_STEP_SUMMARY

    # Compare with main branch
    git fetch origin main
    nix-store -q --requisites ./result > /tmp/new-deps.txt
    nix-store -q --requisites $(nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel --no-link --print-out-paths --impure --expr '(builtins.getFlake "github:VoidNxSEC/nixos/'${{ github.base_ref }}'").nixosConfigurations.kernelcore.config.system.build.toplevel') > /tmp/old-deps.txt

    ADDED=$(comm -13 <(sort /tmp/old-deps.txt) <(sort /tmp/new-deps.txt) | wc -l)
    REMOVED=$(comm -23 <(sort /tmp/old-deps.txt) <(sort /tmp/new-deps.txt) | wc -l)

    echo "- ➕ Added: $ADDED packages" >> $GITHUB_STEP_SUMMARY
    echo "- ➖ Removed: $REMOVED packages" >> $GITHUB_STEP_SUMMARY
```

### 3.2 Changelog Auto-generation
**Prioridade**: Média | **Complexidade**: Baixa
```yaml
- name: Generate changelog
  run: |
    echo "## 📝 Changelog" >> $GITHUB_STEP_SUMMARY
    git log --oneline --no-merges ${{ github.event.before }}..${{ github.sha }} >> $GITHUB_STEP_SUMMARY
```

### 3.3 Build Badges
**Prioridade**: Baixa | **Complexidade**: Baixa
```yaml
# Criar badges dinâmicos
- name: Create status badges
  run: |
    # Generate badge JSON for shields.io
    echo '{"schemaVersion":1,"label":"build","message":"passing","color":"success"}' > /tmp/badge.json
    # Upload to GitHub Pages ou endpoint
```

---

## 🔔 Categoria 4: Notificações e Alertas

### 4.1 Discord/Slack Notifications
**Prioridade**: Média | **Complexidade**: Baixa
```yaml
- name: Notify on Discord
  if: failure()
  env:
    DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
  run: |
    curl -X POST "$DISCORD_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d '{
        "embeds": [{
          "title": "❌ NixOS Build Failed",
          "description": "Build failed on commit ${{ github.sha }}",
          "color": 15158332,
          "fields": [
            {"name": "Branch", "value": "${{ github.ref_name }}", "inline": true},
            {"name": "Author", "value": "${{ github.actor }}", "inline": true}
          ],
          "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
        }]
      }'
```

### 4.2 Email on Critical Failure
**Prioridade**: Baixa | **Complexidade**: Baixa
```yaml
- name: Send email alert
  if: failure() && github.ref == 'refs/heads/main'
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: "🚨 NixOS Build Failed on Main"
    body: "Build failed! Check: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
    to: sec@voidnxlabs.com
```

---

## 🔄 Categoria 5: Automação e GitOps

### 5.1 Auto-update Flake Inputs
**Prioridade**: Média | **Complexidade**: Média
```yaml
name: Update Flake Inputs

on:
  schedule:
    - cron: '0 2 * * 1'  # Segunda-feira às 2am
  workflow_dispatch:

jobs:
  update:
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4

      - name: Update flake.lock
        run: nix flake update

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore(deps): update flake inputs"
          title: "🔄 Weekly Flake Update"
          body: |
            Automated flake.lock update

            - nixpkgs
            - home-manager
            - other inputs
          branch: auto-update-flake
          labels: dependencies,automated
```

### 5.2 Auto-merge Dependabot PRs
**Prioridade**: Baixa | **Complexidade**: Baixa
```yaml
- name: Auto-approve dependabot
  if: github.actor == 'dependabot[bot]'
  run: gh pr review --approve "${{ github.event.pull_request.number }}"
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 5.3 Rollback Automation
**Prioridade**: Alta | **Complexidade**: Média
```yaml
name: Emergency Rollback

on:
  workflow_dispatch:
    inputs:
      generation:
        description: 'Generation number to rollback to'
        required: true

jobs:
  rollback:
    runs-on: [self-hosted, nixos]
    steps:
      - name: Rollback system
        run: |
          sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation ${{ inputs.generation }}
          sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

      - name: Verify rollback
        run: |
          systemctl --failed
          journalctl -p err -n 20
```

---

## 🧪 Categoria 6: Testing Avançado

### 6.1 NixOS VM Tests
**Prioridade**: Alta | **Complexidade**: Alta
```yaml
- name: Run NixOS tests
  run: |
    # Criar test interativo
    cat > /tmp/test.nix <<'EOF'
    import <nixpkgs/nixos/tests/make-test-python.nix> {
      name = "kernelcore-test";
      nodes.machine = { config, pkgs, ... }: {
        imports = [ ./hosts/kernelcore/configuration.nix ];
      };
      testScript = ''
        machine.wait_for_unit("multi-user.target")
        machine.succeed("systemctl status sshd")
        machine.succeed("docker --version")
      '';
    }
    EOF
    nix-build /tmp/test.nix
```

### 6.2 Security Compliance Tests
**Prioridade**: Alta | **Complexidade**: Média
```yaml
- name: CIS benchmark check
  run: |
    # Verificar hardening compliance
    echo "## 🔐 Security Compliance" >> $GITHUB_STEP_SUMMARY

    # Check kernel hardening
    if nix eval .#nixosConfigurations.kernelcore.config.boot.kernel.sysctl --json | grep -q "kernel.unprivileged_userns_clone.*0"; then
      echo "✅ User namespaces disabled" >> $GITHUB_STEP_SUMMARY
    fi

    # Check firewall
    if nix eval .#nixosConfigurations.kernelcore.config.networking.firewall.enable --raw | grep -q "true"; then
      echo "✅ Firewall enabled" >> $GITHUB_STEP_SUMMARY
    fi
```

### 6.3 Performance Regression Tests
**Prioridade**: Média | **Complexidade**: Alta
```yaml
- name: Benchmark boot time
  run: |
    # Build VM and measure boot time
    result=$(nix build .#packages.x86_64-linux.vm-image --no-link --print-out-paths)
    # Run VM with timeout and measure
    timeout 60s $result/bin/run-nixos-vm &
    # Track time to multi-user.target
```

---

## 📈 Categoria 7: Analytics e Insights

### 7.1 Cost Tracking
**Prioridade**: Baixa | **Complexidade**: Baixa
```yaml
- name: Calculate build cost
  run: |
    DURATION=${{ github.event.workflow_run.duration }}
    COST=$(echo "scale=2; $DURATION / 3600 * 0.008" | bc)  # $0.008/hour self-hosted
    echo "💰 Build cost: \$$COST" >> $GITHUB_STEP_SUMMARY
```

### 7.2 Trend Analysis
**Prioridade**: Média | **Complexidade**: Alta
```yaml
- name: Track metrics over time
  run: |
    # Salvar métricas em arquivo JSON
    cat > /tmp/metrics.json <<EOF
    {
      "timestamp": "$(date -Iseconds)",
      "commit": "${{ github.sha }}",
      "closure_size": $(nix path-info -S ./result | awk '{print $2}'),
      "build_time": ${BUILD_TIME},
      "vulnerabilities": ${VULNS}
    }
    EOF

    # Upload para S3/GitHub Pages para tracking histórico
```

---

## 🎯 Resumo de Prioridades

### 🔥 Implementar AGORA (High Priority, Low Complexity):
1. ✅ Build Performance Metrics
2. ✅ Security Score Tracking
3. ✅ Dependency Diff Report
4. ✅ Discord Notifications
5. ✅ Parallel Job Optimization

### 📅 Implementar EM BREVE (High Priority, Medium Complexity):
1. ⏰ NixOS VM Tests
2. ⏰ Security Compliance Tests
3. ⏰ Rollback Automation
4. ⏰ Auto-update Flake Inputs

### 💡 Implementar DEPOIS (Low Priority or High Complexity):
1. 💭 Build Badges
2. 💭 Cost Tracking
3. 💭 Trend Analysis
4. 💭 Email Alerts

---

## 🚀 Quick Wins (Posso implementar agora!)

Quer que eu implemente algum desses enhancements agora? Recomendo começar com:

1. **Build Metrics** - Vai dar visibilidade de performance
2. **Security Score** - Quantifica a segurança do sistema
3. **Discord Notifications** - Alertas em tempo real
4. **Dependency Diff** - Ótimo para PRs

É só me falar qual(is) você quer que eu implemente!
