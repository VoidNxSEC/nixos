# MCP Knowledge Database - Fix de Permissões

## Problema Identificado

**Erro**: `TypeError: Cannot open database because the directory does not exist`

**Causa**: O MCP server está configurado para usar `/var/lib/mcp-knowledge/knowledge.db` via [`mcp_settings.json`](../../../home/kernelcore/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json), mas quando executado via Claude Desktop, o processo roda como usuário normal (`kernelcore`) sem permissões para criar diretórios em `/var/lib/`.

**Estado do código**: O [`database.ts`](../modules/ml/unified-llm/mcp-server/src/knowledge/database.ts:22-27) já possui código correto para criar o diretório pai, mas falha devido a restrições de permissão do sistema.

## Solução Escolhida: System-wide via NixOS Configuration

Configuração a nível de sistema usando `systemd.tmpfiles.rules` para criar o diretório com permissões corretas.

### Vantagens
- ✅ Mantém dados em local system-wide seguro
- ✅ Persiste entre rebuilds do sistema
- ✅ Configuração declarativa via NixOS
- ✅ Permissões controladas pelo sistema
- ✅ Permite compartilhamento entre usuários se necessário

## Plano de Implementação

### Passo 1: Adicionar regra systemd.tmpfiles em configuration.nix

**Arquivo**: `hosts/kernelcore/configuration.nix`

**Localização**: Após linha 372 (seção `systemd.tmpfiles.rules` existente)

**Código a adicionar**:
```nix
# Existing rules (lines 368-372)
systemd.tmpfiles.rules = [
  "d /var/lib/gitea/custom/https 0750 gitea gitea -"
  "L+ /var/lib/gitea/custom/https/localhost.crt - - - - /home/kernelcore/localhost.crt"
  "L+ /var/lib/gitea/custom/https/localhost.key - - - - /home/kernelcore/localhost.key"
  
  # ADD THESE TWO LINES:
  # MCP Knowledge Database directory
  "d /var/lib/mcp-knowledge 0755 kernelcore kernelcore -"
];
```

**Explicação da regra**:
- `d` = criar diretório se não existir
- `/var/lib/mcp-knowledge` = caminho do diretório
- `0755` = permissões (rwxr-xr-x - owner pode escrever, outros podem ler)
- `kernelcore kernelcore` = owner:group
- `-` = sem máscara de idade (não apagar automaticamente)

### Passo 2: Rebuild do sistema

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake .#kernelcore
```

**O que acontece**:
1. NixOS cria o diretório `/var/lib/mcp-knowledge/` com permissões corretas
2. O diretório persiste entre rebuilds
3. Usuário `kernelcore` tem permissão de escrita
4. O MCP server pode criar o database sem erros

### Passo 3: Reiniciar Claude Desktop/VSCodium

Após o rebuild bem-sucedido:
1. Fechar e reabrir VSCodium/Claude Desktop
2. O MCP server iniciará automaticamente
3. O [`database.ts`](../modules/ml/unified-llm/mcp-server/src/knowledge/database.ts:22-27) criará o arquivo `knowledge.db` com sucesso

## Verificação Pós-Implementação

### 1. Verificar diretório criado
```bash
ls -la /var/lib/mcp-knowledge/
# Esperado: drwxr-xr-x kernelcore kernelcore
```

### 2. Verificar logs do MCP server
```bash
# Abrir VSCodium/Claude Desktop e verificar output do MCP server
# Esperado: "[Knowledge] Database initialized at: /var/lib/mcp-knowledge/knowledge.db"
```

### 3. Testar tools do MCP server
```bash
# Via Claude Desktop, testar qualquer tool do MCP server
# Todos devem funcionar sem erros de database
```

## Alternativas Consideradas

### Opção A: Mover para diretório do usuário (NÃO escolhida)
- Caminho: `~/.local/share/mcp-knowledge/knowledge.db`
- Pros: Sem necessidade de privilégios
- Cons: Não atende requisito de configuração system-wide segura

### Opção B: Desabilitar temporariamente (NÃO escolhida)
- `ENABLE_KNOWLEDGE="false"` no mcp_settings.json
- Pros: Teste rápido dos package debugger tools
- Cons: Perde toda funcionalidade de knowledge management

## Segurança

### Análise de Permissões

**Diretório**: `/var/lib/mcp-knowledge/`
- Permissões: `0755` (rwxr-xr-x)
- Owner: `kernelcore:kernelcore`
- Acesso: 
  - Owner pode criar/modificar/deletar arquivos
  - Grupo e outros podem apenas listar e ler
  - Apropriado para dados de sistema acessíveis por múltiplos processos

**Database File**: `knowledge.db`
- Criado automaticamente pelo better-sqlite3
- Herda permissões padrão do usuário (normalmente 0644)
- Apenas `kernelcore` pode escrever

### Considerações de Segurança

1. ✅ Dados persistem em local system-wide padrão (`/var/lib/`)
2. ✅ Permissões restritas ao usuário owner
3. ✅ SQLite usa WAL mode com locks apropriados
4. ✅ Não expõe dados sensíveis (knowledge database é metadados de sessões)
5. ⚠️ Se múltiplos usuários precisarem acesso, considerar grupo dedicado

## Rollback

Se houver problemas após a implementação:

### Remover configuração
```nix
# Em hosts/kernelcore/configuration.nix, remover linha:
"d /var/lib/mcp-knowledge 0755 kernelcore kernelcore -"
```

### Rebuild
```bash
sudo nixos-rebuild switch --flake .#kernelcore
```

### Limpar diretório (opcional)
```bash
sudo rm -rf /var/lib/mcp-knowledge/
```

## Próximos Passos

Após correção bem-sucedida:

1. ✅ **Teste completo do MCP server** com todos os tools
2. ✅ **Verificar logs** para confirmar database inicializado
3. 🔄 **Criar testes unitários** para package debugger tools
4. 🔄 **Documentar uso** dos package debugger tools

## Notas Técnicas

### systemd.tmpfiles.rules Syntax

Formato: `TYPE PATH MODE USER GROUP AGE ARGUMENT`

**Tipos comuns**:
- `d` = criar diretório
- `f` = criar arquivo
- `L+` = criar/sobrescrever symlink
- `Z` = ajustar recursivamente permissões/ownership

**Referência**: `man tmpfiles.d`

### better-sqlite3 Behavior

- Requer diretório pai existente (não cria automaticamente)
- Usa permissões padrão do processo para arquivo DB
- Cria arquivos auxiliares: `knowledge.db-shm`, `knowledge.db-wal`
- WAL mode permite leitura concorrente

## Status

- [x] Problema identificado e analisado
- [x] Solução escolhida e documentada
- [ ] Implementação no configuration.nix (necessário Code mode)
- [ ] Rebuild do sistema
- [ ] Verificação e testes