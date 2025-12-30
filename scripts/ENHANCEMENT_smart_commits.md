# 🚀 Enhancement: Smart Commit Integration for Showcase Projects

## Ideia Original
Integrar `smart-commit.py` com `sync-showcase-projects.sh` para gerar commits contextuais e inteligentes baseados nas mudanças reais de cada projeto.

## Proposta de Implementação

### 1. Commits Inteligentes por Projeto
Ao invés de:
```
chore: sync showcase project - 2025-12-30
```

Teríamos:
```
feat(ml-offload): add GPU memory optimization for llama.cpp
refactor(nixos-hyperlab): migrate to nix2container v2
docs(shadow-debug): update privacy patterns documentation
```

### 2. Bulk Commits por Categoria
Agrupar projetos relacionados em commits batch:

**Categoria: ML/AI Projects**
- ml-offload-api
- ai-agent-os
- (outros ML-related)

**Categoria: Security & SIEM**
- securellm-mcp
- securellm-bridge
- O.W.A.S.A.K.A.
- phantom

**Categoria: Infrastructure & DevOps**
- nixos-hyperlab
- docker-hub
- vmctl
- swissknife

**Categoria: Development Tools**
- shadow-debug-pipeline
- arch-analyzer
- notion-exporter
- cognitive-vault

### 3. Workflow Proposto

```bash
# Para cada categoria:
for category in ml security infra devtools; do
  # Collect all changed files from projects in this category
  changed_files=$(get_changes_for_category $category)
  
  # Generate smart commit message using llamacpp-turbo
  commit_msg=$(smart-commit.py analyze --files $changed_files --category $category)
  
  # Single commit for all projects in category
  git commit -m "$commit_msg"
done
```

### 4. Exemplo de Output Esperado

```
🚀 Git Commit & Smart Analysis for All Projects

════════════════════════════════════════════════
🧠 Category: ML/AI Projects (3 projects)
════════════════════════════════════════════════
  → Analyzing changes...
  → ai-agent-os: +247 -15 (Rust workspace updates)
  → ml-offload-api: +89 -23 (API endpoint changes)
  
  💡 Generated commit message:
  ┌────────────────────────────────────────────┐
  │ feat(ml): enhance GPU orchestration        │
  │                                            │
  │ - Add dynamic VRAM allocation in ai-agent │
  │ - Optimize offload API response times     │
  │ - Update Rust dependencies to latest      │
  └────────────────────────────────────────────┘
  
  ✓ Committed

════════════════════════════════════════════════
🔒 Category: Security & SIEM (4 projects)
════════════════════════════════════════════════
  → No changes detected, skipping...
```

## Integração Técnica

### Script Structure
```bash
#!/usr/bin/env bash
# sync-showcase-projects-smart.sh

# 1. Define project categories
declare -A CATEGORIES=(
  ["ml"]="ml-offload-api ai-agent-os"
  ["security"]="securellm-mcp securellm-bridge O.W.A.S.A.K.A. phantom"
  ["infra"]="nixos-hyperlab docker-hub vmctl swissknife"
  ["devtools"]="shadow-debug-pipeline arch-analyzer notion-exporter"
)

# 2. For each category with changes
for category in "${!CATEGORIES[@]}"; do
  projects=(${CATEGORIES[$category]})
  
  # Collect diff context from all projects
  context=""
  for project in "${projects[@]}"; do
    if has_changes "$project"; then
      context+=$(git -C "/home/kernelcore/dev/projects/$project" diff HEAD)
    fi
  done
  
  # Skip if no changes
  [[ -z "$context" ]] && continue
  
  # Generate smart commit via llamacpp
  commit_msg=$(echo "$context" | smart-commit.py --category "$category")
  
  # Stage and commit all projects in category
  for project in "${projects[@]}"; do
    git -C "/home/kernelcore/dev/projects/$project" add .
    git -C "/home/kernelcore/dev/projects/$project" commit -m "$commit_msg" || true
  done
done
```

## Benefits

1. **Contexto real**: Mensagens baseadas em mudanças efetivas, não genéricas
2. **Histórico legível**: Git log mostra evolução real de cada categoria
3. **Bulk efficiency**: Menos commits, mais significativos
4. **AI-powered**: Aproveita LLM local para análise semântica
5. **Categorização**: Organiza projetos logicamente

## Considerações

- **Performance**: Analisar diffs de 16 projetos pode levar tempo
- **Token limit**: LLMs têm limite de contexto - agrupar ajuda
- **Fallback**: Manter commit genérico se LLM falhar
- **Privacy**: Continua 100% local (llamacpp-turbo)

## Next Steps

1. [ ] Criar `sync-showcase-projects-smart.sh` como PoC
2. [ ] Testar com categoria ML (menor grupo)
3. [ ] Validar qualidade das mensagens geradas
4. [ ] Comparar com commits manuais
5. [ ] Se bem-sucedido, substituir script atual

## Priority

**Medium** - Enhancement nice-to-have, não blocker. Script atual já funciona bem.

---

*Ideia sugerida em: 2025-12-30 09:25 BRT*  
*Status: Proposta/Design*
