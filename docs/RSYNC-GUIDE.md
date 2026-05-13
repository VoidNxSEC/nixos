# 🔄 Rsync Laptop ↔ Desktop - Guia Completo

**Data**: 2025-11-27
**Laptop**: kernelcore @ 192.168.15.9
**Desktop**: cypher @ 192.168.15.7

---

## 📋 Índice

1. [Comandos Rápidos](#comandos-rápidos)
2. [Scripts Disponíveis](#scripts-disponíveis)
3. [Aliases Configurados](#aliases-configurados)
4. [Exemplos de Uso](#exemplos-de-uso)
5. [Opções Avançadas](#opções-avançadas)
6. [Troubleshooting](#troubleshooting)

---

## ⚡ Comandos Rápidos

```bash
# Enviar para desktop
sync-to ~/projects                # Sincroniza projetos para desktop
sync-push ~/Documents             # Push documentos

# Receber do desktop
sync-from projects                # Pull projetos do desktop
sync-pull Documents               # Pull documentos

# Atalhos pré-configurados
sync-nixos                        # Sincroniza /etc/nixos (sem deletar)
sync-projects                     # Sincroniza ~/projects
sync-docs                         # Sincroniza ~/Documents

# Teste antes de executar (dry-run)
sync-to ~/projects --dry-run      # Mostra o que seria transferido
sync-from Documents --dry-run     # Testa recebimento
```

---

## 📝 Scripts Disponíveis

### 1. **sync-to-desktop.sh**
Sincroniza do Laptop → Desktop

```bash
/etc/nixos/scripts/sync-to-desktop.sh [diretório] [opções]

Opções:
  --dry-run        Modo teste (não transfere nada)
  --delete-after   Deleta após transferência (mais seguro)
  --no-delete      Não deleta arquivos no destino
  -h, --help       Mostra ajuda
```

**Exemplo:**
```bash
sync-to ~/projects --dry-run      # Testa primeiro
sync-to ~/projects                # Executa de verdade
```

### 2. **sync-from-desktop.sh**
Sincroniza Desktop → Laptop

```bash
/etc/nixos/scripts/sync-from-desktop.sh [diretório] [opções]

Opções:
  --dry-run        Modo teste
  --no-delete      Não deleta arquivos no destino
  -h, --help       Mostra ajuda
```

**Exemplo:**
```bash
sync-from projects --dry-run      # Testa primeiro
sync-from projects                # Executa
```

---

## 🔧 Aliases Configurados

| Alias | Comando | Descrição |
|-------|---------|-----------|
| `sync-to` | `sync-to-desktop.sh` | Envia para desktop |
| `sync-push` | `sync-to-desktop.sh` | Alias para sync-to |
| `push-desktop` | `sync-to-desktop.sh` | Alias para sync-to |
| `sync-from` | `sync-from-desktop.sh` | Recebe do desktop |
| `sync-pull` | `sync-from-desktop.sh` | Alias para sync-from |
| `pull-desktop` | `sync-from-desktop.sh` | Alias para sync-from |
| `sync-nixos` | Sincroniza /etc/nixos | Sem deletar arquivos |
| `sync-projects` | Sincroniza ~/projects | Com delete |
| `sync-docs` | Sincroniza ~/Documents | Com delete |
| `rsync-desktop` | `rsync -avz --progress` | Rsync direto |
| `rsync-safe` | `rsync -avzn --progress` | Sempre dry-run |

---

## 💡 Exemplos de Uso

### Caso 1: Sincronizar Projetos
```bash
# 1. Teste primeiro (recomendado)
sync-to ~/projects --dry-run

# 2. Se estiver tudo OK, execute
sync-to ~/projects

# 3. Verifique no desktop
ssh desktop "ls -lh ~/projects"
```

### Caso 2: Backup de Configurações
```bash
# Sincroniza /etc/nixos sem deletar nada no destino
sync-nixos

# Ou manualmente com mais controle
sync-to /etc/nixos --no-delete --dry-run
sync-to /etc/nixos --no-delete
```

### Caso 3: Receber Trabalho do Desktop
```bash
# Você trabalhou no desktop e quer trazer para o laptop
sync-from projects --dry-run     # Teste
sync-from projects                # Executa
```

### Caso 4: Sincronização Bidirecional
```bash
# CUIDADO: Pode sobrescrever arquivos!
# Use apenas se souber o que está fazendo

# Opção 1: Enviar e depois receber
sync-to ~/projects --no-delete
sync-from projects --no-delete

# Opção 2: Usar alias especial
sync-both-nixos  # Para /etc/nixos apenas
```

### Caso 5: Sincronizar Dotfiles
```bash
# Sincroniza apenas arquivos de configuração ocultos
sync-home  # Configurado para enviar .bashrc, .zshrc, .config/, etc.
```

---

## 🔬 Opções Avançadas

### Exclusões Padrão (já configuradas)
Os scripts excluem automaticamente:
- `.git/` - Repositórios git
- `node_modules/` - Dependências Node.js
- `.cache/` - Cache de aplicações
- `target/` - Build do Rust
- `__pycache__/`, `*.pyc` - Cache Python
- `.venv/` - Virtual environments
- `.env` - Variáveis de ambiente

### Rsync Manual (para casos específicos)
```bash
# Sincronizar arquivo específico
rsync -avz ~/file.txt desktop:~/

# Sincronizar com exclusões customizadas
rsync -avz --exclude='*.log' ~/projects/ desktop:~/projects/

# Verificar diferenças sem transferir
rsync -avzn --itemize-changes ~/projects/ desktop:~/projects/

# Sincronizar com bandwidth limit (útil em redes lentas)
rsync -avz --bwlimit=1000 ~/projects/ desktop:~/projects/

# Sincronizar e manter permissões originais
rsync -avz --chmod=ugo=rwX ~/projects/ desktop:~/projects/
```

### Sincronização Contínua (watch mode)
```bash
# Instalar inotify-tools (se necessário)
nix-shell -p inotify-tools

# Monitorar e sincronizar automaticamente
while inotifywait -r -e modify,create,delete ~/projects; do
    sync-to ~/projects
    sleep 2
done
```

---

## 🐛 Troubleshooting

### Problema: "Cannot connect to desktop"
```bash
# Verificar conectividade
ping -c 3 192.168.15.7

# Testar SSH
ssh desktop "echo 'Connection OK'"

# Verificar configuração SSH
cat ~/.ssh/config | grep -A 10 "^Host desktop"
```

### Problema: "Permission denied"
```bash
# Verificar chaves SSH
ssh-add -l

# Testar autenticação
ssh -v desktop "whoami"

# Verificar permissões no desktop
ssh desktop "ls -la ~/"
```

### Problema: Sync muito lento
```bash
# Use compressão (já habilitada por padrão)
# Ou desabilite se estiver em rede local rápida
rsync -av --no-compress ~/projects/ desktop:~/projects/

# Use menos verificações para arquivos grandes
rsync -av --inplace --partial ~/large-file.iso desktop:~/
```

### Problema: Arquivos sendo deletados sem querer
```bash
# Sempre use --dry-run primeiro!
sync-to ~/projects --dry-run

# Use --no-delete se não quiser deletar nada
sync-to ~/projects --no-delete

# Use --delete-after para deletar após transferir (mais seguro)
sync-to ~/projects --delete-after
```

### Problema: Muito output/verbose
```bash
# Rsync quieto (apenas erros)
rsync -az --quiet ~/projects/ desktop:~/projects/
```

---

## 📊 Status e Monitoramento

### Ver tamanho antes de sincronizar
```bash
# Local
du -sh ~/projects

# Remoto
ssh desktop "du -sh ~/projects"
```

### Comparar diretórios
```bash
# Ver diferenças sem transferir
rsync -avzn --itemize-changes ~/projects/ desktop:~/projects/

# Contar arquivos diferentes
rsync -avzn --itemize-changes ~/projects/ desktop:~/projects/ | wc -l
```

### Log de transferências
```bash
# Salvar log da sincronização
sync-to ~/projects 2>&1 | tee ~/sync-log-$(date +%Y%m%d-%H%M%S).txt
```

---

## 🚀 Próximos Passos

### Automação com Systemd
Criar um timer para sincronizar automaticamente:

```bash
# TODO: Criar systemd timer
# Ver: /etc/nixos/modules/services/sync-timer.nix
```

### Sincronização via Tailscale
Para acesso remoto fora da rede local:

```bash
# TODO: Configurar sync via Tailscale
# Ver: /etc/nixos/docs/TAILSCALE-SYNC-GUIDE.md
```

---

## 📚 Referências

- [Rsync Official Docs](https://rsync.samba.org/)
- [Rsync Examples](https://www.tecmint.com/rsync-local-remote-file-synchronization-commands/)
- [SSH Config Guide](https://www.ssh.com/academy/ssh/config)

---

**Última atualização**: 2025-11-27
**Mantido por**: kernelcore
**Versão**: 1.0.0
