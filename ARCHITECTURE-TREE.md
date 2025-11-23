# NixOS Repository Architecture

> **Auto-Generated Tree Diagram**
> **Generated**: 2025-11-22 23:33:17 -02
> **Location**: /etc/nixos
> **Host**: nx
> **Branch**: main (032cd66)

## Legend

| Symbol | Meaning |
|--------|---------|
| `/`    | Directory |
| `*`    | Executable file |
| `.nix` | Nix configuration |
| `.md`  | Documentation |
| `.sh`  | Shell script |

## Filters Applied

✓ **Excluded**: .git, result*, *.iso, *.qcow2, target/, node_modules/, archive/
✓ **Max depth**: 5 levels
✓ **Sorting**: Directories first, alphabetically sorted

## Repository Statistics

```
Total Files:       925
Total Directories: 647
.nix files:        147
.md files:         350
.sh files:         33
ML modules size:   3.8G
Repository size:   6.9G
```

## Architecture Tree

```
/etc/nixos/
├── dev/
│   ├── flakes/
│   │   └── Python-Flake/
│   │       ├── analyze_binary.py
│   │       ├── ask_claude.py
│   │       ├── docker-compose.yml
│   │       ├── download_datasets.py
│   │       ├── flake.lock
│   │       ├── flake.nix
│   │       ├── Makefile
│   │       ├── pyproject.toml
│   │       ├── QUICKSTART.md
│   │       ├── README.md
│   │       └── setup_env.py
│   └── default.nix
├── docs/
│   ├── architecture/
│   ├── guides/
│   │   ├── DEB-PACKAGES-GUIDE.md
│   │   ├── MULTI-HOST-SETUP.md
│   │   ├── SECRETS.md
│   │   ├── SETUP-SOPS-FINAL.md
│   │   └── SSH-CONFIGURATION.md
│   ├── reports/
│   │   ├── CI_CD_README.md*
│   │   ├── ml-offload-phase1-test-report.md
│   │   ├── SECURITY_AUDIT_REPORT.md*
│   │   ├── SERVICES_MIGRATION_PLAN.md*
│   │   ├── SERVICES_VISUAL_MAP.txt*
│   │   └── SYSTEMD_SERVICES_SUMMARY.txt*
│   ├── ARCHITECTURE-BLUEPRINT.md
│   ├── ARCHITECTURE-TRACKING.md
│   ├── ARCHITECTURE-TREE.txt
│   ├── AUDITD_INVESTIGATION.md*
│   ├── BINARY-CACHE-SETUP.md
│   ├── BUILD-OPTIMIZATION-2025-11-22.md
│   ├── CONFIGURATION_ENHANCEMENTS.md*
│   ├── DECISOES-CRITICAS.md
│   ├── DESKTOP-OFFLOAD-QUICKSTART.md
│   ├── DESKTOP-SETUP-REQUIRED.md
│   ├── DESKTOP-TROUBLESHOOTING.md
│   ├── DEV-DIRECTORY-SECURITY.md
│   ├── DNS_FIX_SUMMARY.md*
│   ├── DNS_WORKING_CONFIG.md*
│   ├── FINAL-STATUS-REPORT.md
│   ├── GITHUB_ACTIONS_SETUP.md*
│   ├── GITHUB_CLI_AUTH.md
│   ├── GITHUB-SOPS-INTEGRATION.md
│   ├── GIT-WORKFLOW-TESTING-IMPROVEMENT-PLAN.md
│   ├── GUIA-CORRECAO-DNS.md*
│   ├── IMPLEMENTATION-SUMMARY.md
│   ├── INSTRUCTIONS.md
│   ├── LAPTOP-BUILD-SETUP.md
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
│   ├── MCP-SECURE-ARCHITECTURE.md
│   ├── MCP-SERVER-HEALTH-REPORT.md
│   ├── MCP-SESSION-HANDOFF.md
│   ├── MCP-SYNC-SUMMARY.md
│   ├── MCP-TOOLS-USAGE-GUIDE.md
│   ├── MCP-TROUBLESHOOTING.md
│   ├── ML-ARCHITECTURE-REFACTORING.md
│   ├── ml-offload-phase2-design.md
│   ├── ml-offload-testing-plan.md
│   ├── neovim-integration-analysis.md
│   ├── NEXT-SESSION-PROMPT.md
│   ├── OS-KEYRING-SETUP.md
│   ├── PHASE2-IMPLEMENTATION-ROADMAP.md
│   ├── PHASE2-UNIFIED-ARCHITECTURE.md
│   ├── QUICK-START-IMPROVEMENTS.md
│   ├── README_SYSTEMD_INVENTORY.txt*
│   ├── REBUILD-FIX.md
│   ├── REMOTE-BUILDER-CACHE-GUIDE.md
│   ├── REPOSITORY-ANALYSIS.md
│   ├── RESTRUCTURING-MISSION.md
│   ├── sample.md
│   ├── SECURITY-HARDENING-STATUS.md
│   ├── SESSION-1-SUMMARY.md
│   ├── SOPS-TROUBLESHOOTING.md*
│   ├── SUMMARY.md*
│   ├── SYSTEMD_CENTRALIZATION_INDEX.md*
│   ├── SYSTEMD_SERVICES_INVENTORY.md*
│   ├── TODO.md*
│   └── VMCTL-USAGE.md
├── evidences/
│   ├── rebuild-monitor-20251122-172701/
│   │   ├── cpu.csv
│   │   ├── memory.csv
│   │   ├── monitor.log
│   │   ├── processes.csv
│   │   ├── report.txt
│   │   └── top-consumers.log
│   ├── rebuild-monitor-20251122-184556/
│   │   ├── cpu.csv
│   │   ├── disk.csv
│   │   ├── file-descriptors.csv
│   │   ├── fork-analysis.csv
│   │   ├── memory.csv
│   │   ├── monitor.log
│   │   ├── network.csv
│   │   ├── nix-store.csv
│   │   ├── processes.csv
│   │   ├── process-limits.csv
│   │   ├── report.html
│   │   ├── report.txt
│   │   ├── temperature.csv
│   │   └── top-consumers.log
│   ├── rebuild-monitor-20251122-184723/
│   │   ├── cpu.csv
│   │   ├── disk.csv
│   │   ├── file-descriptors.csv
│   │   ├── fork-analysis.csv
│   │   ├── memory.csv
│   │   ├── monitor.log
│   │   ├── network.csv
│   │   ├── nix-store.csv
│   │   ├── processes.csv
│   │   ├── process-limits.csv
│   │   ├── report.html
│   │   ├── report.txt
│   │   ├── temperature.csv
│   │   └── top-consumers.log
│   ├── rebuild-monitor-20251122-185645/
│   │   ├── cpu.csv
│   │   ├── disk.csv
│   │   ├── file-descriptors.csv
│   │   ├── fork-analysis.csv
│   │   ├── memory.csv
│   │   ├── monitor.log
│   │   ├── network.csv
│   │   ├── nix-store.csv
│   │   ├── processes.csv
│   │   ├── process-limits.csv
│   │   ├── report.html
│   │   ├── report.txt
│   │   ├── temperature.csv
│   │   └── top-consumers.log
│   └── rebuild-monitor-20251122-190106/
│       ├── cpu.csv
│       ├── disk.csv
│       ├── file-descriptors.csv
│       ├── fork-analysis.csv
│       ├── journal.log
│       ├── memory.csv
│       ├── monitor.log
│       ├── network.csv
│       ├── nix-store.csv
│       ├── processes.csv
│       ├── process-limits.csv
│       ├── report.html
│       ├── report.txt
│       ├── temperature.csv
│       └── top-consumers.log
├── hosts/
│   └── kernelcore/
│       ├── home/
│       │   ├── aliases/
│       │   │   ├── ai-compose-stack.sh*
│       │   │   ├── ai-ml-stack.sh*
│       │   │   ├── aliases.sh
│       │   │   ├── gcloud.sh*
│       │   │   ├── gpu-docker-core.sh*
│       │   │   ├── gpu-management.sh
│       │   │   ├── gpu.sh*
│       │   │   ├── litellm_runtime_manager.sh*
│       │   │   ├── multimodal.sh*
│       │   │   ├── nixos-aliases.nix
│       │   │   └── nx.sh*
│       │   ├── shell/
│       │   │   ├── bash.nix
│       │   │   ├── default.nix
│       │   │   ├── options.nix
│       │   │   ├── p10k.zsh
│       │   │   ├── README.md
│       │   │   └── zsh.nix
│       │   └── home.nix*
│       ├── configuration.nix*
│       ├── configurations-template.nix*
│       ├── default.nix*
│       └── hardware-configuration.nix*
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
│   │   ├── vscode-secure.nix*
│   │   └── vscodium-secure.nix*
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
│   │   ├── default.nix
│   │   ├── hyprland.nix
│   │   └── i3-lightweight.nix
│   ├── development/
│   │   ├── cicd.nix*
│   │   ├── environments.nix*
│   │   └── jupyter.nix*
│   ├── hardware/
│   │   ├── bluetooth.nix
│   │   ├── default.nix
│   │   ├── intel.nix*
│   │   ├── nvidia.nix*
│   │   ├── trezor.nix*
│   │   └── wifi-optimization.nix
│   ├── ml/
│   │   ├── mcp-config/
│   │   │   └── default.nix
│   │   ├── offload/
│   │   │   ├── api/
│   │   │   │   ├── src/
│   │   │   │   ├── Cargo.lock
│   │   │   │   ├── Cargo.toml
│   │   │   │   ├── dev-ui.html
│   │   │   │   ├── ml-offload-api.py
│   │   │   │   ├── registry.py
│   │   │   │   └── vram_monitor.py
│   │   │   ├── backends/
│   │   │   │   └── default.nix
│   │   │   ├── neovim/
│   │   │   │   └── README.md
│   │   │   ├── default.nix
│   │   │   ├── manager.nix
│   │   │   ├── model-registry.nix
│   │   │   └── vram-intelligence.nix
│   │   ├── Security-Architect/
│   │   │   ├── config/
│   │   │   ├── crates/
│   │   │   │   ├── api/
│   │   │   │   ├── cli/
│   │   │   │   ├── core/
│   │   │   │   ├── local/
│   │   │   │   ├── providers/
│   │   │   │   ├── router/
│   │   │   │   └── security/
│   │   │   ├── docs/
│   │   │   │   ├── MIGRATION-NOTES.md
│   │   │   │   └── WEEK2-PLAN.md
│   │   │   ├── mcp-server/
│   │   │   ├── scripts/
│   │   │   ├── tests/
│   │   │   ├── Cargo.lock
│   │   │   └── Cargo.toml
│   │   ├── unified-llm/
│   │   │   ├── cli/
│   │   │   │   └── src/
│   │   │   ├── config/
│   │   │   │   └── config.toml
│   │   │   ├── crates/
│   │   │   │   ├── api-server/
│   │   │   │   ├── cli/
│   │   │   │   ├── core/
│   │   │   │   ├── providers/
│   │   │   │   └── security/
│   │   │   ├── docker/
│   │   │   │   ├── docker-compose.yml
│   │   │   │   ├── Dockerfile
│   │   │   │   └── Dockerfile.alpine
│   │   │   ├── docs/
│   │   │   │   ├── CONTRIBUTING.md
│   │   │   │   ├── GETTING_STARTED.md
│   │   │   │   ├── PROJETO_COMPLETO.md
│   │   │   │   ├── QUICK_START.md
│   │   │   │   ├── README.md
│   │   │   │   └── SECURITY.md
│   │   │   ├── examples/
│   │   │   │   ├── basic_usage.sh*
│   │   │   │   ├── config.toml.example
│   │   │   │   └── rust_api_example.rs
│   │   │   ├── mcp-server/
│   │   │   │   ├── docs/
│   │   │   │   ├── examples/
│   │   │   │   ├── secrets/
│   │   │   │   ├── src/
│   │   │   │   ├── tests/
│   │   │   │   ├── knowledge.db
│   │   │   │   ├── knowledge.db-shm
│   │   │   │   ├── knowledge.db-wal
│   │   │   │   ├── package.json
│   │   │   │   ├── package-lock.json
│   │   │   │   ├── README.md
│   │   │   │   └── tsconfig.json
│   │   │   ├── mnt/
│   │   │   │   └── user-data/
│   │   │   ├── nix/
│   │   │   │   ├── flake.lock
│   │   │   │   └── flake.nix
│   │   │   ├── src/
│   │   │   │   ├── core/
│   │   │   │   ├── providers/
│   │   │   │   ├── security/
│   │   │   │   └── config.rs
│   │   │   ├── Cargo.lock
│   │   │   ├── Cargo.toml
│   │   │   ├── CLAUDE.md
│   │   │   ├── LICENSE-APACHE
│   │   │   ├── LICENSE-MIT
│   │   │   ├── Makefile
│   │   │   ├── mcp-server-config.json
│   │   │   └── README.md
│   │   ├── llama.nix*
│   │   ├── models-storage.nix*
│   │   └── ollama-gpu-manager.nix*
│   ├── network/
│   │   ├── dns/
│   │   │   ├── config.example.json
│   │   │   ├── default.nix
│   │   │   ├── go.mod
│   │   │   ├── go.sum
│   │   │   ├── main.go
│   │   │   └── README.md
│   │   ├── vpn/
│   │   │   └── nordvpn.nix*
│   │   ├── bridge.nix
│   │   └── dns-resolver.nix*
│   ├── packages/
│   │   ├── deb-packages/
│   │   │   ├── packages/
│   │   │   │   ├── cursor.nix
│   │   │   │   ├── example.nix
│   │   │   │   ├── protonvpn.nix
│   │   │   │   └── README.md
│   │   │   ├── storage/
│   │   │   │   ├── cursor_2.0.34_amd64.deb
│   │   │   │   ├── protonvpn-stable-release_1.0.8_all.deb
│   │   │   │   └── README.md
│   │   │   ├── audit.nix
│   │   │   ├── builder.nix
│   │   │   ├── default.nix
│   │   │   ├── README.md
│   │   │   └── sandbox.nix
│   │   ├── js-packages/
│   │   │   ├── storage/
│   │   │   │   ├── gemini-cli-v0.15.0-nightly.20251107.cd27cae8.tar.gz
│   │   │   │   ├── gemini-cli-v0.18.0-nightly.20251118.7cc5234b9.tar.gz
│   │   │   │   └── README.md
│   │   │   ├── default.nix
│   │   │   ├── gemini-cli.nix
│   │   │   └── js-packages.nix
│   │   ├── tar-packages/
│   │   │   ├── packages/
│   │   │   │   ├── codex.nix
│   │   │   │   ├── lynis.nix
│   │   │   │   └── zellij.nix
│   │   │   ├── storage/
│   │   │   │   ├── Antigravity.tar.gz
│   │   │   │   ├── lynis-3.1.6.tar.gz
│   │   │   │   └── zellij-v0.43.1-x86_64-unknown-linux-musl.tar.gz
│   │   │   ├── builder.nix
│   │   │   ├── default.nix
│   │   │   └── README.md
│   │   ├── default.nix
│   │   ├── DOCUMENTATION.md
│   │   ├── PACKAGES-STATUS.md
│   │   ├── README.md
│   │   └── SETUP.md
│   ├── programs/
│   │   └── default.nix
│   ├── secrets/
│   │   ├── api-keys.nix
│   │   └── sops-config.nix*
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
│   │   │   │   ├── default.nix
│   │   │   │   └── system.nix
│   │   │   ├── security/
│   │   │   │   ├── default.nix
│   │   │   │   └── secrets.nix
│   │   │   ├── system/
│   │   │   │   ├── default.nix
│   │   │   │   └── utils.nix
│   │   │   ├── default.nix
│   │   │   └── README.md
│   │   ├── scripts/
│   │   │   ├── bash/
│   │   │   └── python/
│   │   │       ├── gpu_monitor.py*
│   │   │       └── model_manager.py*
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
│   │   ├── memory.nix*
│   │   ├── ml-gpu-users.nix
│   │   ├── nix.nix*
│   │   ├── services.nix*
│   │   ├── ssh-config.nix
│   │   └── sudo-claude-code.nix
│   └── virtualization/
│       ├── default.nix
│       ├── vmctl.nix
│       └── vms.nix*
├── overlays/
│   ├── default.nix
│   ├── hyprland.nix
│   ├── python-packages.nix
│   └── README.md
├── scripts/
│   ├── SecOps/
│   │   └── bedrock-investigation-brief.md
│   ├── add-secret.sh*
│   ├── auditoria-disco.sh*
│   ├── backup-rapido.sh*
│   ├── deb-add*
│   ├── diagnose-home-manager.sh*
│   ├── diagnostico-detalhado.sh*
│   ├── fix-mcp-configs.sh*
│   ├── fix-secrets-permissions.sh*
│   ├── generate-architecture-tree.sh*
│   ├── generate-mcp-config.sh*
│   ├── generate-tree-diagram.sh*
│   ├── limpeza-agressiva.sh*
│   ├── mcp-health-check.sh*
│   ├── migrate-sec-to-sops.sh*
│   ├── monitor-rebuild.sh*
│   ├── MONITOR-REBUILD-USAGE.md
│   ├── post-rebuild-validate.sh*
│   ├── setup-desktop-offload.sh*
│   ├── setup-git-hooks.sh*
│   ├── setup-packages*
│   ├── sync-github-secrets.sh*
│   └── test-coverage.sh*
├── sec/
│   ├── hardening.nix*
│   └── user-password*
├── secrets/
│   ├── ssh-keys/
│   │   ├── dev.yaml*
│   │   ├── production.yaml*
│   │   └── staging.yaml*
│   ├── api.yaml
│   ├── aws.yaml*
│   ├── database.yaml*
│   ├── github.yaml
│   ├── github.yaml.backup*
│   ├── prod.yaml*
│   ├── secrets.yaml
│   └── ssh.yaml*
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
│   └── README.md
├── AGENTS.md
├── ALTERNATIVA-REINSTALACAO-LIMPA.md
├── ARCHITECTURE-TREE.md
├── ARCHITECTURE-TREE.txt
├── auditoria-disco-20251122-054711.txt
├── AUDITORIA-DISCO-FERRAMENTAS.md
├── CENTRALIZACAO-LOGS-DESKTOP.md
├── CLAUDE.md
├── DESKTOP-OFFLOAD-SETUP.md
├── diagnostico-disco.sh*
├── ECONOMIA-ESPACO.md
├── EMERGENCIA-LIBERAR-ESPACO.md
├── ESTRATEGIA-FINAL-COMPLETA.md
├── example.yaml
├── EXECUTAR-AGORA.md
├── flake.lock*
├── flake.nix*
├── GUIA-BACKUP-E-REINSTALACAO.md
├── knowledge.db
├── PLANO-ACAO-LIMPEZA.md
├── README.md
└── REFATORACAO-ARQUITETURA-2025.md

121 directories, 432 files
```

## Key Areas

### Core System Configuration
- `hosts/` - Host-specific configurations
- `modules/` - Modular NixOS configurations
- `overlays/` - Package overlays
- `lib/` - Utility functions and packages

### Security
- `modules/security/` - Security hardening
- `sec/` - Final security overrides
- `secrets/` - SOPS-encrypted secrets

### Machine Learning
- `modules/ml/` - ML infrastructure
  - ⚠️ **REFACTORING PLANNED**: See `docs/ML-ARCHITECTURE-REFACTORING.md`
  - Target: 3.8GB → 100KB (separate repos)

### Documentation
- `docs/` - Comprehensive documentation
- `CLAUDE.md` - AI assistant instructions
- `README.md` - Repository overview

### Development
- `scripts/` - Utility scripts
- `lib/shells.nix` - Development shells

## Related Documentation

- [ML Refactoring Plan](docs/ML-ARCHITECTURE-REFACTORING.md)
- [~/dev Security](docs/DEV-DIRECTORY-SECURITY.md)
- [Repository Restructuring](CLAUDE.md)

## Maintenance

This diagram is auto-generated. To regenerate:

```bash
bash scripts/generate-architecture-tree.sh
```

**Last Generated**: 2025-11-22 23:33:18
