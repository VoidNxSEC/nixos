# MCP Knowledge System - Guia Rápido

> **Como Usar**: Peça ao Claude para executar estes comandos
> **Localização**: Ferramentas MCP do securellm-bridge
> **Status**: ✅ Operacional (12 tools disponíveis)

---

## 📚 Comandos de Conhecimento (Knowledge Management)

### 1. Listar Sessões Recentes

**Uso**: Ver histórico de sessões de trabalho

```
Claude, liste as últimas 10 sessões MCP
```

**Comando técnico**:
```
mcp__securellm-bridge__list_sessions
  limit: 10
```

**Output**: Lista de sessões com ID, timestamp, summary

---

### 2. Carregar Sessão Específica

**Uso**: Recuperar contexto completo de uma sessão anterior

```
Claude, carregue a sessão sess_c18130d20c39e3ba0ca49120780e2259
```

**Comando técnico**:
```
mcp__securellm-bridge__load_session
  session_id: "sess_c18130d20c39e3ba0ca49120780e2259"
```

**Output**: Todas as entradas (insights, decisions, code, references) da sessão

---

### 3. Buscar no Conhecimento

**Uso**: Pesquisar em todas as sessões salvas

```
Claude, busque no conhecimento: "refatoramento ML arquitetura"
```

**Comando técnico**:
```
mcp__securellm-bridge__search_knowledge
  query: "refatoramento ML arquitetura"
  limit: 10
```

**Tips**:
- Use palavras-chave específicas
- Suporta operadores: AND, OR, NOT
- Evite caracteres especiais como `/`

---

### 4. Ver Conhecimento Recente

**Uso**: Ver as últimas entradas salvas (qualquer sessão)

```
Claude, mostre os últimos 20 conhecimentos salvos
```

**Comando técnico**:
```
mcp__securellm-bridge__get_recent_knowledge
  limit: 20
```

**Output**: Últimas entradas ordenadas por timestamp

---

### 5. Criar Nova Sessão

**Uso**: Iniciar nova sessão de trabalho

```
Claude, crie uma nova sessão MCP para "Implementar GPU offload"
```

**Comando técnico**:
```
mcp__securellm-bridge__create_session
  summary: "Implementar GPU offload"
  metadata: { "project": "ml-offload" }
```

---

### 6. Salvar Conhecimento

**Uso**: Salvar informação importante (Claude faz automaticamente, mas você pode pedir)

```
Claude, salve esta decisão: "Usar Rust para API de offload"
```

**Comando técnico**:
```
mcp__securellm-bridge__save_knowledge
  content: "Usar Rust para API de offload"
  type: "decision"
  tags: ["rust", "api", "offload"]
  priority: "high"
```

**Tipos disponíveis**:
- `insight` - Descoberta ou percepção importante
- `code` - Snippet de código ou implementação
- `decision` - Decisão arquitetural ou de design
- `reference` - Referência técnica ou link
- `question` - Pergunta pendente
- `answer` - Resposta a pergunta anterior

---

## 🛠️ Comandos de Desenvolvimento (Dev Tools)

### 7. Testar Provedor LLM

```
Claude, teste o provedor deepseek com "Hello World"
```

**Comando técnico**:
```
mcp__securellm-bridge__provider_test
  provider: "deepseek"
  prompt: "Hello World"
  model: "deepseek-chat" (opcional)
```

---

### 8. Auditoria de Segurança

```
Claude, rode auditoria de segurança no config.toml
```

**Comando técnico**:
```
mcp__securellm-bridge__security_audit
  config_file: "/path/to/config.toml"
```

---

### 9. Verificar Rate Limits

```
Claude, verifique rate limits do OpenAI
```

**Comando técnico**:
```
mcp__securellm-bridge__rate_limit_check
  provider: "openai"
```

---

### 10. Build e Test

```
Claude, rode build e testes no projeto
```

**Comando técnico**:
```
mcp__securellm-bridge__build_and_test
  test_type: "all"  # ou "unit", "integration"
```

---

## 💡 Frases Úteis (Copiar e Colar)

### Resumir Sessão Atual
```
Claude, resuma nossa sessão atual e salve no knowledge base
```

### Recuperar Contexto de Ontem
```
Claude, liste as sessões de ontem e mostre a mais recente
```

### Buscar Decisões Anteriores
```
Claude, busque no knowledge todas as decisões sobre "security"
```

### Ver Progresso do Projeto
```
Claude, mostre todo conhecimento relacionado ao projeto ML
```

### Criar Snapshot de Trabalho
```
Claude, crie uma sessão MCP e salve tudo que fizemos hoje como reference
```

---

## 📊 Estrutura de Sessão MCP

```
Sessão MCP
├── Session ID (único)
│   sess_c18130d20c39e3ba0ca49120780e2259
│
├── Entries (múltiplas)
│   ├── Entry 1: type=insight, priority=high
│   ├── Entry 2: type=decision, tags=[rust, api]
│   ├── Entry 3: type=code
│   └── Entry N: type=reference
│
└── Metadata
    ├── timestamp
    ├── summary
    └── project info
```

---

## 🎯 Casos de Uso Comuns

### Caso 1: Pausar Trabalho e Retomar Depois

**Pausar**:
```
Claude, crie um resumo final da sessão e salve como pause-point
```

**Retomar** (amanhã):
```
Claude, liste as sessões recentes
Claude, carregue a sessão sess_XXXXX
```

---

### Caso 2: Pesquisar Solução Anterior

```
Claude, busque no knowledge: "como resolver OOM builds"
```

---

### Caso 3: Revisar Decisões de Arquitetura

```
Claude, busque todas as entradas type=decision dos últimos 7 dias
```

---

### Caso 4: Criar Documentação de Projeto

```
Claude, carregue a sessão do refatoramento ML e crie um documento resumindo tudo
```

---

## ⚙️ Configuração

### Localização do Knowledge Database

```
/var/lib/mcp-knowledge/knowledge.db
```

### Backup do Knowledge Database

```bash
# Manual backup
sudo cp /var/lib/mcp-knowledge/knowledge.db \
        /backup/mcp-knowledge-$(date +%Y%m%d).db

# Restore
sudo cp /backup/mcp-knowledge-YYYYMMDD.db \
        /var/lib/mcp-knowledge/knowledge.db
```

### Verificar Saúde do MCP Server

```bash
bash /etc/nixos/scripts/mcp-health-check.sh
```

---

## 🔍 Debugging

### Se Busca Retorna Erro de Sintaxe

**Problema**: Caracteres especiais na query (/, -, etc)

**Solução**: Use palavras simples sem caracteres especiais
```
❌ "modules/ml refatoramento"
✅ "modules ml refatoramento"
```

### Se Sessão Não Carrega

**Problema**: Session ID inválido

**Solução**: Liste sessões primeiro
```
Claude, liste as últimas 20 sessões
```

---

## 📚 Documentação Relacionada

- **MCP Server Health**: `/etc/nixos/docs/MCP-SERVER-HEALTH-REPORT.md`
- **MCP Implementation**: `/etc/nixos/.claude/mcp-server-implementation.md`
- **MCP Architecture**: `/etc/nixos/docs/MCP-KNOWLEDGE-STABILIZATION.md`
- **Health Check Script**: `/etc/nixos/scripts/mcp-health-check.sh`

---

## 🚀 Próximos Passos

1. **Salve este guia**: Está em `/etc/nixos/docs/MCP-QUICK-REFERENCE.md`
2. **Teste os comandos**: Peça ao Claude para executá-los
3. **Crie aliases**: (próximo passo - script helper)

---

**Versão**: 1.0.0
**Data**: 2025-11-23
**Autor**: Claude
**Status**: ✅ Guia Completo
