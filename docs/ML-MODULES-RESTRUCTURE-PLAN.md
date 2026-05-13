# Plano de Reestruturação: modules/ml/

> **Status**: Rascunho - Reorganização Completa de ML Modules
> **Criado**: 2025-11-26
> **Objetivo**: Modularizar, eliminar sobreposição, melhorar manutenibilidade

---

## Resumo Executivo

A pasta `modules/ml/` contém infraestrutura ML crítica, mas sofre de:
- **Sobreposição funcional** entre componentes
- **Falta de hierarquia clara** (serviços vs infraestrutura vs aplicações)
- **Múltiplos pontos de entrada** sem agregação clara
- **Projetos grandes misturados** com módulos pequenos

Este plano propõe reorganizar em estrutura modular clara, separando:
- **Serviços ML** (llama.cpp, Ollama)
- **Infraestrutura** (storage, VRAM, offload)
- **Aplicações** (unified-llm/SecureLLM Bridge)
- **Integrações** (MCP servers, APIs)

---

## Análise da Estrutura Atual

### Estado Atual
```
modules/ml/
├── llama.nix                    # Serviço llama.cpp (207 linhas)
├── models-storage.nix           # Storage padronizado (130 linhas)
├── ollama-gpu-manager.nix       # Gerenciamento GPU Ollama (133 linhas)
├── mcp-config/                  # Configuração MCP
│   └── default.nix
├── offload/                     # Sistema unificado de offload
│   ├── default.nix             # Agregador principal
│   ├── manager.nix             # Gerenciador de offload
│   ├── model-registry.nix      # Registro de modelos
│   ├── vram-intelligence.nix   # Inteligência VRAM
│   ├── backends/               # Backends (Ollama, llama.cpp, vLLM, TGI)
│   │   └── default.nix
│   ├── api/                    # API REST Rust
│   │   ├── Cargo.toml
│   │   ├── src/
│   │   └── target/
│   ├── neovim/                 # Integração Neovim
│   └── flake.nix
└── unified-llm/                 # SecureLLM Bridge (projeto grande)
    ├── Cargo.toml
    ├── CLAUDE.md               # 807 linhas de docs
    ├── crates/
    │   ├── core/
    │   ├── security/
    │   ├── providers/
    │   ├── cli/
    │   └── api-server/
    ├── mcp-server/             # MCP Server TypeScript
    │   ├── src/
    │   ├── package.json
    │   └── knowledge.db
    ├── docs/
    ├── examples/
    ├── docker/
    └── flake.nix
```

### Métricas
- **Total de arquivos .nix no ml/**: 6 arquivos raiz + múltiplos subdiretórios
- **Maior projeto**: unified-llm/ (~1.5MB, projeto Rust completo)
- **API Rust duplicada**: offload/api/ vs unified-llm/crates/api-server/
- **MCP servers**: 2 instâncias (mcp-config/ + unified-llm/mcp-server/)
- **Build artifacts**: target/ com 1.8MB em offload/api/

---

## Problemas Identificados

### 🔴 Críticos

#### 1. Sobreposição Funcional: API Servers
**Problema**: Duas APIs Rust diferentes:
- `offload/api/` - API REST para offload (Python + Rust)
- `unified-llm/crates/api-server/` - API REST para SecureLLM Bridge

**Análise**:
- Ambas servem endpoints HTTP
- Ambas gerenciam providers LLM
- `offload/api/` foca em VRAM e model registry
- `unified-llm` foca em segurança e proxy LLM

**Decisão necessária**:
- **Opção A**: Manter separadas (propósitos diferentes)
- **Opção B**: Unificar em API single (mais complexo)
- **Opção C**: unified-llm consome offload/api como backend

#### 2. Sobreposição Funcional: GPU Management
**Problema**: Gerenciamento de GPU em múltiplos lugares:
- `ollama-gpu-manager.nix` - Auto-offload para Ollama
- `offload/vram-intelligence.nix` - VRAM monitoring geral
- `unified-llm` - Provider-aware resource management

**Conflito**: Múltiplos sistemas tentando gerenciar mesma GPU

#### 3. MCP Servers Duplicados
**Problema**:
- `mcp-config/default.nix` - Config MCP genérica
- `unified-llm/mcp-server/` - MCP server completo (TypeScript)

**Análise**:
- `mcp-config/` parece stub ou config
- `unified-llm/mcp-server/` é implementação completa
- Unclear qual é usado

#### 4. Projeto Grande Dentro de modules/
**Problema**: `unified-llm/` é projeto standalone completo:
- Workspace Cargo multi-crate
- Sistema de build próprio (flake.nix)
- Documentação extensa (CLAUDE.md)
- Docker, examples, testes

**Questão**: Deveria estar em `/etc/nixos/modules/` ou em local separado?

### ⚠️ Alta Prioridade

#### 5. Falta de default.nix Principal
**Problema**: Nenhum `modules/ml/default.nix` agregando tudo
**Impacto**: Imports verbosos no flake.nix

#### 6. Build Artifacts no Repo
**Problema**:
- `offload/api/target/` (artifacts Rust)
- `unified-llm/target/` (artifacts Rust)
- `unified-llm/mcp-server/knowledge.db*` (database runtime)

**Risco**: Repo inchado, conflicts git

#### 7. Storage Management Fragmentado
**Problema**:
- `models-storage.nix` - Storage paths
- `offload/model-registry.nix` - Model registry DB
- Cada serviço tem seu path

**Resultado**: Confusion sobre onde modelos ficam

### 💡 Oportunidades

#### 8. Modularização Clara
**Oportunidade**: Separar em camadas:
- **Infraestrutura**: Storage, VRAM, hardware
- **Serviços**: llama.cpp, Ollama services
- **Orquestração**: Offload manager, registry
- **Aplicações**: SecureLLM Bridge
- **Integrações**: MCP servers, APIs

#### 9. Default.nix por Categoria
**Oportunidade**: Criar aggregators:
```nix
modules/ml/services/default.nix       # Agrega todos serviços ML
modules/ml/infrastructure/default.nix # Agrega storage, VRAM
modules/ml/applications/default.nix   # Agrega apps (unified-llm)
```

---

## Estrutura Proposta

### Opção A: Hierarquia por Função (Recomendado)

```
modules/ml/
├── default.nix                      # Agregador principal (NOVO)
│
├── infrastructure/                  # Infraestrutura base (NOVO)
│   ├── default.nix                 # Agrega infra
│   ├── storage.nix                 # models-storage.nix renomeado
│   ├── vram/                       # VRAM management (NOVO)
│   │   ├── default.nix
│   │   ├── monitoring.nix          # De offload/vram-intelligence.nix
│   │   └── scheduler.nix           # GPU scheduling logic
│   └── hardware/                   # Hardware config (NOVO)
│       └── cuda.nix                # CUDA/GPU specific
│
├── services/                        # Serviços ML (NOVO)
│   ├── default.nix                 # Agrega serviços
│   ├── llama-cpp.nix               # llama.nix renomeado
│   ├── ollama/                     # Ollama service + management (NOVO)
│   │   ├── default.nix
│   │   ├── service.nix             # Base Ollama service
│   │   └── gpu-manager.nix         # ollama-gpu-manager.nix movido
│   └── vllm.nix                    # vLLM service (FUTURO)
│
├── orchestration/                   # Orquestração & offload (NOVO)
│   ├── default.nix                 # De offload/default.nix
│   ├── manager.nix                 # De offload/manager.nix
│   ├── registry/                   # Model registry (NOVO)
│   │   ├── default.nix
│   │   ├── database.nix            # SQLite registry
│   │   └── discovery.nix           # Auto-discovery
│   ├── backends/                   # De offload/backends/
│   │   ├── default.nix
│   │   ├── ollama.nix
│   │   ├── llamacpp.nix
│   │   ├── vllm.nix
│   │   └── tgi.nix
│   └── api/                        # De offload/api/
│       ├── flake.nix
│       ├── Cargo.toml
│       └── src/
│
├── applications/                    # Apps standalone (NOVO)
│   ├── default.nix                 # Agrega apps
│   └── securellm-bridge/           # unified-llm/ renomeado
│       ├── flake.nix
│       ├── CLAUDE.md
│       ├── crates/
│       ├── mcp-server/
│       └── ...
│
└── integrations/                    # Integrações externas (NOVO)
    ├── default.nix
    ├── mcp/                        # MCP integration
    │   ├── default.nix             # De mcp-config/
    │   └── config.nix
    └── neovim/                     # De offload/neovim/
        └── README.md
```

### Opção B: Hierarquia Flat com Prefixos

```
modules/ml/
├── default.nix
├── core-storage.nix                # models-storage.nix
├── core-vram-monitoring.nix        # offload/vram-intelligence.nix
├── core-vram-scheduler.nix         # GPU scheduling
├── service-llamacpp.nix            # llama.nix
├── service-ollama.nix              # Ollama service
├── service-ollama-gpu.nix          # ollama-gpu-manager.nix
├── orchestration-manager.nix       # offload/manager.nix
├── orchestration-registry.nix      # offload/model-registry.nix
├── orchestration-backends.nix      # offload/backends/
├── app-securellm-bridge/           # unified-llm/
└── integration-mcp/                # mcp-config/
```

**Análise de Opções**:
- **Opção A**: Mais clara hierarquia, melhor escalabilidade
- **Opção B**: Mais flat, mais fácil encontrar arquivos específicos
- **Recomendação**: **Opção A** para melhor organização a longo prazo

---

## Decisões Arquiteturais

### Decisão 1: unified-llm/ Location

**Pergunta**: unified-llm/ deve ficar em `modules/ml/` ou mover para `/etc/nixos/apps/`?

**Opções**:
1. **Manter em modules/ml/applications/** - É infraestrutura ML
2. **Mover para /etc/nixos/apps/** - É aplicação standalone
3. **Mover para /etc/nixos/services/** - É serviço system-wide

**Recomendação**: **Opção 1** - Manter em `modules/ml/applications/securellm-bridge/`
- Faz parte da stack ML
- Integra com offload/
- Não é app user-space (é infraestrutura)

### Decisão 2: APIs Rust - Merge ou Separar?

**Pergunta**: Unificar `offload/api/` e `unified-llm/crates/api-server/`?

**Análise**:
- `offload/api/` - VRAM monitoring, model registry, backend management
- `unified-llm/api-server/` - Secure LLM proxy, rate limiting, audit

**Propósitos diferentes**:
- offload/api → **Internal management API** (VRAM, models, backends)
- unified-llm → **External proxy API** (secure LLM access)

**Recomendação**: **Manter separadas**
- unified-llm pode **consumir** offload/api como backend
- offload/api = infraestrutura interna
- unified-llm = gateway externo

**Integração**:
```rust
// unified-llm/crates/providers/src/local.rs
pub struct LocalProvider {
    offload_api_client: OffloadApiClient, // http://localhost:9000
}

impl LocalProvider {
    async fn check_vram(&self) -> Result<VramState> {
        self.offload_api_client.get("/vram/status").await
    }
}
```

### Decisão 3: GPU Management - Centralizar ou Distribuir?

**Pergunta**: Centralizar VRAM management ou deixar por serviço?

**Análise atual**:
- `ollama-gpu-manager.nix` - Ollama-specific idle detection
- `offload/vram-intelligence.nix` - Generic VRAM monitoring
- Potential conflicts se ambos tentam gerenciar GPU

**Recomendação**: **Arquitetura em camadas**

```
┌───────────────────────────────────────────┐
│  infrastructure/vram/scheduler.nix        │  ← Central scheduler
│  (Single source of truth para GPU)        │
└─────────────────┬─────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼────┐  ┌────▼─────┐  ┌───▼─────┐
│ Ollama │  │llama.cpp │  │  vLLM   │  ← Services request GPU
└────────┘  └──────────┘  └─────────┘
```

**Implementação**:
- `infrastructure/vram/scheduler.nix` - Central VRAM scheduler
- Services registram com scheduler
- Scheduler aloca VRAM baseado em prioridade
- `ollama-gpu-manager` se torna client do scheduler

### Decisão 4: MCP Servers

**Pergunta**: Quantos MCP servers manter?

**Análise**:
- `mcp-config/default.nix` - Parece config stub
- `unified-llm/mcp-server/` - Full TypeScript implementation

**Recomendação**: **Single MCP server em integrations/**

```
modules/ml/integrations/mcp/
├── default.nix              # Config Nix
├── server/                  # unified-llm/mcp-server/ movido
│   ├── src/
│   ├── package.json
│   └── knowledge.db
└── config.nix               # mcp-config merged
```

---

## Plano de Migração

### Fase 1: Preparação (Dia 1)

#### 1.1 Backup & Git Tag
```bash
# Tag estado atual
git tag -a ml-restructure-pre -m "Before ML modules restructure"
git push origin ml-restructure-pre

# Backup completo
sudo cp -a /etc/nixos/modules/ml /etc/nixos/modules/ml.backup-$(date +%Y%m%d)
```

#### 1.2 Criar Nova Estrutura (Diretórios Vazios)
```bash
cd /etc/nixos/modules/ml

# Criar nova hierarquia
mkdir -p infrastructure/{vram,hardware}
mkdir -p services/ollama
mkdir -p orchestration/{registry,backends,api}
mkdir -p applications
mkdir -p integrations/{mcp/server,neovim}
```

#### 1.3 Criar Aggregators (default.nix)
```bash
# Criar todos os default.nix necessários
touch default.nix
touch infrastructure/default.nix
touch services/default.nix
touch orchestration/default.nix
touch applications/default.nix
touch integrations/default.nix
```

### Fase 2: Migração de Arquivos (Dia 2-3)

#### 2.1 Infrastructure Layer
```bash
# Storage
git mv modules/ml/models-storage.nix modules/ml/infrastructure/storage.nix

# VRAM
git mv modules/ml/offload/vram-intelligence.nix modules/ml/infrastructure/vram/monitoring.nix

# Criar scheduler novo (não existe ainda)
# TODO: Extrair scheduling logic do offload/manager.nix
```

#### 2.2 Services Layer
```bash
# LLaMA C++
git mv modules/ml/llama.nix modules/ml/services/llama-cpp.nix

# Ollama
git mv modules/ml/ollama-gpu-manager.nix modules/ml/services/ollama/gpu-manager.nix

# Criar Ollama service base
# TODO: Extrair do configuration.nix se existir
```

#### 2.3 Orchestration Layer
```bash
# Manager & Registry
git mv modules/ml/offload/manager.nix modules/ml/orchestration/manager.nix
git mv modules/ml/offload/model-registry.nix modules/ml/orchestration/registry/database.nix

# Backends
git mv modules/ml/offload/backends modules/ml/orchestration/backends

# API (manter estrutura)
git mv modules/ml/offload/api modules/ml/orchestration/api

# Cleanup offload flake
# Decidir: manter flake ou integrar no flake principal
```

#### 2.4 Applications Layer
```bash
# Unified LLM → SecureLLM Bridge
git mv modules/ml/unified-llm modules/ml/applications/securellm-bridge
```

#### 2.5 Integrations Layer
```bash
# MCP
git mv modules/ml/unified-llm/mcp-server modules/ml/integrations/mcp/server
git mv modules/ml/mcp-config modules/ml/integrations/mcp/config

# Neovim
git mv modules/ml/offload/neovim modules/ml/integrations/neovim
```

### Fase 3: Atualizar Imports (Dia 3-4)

#### 3.1 Criar default.nix Principal
```nix
# modules/ml/default.nix
{
  imports = [
    ./infrastructure
    ./services
    ./orchestration
    ./applications
    ./integrations
  ];
}
```

#### 3.2 Criar Aggregators por Layer
```nix
# modules/ml/infrastructure/default.nix
{
  imports = [
    ./storage.nix
    ./vram
    ./hardware
  ];
}

# modules/ml/services/default.nix
{
  imports = [
    ./llama-cpp.nix
    ./ollama
  ];
}

# modules/ml/orchestration/default.nix
{
  imports = [
    ./manager.nix
    ./registry
    ./backends
  ];
}

# modules/ml/applications/default.nix
{
  imports = [
    ./securellm-bridge
  ];
}

# modules/ml/integrations/default.nix
{
  imports = [
    ./mcp
    ./neovim
  ];
}
```

#### 3.3 Atualizar flake.nix
```nix
# /etc/nixos/flake.nix

# DE:
./modules/ml/llama.nix
./modules/ml/models-storage.nix
./modules/ml/ollama-gpu-manager.nix
./modules/ml/offload
./modules/ml/unified-llm

# PARA:
./modules/ml  # Single import!
```

#### 3.4 Atualizar Referências Internas
```bash
# Procurar todos imports que referenciam paths antigos
grep -r "modules/ml/llama.nix" /etc/nixos --include="*.nix"
grep -r "modules/ml/offload" /etc/nixos --include="*.nix"
grep -r "modules/ml/unified-llm" /etc/nixos --include="*.nix"

# Atualizar cada referência encontrada
```

### Fase 4: Validação & Testes (Dia 4-5)

#### 4.1 Validar Sintaxe
```bash
# Check flake
nix flake check

# Se falhar, usar --show-trace
nix flake check --show-trace
```

#### 4.2 Build Test
```bash
# Build sem aplicar
sudo nixos-rebuild build --flake /etc/nixos#kernelcore

# Verificar que gerou derivation
ls -la /nix/store/*-nixos-system-*/
```

#### 4.3 Verificar Imports
```bash
# Listar todas imports que serão incluídas
nix-instantiate --eval --strict -E '
  with import <nixpkgs> {};
  (import /etc/nixos/flake.nix).nixosConfigurations.kernelcore.imports
'
```

#### 4.4 Dry-Run Activation
```bash
# Dry activation para ver mudanças
sudo nixos-rebuild dry-activate --flake /etc/nixos#kernelcore
```

### Fase 5: Deploy (Dia 5)

#### 5.1 Rebuild & Switch
```bash
# Rebuild final
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Watch journal para erros
sudo journalctl -xef
```

#### 5.2 Verificar Serviços
```bash
# Check ML services
systemctl status llamacpp
systemctl status ollama
systemctl status ml-offload-api
systemctl status ollama-gpu-idle-monitor

# Check VRAM
nvidia-smi
```

#### 5.3 Testar Funcionalidade
```bash
# Test llama.cpp
curl http://127.0.0.1:8080/health

# Test Ollama
ollama list

# Test offload API
curl http://localhost:9000/health

# Test unified-llm (se enabled)
# ...
```

### Fase 6: Cleanup (Dia 6)

#### 6.1 Remover Diretórios Antigos
```bash
# Remover offload/ vazio (se tudo foi movido)
rmdir /etc/nixos/modules/ml/offload

# Remover mcp-config/ vazio
rmdir /etc/nixos/modules/ml/mcp-config

# Verificar que nada foi esquecido
find /etc/nixos/modules/ml -maxdepth 1 -type f -name "*.nix"
```

#### 6.2 Limpar Build Artifacts
```bash
# Adicionar ao .gitignore
echo "modules/ml/**/target/" >> /etc/nixos/.gitignore
echo "modules/ml/**/*.db" >> /etc/nixos/.gitignore
echo "modules/ml/**/*.db-shm" >> /etc/nixos/.gitignore
echo "modules/ml/**/*.db-wal" >> /etc/nixos/.gitignore

# Remover artifacts existentes
rm -rf modules/ml/orchestration/api/target
rm -rf modules/ml/applications/securellm-bridge/target
rm -rf modules/ml/integrations/mcp/server/*.db*
```

#### 6.3 Commit Migração
```bash
cd /etc/nixos

git add modules/ml/
git commit -m "refactor(ml): Complete ML modules restructure

## Changes:

### New Hierarchical Structure
Created clear separation by function:
- infrastructure/ - Storage, VRAM, hardware
- services/ - llama.cpp, Ollama services
- orchestration/ - Offload manager, registry, backends, API
- applications/ - SecureLLM Bridge (unified-llm renamed)
- integrations/ - MCP server, Neovim

### File Migrations
- llama.nix → services/llama-cpp.nix
- models-storage.nix → infrastructure/storage.nix
- ollama-gpu-manager.nix → services/ollama/gpu-manager.nix
- offload/vram-intelligence.nix → infrastructure/vram/monitoring.nix
- offload/manager.nix → orchestration/manager.nix
- offload/model-registry.nix → orchestration/registry/database.nix
- offload/backends → orchestration/backends
- offload/api → orchestration/api
- unified-llm → applications/securellm-bridge
- unified-llm/mcp-server → integrations/mcp/server
- mcp-config → integrations/mcp/config

### Benefits
✅ Clear module hierarchy by function
✅ Single import point (modules/ml)
✅ Eliminated overlapping functionality
✅ Better scalability for future additions
✅ Reduced flake.nix import verbosity (~5 imports → 1 import)

### Testing
- [x] nix flake check passed
- [x] nixos-rebuild build successful
- [x] All ML services started correctly
- [x] VRAM monitoring operational
- [x] No functional regressions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

#### 6.4 Tag Conclusão
```bash
git tag -a ml-restructure-complete -m "ML modules restructure completed"
git push origin ml-restructure-complete
```

### Fase 7: Documentação (Dia 7)

#### 7.1 Atualizar README
```bash
# Criar README principal
cat > modules/ml/README.md << 'EOF'
# ML Modules - Machine Learning Infrastructure

Modular ML infrastructure for NixOS with VRAM management, model orchestration, and secure LLM access.

## Structure

- **infrastructure/** - Storage, VRAM monitoring, hardware configs
- **services/** - ML services (llama.cpp, Ollama)
- **orchestration/** - Offload manager, model registry, backends
- **applications/** - Standalone ML apps (SecureLLM Bridge)
- **integrations/** - External integrations (MCP, Neovim)

## Quick Start

```nix
# Enable ML infrastructure
kernelcore.ml = {
  # Infrastructure
  models-storage.enable = true;

  # Services
  services.llamacpp.enable = true;
  services.ollama.enable = true;

  # Orchestration
  offload.enable = true;
};
```

See individual module READMEs for detailed configuration.
EOF
```

#### 7.2 Criar READMEs por Layer
```bash
# Infrastructure
touch modules/ml/infrastructure/README.md

# Services
touch modules/ml/services/README.md

# Orchestration
touch modules/ml/orchestration/README.md

# Applications
touch modules/ml/applications/README.md

# Integrations
touch modules/ml/integrations/README.md
```

#### 7.3 Atualizar CLAUDE.md Principal
```bash
# Atualizar /etc/nixos/CLAUDE.md com nova estrutura
# Adicionar seção sobre ML modules organization
```

---

## Rollback Strategy

### Se Problemas Ocorrerem

#### Opção 1: Git Reset
```bash
# Rollback git changes
git reset --hard ml-restructure-pre
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

#### Opção 2: System Rollback
```bash
# Rollback para geração anterior
sudo nixos-rebuild switch --rollback
```

#### Opção 3: Restore Backup
```bash
# Restaurar backup completo
sudo rm -rf /etc/nixos/modules/ml
sudo cp -a /etc/nixos/modules/ml.backup-YYYYMMDD /etc/nixos/modules/ml
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

---

## Métricas de Sucesso

### Após Migração Completa

**Estrutura**:
- ✅ Hierarquia clara por função (5 layers)
- ✅ Todos módulos com default.nix aggregator
- ✅ Zero sobreposição funcional
- ✅ Build artifacts removidos do repo

**Imports**:
- ✅ flake.nix imports reduzidos (5+ → 1)
- ✅ Todos imports relativos corretos
- ✅ Nenhum path absoluto hardcoded

**Funcionalidade**:
- ✅ Todos serviços ML funcionando
- ✅ VRAM monitoring operacional
- ✅ Model registry funcional
- ✅ SecureLLM Bridge operacional
- ✅ MCP server acessível

**Documentação**:
- ✅ README.md em cada layer
- ✅ CLAUDE.md atualizado
- ✅ Migration guide disponível

---

## Próximos Passos

### Após Reestruturação

1. **Implementar Central VRAM Scheduler** (infrastructure/vram/scheduler.nix)
   - Substituir GPU management distribuído
   - Single source of truth para GPU allocation

2. **Integrar unified-llm com offload/api**
   - LocalProvider consume offload API
   - Intelligent model selection baseado em VRAM

3. **Consolidar MCP Servers**
   - Single MCP server em integrations/mcp/
   - Tools para todos componentes ML

4. **Criar Testes Integrados**
   - Test suite para ML stack completa
   - Integration tests entre layers

5. **Performance Optimization**
   - Model loading time
   - VRAM allocation efficiency
   - API response times

---

## Questões para Resolução

Antes de executar migração, decidir:

1. **unified-llm location**: Manter em modules/ml/applications/ ou mover?
   - **Recomendação**: Manter (é infraestrutura ML)

2. **APIs Rust**: Unificar offload/api e unified-llm/api-server?
   - **Recomendação**: Manter separadas, unified-llm consome offload/api

3. **GPU Management**: Centralizar em scheduler único?
   - **Recomendação**: Sim, criar infrastructure/vram/scheduler.nix

4. **MCP Servers**: Quantos manter?
   - **Recomendação**: 1 em integrations/mcp/server/

5. **Build Artifacts**: Adicionar ao .gitignore?
   - **Recomendação**: Sim, target/ e *.db não devem estar no repo

6. **Flake Separation**: Manter flake.nix em subprojetos?
   - **Recomendação**: Sim para orchestration/api e applications/securellm-bridge

---

## Arquitetura Final Proposta

```
┌─────────────────────────────────────────────────────────────┐
│                    modules/ml/                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  infrastructure/                                     │   │
│  │  - storage.nix (model paths, directories)            │   │
│  │  - vram/monitoring.nix (VRAM metrics)                │   │
│  │  - vram/scheduler.nix (GPU allocation) ← CENTRAL     │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       │                                     │
│  ┌────────────────────▼────────────────────────────────┐   │
│  │  services/                                           │   │
│  │  - llama-cpp.nix (llama.cpp systemd service)         │   │
│  │  - ollama/service.nix (Ollama systemd)               │   │
│  │  - ollama/gpu-manager.nix (client do scheduler)      │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       │                                     │
│  ┌────────────────────▼────────────────────────────────┐   │
│  │  orchestration/                                      │   │
│  │  - manager.nix (offload orchestration)               │   │
│  │  - registry/ (model discovery & DB)                  │   │
│  │  - backends/ (Ollama, llama.cpp, vLLM, TGI)          │   │
│  │  - api/ (Rust REST API port 9000)                    │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       │                                     │
│  ┌────────────────────▼────────────────────────────────┐   │
│  │  applications/                                       │   │
│  │  - securellm-bridge/ (ex unified-llm)                │   │
│  │    - Secure LLM proxy                                │   │
│  │    - Consumes orchestration/api                      │   │
│  │    - Provides external API                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  integrations/                                       │   │
│  │  - mcp/server/ (MCP server TypeScript)               │   │
│  │  - mcp/config.nix (MCP configuration)                │   │
│  │  - neovim/ (Neovim integration)                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

**Versão do Documento**: 1.0.0
**Última Atualização**: 2025-11-26
**Mantido Por**: kernelcore
**Cronograma de Revisão**: Após cada fase de migração
