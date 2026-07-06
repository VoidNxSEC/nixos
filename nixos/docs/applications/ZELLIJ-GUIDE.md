# Zellij Terminal Multiplexer - Guia Completo

> **Status**: Gerenciado via NixOS
> **Module**: `modules/applications/zellij.nix`
> **Version**: 0.43.1
> **Performance**: Optimized for low latency

---

## 🚀 Quick Start

### Iniciar Zellij
```bash
# Comandos básicos
zellij                    # Inicia nova sessão
zellij attach --create    # Cria ou anexa sessão "default"
zellij list-sessions      # Lista todas as sessões
zellij kill-session main  # Mata sessão específica

# Aliases disponíveis (via NixOS)
zj                        # zellij
zja                       # zellij attach --create
zjl                       # zellij list-sessions
zjk                       # zellij kill-session
zjc                       # zellij-cleanup (limpa cache)
```

---

## ⌨️ Atalhos Configurados

### 📑 Gerenciamento de Abas (Tabs)
| Atalho | Ação |
|--------|------|
| `Alt+T` | Nova aba |
| `Alt+W` | Fechar aba atual |
| `Alt+N` | Próxima aba |
| `Alt+P` | Aba anterior |
| `Alt+1-9` | Ir para aba 1-9 |
| `Alt+R` | Renomear aba (Enter confirma, Esc cancela) |

### 🪟 Gerenciamento de Painéis (Panes)
| Atalho | Ação |
|--------|------|
| `Alt+H` | Novo painel à esquerda |
| `Alt+J` | Novo painel abaixo |
| `Alt+K` | Novo painel acima |
| `Alt+L` | Novo painel à direita |
| `Alt+X` | Fechar painel atual |
| `Alt+F` | Toggle fullscreen do painel |

### 🧭 Navegação entre Painéis
| Atalho | Ação |
|--------|------|
| `Alt+←` | Mover foco para esquerda |
| `Alt+→` | Mover foco para direita |
| `Alt+↑` | Mover foco para cima |
| `Alt+↓` | Mover foco para baixo |

### 📐 Redimensionar Painéis
| Atalho | Ação |
|--------|------|
| `Alt++` | Aumentar tamanho do painel |
| `Alt+-` | Diminuir tamanho do painel |

### 🔍 Modo Scroll
| Atalho | Ação |
|--------|------|
| `Alt+S` | Entrar em modo scroll |
| `j` / `↓` | Scroll para baixo |
| `k` / `↑` | Scroll para cima |
| `d` | Meia página para baixo |
| `u` | Meia página para cima |
| `PageDown` | Página inteira para baixo |
| `PageUp` | Página inteira para cima |
| `Esc` / `q` | Sair do modo scroll |

### 🛡️ Segurança
- `Ctrl+Q` está **desabilitado** para evitar fechamento acidental

---

## 🔧 Configuração NixOS

### Habilitar Zellij
Adicione ao seu `configuration.nix`:

```nix
kernelcore.applications.zellij = {
  enable = true;
  autoCleanup = true;           # Cleanup automático de cache
  cleanupInterval = "daily";    # Opções: daily, weekly, monthly
  maxCacheSizeMB = 50;          # Limite de cache (MB)
};
```

### Estrutura de Arquivos
```
/etc/nixos/modules/applications/zellij.nix  # Módulo principal
/etc/zellij/config.kdl                      # Config gerenciada pelo NixOS
$HOME/.config/zellij/config.kdl             # Symlink para /etc/zellij/config.kdl
$HOME/.cache/zellij/                        # Cache de sessões
```

### Limpeza de Cache
O módulo NixOS gerencia automaticamente o cache:

- **Automático**: Via systemd timer (configurável)
- **Manual**: Execute `zellij-cleanup` ou `zjc`
- **Limite**: Cache mantido abaixo de 50MB por padrão

```bash
# Verificar tamanho do cache
du -sh ~/.cache/zellij/

# Limpeza manual
zellij-cleanup

# O que é removido:
# - Sessões antigas (>7 dias)
# - Arquivos grandes (>5MB) não usados (>1 dia)
# - Diretórios vazios
```

---

## 🎨 Tema e Aparência

### Tema Atual: Gruvbox Dark
- **Background**: `#282828`
- **Foreground**: `#ebdbb2`
- **UI**: Simplificada para performance
- **Frames**: Desabilitados (menos overhead visual)
- **Layout**: Compact mode (mais espaço útil)

### Personalização
Para modificar o tema, edite `/etc/nixos/modules/applications/zellij.nix`:

```kdl
themes {
    custom-theme {
        fg "#ffffff"
        bg "#000000"
        // ... suas cores
    }
}
```

Depois reconstrua o sistema:
```bash
sudo nixos-rebuild switch
```

---

## 🚀 Performance & Otimizações

### Otimizações Implementadas

1. **Session Serialization Disabled**
   - Reduz I/O de disco
   - Menos overhead de CPU
   - Cache mais limpo

2. **Copy-on-Select Disabled**
   - Menos operações de clipboard
   - Reduz latência ao selecionar texto

3. **Simplified UI**
   - Menos elementos visuais
   - Menor uso de CPU para renderização
   - Layout compacto

4. **Automatic Cache Cleanup**
   - Mantém cache abaixo de 50MB
   - Remove sessões antigas automaticamente
   - Previne acúmulo de dados

5. **Optimized Build**
   - Binary estático (musl libc)
   - Sem dependências dinâmicas desnecessárias
   - Menor footprint de memória

### Benchmarks Esperados
- **Startup Time**: <100ms
- **Memory Usage**: 10-20MB por sessão
- **Cache Size**: <50MB (com cleanup ativo)
- **CPU Usage**: <1% em idle

---

## 🐛 Troubleshooting

### Zellij está travando/lagando

**Diagnóstico**:
```bash
# Verificar processos Zellij
ps aux | grep zellij

# Verificar cache
du -sh ~/.cache/zellij/

# Limpar cache
zellij-cleanup

# Matar todas as sessões
zellij kill-all-sessions
```

**Solução**:
1. Execute `zellij-cleanup` para limpar cache
2. Mate sessões antigas: `zellij kill-session <nome>`
3. Se persistir, remova cache manualmente: `rm -rf ~/.cache/zellij/*`

### Config não está sendo aplicada

**Verificar symlink**:
```bash
ls -la ~/.config/zellij/config.kdl

# Deve apontar para:
# ~/.config/zellij/config.kdl -> /etc/zellij/config.kdl
```

**Recriar config**:
```bash
sudo nixos-rebuild switch
```

### Cache crescendo muito

**Ajustar intervalo de cleanup**:
```nix
kernelcore.applications.zellij.cleanupInterval = "daily";  # Mais agressivo
```

**Verificar timer systemd**:
```bash
systemctl --user status zellij-cleanup.timer
systemctl --user start zellij-cleanup.service
```

---

## 🔗 Integração com Alacritty

### Opção 1: Start Manual (Recomendado)
Apenas execute `zellij` quando quiser:
```bash
zellij attach --create main
```

### Opção 2: Auto-start (Opcional)
Edite `~/.config/alacritty/alacritty.toml`:
```toml
[shell]
program = "/run/current-system/sw/bin/zellij"
args = ["attach", "--create", "main"]
```

**Nota**: Auto-start pode causar problemas se você usa outros multiplexers (tmux, screen).

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [Zellij Docs](https://zellij.dev/documentation/)
- [KDL Config Format](https://kdl.dev/)

### Arquivos Relacionados
- **Module**: `/etc/nixos/modules/applications/zellij.nix`
- **Config**: `/etc/zellij/config.kdl`
- **Cleanup Script**: `zellij-cleanup`
- **Wrapper**: `zellij-optimized`

### Comandos Úteis
```bash
# Ver todas as sessões
zellij list-sessions

# Anexar a sessão específica
zellij attach <session-name>

# Criar nova sessão nomeada
zellij --session <name>

# Matar sessão específica
zellij kill-session <name>

# Limpeza de cache
zellij-cleanup

# Ver tamanho do cache
du -sh ~/.cache/zellij/
```

---

## 🎯 Dicas & Truques

### Workflow Produtivo
1. **Uma sessão por projeto**: `zellij --session myproject`
2. **Abas para contextos**: Dev, Tests, Logs, etc.
3. **Painéis para visualização paralela**: Editor + Terminal
4. **Modo fullscreen**: `Alt+F` para focar em tarefa única

### Boas Práticas
- ✅ Use nomes descritivos para sessões
- ✅ Feche sessões não usadas regularmente
- ✅ Execute `zellij-cleanup` semanalmente
- ✅ Monitore uso de cache: `du -sh ~/.cache/zellij/`
- ❌ Evite criar muitas sessões simultâneas
- ❌ Não use auto-start se usar outros multiplexers

### Performance Tips
- Mantenha cache <50MB
- Use no máximo 5 sessões ativas
- Feche abas não utilizadas
- Execute cleanup regularmente

---

**Última atualização**: 2025-11-24
**Gerenciado por**: NixOS declarative configuration
**Suporte**: `/etc/nixos/modules/applications/zellij.nix`
