# Guia Completo: MCP Server + Claude Code CLI

**Data**: 2025-11-08
**Status**: ✅ Configuração Completa
**Versão**: 2.0.1

---

## 🎯 Visão Geral

O MCP (Model Context Protocol) Server permite que o Claude Code CLI acesse ferramentas adicionais para:
- Testar provedores LLM (DeepSeek, OpenAI, Anthropic, Ollama)
- Gerenciar conhecimento persistente (knowledge base)
- Diagnosticar e configurar pacotes Nix
- Auditar segurança
- Gerar certificados TLS

---

## ✅ Configuração Atual

### 1. MCP Server Status

O servidor MCP já está **configurado e operacional**:

```bash
# Localização do servidor
/etc/nixos/modules/ml/unified-llm/mcp-server/build/src/index.js

# Configuração
/etc/nixos/.mcp.json

# Status
✅ Auto-detecção de PROJECT_ROOT (/etc/nixos)
✅ Auto-detecção de hostname (kernelcore)
✅ Knowledge DB em ~/.local/share/securellm/knowledge.db
```

### 2. Ativar no Claude Code CLI

O MCP server será carregado **automaticamente** na próxima vez que você:

**Opção A: Reiniciar sessão do Claude Code**
```bash
# Saia da sessão atual
exit

# Inicie nova sessão
claude
```

**Opção B: Recarregar configuração** (se disponível)
```bash
# Dentro do Claude Code
/reload
```

### 3. Verificar Ferramentas Disponíveis

Após reiniciar, você verá as ferramentas MCP disponíveis:

```
🔧 Ferramentas MCP Disponíveis:
├── mcp__securellm-bridge__provider_test
├── mcp__securellm-bridge__security_audit
├── mcp__securellm-bridge__rate_limit_check
├── mcp__securellm-bridge__build_and_test
├── mcp__securellm-bridge__provider_config_validate
├── mcp__securellm-bridge__crypto_key_generate
├── mcp__securellm-bridge__rate_limiter_status
├── mcp__securellm-bridge__package_diagnose
├── mcp__securellm-bridge__package_download
├── mcp__securellm-bridge__package_configure
├── mcp__securellm-bridge__create_session
├── mcp__securellm-bridge__save_knowledge
├── mcp__securellm-bridge__search_knowledge
├── mcp__securellm-bridge__load_session
├── mcp__securellm-bridge__list_sessions
└── mcp__securellm-bridge__get_recent_knowledge
```

---

## 🤖 Configurar Provedores LLM

### Provedores Suportados

| Provedor | Status | Requer API Key | Uso |
|----------|--------|----------------|-----|
| **DeepSeek** | ✅ Configurado | Sim | Modelos econômicos (R1, Chat) |
| **OpenAI** | ✅ Configurado | Sim | GPT-4, GPT-3.5 |
| **Anthropic** | ✅ Configurado | Sim | Claude Sonnet, Opus |
| **Ollama** | ✅ Pronto | Não | Modelos locais (llama, mistral) |

### 1. Verificar API Keys Atuais

```bash
# Carregar API keys do sistema
source /etc/load-api-keys.sh

# Verificar se estão definidas
echo "Anthropic: ${ANTHROPIC_API_KEY:0:15}..."
echo "OpenAI: ${OPENAI_API_KEY:0:15}..."
echo "DeepSeek: ${DEEPSEEK_API_KEY:0:15}..."
```

### 2. Adicionar/Atualizar API Keys

As API keys estão armazenadas de forma segura com **SOPS**:

```bash
# Editar secrets
cd /etc/nixos
sops secrets/api-keys/anthropic.key
sops secrets/api-keys/openai.key
sops secrets/api-keys/deepseek.key

# Reconstruir sistema para aplicar
sudo nixos-rebuild switch
```

### 3. Testar Provedores via MCP

Dentro do Claude Code, você pode pedir para testar:

```
Me teste o provedor DeepSeek com uma mensagem simples
```

O Claude Code vai usar a ferramenta MCP:
```json
{
  "tool": "mcp__securellm-bridge__provider_test",
  "arguments": {
    "provider": "deepseek",
    "prompt": "Hello, how are you?",
    "model": "deepseek-chat"
  }
}
```

---

## 📚 Usar Knowledge Base

A Knowledge Base permite **persistir informações** entre sessões:

### Criar uma Sessão

```
Crie uma nova sessão de conhecimento para trabalhar em autenticação JWT
```

### Salvar Conhecimento

```
Salve este snippet de código como referência:
[seu código aqui]
```

### Buscar Conhecimento

```
Busque no conhecimento informações sobre JWT authentication
```

### Listar Sessões

```
Liste minhas sessões de conhecimento recentes
```

---

## 🔧 Ferramentas de Desenvolvimento

### 1. Diagnosticar Pacotes Nix

```
Diagnostique o pacote em modules/packages/tar-packages/lynis.nix
```

### 2. Baixar e Configurar Pacotes

```
Baixe o pacote lynis do GitHub release mais recente
```

### 3. Auditar Segurança

```
Execute uma auditoria de segurança no config.toml
```

---

## 🚀 Configuração Avançada

### Variáveis de Ambiente Opcionais

Adicione ao seu shell profile (`~/.bashrc` ou `~/.zshrc`):

```bash
# Forçar hostname específico (evita warning de múltiplos hosts)
export NIXOS_HOST_NAME=kernelcore

# Custom knowledge database location
export KNOWLEDGE_DB_PATH=/secure/path/knowledge.db

# Desabilitar knowledge management (se desejar)
export ENABLE_KNOWLEDGE=false

# Forçar PROJECT_ROOT (raramente necessário)
export PROJECT_ROOT=/etc/nixos
```

### Configuração para Múltiplos Ambientes

Se você trabalha em **múltiplos projetos Nix**:

```bash
# Projeto A
cd /path/to/project-a
export NIXOS_HOST_NAME=laptop
export KNOWLEDGE_DB_PATH=~/.local/share/securellm/project-a.db

# Projeto B
cd /path/to/project-b
export NIXOS_HOST_NAME=desktop
export KNOWLEDGE_DB_PATH=~/.local/share/securellm/project-b.db
```

O MCP server **auto-detecta** o PROJECT_ROOT baseado em onde o `flake.nix` está!

---

## 🔍 Troubleshooting

### MCP Server não aparece no Claude Code

```bash
# 1. Verificar configuração
cat /etc/nixos/.mcp.json

# 2. Testar servidor manualmente
cd /etc/nixos
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  node modules/ml/unified-llm/mcp-server/build/src/index.js

# 3. Verificar logs (stderr do Claude Code)
# Procure por: "MCP Server initialization complete"

# 4. Reconstruir servidor
cd /etc/nixos/modules/ml/unified-llm/mcp-server
npm run build
```

### Provedor LLM não funciona

```bash
# 1. Verificar API key está definida
source /etc/load-api-keys.sh
echo $DEEPSEEK_API_KEY

# 2. Testar provedor diretamente (Rust CLI)
cd /etc/nixos/modules/ml/unified-llm
cargo run --bin securellm -- test deepseek

# 3. Verificar rate limits
# Dentro do Claude Code: "Check rate limits for deepseek"
```

### Knowledge DB corrompido

```bash
# Backup e reset
mv ~/.local/share/securellm/knowledge.db \
   ~/.local/share/securellm/knowledge.db.bak

# Próxima execução cria novo DB
```

### Hostname errado detectado

```bash
# Verificar hosts disponíveis
cd /etc/nixos
grep -A10 "nixosConfigurations" flake.nix

# Forçar hostname correto
export NIXOS_HOST_NAME=kernelcore
```

---

## 📖 Exemplos de Uso

### Exemplo 1: Testar Múltiplos Provedores

```
Teste todos os provedores disponíveis (DeepSeek, OpenAI, Anthropic)
com a mensagem "Hello World" e compare os resultados
```

### Exemplo 2: Criar Sistema de Conhecimento

```
1. Crie uma sessão chamada "Rust API Development"
2. Salve este código como referência:
   [seu código Rust]
3. Salve esta decisão: "Usaremos Actix-Web ao invés de Rocket"
4. Liste todas as minhas sessões
```

### Exemplo 3: Gerenciar Pacotes Nix

```
1. Baixe o pacote 'bat' do GitHub (sharkdp/bat)
2. Configure-o como um tar package
3. Diagnostique se há problemas na configuração
```

---

## 🔐 Segurança

### Melhores Práticas

1. **API Keys**: Sempre use SOPS para secrets
2. **Knowledge DB**: Use path dedicado em produção
   ```bash
   export KNOWLEDGE_DB_PATH=/var/lib/securellm/knowledge.db
   ```
3. **Permissions**: Knowledge DB só leitura/escrita do seu user
   ```bash
   chmod 600 ~/.local/share/securellm/knowledge.db
   ```
4. **Rate Limiting**: MCP server tem rate limiting built-in
5. **Audit Logs**: Habilitado por padrão (track API usage)

---

## 📚 Referências

- **MCP Server Source**: `modules/ml/unified-llm/mcp-server/`
- **Health Report**: `docs/MCP-SERVER-HEALTH-REPORT.md`
- **Implementation Guide**: `.claude/mcp-server-implementation.md`
- **Project Analysis**: `docs/MCP-PROJECT-ROOT-ANALYSIS.md`
- **MCP Protocol**: https://modelcontextprotocol.io/

---

## 🎯 Próximos Passos

1. ✅ Reiniciar Claude Code para carregar MCP server
2. ✅ Testar ferramentas MCP com comandos simples
3. ✅ Verificar API keys dos provedores
4. ✅ Criar primeira sessão de conhecimento
5. ⏳ Integrar com ml-offload-api para inferência local (futuro)

---

**Última Atualização**: 2025-11-08
**Mantido por**: kernelcore
**Status**: ✅ Produção
