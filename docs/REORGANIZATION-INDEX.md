# 📋 Documentation Reorganization Index

**Total files to relocate**: 127 .md files in `/etc/nixos/docs/`

Use this as your checklist. Commands are `git mv` to preserve history.

---

## ✅ Priority 1: Setup Guides → `guides/setup/`

```bash
git mv DESKTOP-QUICK-SETUP.md guides/setup/desktop-setup.md
git mv LAPTOP-QUICK-SETUP.md guides/setup/laptop-setup.md
git mv TAILSCALE-QUICKSTART-GUIDE.md guides/setup/tailscale-setup.md
git mv TAILSCALE-COMPLETE-SETUP.md guides/setup/tailscale-complete.md
git mv DESKTOP-OFFLOAD-QUICKSTART.md guides/setup/desktop-offload.md
git mv LAPTOP-BUILD-SETUP.md guides/setup/laptop-build.md
git mv BINARY-CACHE-SETUP.md guides/setup/binary-cache.md
git mv GITHUB_ACTIONS_SETUP.md guides/setup/github-actions.md
git mv GITHUB_CLI_AUTH.md guides/setup/github-cli-auth.md
git mv OS-KEYRING-SETUP.md guides/setup/os-keyring.md
git mv VM-CLIPBOARD-SETUP.md guides/setup/vm-clipboard.md
git mv mobile-workspace-setup-complete.md guides/setup/mobile-workspace.md
git mv ssh-mosh-setup-complete.md guides/setup/ssh-mosh.md
```

---

## 🏗️ Priority 2: Architecture → `architecture/`

```bash
git mv ARCHITECTURE-BLUEPRINT.md architecture/system-overview.md
git mv ARCHITECTURE-TREE.md architecture/module-tree.md
git mv ARCHITECTURE-TRACKING.md architecture/evolution-tracking.md
git mv ENTERPRISE-SHOWCASE-ARCHITECTURE.md architecture/showcase-design.md
git mv ML-ARCHITECTURE-REFACTORING.md architecture/ml-infrastructure.md
git mv MCP-SECURE-ARCHITECTURE.md architecture/mcp-design.md
git mv INFRASTRUCTURE-REORGANIZATION-PLAN.md architecture/infra-reorganization.md
git mv CI-CD-ARCHITECTURE.md architecture/cicd-design.md
git mv GLASSMORPHISM-DESIGN-SYSTEM.md architecture/ui-design-system.md
git mv LOGSTREAM-INTELLIGENCE-DESIGN.md architecture/logstream-design.md
```

---

## 📖 Priority 3: Troubleshooting → `guides/troubleshooting/`

```bash
git mv DESKTOP-TROUBLESHOOTING.md guides/troubleshooting/desktop-issues.md
git mv AUDIO_TROUBLESHOOTING.md guides/troubleshooting/audio-issues.md
git mv DNS_FIX_SUMMARY.md guides/troubleshooting/dns-fixes.md
git mv GUIA-CORRECAO-DNS.md guides/troubleshooting/dns-guide-pt.md
git mv SOPS-TROUBLESHOOTING.md guides/troubleshooting/sops-issues.md
git mv MCP-TROUBLESHOOTING.md guides/troubleshooting/mcp-issues.md
git mv GITHUB-ACTIONS-RUNNER-FIX.md guides/troubleshooting/github-runner.md
git mv REBUILD-FIX.md guides/troubleshooting/rebuild-failures.md
git mv alacritty-regex-error-report.md guides/troubleshooting/alacritty-regex.md
git mv ANALISE-SSH-CONFIG-PROBLEMAS.md guides/troubleshooting/ssh-config-pt.md
```

---

## 🔄 Priority 4: Workflows → `guides/workflows/`

```bash
git mv GIT-WORKFLOW-TESTING-IMPROVEMENT-PLAN.md guides/workflows/git-workflow.md
git mv MONITOR-REBUILD-USAGE.md guides/workflows/rebuild-monitoring.md
git mv RSYNC-GUIDE.md guides/workflows/rsync-sync.md
git mv PACKAGE-UPDATE-GUIDE.md guides/workflows/package-updates.md
```

---

## 📊 Priority 5: Reports → `reports/`

```bash
git mv EXECUTIVE-SUMMARY-SHOWCASE.md reports/showcase-summary.md
git mv FINAL-STATUS-REPORT.md reports/final-status.md
git mv SECURITY-HARDENING-STATUS.md reports/security-status.md
git mv EXEC-SUMMARY-LYNIS.md reports/lynis-summary.md
git mv IMPLEMENTATION-SUMMARY.md reports/implementation-summary.md
git mv INFRASTRUCTURE-FIX-SUMMARY.md reports/infrastructure-fixes.md
git mv SESSION-1-SUMMARY.md reports/session-summaries/2025-session-1.md
git mv MCP-SERVER-HEALTH-REPORT.md reports/mcp-health.md
git mv LLM-WORKFLOW-DEBUG-FRICTION-REPORT.md reports/llm-workflow-analysis.md
git mv REPOSITORY-ANALYSIS.md reports/repo-analysis.md
```

---

## 📚 Priority 6: References → `references/`

```bash
git mv HYPRLAND-KEYBINDINGS.md references/hyprland-keys.md
git mv TAILSCALE-CHEATSHEET.md references/tailscale-cheatsheet.md
git mv NIX-EMERGENCY-PROCEDURES.md references/nix-emergency.md
git mv MCP-QUICK-REFERENCE.md references/mcp-quick-ref.md
git mv MCP-TOOLS-USAGE-GUIDE.md references/mcp-tools-guide.md
git mv VMCTL-USAGE.md references/vmctl-usage.md
git mv AGENT-TOOLKIT-QUICKSTART.md references/agent-toolkit.md
git mv INSTRUCTIONS.md references/general-instructions.md
git mv QUICK-START-IMPROVEMENTS.md references/quick-start.md
```

---

## 🚀 Priority 7: Proposals → `proposals/`

```bash
git mv PHASE2-UNIFIED-ARCHITECTURE.md proposals/phase2-architecture.md
git mv PHASE2-IMPLEMENTATION-ROADMAP.md proposals/phase2-roadmap.md
git mv ML-MODULES-RESTRUCTURE-PLAN.md proposals/ml-restructure.md
git mv POTENTIAL-ENHANCEMENTS-BRAINSTORM.md proposals/enhancements-brainstorm.md
git mv MCP-KNOWLEDGE-EXTENSION-PLAN.md proposals/mcp-knowledge-extension.md
git mv SIEM-INTEGRATION.md proposals/siem-integration.md
git mv ml-offload-phase2-design.md proposals/ml-offload-phase2.md
git mv ml-offload-testing-plan.md proposals/ml-offload-testing.md
git mv neovim-integration-analysis.md proposals/neovim-integration.md
```

---

## 🗄️ Priority 8: Archive → `archive/2025-12/`

**Session handoffs & old status docs:**
```bash
mkdir -p archive/2025-12
git mv NEXT-SESSION-PROMPT.md archive/2025-12/
git mv HANDOFF-TAILSCALE-E-INFRAESTRUTURA.md archive/2025-12/
git mv MCP-SESSION-HANDOFF.md archive/2025-12/
git mv MCP-SYNC-SUMMARY.md archive/2025-12/
git mv DECISOES-CRITICAS.md archive/2025-12/
git mv EXECUTAR-AGORA.md archive/2025-12/
git mv ESTRATEGIA-FINAL-COMPLETA.md archive/2025-12/
git mv BUILD-OPTIMIZATION-2025-11-22.md archive/2025-12/
```

**Specific bug fixes (historical):**
```bash
git mv alacritty-enhancements-summary.md archive/2025-12/
git mv vscode-remote-test-summary.md archive/2025-12/
git mv mosh-connection-test.md archive/2025-12/
git mv AUDITD_INVESTIGATION.md archive/2025-12/
git mv DNS_WORKING_CONFIG.md archive/2025-12/
git mv PROTONPASS-STATUS.md archive/2025-12/
git mv RESTRUCTURING-MISSION.md archive/2025-12/
```

**Maintenance/cleanup docs (PT-BR, can archive):**
```bash
git mv PLANO-ACAO-LIMPEZA.md archive/2025-12/
git mv EMERGENCIA-LIBERAR-ESPACO.md archive/2025-12/
git mv ECONOMIA-ESPACO.md archive/2025-12/
git mv AUDITORIA-DISCO-FERRAMENTAS.md archive/2025-12/
git mv GUIA-BACKUP-E-REINSTALACAO.md archive/2025-12/
git mv ALTERNATIVA-REINSTALACAO-LIMPA.md archive/2025-12/
```

---

## 🔧 Special Cases

**MCP-related (many files, consider grouping):**
```bash
# Keep most important in references/
git mv MCP-INTEGRATION-GUIDE.md references/mcp-integration.md
git mv MCP-KNOWLEDGE-DB-FIX.md guides/troubleshooting/mcp-knowledge-db.md
git mv MCP-PROJECT-ROOT-ANALYSIS.md architecture/mcp-project-roots.md

# Archive detailed design docs
git mv MCP-KNOWLEDGE-STABILIZATION.md archive/2025-12/
git mv MCP-EXTENDED-TOOLS-DESIGN.md archive/2025-12/
git mv MCP-EXTENDED-TOOLS-PROGRESS.md archive/2025-12/
git mv MCP-EXTENDED-TOOLS-FINAL-REPORT.md archive/2025-12/
git mv MCP-SERVER-PACKAGE.md archive/2025-12/
git mv MCP-CLAUDE-CODE-SETUP.md archive/2025-12/
git mv MCP-CODEX-INTEGRATION.md archive/2025-12/
git mv MCP-ARCHITECTURE-ACCESS.md archive/2025-12/
```

**GitHub/SOPS integration:**
```bash
git mv GITHUB-SOPS-INTEGRATION.md guides/setup/github-sops.md
git mv GITHUB-ACTIONS-RUNNER-CONFIG-EXAMPLES.md references/github-runner-examples.md
```

**Security & hardening:**
```bash
git mv DEV-DIRECTORY-SECURITY.md architecture/dev-security.md
git mv LAPTOP-DEFENSE-FRAMEWORK.md architecture/laptop-security.md
git mv LYNIS-ENHANCEMENTS.md proposals/lynis-enhancements.md
```

**Misc guides:**
```bash
git mv AGENT-EMPOWERMENT-TOOLKIT.md references/agent-toolkit-full.md
git mv CONFIGURATION_ENHANCEMENTS.md proposals/config-enhancements.md
git mv WEB-SEARCH-TOOLS.md references/web-search-tools.md
git mv TEMPLATE_GUIDE.md references/template-guide.md
```

**Desktop/Laptop specific:**
```bash
git mv DESKTOP-SETUP-REQUIRED.md guides/setup/desktop-requirements.md
git mv DESKTOP-OFFLOAD-SETUP.md guides/setup/desktop-offload-detailed.md
git mv PLANO-INTEROPERABILIDADE-LAPTOP-DESKTOP.md architecture/laptop-desktop-interop-pt.md
git mv STACK-SERVER-CLIENT-COMPLETE-GUIDE.md guides/setup/stack-complete.md
git mv README-STACK-SETUP.md guides/setup/stack-readme.md
git mv REMOTE-BUILDER-CACHE-GUIDE.md guides/setup/remote-builder-cache.md
git mv CENTRALIZACAO-LOGS-DESKTOP.md guides/setup/log-centralization-pt.md
```

**Tailscale:**
```bash
git mv TAILSCALE-SUBNET-ROUTING-GUIDE.md guides/setup/tailscale-subnet.md
git mv TAILSCALE-DEPLOYMENT-STATUS.md reports/tailscale-deployment.md
```

**Systemd:**
```bash
git mv SYSTEMD_CENTRALIZATION_INDEX.md references/systemd-index.md
git mv SYSTEMD_SERVICES_INVENTORY.md references/systemd-inventory.md
```

**Keep in root (important meta docs):**
```bash
# These can stay in /docs root as they're meta/index docs:
# - README.md (master index, already updated)
# - TODO.md (current TODO list)
# - SUMMARY.md (project summary)
# - TECHNICAL-OVERVIEW.md (general overview)
```

---

## 📁 Files/Dirs to Review

**Already organized (leave as-is):**
- `guides/` subdirs (already have content)
- `architecture/` subdirs  
- `reports/` subdirs
- `applications/` (apps-specific)
- `system/` (system-specific)

**Text files (not MD):**
```bash
# Convert or archive these:
- .tree-commands.md → references/tree-commands.md
- ARCHITECTURE-TREE.txt → archive/2025-12/ (redundant with .md version)
- README_SYSTEMD_INVENTORY.txt → archive/2025-12/
- auditoria-disco-20251122-054711.txt → archive/2025-12/
- 2025-11-26-claude-*.txt → archive/2025-12/
- relatorio.md → archive/2025-12/
- sample.md → archive/2025-12/
- test.md → (delete? or archive)
```

---

## ✅ Post-Move Checklist

1. Update `/docs/README.md` with actual file links
2. Create category-specific READMEs:
   - `guides/setup/README.md`
   - `guides/troubleshooting/README.md`
   - `architecture/README.md`
   - `proposals/README.md`
   - etc.
3. Delete empty subdirs
4. Single commit: `git commit -m 'refactor(docs): reorganize all documentation'`
5. Push and celebrate 🎉

---

**Estimated time**: 15-20 mins if you batch the commands  
**Suggested approach**: Copy sections to terminal, review, execute

*Generated: 2025-12-30*
