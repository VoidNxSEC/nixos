# Notion Database Exporter - Guia Completo

## 📦 O que é?

Script para **migrar completamente** seus databases do Notion para formatos abertos (Markdown e JSON).

**Ideal para**:
- Migração de plataforma (Notion → Obsidian, Logseq, etc.)
- Backup completo dos seus dados
- Arquivamento de projetos
- Integração com outras ferramentas

---

## 🚀 Como Usar

### Passo 1: Obter Token de Integração

1. Acesse: https://www.notion.so/my-integrations
2. Clique em **"+ New integration"**
3. Dê um nome (ex: "Database Exporter")
4. Selecione o workspace
5. Copie o **Internal Integration Token** (começa com `secret_`)

### Passo 2: Obter Database ID

**Opção A - Da URL:**
```
https://www.notion.so/myworkspace/abc123def456?v=...
                                 ^^^^^^^^^^^^
                                 Database ID
```

**Opção B - Compartilhar com Integração:**
1. Abra o database no Notion
2. Clique nos 3 pontinhos (⋯) → **Add connections**
3. Selecione sua integração
4. Copie o ID da URL

### Passo 3: Exportar

```bash
# Método 1: Argumentos diretos
python3 /etc/nixos/scripts/notion-exporter.py \
  --token secret_xxxxxxxxx \
  --database abc123def456 \
  --output ~/notion-backup

# Método 2: Variáveis de ambiente (mais seguro)
export NOTION_TOKEN="secret_xxxxxxxxx"
export NOTION_DATABASE="abc123def456"
python3 /etc/nixos/scripts/notion-exporter.py --output ~/notion-backup
```

---

## 📂 Estrutura de Saída

```
notion-backup/
├── markdown/
│   ├── Projeto_A.md
│   ├── Tarefa_123.md
│   └── Notas_2024.md
└── json/
    ├── Projeto_A.json
    ├── Tarefa_123.json
    └── Notas_2024.json
```

### Formato Markdown

```markdown
# Título da Página

---

## Metadata
- **Status**: Em Progresso
- **Tags**: projeto, dev, nixos
- **Created**: 2024-01-15
- **People**: João, Maria

---

## Heading 1
Conteúdo da página...

- Lista item 1
- Lista item 2

### Código
```python
print("Hello World")
```

---
*Exported from Notion on 2025-12-29*
*Original URL: https://notion.so/...*
```

### Formato JSON

```json
{
  "id": "abc-123",
  "title": "Projeto A",
  "url": "https://notion.so/...",
  "metadata": {
    "Status": "Em Progresso",
    "Tags": ["projeto", "dev"],
    "Created": "2024-01-15"
  },
  "content": "# Heading 1\n\nConteúdo...",
  "exported_at": "2025-12-29T13:50:00",
  "raw_notion_data": { ... }
}
```

---

## ⚙️ Opções Avançadas

### Apenas Markdown
```bash
notion-exporter.py --format markdown --output ~/notes
```

### Apenas JSON
```bash
notion-exporter.py --format json --output ~/backup
```

### Timeout Maior (para databases grandes)
```bash
notion-exporter.py --timeout 60 --output ~/export
```

---

## 🎯 Casos de Uso

### 1. Migração para Obsidian

```bash
# Exportar apenas markdown
notion-exporter.py --format markdown --output ~/ObsidianVault/NotionImport

# Resultado: arquivos .md prontos para Obsidian
```

### 2. Backup Automático

```bash
#!/usr/bin/env bash
# backup-notion.sh

export NOTION_TOKEN="secret_xxx"
export NOTION_DATABASE="abc123"

DATE=$(date +%Y-%m-%d)
OUTPUT="$HOME/backups/notion-$DATE"

python3 /etc/nixos/scripts/notion-exporter.py --output "$OUTPUT"

# Comprimir
tar -czf "$OUTPUT.tar.gz" "$OUTPUT"
rm -rf "$OUTPUT"

echo "✅ Backup criado: $OUTPUT.tar.gz"
```

### 3. Migração para AppFlowy

```bash
# Exportar JSON para processamento
notion-exporter.py --format json --output ~/appflowy-import

# Converter JSON → AppFlowy format (script adicional necessário)
```

---

## 🔒 Segurança

### ✅ Boas Práticas

**Nunca commite o token no git:**
```bash
# Use variáveis de ambiente
echo 'export NOTION_TOKEN="secret_xxx"' >> ~/.zshrc.local

# Ou use gerenciador de secrets
pass insert notion/token
export NOTION_TOKEN=$(pass notion/token)
```

**Permissões mínimas:**
- A integração só precisa de **Read** access
- Configure em: https://www.notion.so/my-integrations

---

## 🐛 Troubleshooting

### Erro: "Integration token required"
```bash
# Verifique se o token está correto
echo $NOTION_TOKEN

# Teste manualmente
curl -H "Authorization: Bearer $NOTION_TOKEN" \
     -H "Notion-Version: 2022-06-28" \
     https://api.notion.com/v1/users/me
```

### Erro: "Database not found"
- Verifique se compartilhou o database com a integração
- Database → ⋯ → Add connections → Sua integração

### Erro: "Rate limited"
- API do Notion tem limite de 3 requests/segundo
- O script já tem retry automático
- Para databases muito grandes, aguarde alguns minutos

### Páginas vazias exportadas
- Certifique-se que a integração tem acesso ao database
- Verifique se as páginas não estão em outro workspace

---

## 📊 Performance

| Database Size | Export Time | Output Size |
|---------------|-------------|-------------|
| 10 páginas    | ~5s         | ~50KB       |
| 100 páginas   | ~30s        | ~500KB      |
| 1000 páginas  | ~5min       | ~5MB        |

**Dica**: Para databases muito grandes (>1000 páginas), considere exportar em lotes usando filtros.

---

## 🔄 Próximos Passos Após Export

### Para Obsidian
1. Copie arquivos `.md` para vault
2. Ajuste links internos se necessário
3. Configure tags e metadata

### Para Backup
1. Comprima: `tar -czf notion-backup.tar.gz notion-export/`
2. Armazene em local seguro
3. Teste restauração periodicamente

### Para Análise
1. Use os arquivos JSON
2. Processe com Python/jq
3. Gere relatórios customizados

---

## 📚 Recursos Adicionais

- [Notion API Docs](https://developers.notion.com/reference/intro)
- [Integration Setup](https://developers.notion.com/docs/create-a-notion-integration)
- [Database Query Filters](https://developers.notion.com/reference/post-database-query-filter)

---

## ✅ Checklist de Migração

- [ ] Criar integração no Notion
- [ ] Obter token de integração
- [ ] Compartilhar database com integração
- [ ] Copiar database ID
- [ ] Executar export
- [ ] Validar arquivos gerados
- [ ] Importar na nova plataforma
- [ ] Verificar integridade dos dados
- [ ] Manter backup original

---

**Criado**: 2025-12-29  
**Script**: `/etc/nixos/scripts/notion-exporter.py`
