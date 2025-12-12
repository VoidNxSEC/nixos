# NixOS Architecture Analysis Report

> **Professional Edition v2.0.0**
> **Generated**: 2025-12-11 18:49:55 -02
> **Location**: `/etc/nixos`

---

## 📋 Table of Contents

- [Executive Summary](#executive-summary)
- [Module Breakdown](#module-breakdown)
- [Security Analysis](#security-analysis)
- [Health Score](#health-score)
- [Recommendations](#recommendations)
- [Statistics](#statistics)
- [Architecture Tree](#architecture-tree)

---

## 🎯 Executive Summary

### Repository Information

| Metric | Value |
|--------|-------|
| **Total Files** | 881 |
| **Total Directories** | 350 |
| **Repository Size** | 2.7G |
| **Git Branch** | `main` |
| **Git Commit** | `28c3297` |
| **Total Commits** | 210 |
| **Contributors** | 3 |
| **Repository Age** | 0 days |

### NixOS Configuration

| Metric | Value |
|--------|-------|
| **.nix files** | 247 (47144 lines) |
| **Total modules** | 171 |
| **Module categories** | 12 |
| **Modules size** | 1.2G |

### Health Metrics

| Metric | Score | Status |
|--------|-------|--------|
| **Overall Health** | 65/100 | ⚠️ Needs Work |
| **Security** | 100/100 | ✅ Strong |
| **Documentation** | 51/100 | ⚠️ Needs Work |

---

## 📦 Module Breakdown

| Category | Modules | Lines | Description |
|----------|---------|-------|-------------|
| **shell** | 35 | 5243 | Shell configuration and aliases |
| **packages** | 27 | 3034 | Custom packages and overlays |
| **ml** | 26 | 2573 | Machine learning infrastructure |
| **security** | 17 | 2257 | Security hardening and policies |
| **services** | 15 | 2798 | System services and daemons |
| **hardware** | 12 | 2785 | Hardware configurations (GPU, CPU, peripherals) |
| **network** | 11 | 2811 | Network configuration and services |
| **system** | 8 | 1108 | Core system configuration |
| **applications** | 8 | 1854 | User applications and tools |
| **virtualization** | 4 | 1971 | VMs, QEMU, libvirt |
| **development** | 4 | 963 | Development environments and tools |
| **containers** | 4 | 361 | Docker, Podman, NixOS containers |

---

## 🔒 Security Analysis

### Configuration

- **Security modules**: 17
- **SOPS secrets**: 11
- **Hardening config**: ✅ Enabled

### Security Score: 100/100

**Status**: ✅ Excellent security posture

---

## 📊 Health Score

### Overall: 65/100

| Component | Score |
|-----------|-------|
| Documentation | 51/100 |
| Security | 100/100 |
| Structure | 100/100 |

**Status**: ⚠️ Good - Minor improvements recommended

---

## 💡 Recommendations

### 📚 Documentation

- **Current**: 51%
- **Target**: 80%+
- **Action**: Add `description` fields to module options
- **Benefit**: Better maintainability and onboarding


---

## 📈 Statistics

### Files by Type

| Type | Count | Lines |
|------|-------|-------|
| .nix | 247 | 47144 |
| .sh | 75 | 14164 |
| .md | 284 | 104034 |
| .yaml | 16 | - |

### Directory Sizes

| Directory | Size |
|-----------|------|
| modules/ | 1.2G |
| docs/ | 2.0M |
| scripts/ | 796.0K |
| **Total** | **2.7G** |

---

## 🌳 Architecture Tree

```
/etc/nixos/
├── arch/
│   ├── snapshots/
│   │   ├── snapshot-20251210-054056.txt
│   │   ├── snapshot-20251210-054112.txt
│   │   └── snapshot-20251210-054218.txt
│   ├── ARCHITECTURE-REPORT.json
│   ├── ARCHITECTURE-REPORT.md
│   ├── ARCHITECTURE-REPORT.txt
│   ├── ARCHITECTURE-TREE.md
│   ├── ARCHITECTURE-TREE.txt
│   └── README.md
├── dev/
│   ├── flakes/
│   └── default.nix
├── docs/
│   ├── applications/
│   │   └── ZELLIJ-GUIDE.md
│   ├── architecture/
│   │   ├── COMPONENT-MAP.md
│   │   ├── MODULES-INDEX.md
│   │   ├── QUICK-REFERENCE.md
│   │   ├── README.md
│   │   ├── snapshot-20251122-233317.txt
│   │   ├── snapshot-20251210-053819.txt
│   │   ├── snapshot-20251210-053829.txt
│   │   └── VISUAL-ARCHITECTURE.md
│   ├── guides/
│   │   ├── AWS-BEDROCK-SETUP.md
│   │   ├── DEB-PACKAGES-GUIDE.md
│   │   ├── KERNELCORE-TAILSCALE-CONFIG.nix
│   │   ├── MULTI-HOST-SETUP.md
│   │   ├── SECRETS.md
│   │   ├── SETUP-SOPS-FINAL.md
│   │   ├── SSH-CONFIGURATION.md
│   │   ├── TAILSCALE-IMPLEMENTATION-SUMMARY.md
│   │   ├── TAILSCALE-LAPTOP-CLIENT.nix
│   │   ├── TAILSCALE-MESH-NETWORK.md
│   │   └── TAILSCALE-QUICK-START.nix
│   ├── prompts/
│   ├── reports/
│   │   ├── CI_CD_README.md*
│   │   ├── ml-offload-phase1-test-report.md
│   │   ├── SECURITY_AUDIT_REPORT.md*
│   │   ├── SERVICES_MIGRATION_PLAN.md*
│   │   ├── SERVICES_VISUAL_MAP.txt*
│   │   └── SYSTEMD_SERVICES_SUMMARY.txt*
│   ├── system/
│   │   ├── REBUILD-GUIDE.md
│   │   └── REBUILD-PROFESSIONAL.md
│   ├── 2025-11-26-claude-preciso-acessar-o-server-desktop-o-guiux.txt
│   ├── AGENT-EMPOWERMENT-TOOLKIT.md
│   ├── AGENT-TOOLKIT-QUICKSTART.md
│   ├── ALTERNATIVA-REINSTALACAO-LIMPA.md
│   ├── ANALISE-SSH-CONFIG-PROBLEMAS.md
│   ├── ARCHITECTURE-BLUEPRINT.md
│   ├── ARCHITECTURE-TRACKING.md
│   ├── ARCHITECTURE-TREE.md
│   ├── ARCHITECTURE-TREE.txt
│   ├── AUDITD_INVESTIGATION.md*
│   ├── auditoria-disco-20251122-054711.txt
│   ├── AUDITORIA-DISCO-FERRAMENTAS.md
│   ├── BINARY-CACHE-SETUP.md
│   ├── BUILD-OPTIMIZATION-2025-11-22.md
│   ├── CENTRALIZACAO-LOGS-DESKTOP.md
│   ├── CI-CD-ARCHITECTURE.md
│   ├── CONFIGURATION_ENHANCEMENTS.md*
│   ├── DECISOES-CRITICAS.md
│   ├── DESKTOP-OFFLOAD-QUICKSTART.md
│   ├── DESKTOP-OFFLOAD-SETUP.md
│   ├── DESKTOP-QUICK-SETUP.md
│   ├── DESKTOP-SETUP-REQUIRED.md
│   ├── DESKTOP-TROUBLESHOOTING.md
│   ├── DEV-DIRECTORY-SECURITY.md
│   ├── DNS_FIX_SUMMARY.md*
│   ├── DNS_WORKING_CONFIG.md*
│   ├── ECONOMIA-ESPACO.md
│   ├── EMERGENCIA-LIBERAR-ESPACO.md
│   ├── ESTRATEGIA-FINAL-COMPLETA.md
│   ├── EXEC-SUMMARY-LYNIS.md
│   ├── EXECUTAR-AGORA.md
│   ├── EXEMPLO-INTEGRACAO-HOST.md
│   ├── FINAL-STATUS-REPORT.md
│   ├── GITHUB-ACTIONS-RUNNER-CONFIG-EXAMPLES.md
│   ├── GITHUB-ACTIONS-RUNNER-FIX.md
│   ├── GITHUB_ACTIONS_SETUP.md*
│   ├── GITHUB_CLI_AUTH.md
│   ├── GITHUB-SOPS-INTEGRATION.md
│   ├── GIT-WORKFLOW-TESTING-IMPROVEMENT-PLAN.md
│   ├── GUIA-BACKUP-E-REINSTALACAO.md
│   ├── GUIA-CORRECAO-DNS.md*
│   ├── HANDOFF-TAILSCALE-E-INFRAESTRUTURA.md
│   ├── IMPLEMENTATION-SUMMARY.md
│   ├── INFRASTRUCTURE-FIX-SUMMARY.md
│   ├── INSTRUCTIONS.md
│   ├── LAPTOP-BUILD-SETUP.md
│   ├── LAPTOP-DEFENSE-FRAMEWORK.md
│   ├── LAPTOP-QUICK-SETUP.md
│   ├── LLM-WORKFLOW-DEBUG-FRICTION-REPORT.md
│   ├── LOGSTREAM-INTELLIGENCE-DESIGN.md
│   ├── LYNIS-ENHANCEMENTS.md
│   ├── MCP-ARCHITECTURE-ACCESS.md
│   ├── MCP-CLAUDE-CODE-SETUP.md
│   ├── MCP-CODEX-INTEGRATION.md
│   ├── MCP-EXTENDED-TOOLS-DESIGN.md
│   ├── MCP-EXTENDED-TOOLS-FINAL-REPORT.md
│   ├── MCP-EXTENDED-TOOLS-PROGRESS.md
│   ├── MCP-INTEGRATION-GUIDE.md
│   ├── MCP-KNOWLEDGE-DB-FIX.md
│   ├── MCP-KNOWLEDGE-EXTENSION-PLAN.md
│   ├── MCP-KNOWLEDGE-STABILIZATION.md
│   ├── MCP-PROJECT-ROOT-ANALYSIS.md
│   ├── MCP-QUICK-REFERENCE.md
│   ├── MCP-SECURE-ARCHITECTURE.md
│   ├── MCP-SERVER-HEALTH-REPORT.md
│   ├── MCP-SERVER-PACKAGE.md
│   ├── MCP-SESSION-HANDOFF.md
│   ├── MCP-SYNC-SUMMARY.md
│   ├── MCP-TOOLS-USAGE-GUIDE.md
│   ├── MCP-TROUBLESHOOTING.md
│   ├── ML-ARCHITECTURE-REFACTORING.md
│   ├── ML-MODULES-RESTRUCTURE-PLAN.md
│   ├── ml-offload-phase2-design.md
│   ├── ml-offload-testing-plan.md
│   ├── neovim-integration-analysis.md
│   ├── NEXT-SESSION-PROMPT.md
│   ├── NIX-EMERGENCY-PROCEDURES.md
│   ├── OS-KEYRING-SETUP.md
│   ├── PACKAGE-UPDATE-GUIDE.md
│   ├── PHASE2-IMPLEMENTATION-ROADMAP.md
│   ├── PHASE2-UNIFIED-ARCHITECTURE.md
│   ├── PLANO-ACAO-LIMPEZA.md
│   ├── PLANO-INTEROPERABILIDADE-LAPTOP-DESKTOP.md
│   ├── PROTONPASS-STATUS.md
│   ├── QUICK-START-IMPROVEMENTS.md
│   ├── README.md
│   ├── README-STACK-SETUP.md
│   ├── README_SYSTEMD_INVENTORY.txt*
│   ├── REBUILD-FIX.md
│   ├── REFATORACAO-ARQUITETURA-2025.md
│   ├── relatorio.md
│   ├── REMOTE-BUILDER-CACHE-GUIDE.md
│   ├── REPOSITORY-ANALYSIS.md
│   ├── RESTRUCTURING-MISSION.md
│   ├── RSYNC-GUIDE.md
│   ├── sample.md
│   ├── SECURITY-HARDENING-STATUS.md
│   ├── SESSION-1-SUMMARY.md
│   ├── SIEM-INTEGRATION.md
│   ├── SOPS-TROUBLESHOOTING.md*
│   ├── STACK-SERVER-CLIENT-COMPLETE-GUIDE.md
│   ├── SUMMARY.md*
│   ├── SYSTEMD_CENTRALIZATION_INDEX.md*
│   ├── SYSTEMD_SERVICES_INVENTORY.md*
│   ├── TAILSCALE-CHEATSHEET.md
│   ├── TAILSCALE-COMPLETE-SETUP.md
│   ├── TAILSCALE-DEPLOYMENT-STATUS.md
│   ├── TAILSCALE-QUICKSTART-GUIDE.md
│   ├── TAILSCALE-SUBNET-ROUTING-GUIDE.md
│   ├── test.md
│   ├── TODO.md*
│   ├── VM-CLIPBOARD-SETUP.md
│   ├── VMCTL-USAGE.md
│   └── WEB-SEARCH-TOOLS.md
├── hooks/
│   └── nfs-tests.sh*
├── hosts/
│   ├── kernelcore/
│   │   ├── acpi-fix/
│   │   │   ├── dsdt.aml
│   │   │   ├── dsdt.dat
│   │   │   └── dsdt.dsl
│   │   ├── home/
│   │   │   ├── aliases/
│   │   │   │   ├── ai-compose-stack.sh*
│   │   │   │   ├── ai-ml-stack.sh*
│   │   │   │   ├── aliases.sh
│   │   │   │   ├── gcloud.sh*
│   │   │   │   ├── gpu-docker-core.sh*
│   │   │   │   ├── gpu-management.sh
│   │   │   │   ├── gpu.sh*
│   │   │   │   ├── litellm_runtime_manager.sh*
│   │   │   │   ├── multimodal.sh*
│   │   │   │   ├── nixos-aliases.nix
│   │   │   │   └── nx.sh*
│   │   │   ├── glassmorphism/
│   │   │   │   ├── agent-hub.nix
│   │   │   │   ├── colors.nix
│   │   │   │   ├── default.nix
│   │   │   │   ├── hyprlock.nix
│   │   │   │   ├── kitty.nix
│   │   │   │   ├── mako.nix
│   │   │   │   ├── README.md
│   │   │   │   ├── swappy.nix
│   │   │   │   ├── wallpaper.nix
│   │   │   │   ├── waybar.nix
│   │   │   │   ├── wlogout.nix
│   │   │   │   ├── wofi.nix
│   │   │   │   └── zellij.nix
│   │   │   ├── shell/
│   │   │   │   ├── bash.nix
│   │   │   │   ├── default.nix
│   │   │   │   ├── options.nix
│   │   │   │   ├── p10k.zsh
│   │   │   │   ├── README.md
│   │   │   │   └── zsh.nix
│   │   │   ├── alacritty.nix
│   │   │   ├── flameshot.nix
│   │   │   ├── git.nix
│   │   │   ├── home.nix*
│   │   │   ├── hyprland.nix
│   │   │   ├── theme.nix
│   │   │   ├── tmux.nix
│   │   │   └── yazi.nix
│   │   ├── configuration.nix*
│   │   ├── configurations-template.nix*
│   │   ├── default.nix*
│   │   └── hardware-configuration.nix*
│   └── workstation/
│       └── configuration.nix
├── knowledge/
│   └── sudo-claude-code.nix.backup
├── lib/
│   ├── packages.nix*
│   ├── shell.nix*
│   └── shells.nix*
├── modules/
│   ├── applications/
│   │   ├── brave-secure.nix*
│   │   ├── chromium.nix
│   │   ├── default.nix
│   │   ├── firefox-privacy.nix*
│   │   ├── nemo-full.nix
│   │   ├── vscode-secure.nix*
│   │   ├── vscodium-secure.nix*
│   │   └── zellij.nix
│   ├── audio/
│   │   ├── production.nix
│   │   └── README.md
│   ├── containers/
│   │   ├── default.nix
│   │   ├── docker.nix*
│   │   ├── nixos-containers.nix*
│   │   └── podman.nix
│   ├── debug/
│   │   ├── debug-init.nix*
│   │   └── test-init.nix*
│   ├── desktop/
│   │   ├── yazi/
│   │   │   └── yazi.nix
│   │   ├── default.nix
│   │   ├── hyprland.nix
│   │   └── i3-lightweight.nix
│   ├── development/
│   │   ├── cicd.nix*
│   │   ├── claude-profiles.nix
│   │   ├── environments.nix*
│   │   └── jupyter.nix*
│   ├── hardware/
│   │   ├── i915-governor/
│   │   │   └── default.nix
│   │   ├── laptop-defense/
│   │   │   ├── flake.nix
│   │   │   ├── mcp-integration.nix
│   │   │   └── rebuild-hooks.nix
│   │   ├── bluetooth.nix
│   │   ├── default.nix
│   │   ├── intel.nix*
│   │   ├── lenovo-throttled.nix
│   │   ├── nvidia.nix*
│   │   ├── thermal-profiles.nix
│   │   ├── trezor.nix*
│   │   └── wifi-optimization.nix
│   ├── ml/
│   │   ├── applications/
│   │   │   ├── securellm-bridge/
│   │   │   │   ├── cli/
│   │   │   │   ├── config/
│   │   │   │   ├── crates/
│   │   │   │   ├── docker/
│   │   │   │   ├── docs/
│   │   │   │   ├── examples/
│   │   │   │   ├── mnt/
│   │   │   │   ├── nix/
│   │   │   │   ├── src/
│   │   │   │   ├── Cargo.lock
│   │   │   │   ├── Cargo.toml
│   │   │   │   ├── CLAUDE.md
│   │   │   │   ├── default.nix
│   │   │   │   ├── flake.nix
│   │   │   │   ├── LICENSE-APACHE
│   │   │   │   ├── LICENSE-MIT
│   │   │   │   ├── Makefile
│   │   │   │   └── README.md
│   │   │   ├── default.nix
│   │   │   └── README.md
│   │   ├── infrastructure/
│   │   │   ├── hardware/
│   │   │   │   └── default.nix
│   │   │   ├── vram/
│   │   │   │   ├── default.nix
│   │   │   │   └── monitoring.nix
│   │   │   ├── default.nix
│   │   │   ├── README.md
│   │   │   └── storage.nix*
│   │   ├── integrations/
│   │   │   ├── mcp/
│   │   │   │   ├── server/
│   │   │   │   ├── config.nix
│   │   │   │   └── default.nix
│   │   │   ├── neovim/
│   │   │   │   ├── default.nix
│   │   │   │   └── README.md
│   │   │   ├── default.nix
│   │   │   └── README.md
│   │   ├── orchestration/
│   │   │   ├── api/
│   │   │   │   ├── src/
│   │   │   │   ├── Cargo.lock
│   │   │   │   ├── Cargo.toml
│   │   │   │   └── dev-ui.html
│   │   │   ├── backends/
│   │   │   │   └── default.nix
│   │   │   ├── registry/
│   │   │   │   ├── database.nix
│   │   │   │   └── default.nix
│   │   │   ├── default.nix
│   │   │   ├── flake.nix
│   │   │   ├── manager.nix
│   │   │   └── README.md
│   │   ├── services/
│   │   │   ├── ollama/
│   │   │   │   ├── default.nix
│   │   │   │   └── gpu-manager.nix*
│   │   │   ├── default.nix
│   │   │   ├── llama-cpp.nix*
│   │   │   ├── llama-cpp-swap.nix
│   │   │   └── README.md
│   │   ├── default.nix
│   │   └── README.md
│   ├── network/
│   │   ├── dns/
│   │   │   ├── config.example.json
│   │   │   ├── default.nix
│   │   │   ├── go.mod
│   │   │   ├── go.sum
│   │   │   └── README.md
│   │   ├── monitoring/
│   │   │   └── tailscale-monitor.nix
│   │   ├── proxy/
│   │   │   ├── nginx-tailscale.nix
│   │   │   └── tailscale-services.nix
│   │   ├── security/
│   │   │   └── firewall-zones.nix
│   │   ├── vpn/
│   │   │   ├── nordvpn.nix*
│   │   │   ├── tailscale-desktop.nix
│   │   │   ├── tailscale-laptop.nix
│   │   │   └── tailscale.nix
│   │   ├── bridge.nix
│   │   └── dns-resolver.nix*
│   ├── packages/
│   │   ├── deb-packages/
│   │   │   ├── packages/
│   │   │   │   ├── all.nix
│   │   │   │   ├── cursor.nix
│   │   │   │   ├── example.nix
│   │   │   │   ├── protonpass.nix
│   │   │   │   ├── protonvpn.nix
│   │   │   │   └── README.md
│   │   │   ├── storage/
│   │   │   │   ├── cursor_2.0.34_amd64.deb
│   │   │   │   ├── ProtonPass.deb
│   │   │   │   ├── README.md
│   │   │   │   └── warp-terminal_0.2025.11.19.08.12.stable.03_amd64.deb
│   │   │   ├── audit.nix
│   │   │   ├── builder.nix
│   │   │   ├── default.nix
│   │   │   ├── README.md
│   │   │   └── sandbox.nix
│   │   ├── js-packages/
│   │   │   ├── storage/
│   │   │   │   ├── gemini-cli-0.19.0-nightly.20251124.e177314a4/
│   │   │   │   └── README.md
│   │   │   ├── builder.nix
│   │   │   ├── build-gemini.nix
│   │   │   ├── default.nix
│   │   │   ├── gemini-cli.nix
│   │   │   └── js-packages.nix
│   │   ├── lib/
│   │   │   ├── builders.nix
│   │   │   └── sandbox.nix
│   │   ├── _sources/
│   │   │   ├── generated.json
│   │   │   └── generated.nix
│   │   ├── tar-packages/
│   │   │   ├── packages/
│   │   │   │   ├── antigravity.nix
│   │   │   │   ├── appflowy.nix
│   │   │   │   ├── codex.nix
│   │   │   │   ├── lynis.nix
│   │   │   │   ├── protonpass.nix
│   │   │   │   └── zellij.nix
│   │   │   ├── storage/
│   │   │   │   └── codex-x86_64-unknown-linux-musl*
│   │   │   ├── builder.nix
│   │   │   ├── default.nix
│   │   │   └── README.md
│   │   ├── appflowy.nix
│   │   ├── default.nix
│   │   ├── DOCUMENTATION.md
│   │   ├── nvfetcher.toml
│   │   ├── PACKAGES-STATUS.md
│   │   ├── README.md
│   │   └── SETUP.md
│   ├── programs/
│   │   ├── cognitive-vault.nix
│   │   └── default.nix
│   ├── secrets/
│   │   ├── api-keys.nix
│   │   ├── aws-bedrock.nix
│   │   ├── sops-config.nix*
│   │   └── tailscale.nix
│   ├── security/
│   │   ├── aide.nix*
│   │   ├── audit.nix*
│   │   ├── auto-upgrade.nix*
│   │   ├── boot.nix*
│   │   ├── clamav.nix*
│   │   ├── compiler-hardening.nix*
│   │   ├── default.nix
│   │   ├── dev-directory-hardening.nix
│   │   ├── hardening.nix*
│   │   ├── hardening-template.nix*
│   │   ├── kernel.nix*
│   │   ├── keyring.nix
│   │   ├── network.nix*
│   │   ├── nix-daemon.nix*
│   │   ├── packages.nix*
│   │   ├── pam.nix*
│   │   └── ssh.nix*
│   ├── services/
│   │   ├── users/
│   │   │   ├── actions.nix*
│   │   │   ├── claude-code.nix*
│   │   │   ├── codex-agent.nix
│   │   │   ├── default.nix*
│   │   │   ├── gemini-agent.nix
│   │   │   └── gitlab-runner.nix
│   │   ├── default.nix*
│   │   ├── gpu-orchestration.nix
│   │   ├── laptop-builder-client.nix
│   │   ├── laptop-offload-client.nix
│   │   ├── mcp-server.nix
│   │   ├── mobile-workspace.nix
│   │   ├── mosh.nix
│   │   ├── offload-server.nix
│   │   └── scripts.nix*
│   ├── shell/
│   │   ├── aliases/
│   │   │   ├── ai/
│   │   │   │   ├── default.nix
│   │   │   │   └── ollama.nix
│   │   │   ├── amazon/
│   │   │   │   ├── aws.nix
│   │   │   │   └── default.nix
│   │   │   ├── desktop/
│   │   │   │   ├── default.nix
│   │   │   │   └── hyprland.nix
│   │   │   ├── docker/
│   │   │   │   ├── build.nix
│   │   │   │   ├── compose.nix
│   │   │   │   ├── default.nix
│   │   │   │   └── run.nix
│   │   │   ├── gcloud/
│   │   │   │   ├── default.nix
│   │   │   │   └── gcloud.nix
│   │   │   ├── kubernetes/
│   │   │   │   ├── default.nix
│   │   │   │   └── kubectl.nix
│   │   │   ├── nix/
│   │   │   │   ├── analytics.nix
│   │   │   │   ├── default.nix
│   │   │   │   ├── rebuild-advanced.nix
│   │   │   │   ├── rebuild-helpers.nix
│   │   │   │   └── system.nix
│   │   │   ├── security/
│   │   │   │   ├── default.nix
│   │   │   │   └── secrets.nix
│   │   │   ├── system/
│   │   │   │   ├── default.nix
│   │   │   │   ├── navigation.nix
│   │   │   │   └── utils.nix
│   │   │   ├── ALIAS-TRACKING-GUIDE.md
│   │   │   ├── default.nix
│   │   │   ├── emergency.nix
│   │   │   ├── laptop-defense.nix
│   │   │   ├── macos-kvm.nix
│   │   │   ├── mcp.nix
│   │   │   ├── NAVIGATION-GUIDE.md
│   │   │   ├── nixos-explorer.nix
│   │   │   ├── README.md
│   │   │   ├── service-control.nix
│   │   │   └── sync.nix
│   │   ├── scripts/
│   │   │   ├── bash/
│   │   │   └── python/
│   │   ├── templates/
│   │   ├── default.nix*
│   │   ├── gpu-flags.nix*
│   │   ├── INTEGRATION.md*
│   │   └── training-logger.nix
│   ├── system/
│   │   ├── bash/
│   │   │   └── void.sh
│   │   ├── aliases.nix*
│   │   ├── binary-cache.nix
│   │   ├── emergency-monitor.nix
│   │   ├── memory.nix*
│   │   ├── ml-gpu-users.nix
│   │   ├── nix.nix*
│   │   ├── services.nix*
│   │   └── ssh-config.nix
│   └── virtualization/
│       ├── default.nix
│       ├── macos-kvm.nix
│       ├── vmctl.nix
│       └── vms.nix*
├── overlays/
│   ├── default.nix
│   ├── hyprland.nix
│   ├── python-packages.nix
│   └── README.md
├── projects/
│   ├── cognitive-vault/
│   │   ├── cli/
│   │   │   ├── cmd/
│   │   │   ├── internal/
│   │   │   │   └── crypto/
│   │   │   ├── default.nix
│   │   │   ├── go.mod
│   │   │   └── go.sum
│   │   ├── core/
│   │   │   ├── include/
│   │   │   │   └── vault_core.h
│   │   │   ├── src/
│   │   │   ├── Cargo.lock
│   │   │   ├── Cargo.toml
│   │   │   └── default.nix
│   │   ├── default.nix
│   │   ├── flake.lock
│   │   └── flake.nix
│   └── i915-governor/
│       ├── nix/
│       │   └── package.nix
│       ├── src/
│       │   └── main.zig
│       ├── build.zig
│       └── default.nix
├── scripts/
│   ├── nixos-shell/
│   │   ├── scripts/
│   │   └── README.md
│   ├── nixos-ssh/
│   │   └── README.md
│   ├── SecOps/
│   │   └── bedrock-investigation-brief.md
│   ├── add-secret.sh*
│   ├── add-to-sops.sh*
│   ├── alacritty-enhancements-summary.md
│   ├── alias-inspector.sh*
│   ├── auditoria-disco.sh*
│   ├── auto-commit.sh*
│   ├── backup-rapido.sh*
│   ├── clean-sudo.nix
│   ├── deb-add*
│   ├── desktop-cfg2.nix
│   ├── desktop-cfg.nix
│   ├── desktop-config-backup.nix
│   ├── desktop-config-clean.nix
│   ├── detecta-anomalias.sh*
│   ├── diagnose-home-manager.sh*
│   ├── diagnostico-detalhado.sh*
│   ├── diagnostico-disco.sh*
│   ├── dns-diagnostics.sh*
│   ├── fix-mcp-configs.sh*
│   ├── fix-secrets-permissions.sh*
│   ├── fix-sudo2.nix
│   ├── fix-sudo3.nix
│   ├── fix-sudo.nix
│   ├── generate-architecture-tree.sh*
│   ├── generate-mcp-config.sh*
│   ├── generate-tree-diagram.sh*
│   ├── interage-llm.sh*
│   ├── investigate-infra.sh*
│   ├── kill-children.sh*
│   ├── limpa-processos.sh*
│   ├── limpeza-agressiva.sh*
│   ├── load-api-keys.sh*
│   ├── load-aws-bedrock.sh*
│   ├── mcp-health-check.sh*
│   ├── mcp-helper.sh*
│   ├── migrate-sec-to-sops.sh*
│   ├── monitora-logs-seguranca.sh*
│   ├── monitora-processos-detalhado.sh*
│   ├── monitora-rede.sh*
│   ├── monitor-nix-store.sh*
│   ├── monitor-rebuild.sh*
│   ├── MONITOR-REBUILD-USAGE.md
│   ├── nix-emergency.sh*
│   ├── nix-hard-reset.sh*
│   ├── nixos-perfect-install.sh
│   ├── post-rebuild-validate.sh*
│   ├── pre_processa_dados_llm.sh*
│   ├── SecOps (copy)
│   ├── setup-claude-secrets.sh*
│   ├── setup-desktop-offload.sh*
│   ├── setup-git-hooks.sh*
│   ├── setup-offload-keys.sh*
│   ├── setup-packages*
│   ├── simple-update.sh*
│   ├── sops-editor.sh*
│   ├── sync-from-desktop.sh*
│   ├── sync-github-secrets.sh*
│   ├── sync-to-desktop.sh*
│   ├── tailscale-catchall.sh*
│   ├── tailscale-quick-setup.sh*
│   ├── tailscale-subnet-setup.sh*
│   ├── tauri-stop-dev-processes.sh*
│   ├── test-alacritty.sh*
│   ├── test-coverage.sh*
│   ├── test-remote-build.nix
│   ├── update-api-secrets.sh*
│   ├── update-npm-package.sh
│   ├── update-packages.sh*
│   ├── update-rust-package.sh
│   ├── update-secrets.sh*
│   ├── vscode-remote-test-summary.md
│   ├── vscode-ssh-diagnostic.sh*
│   ├── vscodium-wrapper.sh*
│   └── wifi-diagnostics.sh*
├── sec/
│   ├── hardening.nix*
│   └── user-password*
├── secrets/
│   ├── ssh-keys/
│   │   ├── dev.yaml*
│   │   ├── production.yaml*
│   │   └── staging.yaml*
│   ├── api.yaml
│   ├── api.yaml.pre-update
│   ├── aws.yaml*
│   ├── database.yaml*
│   ├── github.yaml
│   ├── github.yaml.backup*
│   ├── prod.yaml*
│   ├── secrets.yaml
│   ├── ssh.yaml*
│   └── tailscale.yaml
├── tests/
│   ├── integration/
│   │   ├── docker-services.nix
│   │   ├── networking.nix
│   │   └── security-hardening.nix
│   ├── lib/
│   │   └── test-helpers.nix
│   ├── modules/
│   ├── vm/
│   ├── default.nix
│   ├── README.md
│   └── tailscale-integration-test.nix
├── CLAUDE.md
├── example.yaml
├── flake.lock*
├── flake.nix*
├── knowledge.db
└── run-lynis-audits.sh*

127 directories, 550 files
```

---

## 📝 Metadata

- **Report Version**: 2.0.0
- **Generated**: 2025-12-11 18:49:55 -02
- **Tool**: NixOS Architecture Analysis Tool
- **Repository**: /etc/nixos

To regenerate this report:

```bash
bash scripts/generate-architecture-tree.sh
```

---

*Generated with ❤️ by NixOS Architecture Analysis Tool*
