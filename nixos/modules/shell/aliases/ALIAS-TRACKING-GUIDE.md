# Guia Completo de Rastreamento de Aliases

## 🎯 Objetivo
Este guia mostra todas as formas de rastrear, debugar e entender aliases no sistema NixOS.

---

## 📚 Métodos Disponíveis

### 1. **Comandos Nativos do Shell** (Básico)

```bash
# Ver todos os aliases ativos
alias

# Ver definição de um alias específico
alias lt

# Descobrir o tipo (alias, function, builtin, file)
type lt
type tree

# Ver cadeia completa de resolução
type -a ls
```

### 2. **Aliases Helpers** (Rápido)

Depois do rebuild, use estes aliases:

```bash
# Listar todos os aliases (ordenado)
aliases

# Buscar aliases por padrão
alias-search docker    # busca "docker" em todos os aliases ativos

# Contar total de aliases
alias-count

# Ver aliases por categoria
alias-docker           # aliases Docker
alias-k8s              # aliases Kubernetes
alias-nix              # aliases Nix
alias-nav              # aliases de navegação

# Ver o que um comando vai executar
what lt                # mostra cadeia completa de resolução

# Ver aliases recentes (git log)
alias-recent
```

### 3. **Alias Inspector** (Avançado) ⭐

Ferramenta interativa completa:

```bash
# Ajuda completa
ai help

# Encontrar onde um alias está definido
ai find lt

# Informação completa sobre um alias
ai info tree
alias-info tree        # atalho

# Buscar aliases por padrão
ai search docker

# Listar aliases
ai list                # todas as categorias
ai list nix            # categoria específica

# Estatísticas
ai stats

# Rastrear cadeia de resolução completa
ai trace rebuild
alias-trace rebuild    # atalho
```

---

## 🔍 Casos de Uso Práticos

### Descobrir o que um alias faz

```bash
# Método 1: Shell nativo
alias lt
type lt

# Método 2: Inspector (mais detalhado)
ai info lt
```

**Output esperado:**
```
Current Definition:
lt='eza --tree --level=2 --group-directories-first --color=always ...'

Type Information:
lt is aliased to `eza --tree --level=2...'

Configuration Files:
Found in: /etc/nixos/modules/shell/aliases/system/navigation.nix
```

### Encontrar onde um alias está definido

```bash
# Encontrar nos arquivos de config
ai find rebuild

# Ou buscar manualmente
grep -r "rebuild" /etc/nixos/modules/shell/aliases/
```

### Buscar aliases relacionados

```bash
# Buscar por padrão
ai search docker

# Buscar em aliases ativos
alias-search tree
```

### Ver todos os aliases de uma categoria

```bash
# Docker
alias-docker

# Kubernetes
alias-k8s

# Nix
alias-nix

# Navegação
alias-nav

# Ou usar o inspector
ai list docker
```

### Rastrear resolução completa

```bash
# Traçar cadeia completa
ai trace ls

# Output mostra:
# 1. Se está ativo
# 2. Tipo de comando
# 3. Cadeia de resolução
# 4. Arquivo de configuração
# 5. Dependências
```

### Estatísticas do sistema

```bash
ai stats

# Mostra:
# - Total de aliases ativos
# - Total de arquivos de definição
# - Aliases por categoria
# - Top 10 definições mais longas
```

---

## 📂 Estrutura de Arquivos

Todos os aliases estão em:
```
/etc/nixos/modules/shell/aliases/
├── default.nix              # Importa todos
├── system/
│   ├── navigation.nix       # ls, lt, tree, etc
│   └── utils.nix            # grep, rm, cp, mv, etc
├── nix/
│   ├── build.nix           # rebuild, etc
│   └── management.nix
├── docker/
│   ├── run.nix
│   └── compose.nix
├── kubernetes/
├── gcloud/
├── ai/
└── ...
```

---

## 🛠️ Modificar Aliases

### 1. Encontrar o arquivo

```bash
ai find lt
# Output: /etc/nixos/modules/shell/aliases/system/navigation.nix
```

### 2. Editar o arquivo

```bash
cd /etc/nixos
# Editar: modules/shell/aliases/system/navigation.nix
```

### 3. Testar (depois do rebuild)

```bash
# Verificar definição
alias lt

# Testar funcionamento
lt

# Ver informação completa
ai info lt
```

---

## 💡 Dicas & Truques

### Descobrir comandos desconhecidos

```bash
# Se você vê um comando e não sabe o que é:
what comando
ai trace comando
```

### Buscar aliases similares

```bash
# Quer aliases relacionados a "tree"?
ai search tree
alias-search tree
```

### Ver aliases mais usados

```bash
# Ver histórico de comandos
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -20

# Comparar com aliases definidos
alias | wc -l
```

### Encontrar aliases problemáticos

```bash
# Aliases com comandos longos (>200 chars)
ai stats | grep -A 10 "Longest Alias"

# Aliases que sobrescrevem comandos do sistema
type -a ls
type -a rm
```

### Debugar alias que não funciona

```bash
# 1. Verificar se está ativo
alias nome

# 2. Ver tipo
type nome

# 3. Rastrear completo
ai trace nome

# 4. Verificar no arquivo de config
ai find nome
```

---

## 📋 Checklist de Troubleshooting

Se um alias não está funcionando:

- [ ] Está definido no config? → `ai find nome`
- [ ] Rebuild foi feito? → `sudo nixos-rebuild switch`
- [ ] Está ativo no shell? → `alias nome`
- [ ] Conflito com outro comando? → `type -a nome`
- [ ] Sintaxe correta no .nix? → Verificar arquivo
- [ ] Shell foi recarregado? → `exec $SHELL` ou novo terminal

---

## 🚀 Quick Reference Card

| Tarefa | Comando | Exemplo |
|--------|---------|---------|
| **Ver alias** | `alias nome` | `alias lt` |
| **Tipo de comando** | `type nome` | `type tree` |
| **Cadeia completa** | `type -a nome` | `type -a ls` |
| **Onde está definido** | `ai find nome` | `ai find rebuild` |
| **Info completa** | `ai info nome` | `ai info docker-up` |
| **Buscar padrão** | `ai search padrão` | `ai search kubernetes` |
| **Listar categoria** | `ai list cat` | `ai list nix` |
| **Estatísticas** | `ai stats` | `ai stats` |
| **Trace completo** | `ai trace nome` | `ai trace gc` |
| **Buscar ativos** | `alias-search padrão` | `alias-search git` |
| **Contar total** | `alias-count` | `alias-count` |

---

## 📖 Referências

- **Alias Inspector Script**: `/etc/nixos/scripts/alias-inspector.sh`
- **Alias Configs**: `/etc/nixos/modules/shell/aliases/`
- **Helper Aliases**: `/etc/nixos/modules/shell/aliases/system/utils.nix`
- **Navigation Guide**: `/etc/nixos/modules/shell/aliases/NAVIGATION-GUIDE.md`

---

## 🎓 Exemplos Avançados

### Script para exportar todos os aliases

```bash
# Exportar aliases para arquivo
alias > ~/my-aliases.txt

# Exportar com categorias
for cat in docker nix kubernetes gcloud; do
  echo "=== $cat ===" >> ~/aliases-export.txt
  ai list "$cat" >> ~/aliases-export.txt
  echo "" >> ~/aliases-export.txt
done
```

### Comparar aliases entre sistemas

```bash
# Sistema 1
alias | sort > /tmp/aliases-system1.txt

# Sistema 2 (outro host)
alias | sort > /tmp/aliases-system2.txt

# Comparar
diff /tmp/aliases-system1.txt /tmp/aliases-system2.txt
```

### Criar alias temporário

```bash
# Alias que dura apenas na sessão atual
alias temp='echo "This is temporary"'

# Para tornar permanente, adicionar ao arquivo .nix apropriado
```

---

**Última atualização**: 2025-11-28
**Versão**: 1.0.0
