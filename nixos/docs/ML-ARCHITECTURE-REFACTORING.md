# Arquitetura ML - Refatoração 2025-11-22

> **Status**: 📋 Proposta Arquitetural
> **Objetivo**: Separar aplicações do monorepo NixOS
> **Impacto**: 3.8GB → 100KB em /etc/nixos/modules/ml/
> **Risco**: MEDIUM (mitigado com backups)

---

## 📊 Visão Executiva

### Problema Atual

```
❌ /etc/nixos/modules/ml/  [3.8GB]
   ├── Código de aplicação (Rust/TypeScript)
   ├── Build artifacts (2.8GB de target/)
   ├── Runtime data (knowledge.db)
   └── NixOS modules (apenas 32KB úteis)

⚠️ Impactos:
   - Build OOM (7GB+ RAM) → offload desabilitado
   - Git lento (3.8GB de arquivos)
   - Confusão arquitetural
   - Duplicação de código
```

### Solução Proposta

```
✅ Separação clara de responsabilidades:

/etc/nixos/modules/ml/          [~100KB]  → NixOS config
~/projects/securellm-bridge/    [git]     → Aplicação Rust/TS
~/projects/ml-offload-api/      [git]     → Aplicação Rust
/var/lib/                       [runtime] → Dados em execução

📈 Benefícios:
   - 97% redução de tamanho (3.8GB → 100KB)
   - Builds incrementais (sem OOM)
   - Desenvolvimento independente
   - Git history limpo
```

---

## 🏗️ Diagrama Arquitetural

### ANTES: Estrutura Atual (Problemática)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ /etc/nixos/modules/ml/                                      [3.8GB]     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────┐  ┌──────────────────────┐                    │
│  │  NixOS Modules       │  │  Application Code    │  ❌ MISTURADO      │
│  │  (~32KB)             │  │  (3.6GB+)            │                    │
│  ├──────────────────────┤  ├──────────────────────┤                    │
│  │ • llama.nix          │  │ unified-llm/         │                    │
│  │ • models-storage.nix │  │   ├── crates/        │                    │
│  │ • ollama-manager.nix │  │   ├── target/ [2.8GB]│  ❌ BUILD ARTIFACTS│
│  │ • mcp-config/        │  │   └── mcp-server/    │                    │
│  │                      │  │                      │                    │
│  │                      │  │ Security-Architect/  │  ❌ DUPLICADO?     │
│  │                      │  │   ├── crates/        │                    │
│  │                      │  │   └── target/ [352MB]│                    │
│  │                      │  │                      │                    │
│  │                      │  │ offload/             │  ⚠️ PARCIAL        │
│  │                      │  │   ├── api/ [Rust]    │  ❌ APP CODE       │
│  │                      │  │   └── *.nix          │  ✅ MODULES        │
│  └──────────────────────┘  └──────────────────────┘                    │
│                                                                         │
│  ┌──────────────────────────────────────────────┐                      │
│  │  Runtime Data (não deveria estar aqui!)      │  ❌ WRONG LOCATION  │
│  ├──────────────────────────────────────────────┤                      │
│  │ • unified-llm/mcp-server/knowledge.db        │                      │
│  │ • unified-llm/mcp-server/knowledge.db-wal    │                      │
│  │ • unified-llm/mcp-server/knowledge.db-shm    │                      │
│  └──────────────────────────────────────────────┘                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ Uso no flake.nix:                                                       │
├─────────────────────────────────────────────────────────────────────────┤
│  ✅ ./modules/ml/llama.nix                                              │
│  ✅ ./modules/ml/models-storage.nix                                     │
│  ✅ ./modules/ml/ollama-gpu-manager.nix                                 │
│  ❌ # ./modules/ml/offload  → DISABLED: OOM (7GB+ RAM)                  │
│                                                                         │
│  ❌ unified-llm/ → NÃO USADO                                            │
│  ❌ Security-Architect/ → NÃO USADO                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### DEPOIS: Arquitetura Proposta (Limpa)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ /etc/nixos/                                                             │
│ ├── flake.nix                                                           │
│ │   inputs:                                                             │
│ │     securellm-bridge → github:you/securellm-bridge                    │
│ │     ml-offload-api   → github:you/ml-offload-api                      │
│ │                                                                        │
│ └── modules/ml/                                          [~100KB]       │
│     ├── default.nix                        ✅ Aggregator                │
│     ├── llama.nix                          ✅ NixOS module              │
│     ├── models-storage.nix                 ✅ NixOS module              │
│     ├── ollama-gpu-manager.nix             ✅ NixOS module              │
│     ├── mcp.nix                            ✅ NixOS module (refactored) │
│     ├── securellm-bridge.nix               ✅ Thin wrapper (imports)    │
│     ├── ml-offload.nix                     ✅ Thin wrapper (imports)    │
│     └── offload/                                                        │
│         ├── backends/default.nix           ✅ Config                    │
│         ├── model-registry.nix             ✅ NixOS module              │
│         └── vram-intelligence.nix          ✅ NixOS module              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ ~/projects/securellm-bridge/                   [Separate Git Repo]     │
│ ├── flake.nix                                  ✅ Standalone build      │
│ ├── Cargo.{toml,lock}                          ✅ Rust workspace        │
│ ├── crates/                                                             │
│ │   ├── api-server/         → REST API                                 │
│ │   ├── cli/                → CLI interface                            │
│ │   ├── core/               → Core types                               │
│ │   ├── providers/          → LLM providers                            │
│ │   └── security/           → Security layer                           │
│ ├── mcp-server/                               ✅ TypeScript             │
│ │   ├── package.json                                                    │
│ │   ├── src/                                                            │
│ │   └── build/ (gitignored)                   ⚠️ Not committed          │
│ ├── docs/                                                               │
│ ├── .gitignore                                                          │
│ │   target/                                   ✅ Ignored                │
│ │   node_modules/                             ✅ Ignored                │
│ │   *.db                                      ✅ Ignored                │
│ └── README.md                                                           │
│                                                                         │
│ Outputs (via flake):                                                    │
│   packages.x86_64-linux.default      → securellm-bridge binary         │
│   packages.x86_64-linux.mcp-server   → MCP server                      │
│   packages.x86_64-linux.docker       → Docker image                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ ~/projects/ml-offload-api/                     [Separate Git Repo]     │
│ ├── flake.nix                                  ✅ Standalone build      │
│ ├── Cargo.{toml,lock}                          ✅ Rust project          │
│ ├── src/                                                                │
│ │   ├── main.rs                                                         │
│ │   ├── api.rs              → REST endpoints                           │
│ │   ├── backends.rs         → Backend management                       │
│ │   ├── vram.rs             → VRAM monitoring                          │
│ │   └── models.rs           → Model registry                           │
│ ├── .gitignore                                                          │
│ │   target/                                   ✅ Ignored                │
│ └── README.md                                                           │
│                                                                         │
│ Outputs (via flake):                                                    │
│   packages.x86_64-linux.default      → ml-offload-api binary           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ /var/lib/                                      [Runtime Data]           │
│ ├── mcp-knowledge/                             ✅ Proper location       │
│ │   ├── knowledge.db                           ✅ SQLite DB             │
│ │   ├── knowledge.db-wal                                                │
│ │   └── knowledge.db-shm                                                │
│ ├── ml-offload/                                                         │
│ │   ├── registry.db                            ✅ Model registry        │
│ │   └── logs/                                                           │
│ └── ml-models/                                 ✅ Model storage         │
│     ├── llamacpp/models/                                                │
│     ├── ollama/models/                                                  │
│     ├── huggingface/hub/                                                │
│     └── cache/                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ Integration Pattern: Flake Inputs                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  /etc/nixos/flake.nix:                                                  │
│  {                                                                      │
│    inputs.securellm-bridge.url = "github:you/securellm-bridge";        │
│    inputs.ml-offload-api.url = "github:you/ml-offload-api";            │
│                                                                         │
│    outputs = { securellm-bridge, ml-offload-api, ... }: {              │
│      nixosConfigurations.kernelcore = {                                │
│        modules = [ ./modules/ml ];  # ← Imports default.nix            │
│      };                                                                 │
│    };                                                                   │
│  }                                                                      │
│                                                                         │
│  /etc/nixos/modules/ml/securellm-bridge.nix:                            │
│  { inputs, ... }:                                                       │
│  {                                                                      │
│    systemd.services.mcp-server = {                                     │
│      ExecStart = "${inputs.securellm-bridge.packages.mcp-server}/bin"; │
│      Environment = "KNOWLEDGE_DB_PATH=/var/lib/mcp-knowledge/...";     │
│    };                                                                   │
│  }                                                                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Dados e Integração

### Build Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Developer Workflow                                                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1️⃣ Trabalhar em securellm-bridge:                                      │
│     cd ~/dev/securellm-bridge                                            │
│     nix develop                    → Rust + Node.js env                 │
│     cargo build                    → Build incremental (local target/)  │
│     cargo test                                                           │
│     git commit && git push                                               │
│                                                                          │
│  2️⃣ Atualizar NixOS:                                                     │
│     cd /etc/nixos                                                        │
│     nix flake update securellm-bridge  → Update flake.lock              │
│     sudo nixos-rebuild switch          → Rebuild system                 │
│                                                                          │
│  ✅ Benefício: Builds separados, sem OOM                                 │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│ CI/CD Flow                                                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  securellm-bridge repo:                                                 │
│    GitHub Actions → nix build .#default                                 │
│                  → nix build .#mcp-server                               │
│                  → cargo test                                           │
│                  → Push to cachix (binary cache)                        │
│                                                                          │
│  /etc/nixos repo:                                                        │
│    GitHub Actions → nix flake check                                     │
│                  → nix build .#iso                                      │
│                  → Use cached builds from cachix                        │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### Runtime Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│ System Runtime                                                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  systemd services:                                                       │
│                                                                          │
│  llamacpp.service                                                        │
│    ↓ Configured by: /etc/nixos/modules/ml/llama.nix                     │
│    ↓ Binary: nixpkgs.llama-cpp                                           │
│    ↓ Runs on: http://localhost:8080                                     │
│    ↓ Models: /var/lib/ml-models/llamacpp/                               │
│                                                                          │
│  ollama.service                                                          │
│    ↓ Configured by: nixpkgs + ollama-gpu-manager.nix                    │
│    ↓ Binary: nixpkgs.ollama                                              │
│    ↓ Runs on: http://localhost:11434                                    │
│    ↓ Models: /var/lib/ml-models/ollama/                                 │
│    ↓ Auto-offload: ollama-gpu-idle-monitor.service                      │
│                                                                          │
│  mcp-server.service                                                      │
│    ↓ Configured by: /etc/nixos/modules/ml/securellm-bridge.nix          │
│    ↓ Binary: inputs.securellm-bridge.packages.mcp-server                │
│    ↓ Socket: stdio (used by VSCodium/Cline)                             │
│    ↓ Knowledge DB: /var/lib/mcp-knowledge/knowledge.db                  │
│    ↓ Tools: 12 tools (provider_test, security_audit, etc.)              │
│                                                                          │
│  ml-offload-api.service                                                  │
│    ↓ Configured by: /etc/nixos/modules/ml/ml-offload.nix                │
│    ↓ Binary: inputs.ml-offload-api.packages.default                     │
│    ↓ Runs on: http://localhost:9000                                     │
│    ↓ Registry: /var/lib/ml-offload/registry.db                          │
│    ↓ Monitors: VRAM, backends (ollama, llama.cpp)                       │
│                                                                          │
│  Integration:                                                            │
│    securellm-bridge → ml-offload-api → ollama/llama.cpp                 │
│    IDE (VSCodium) → MCP server → knowledge DB                            │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Componentes Detalhados

### 1. securellm-bridge (ex unified-llm)

```
Tipo: Aplicação Rust + TypeScript
Propósito: Proxy LLM seguro com MCP server
Output: Binários + MCP server

Estrutura:
~/dev/securellm-bridge/
├── flake.nix                    → Builds tudo
│   outputs:
│     packages.default           → securellm-bridge CLI
│     packages.mcp-server        → MCP server (Node.js)
│     packages.api-server        → REST API server
│     packages.docker            → Docker image
│     devShells.default          → Rust + Node.js
│
├── crates/
│   ├── core/                    → Types, traits, interfaces
│   ├── security/                → TLS, rate limiting, audit
│   ├── providers/               → DeepSeek, OpenAI, Anthropic
│   ├── cli/                     → CLI commands
│   └── api-server/              → REST API (opcional)
│
├── mcp-server/                  → TypeScript MCP implementation
│   ├── src/
│   │   ├── index.ts
│   │   ├── tools/               → 12 MCP tools
│   │   ├── knowledge/           → Knowledge system
│   │   └── providers/           → Provider integrations
│   └── package.json
│
└── docs/
    ├── ARCHITECTURE.md
    ├── SECURITY.md
    └── API.md

Integration with NixOS:
- Imported via flake input
- Deployed via systemd service (mcp-server.service)
- Config in /etc/nixos/modules/ml/securellm-bridge.nix
```

### 2. ml-offload-api (ex offload/api/)

```
Tipo: Aplicação Rust
Propósito: API de offload de ML para desktop
Output: Binário ml-offload-api

Estrutura:
~/dev/ml-offload-api/
├── flake.nix                    → Build setup
│   outputs:
│     packages.default           → ml-offload-api
│     devShells.default          → Rust + Python (dev)
│
├── src/
│   ├── main.rs                  → Entry point
│   ├── api.rs                   → REST endpoints
│   │   GET  /health
│   │   GET  /health/vram
│   │   GET  /v1/models
│   │   POST /v1/chat/completions
│   │   POST /v1/completions
│   │
│   ├── backends.rs              → Backend management
│   │   - Ollama (localhost:11434)
│   │   - llama.cpp (localhost:8080)
│   │   - vLLM (futuro)
│   │
│   ├── vram.rs                  → VRAM monitoring (nvidia-smi)
│   ├── models.rs                → Model registry & selection
│   └── db.rs                    → SQLite registry
│
└── Cargo.toml

Dependencies:
- axum (REST API)
- tokio (async runtime)
- sqlx (database)
- sysinfo (system monitoring)

Integration with NixOS:
- Imported via flake input
- Deployed via systemd service (ml-offload-api.service)
- Config in /etc/nixos/modules/ml/ml-offload.nix
- Uses NVIDIA tools (via LD_LIBRARY_PATH)
```

### 3. NixOS Modules (thin wrappers)

```
/etc/nixos/modules/ml/

default.nix                      → Aggregator, imports all
llama.nix                        → systemd service (llama-cpp)
models-storage.nix               → Diretórios + env vars
ollama-gpu-manager.nix           → Auto-offload + monitoring

securellm-bridge.nix             → Wrapper for flake input
  - Imports: inputs.securellm-bridge.packages.*
  - Creates: systemd.services.mcp-server
  - Sets: /var/lib/mcp-knowledge/ paths
  - Groups: mcp-shared

ml-offload.nix                   → Wrapper for flake input
  - Imports: inputs.ml-offload-api.packages.default
  - Creates: systemd.services.ml-offload-api
  - Sets: /var/lib/ml-offload/ paths
  - Imports sub-modules:
      offload/backends/default.nix
      offload/model-registry.nix
      offload/vram-intelligence.nix

mcp.nix (refactored from mcp-config/)
  - Multi-agent MCP configuration
  - Shared knowledge DB setup
  - Per-agent workspace management
```

---

## 🎯 Componentes por Responsabilidade

### Layer 1: Infrastructure (NixOS)

```
Responsabilidade: Sistema operacional, serviços, usuários
Localização: /etc/nixos/modules/ml/

Componentes:
✅ llama.nix                    → systemd service
✅ models-storage.nix           → Filesystem structure
✅ ollama-gpu-manager.nix       → GPU memory management
✅ mcp.nix                      → MCP configuration

Características:
- Declarativo (Nix)
- Systemd services
- User/group management
- Filesystem permissions
```

### Layer 2: Applications (Separate Repos)

```
Responsabilidade: Lógica de negócio, ML inference
Localização: ~/projects/ (Git separado)

Componentes:
✅ securellm-bridge             → LLM proxy + MCP server
✅ ml-offload-api               → Offload API + VRAM mgmt

Características:
- Imperativo (Rust, TypeScript)
- Independent versioning
- CI/CD próprio
- Build artifacts gitignored
```

### Layer 3: Integration (Flake Inputs)

```
Responsabilidade: Conectar apps aos módulos NixOS
Localização: /etc/nixos/flake.nix + modules/ml/*.nix

Componentes:
✅ flake.nix inputs              → Import repos
✅ securellm-bridge.nix          → Thin wrapper module
✅ ml-offload.nix                → Thin wrapper module

Características:
- Flake inputs pattern
- Package imports
- Service configuration
- Minimal code (~50 LOC each)
```

### Layer 4: Runtime (System State)

```
Responsabilidade: Dados em execução, logs, cache
Localização: /var/lib/, /var/log/

Componentes:
✅ /var/lib/mcp-knowledge/       → Knowledge DB
✅ /var/lib/ml-offload/          → Registry + logs
✅ /var/lib/ml-models/           → Model files
✅ /var/log/securellm/           → Audit logs

Características:
- Persistent data
- Managed by systemd.tmpfiles
- Proper permissions (user:group)
- Backed up separately
```

---

## 📊 Comparação: Antes vs Depois

| Aspecto | ANTES ❌ | DEPOIS ✅ |
|---------|----------|-----------|
| **Tamanho /etc/nixos/modules/ml/** | 3.8GB | ~100KB |
| **Build artifacts commitados** | 3.1GB | 0 |
| **Código aplicação em NixOS** | Sim | Não |
| **Repositórios Git** | 1 (monorepo) | 3 (separados) |
| **Build OOM** | Sim (7GB+ RAM) | Não |
| **Runtime data localização** | /etc/nixos ❌ | /var/lib/ ✅ |
| **Módulos NixOS funcionais** | 3/7 | 7/7 |
| **Desenvolvimento independente** | Não | Sim |
| **CI/CD** | Acoplado | Paralelo |
| **Git clone time** | Lento (3.8GB) | Rápido (~10MB) |
| **Clareza arquitetural** | Baixa | Alta |

---

## 🚀 Próximos Passos

### Decisões Imediatas Necessárias

1. **Security-Architect**: Merge ou separar?
   - [ ] Compare crates/ com unified-llm
   - [ ] Se features únicas: merge para securellm-bridge
   - [ ] Se independente: extrair como repo separado
   - [ ] Após decisão: executar ação

2. **MCP Server Location**: Confirmar estrutura
   - [ ] Manter em securellm-bridge? (recomendado)
   - [ ] Ou criar repo separado mcp-server?

3. **Flake Input Strategy**: Local vs GitHub
   - [ ] Desenvolvimento: path-based inputs
   - [ ] Produção: github inputs
   - [ ] Configurar ambos no flake.nix

### Execução Sugerida

**Fase 1: Backup e Limpeza** (1-2 dias)
- Git tag: `pre-ml-refactor-2025-11-22`
- Backup completo
- Remove build artifacts (3.1GB)
- Move runtime data para /var/lib/

**Fase 2: Extração** (2-3 dias)
- Extrair securellm-bridge com git filter-repo
- Extrair ml-offload-api
- Push para GitHub

**Fase 3: Refatoração** (1-2 dias)
- Criar thin wrapper modules
- Atualizar flake.nix inputs
- Test rebuild

**Fase 4: Validação** (1 dia)
- Test todos os serviços
- Verify functionality
- Update documentation

---

## 📚 Referências Técnicas

**Padrões Arquiteturais**:
- Flake inputs: https://nixos.wiki/wiki/Flakes#Input_schema
- NixOS modules: https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules
- Systemd services: https://www.freedesktop.org/software/systemd/man/systemd.service.html

**Ferramentas**:
- git filter-repo: Extrair subpaths mantendo histórico
- nix flake: Gerenciamento de dependências
- systemd.tmpfiles: Runtime directory management

**Projetos Similares**:
- home-manager: Multi-repo com flake inputs
- NUR: Nix User Repository pattern
- devenv.sh: Development shell pattern

---

**Documento**: ML Architecture Refactoring
**Versão**: 1.0.0
**Data**: 2025-11-22
**Status**: ✅ Proposta Completa - Aguardando Aprovação
**Autor**: Claude (Modo Arquiteto)
