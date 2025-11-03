# NixOS Repository Architecture Blueprint

> **Template para anotações manuais da arquitetura**
> **Auto-gerado**: Use este arquivo para documentar decisões, TODOs e notas

---

## 📋 Index Rápido

- [Visão Geral](#visão-geral)
- [Estrutura de Diretórios](#estrutura-de-diretórios)
- [Módulos Principais](#módulos-principais)
- [Fluxo de Build](#fluxo-de-build)
- [Dependências](#dependências)
- [TODOs e Melhorias](#todos-e-melhorias)

---

## Visão Geral

```
Repository: /etc/nixos
Purpose: Stablish the services for server desktop client and laptop client for usual operations
Hosts:
  - kernelcore-laptop (IP: 192.168.15.8) - Status: ✅ Active
  - kernelcore-desktop (IP: 192.168.15.6) - Status: 🚧 In Progress
```

**Estado Atual:**
- [ ] Single-host (laptop only)
- [ ] Multi-host architecture ready
- [ ] Production deployment complete

---

## Estrutura de Diretórios

### Root Level

```
/etc/nixos/
├── flake.nix                 # [ANOTAR: ]
├── flake.lock                # [ANOTAR: ]
├── README.md                 # [ANOTAR: ]
├── CLAUDE.md                 # [ANOTAR: ]
├── .gitmessage               # [ANOTAR: ]
└── .gitignore                # [ANOTAR: ]
```

**Notas:**
-

---

### 📁 `/hosts/` - Host-Specific Configurations

```
hosts/
├── common/                   # [STATUS: 🚧 Planned]
│   ├── base.nix             # [TODO: Create - users, locale, timezone]
│   ├── hardware.nix         # [TODO: Create - NVIDIA, CUDA]
│   ├── security.nix         # [TODO: Create - security hardening]
│   └── networking.nix       # [TODO: Create - DNS, firewall base]
│
├── kernelcore/               # [STATUS: ✅ Active - LAPTOP]
│   ├── default.nix          # [ANOTAR: ]
│   ├── configuration.nix    # [ANOTAR: Main laptop config]
│   ├── hardware-configuration.nix  # [ANOTAR: Auto-generated]
│   └── home/                # [ANOTAR: Home-manager configs]
│       ├── home.nix
│       └── aliases/
│
└── desktop/                  # [STATUS: 🚧 Planned]
    ├── configuration.nix    # [TODO: Create - Desktop with i3 WM]
    ├── hardware-configuration.nix  # [TODO: Generate on desktop]
    └── desktop.nix          # [TODO: i3 configuration]
```

**Decisões de Design:**
- **Por que common/?** [ANOTAR: ]
- **Hardware separation?** [ANOTAR: ]

**TODOs:**
- [ ] Create hosts/common/ structure
- [ ] Extract shared configs from kernelcore/
- [ ] Generate hardware-configuration.nix on desktop
- [ ] Test multi-host builds

---

### 📁 `/modules/` - Reusable Modules

```
modules/
├── applications/            # [PROPÓSITO: User applications]
│   ├── default.nix         # [STATUS: ✅ Created - Aggregator]
│   ├── firefox-privacy.nix # [ANOTAR: ]
│   ├── brave-secure.nix    # [ANOTAR: ]
│   ├── vscode-secure.nix   # [ANOTAR: ]
│   └── vscodium-secure.nix # [ANOTAR: ]
│
├── containers/              # [PROPÓSITO: Docker, Podman]
│   ├── default.nix         # [STATUS: ✅ Created]
│   ├── docker.nix          # [ANOTAR: ]
│   ├── podman.nix          # [ANOTAR: ]
│   └── nixos-containers.nix # [ANOTAR: ]
│
├── development/             # [PROPÓSITO: Dev environments]
│   ├── rust.nix            # [ANOTAR: ]
│   ├── go.nix              # [ANOTAR: ]
│   ├── python.nix          # [ANOTAR: ]
│   ├── nodejs.nix          # [ANOTAR: ]
│   └── jupyter.nix         # [ANOTAR: ]
│
├── hardware/                # [PROPÓSITO: Hardware configs]
│   ├── default.nix         # [STATUS: ✅ Created]
│   ├── nvidia.nix          # [ANOTAR: CUDA support, drivers]
│   ├── trezor.nix          # [ANOTAR: ]
│   └── wifi-optimization.nix # [ANOTAR: ]
│
├── ml/                      # [PROPÓSITO: Machine Learning]
│   ├── ollama.nix          # [ANOTAR: ]
│   ├── models-storage.nix  # [ANOTAR: ]
│   └── llamacpp.nix        # [ANOTAR: ]
│
├── network/                 # [PROPÓSITO: Networking]
│   ├── dns/                # [ANOTAR: ]
│   │   ├── default.nix
│   │   └── dns-resolver.nix
│   ├── vpn/                # [ANOTAR: ]
│   │   └── nordvpn.nix
│   └── bridge.nix          # [ANOTAR: VM networking]
│
├── security/                # [PROPÓSITO: Security hardening]
│   ├── default.nix         # [STATUS: ✅ Created]
│   ├── hardening.nix       # [ANOTAR: ]
│   ├── audit.nix           # [ANOTAR: auditd]
│   ├── aide.nix            # [ANOTAR: File integrity]
│   ├── clamav.nix          # [ANOTAR: Antivirus]
│   ├── ssh.nix             # [ANOTAR: SSH hardening]
│   ├── kernel.nix          # [ANOTAR: Kernel security]
│   └── pam.nix             # [ANOTAR: PAM hardening]
│
├── services/                # [PROPÓSITO: System services]
│   ├── laptop-offload-client.nix   # [ANOTAR: Build offload]
│   ├── laptop-builder-client.nix   # [ANOTAR: Remote builder]
│   └── users/              # [ANOTAR: User management]
│
├── shell/                   # [PROPÓSITO: Shell configuration]
│   ├── default.nix         # [ANOTAR: Orchestrator]
│   ├── gpu-flags.nix       # [ANOTAR: GPU flags for Docker]
│   ├── aliases/            # [STATUS: ✅ Reorganized - 16 files]
│   │   ├── default.nix
│   │   ├── README.md
│   │   ├── docker/         # [ANOTAR: 4 files]
│   │   ├── kubernetes/     # [ANOTAR: 2 files]
│   │   ├── gcloud/         # [ANOTAR: 2 files]
│   │   ├── ai/             # [ANOTAR: 2 files]
│   │   ├── nix/            # [ANOTAR: 2 files]
│   │   └── system/         # [ANOTAR: 2 files]
│   └── scripts/
│       └── python/         # [ANOTAR: gpu_monitor.py, model_manager.py]
│
├── system/                  # [PROPÓSITO: System-level configs]
│   ├── memory.nix          # [ANOTAR: ]
│   ├── nix.nix             # [ANOTAR: Nix settings]
│   ├── binary-cache.nix    # [ANOTAR: Cache server config]
│   ├── ssh-config.nix      # [STATUS: ✅ Created - SSH declarativo]
│   └── services.nix        # [ANOTAR: ]
│
├── virtualization/          # [PROPÓSITO: VMs, QEMU]
│   ├── default.nix         # [STATUS: ✅ Created]
│   ├── vms.nix             # [ANOTAR: VM definitions]
│   └── vmctl.nix           # [ANOTAR: VM management utility]
│
└── desktop/                 # [PROPÓSITO: Desktop environments]
    ├── default.nix         # [STATUS: ✅ Created]
    └── i3-lightweight.nix  # [STATUS: ✅ Created - i3 WM module]
```

**Decisões de Design:**
- **Por que separar applications/ e browsers/?** [RESPOSTA: Browsers merged into applications/]
- **Security hierarchy?** [ANOTAR: modules/security + sec/hardening.nix]
- **Shell aliases organization?** [RESPOSTA: 6 categories, 16 files]

**Módulos com Conflitos Conhecidos:**
- [ ] NENHUM (todos resolvidos na Session 2)

**TODOs Módulos:**
- [ ] Create modules/core/ for base system
- [ ] Create modules/profiles/ for complete system profiles
- [ ] Document all module options with mkOption descriptions
- [ ] Add module-level README.md files

---

### 📁 `/lib/` - Custom Libraries

```
lib/
├── packages.nix             # [ANOTAR: Docker images, custom packages]
├── shells.nix               # [ANOTAR: Dev shells (python, rust, node, cuda)]
└── shell.nix                # [ANOTAR: ]
```

**Uso:**
- packages.nix → Docker images para ML/AI
- shells.nix → nix develop .#python, .#rust, etc.

**TODOs:**
- [ ] Expand lib/ with builders/ and helpers/
- [ ] Add validation functions
- [ ] Create reusable builders for VMs, ISOs

---

### 📁 `/sec/` - Security Overrides

```
sec/
├── hardening.nix            # [PRIORIDADE: HIGHEST - Final overrides]
└── user-password            # [ANOTAR: Hashed password file]
```

**Hierarquia de Segurança:**
1. `modules/security/*.nix` - Base security configs
2. `sec/hardening.nix` - **FINAL OVERRIDES** (mkForce)

**Notas:**
- sec/hardening.nix tem prioridade MÁXIMA
- Imports todos os módulos de security/
- Usa mkForce para garantir configs finais

---

### 📁 `/secrets/` - SOPS Encrypted Secrets

```
secrets/
├── .sops.yaml               # [ANOTAR: SOPS config]
├── api-keys/                # [ANOTAR: Encrypted API keys]
└── ssh-keys/                # [ANOTAR: Encrypted SSH keys]
```

**Criptografia:**
- Método: SOPS + Age
- Keys location: ~/.config/sops/age/keys.txt

**TODOs:**
- [ ] Document secret rotation process
- [ ] Create secret templates
- [ ] Add validation script

---

### 📁 `/scripts/` - Utility Scripts

```
scripts/
├── add-secret.sh            # [ANOTAR: Add new SOPS secret]
├── diagnose-home-manager.sh # [ANOTAR: Diagnose home-manager issues]
├── generate-tree-diagram.sh # [STATUS: ✅ Created]
└── [outros]
```

**Uso:**
```bash
# Generate tree diagram
./scripts/generate-tree-diagram.sh

# Add secret
./scripts/add-secret.sh api-keys/openai
```

---

### 📁 `/docs/` - Documentation

```
docs/
├── guides/                  # [PROPÓSITO: Setup guides]
│   ├── SECRETS.md          # [ANOTAR: Secret management]
│   ├── SETUP-SOPS-FINAL.md # [ANOTAR: SOPS setup]
│   ├── SSH-CONFIGURATION.md # [STATUS: ✅ Created]
│   └── MULTI-HOST-SETUP.md  # [STATUS: ✅ Created]
│
├── reports/                 # [PROPÓSITO: Technical reports]
│   ├── SECURITY_AUDIT_REPORT.md
│   ├── SERVICES_MIGRATION_PLAN.md
│   └── CI_CD_README.md
│
└── [24 total docs]
```

**Organização:**
- guides/ → How-to guides
- reports/ → Historical technical reports
- Root docs/ → General documentation

---

### 📁 `/archive/` - Legacy Code

```
archive/
├── merged-repos/            # [ANOTAR: Old merged repositories]
│   └── nixtrap/            # [SIZE: 1.8MB - archived]
└── old-aliases-20251101/    # [ANOTAR: Previous alias implementation]
```

**Status:** Archived, não usado em builds ativos

---

### 📁 `/.claude/` - Claude Code Configuration

```
.claude/
├── agents/                  # [ANOTAR: Agent definitions]
├── skills/                  # [ANOTAR: Skills for automation]
├── workflows/               # [ANOTAR: Workflow definitions]
└── settings.local.json      # [ANOTAR: Local Claude settings]
```

---

## Módulos Principais

### 🔐 Security Stack

```
[Base Layer]
  modules/security/audit.nix        → auditd rules
  modules/security/aide.nix         → File integrity
  modules/security/clamav.nix       → Antivirus
  modules/security/kernel.nix       → Kernel hardening
  modules/security/ssh.nix          → SSH hardening
  modules/security/pam.nix          → PAM hardening

[Final Override Layer]
  sec/hardening.nix                 → mkForce final overrides
```

**Decisão:** [ANOTAR: Por que dois layers?]

**Configurações Críticas:**
- [ ] [ANOTAR: Quais configs são mkForce?]
- [ ] [ANOTAR: Quais podem ser overridden?]

---

### 🐳 Container Stack

```
modules/containers/docker.nix       → Docker with GPU support
modules/containers/podman.nix       → Rootless Podman
modules/containers/nixos-containers.nix → Declarative containers

Shell Aliases:
  modules/shell/aliases/docker/     → Build, run, compose shortcuts
```

**GPU Support:**
- [ANOTAR: Como funciona nvidia-docker?]
- [ANOTAR: Flags testadas em gpu-flags.nix]

---

### 🤖 ML/AI Stack

```
modules/ml/ollama.nix               → Local LLM server
modules/ml/models-storage.nix       → Model management
services.llamacpp                   → LlamaCPP server

Shell Tools:
  modules/shell/scripts/python/model_manager.py
  modules/shell/aliases/ai/ollama.nix
```

**Models Location:** `/var/lib/llamacpp/models/`

**Aliases:**
- `ollama-list`, `ollama-run`, `ai-up`, `ai-down`

---

### 🌐 Network Stack

```
[DNS Resolution]
  modules/network/dns/dns-resolver.nix  → dnsmasq + unbound

[VPN]
  modules/network/vpn/nordvpn.nix       → NordVPN integration

[VM Networking]
  modules/network/bridge.nix            → br0 for VMs
```

**DNS Strategy:**
- Primary: 1.1.1.1 (Cloudflare)
- Secondary: 9.9.9.9 (Quad9)
- Fallback: 8.8.8.8 (Google)
- DNSSEC: Disabled (compatibility)

---

### 💻 Development Stack

```
modules/development/rust.nix        → Rust toolchain
modules/development/go.nix          → Go environment
modules/development/python.nix      → Python + pip
modules/development/nodejs.nix      → Node.js + npm
modules/development/jupyter.nix     → Jupyter notebooks

Dev Shells (lib/shells.nix):
  nix develop .#python
  nix develop .#rust
  nix develop .#node
  nix develop .#cuda
```

---

## Fluxo de Build

### Build Local (Laptop)

```
1. Edit configuration
2. nix flake check
3. sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
4. Test
```

### Build Offload (Laptop → Desktop)

```
1. Edit configuration on laptop
2. nix flake check
3. nixos-rebuild switch --flake /etc/nixos#kernelcore
   └─> Offloads heavy builds to desktop (.7)
4. Downloads results from desktop
5. Activates on laptop
```

**Configuration:**
- `modules/services/laptop-offload-client.nix`
- `modules/services/laptop-builder-client.nix`

### Binary Cache (Desktop → Laptop)

```
[Desktop]
  services.nix-serve.enable = true
  Port: 5000
  Serves: /nix/store

[Laptop]
  nix.settings.substituters = ["http://192.168.15.7:5000"]
  Downloads pre-built packages instead of rebuilding
```

---

## Dependências

### External Dependencies

```
GitHub/GitLab:
  - [ANOTAR: Repos usados?]

Nix Channels:
  - nixpkgs: github:NixOS/nixpkgs/nixos-unstable

SOPS:
  - Age encryption keys
```

### Module Dependencies

```
[EXAMPLE]
modules/shell/default.nix
  ├─> modules/shell/gpu-flags.nix
  ├─> modules/shell/aliases/default.nix
  └─> modules/shell/scripts/python/*.py
```

**Dependency Graph:**
- [ ] [TODO: Create visual dependency graph]

---

## TODOs e Melhorias

### 🔴 High Priority

- [ ] Create hosts/common/ structure
- [ ] Extract shared configs from kernelcore/
- [ ] Generate desktop hardware-configuration.nix
- [ ] Test multi-host builds
- [ ] Create root README.md index

### 🟡 Medium Priority

- [ ] Add module-level documentation
- [ ] Create module options reference
- [ ] Improve error messages in modules
- [ ] Add more dev shells (Java, PHP, etc)
- [ ] Expand lib/ with helpers

### 🟢 Low Priority

- [ ] Create tests/ directory
- [ ] Add CI/CD enhancements
- [ ] Performance profiling
- [ ] Create module templates
- [ ] Visual dependency graph

### 💡 Ideas / Future

- [ ] Home-manager integration
- [ ] Multi-user support
- [ ] Automated backups
- [ ] [ANOTAR: Suas ideias]

---

## Notas de Sessão

### Session 1 (2025-11-01)
- ✅ Planning docs created
- ✅ Module aggregators (6 default.nix)
- ✅ Aliases reorganized (16 files)
- ✅ Desktop IP updated (.6 → .7)

### Session 2 (2025-11-02)
- ✅ Repository cleanup (nixtrap archived)
- ✅ Docs organized (docs/guides, docs/reports)
- ✅ Root README.md created
- ✅ Conflicts resolved (aliases, syntax)
- ✅ i3 WM module created
- ✅ Multi-host guide created
- ✅ SSH config module created

### Session 3 (Future)
- [ ] [ANOTAR: ]

---

## Comandos Úteis

```bash
# Generate tree diagram
./scripts/generate-tree-diagram.sh

# View tree
cat ARCHITECTURE-TREE.txt

# Find all .nix files
find . -name '*.nix' -not -path '*/archive/*' | sort

# Count modules
find modules/ -name '*.nix' | wc -l

# Search for option definitions
grep -r "mkOption" modules/

# Find TODOs
grep -r "TODO\|FIXME" modules/ docs/
```

---

## Referências

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Home Manager](https://github.com/nix-community/home-manager)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

---

**Last Updated:** 2025-11-02
**Maintained By:** kernelcore
**Repository:** /etc/nixos
**Status:** 🟢 Active Development
