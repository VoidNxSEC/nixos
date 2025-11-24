# Documentação de Arquitetura do Sistema NixOS

**Host:** kernelcore
**Atualizado em:** 2025-11-23

---

## 📚 Documentos Disponíveis

### 1. [COMPONENT-MAP.md](./COMPONENT-MAP.md)
**Mapa completo de componentes do sistema**

- Localização detalhada de cada componente (Zsh, Hyprland, Zellij, etc)
- Estrutura de diretórios explicada
- Arquivos de configuração e suas funções
- Guia de onde encontrar cada parte do sistema
- Estatísticas do sistema

**Quando usar:** Quando você precisa saber onde está configurado um componente específico.

### 2. [VISUAL-ARCHITECTURE.md](./VISUAL-ARCHITECTURE.md)
**Diagramas visuais da arquitetura**

- Fluxo de configuração (flake → modules → sistema)
- Stack do Desktop Environment (Hyprland)
- Stack do Shell (Zsh + Powerlevel10k + plugins)
- Sistema de aliases modular
- Hyprland startup sequence
- Zellij workflow
- Security layers
- Package management layers
- ML/AI stack
- Rebuild & testing flow
- Data flow diagram

**Quando usar:** Para entender visualmente como os componentes se relacionam e interagem.

### 3. [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
**Referência rápida para uso diário**

- Localização rápida dos componentes principais
- Comandos essenciais (nixos-rebuild, home-manager, etc)
- Como editar configurações (Zsh, Hyprland, Zellij)
- Keybindings importantes
- Troubleshooting comum
- Busca rápida

**Quando usar:** Para consultar rapidamente comandos, localizações e atalhos.

### 4. [MODULES-INDEX.md](./MODULES-INDEX.md)
**Índice completo de todos os módulos NixOS**

- Lista de todos ~130 módulos .nix
- Descrição detalhada de cada módulo
- Features e funcionalidades
- Organizado por categoria
- Tabela resumo

**Quando usar:** Para encontrar um módulo específico ou entender o que cada arquivo faz.

---

## 🎯 Guia de Uso Rápido

### Você quer modificar...

#### **Zsh (Shell)**
1. Leia: [COMPONENT-MAP.md#shell](./COMPONENT-MAP.md#shell-zsh--bash)
2. Edite: `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix`
3. Aplique: `home-manager switch --flake /etc/nixos#kernelcore@kernelcore`
4. Veja também: [MODULES-INDEX.md#shell](./MODULES-INDEX.md#shell)

#### **Hyprland (Desktop)**
1. Leia: [COMPONENT-MAP.md#desktop-environment](./COMPONENT-MAP.md#desktop-environment-hyprland)
2. Edite: `~/.config/hypr/hyprland.conf`
3. Recarregue: `hyprctl reload`
4. Veja também: [VISUAL-ARCHITECTURE.md#desktop-environment-stack](./VISUAL-ARCHITECTURE.md#desktop-environment-stack)

#### **Zellij (Terminal Multiplexer)**
1. Leia: [COMPONENT-MAP.md#terminal-multiplexer](./COMPONENT-MAP.md#terminal-multiplexer-zellij)
2. Edite: `~/.config/zellij/config.kdl`
3. Reinicie zellij
4. Veja também: [VISUAL-ARCHITECTURE.md#zellij-workflow](./VISUAL-ARCHITECTURE.md#zellij-workflow)

#### **Aliases**
1. Leia: [COMPONENT-MAP.md#aliases](./COMPONENT-MAP.md#aliases-do-sistema)
2. Edite: `/etc/nixos/modules/shell/aliases/` (modular) ou inline em `zsh.nix`
3. Aplique: `home-manager switch`
4. Veja também: [VISUAL-ARCHITECTURE.md#sistema-de-aliases](./VISUAL-ARCHITECTURE.md#sistema-de-aliases-modular)

---

## 📊 Visão Geral do Sistema

### Componentes Principais

| Componente | Config Principal | Docs |
|------------|------------------|------|
| **Zsh** | `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix` | [COMPONENT-MAP](./COMPONENT-MAP.md#shell-zsh--bash), [MODULES-INDEX](./MODULES-INDEX.md#zsh-nix-) |
| **Hyprland** | `/etc/nixos/modules/desktop/hyprland.nix` | [COMPONENT-MAP](./COMPONENT-MAP.md#desktop-environment-hyprland), [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#desktop-environment-stack) |
| **Zellij** | `/etc/nixos/modules/packages/tar-packages/packages/zellij.nix` | [COMPONENT-MAP](./COMPONENT-MAP.md#terminal-multiplexer-zellij), [MODULES-INDEX](./MODULES-INDEX.md#packages-zellij-nix-) |
| **Aliases** | `/etc/nixos/modules/shell/aliases/` | [COMPONENT-MAP](./COMPONENT-MAP.md#aliases-do-sistema), [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#sistema-de-aliases-modular) |
| **Segurança** | `/etc/nixos/modules/security/` | [MODULES-INDEX](./MODULES-INDEX.md#segurança), [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#security-layers) |
| **ML/AI** | `/etc/nixos/modules/ml/` | [MODULES-INDEX](./MODULES-INDEX.md#machine-learning), [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#mlai-stack) |

### Estrutura Modular

```
/etc/nixos/
├── flake.nix                    # Entry point
├── hosts/kernelcore/
│   ├── configuration.nix        # System config
│   └── home/shell/zsh.nix       # ⭐ ZSH CONFIG
├── modules/
│   ├── desktop/hyprland.nix     # ⭐ HYPRLAND
│   ├── packages/tar-packages/
│   │   └── packages/zellij.nix  # ⭐ ZELLIJ
│   ├── shell/aliases/           # ⭐ ALIASES
│   ├── security/                # Security modules
│   ├── ml/                      # ML/AI modules
│   └── ...                      # Outros módulos
└── docs/architecture/           # ⭐ VOCÊ ESTÁ AQUI
    ├── README.md
    ├── COMPONENT-MAP.md
    ├── VISUAL-ARCHITECTURE.md
    ├── QUICK-REFERENCE.md
    └── MODULES-INDEX.md
```

---

## 🚀 Fluxo de Trabalho

### 1. Entender a Arquitetura
```
Leia: VISUAL-ARCHITECTURE.md
      ↓
Compreenda os diagramas de fluxo
      ↓
Veja como os componentes interagem
```

### 2. Localizar Componente
```
Leia: COMPONENT-MAP.md
      ↓
Encontre a localização exata do arquivo
      ↓
Use MODULES-INDEX.md para detalhes
```

### 3. Modificar Configuração
```
Consulte: QUICK-REFERENCE.md
      ↓
Edite o arquivo apropriado
      ↓
Aplique as mudanças (rebuild/reload)
```

### 4. Verificar & Troubleshoot
```
Consulte: QUICK-REFERENCE.md#troubleshooting
      ↓
Execute comandos de verificação
      ↓
Consulte logs se necessário
```

---

## 🔍 Busca Rápida

### Por Componente
- **Zsh:** [COMPONENT-MAP](./COMPONENT-MAP.md#shell-zsh--bash) → [MODULES-INDEX](./MODULES-INDEX.md#zsh-nix-)
- **Hyprland:** [COMPONENT-MAP](./COMPONENT-MAP.md#desktop-environment-hyprland) → [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#desktop-environment-stack)
- **Zellij:** [COMPONENT-MAP](./COMPONENT-MAP.md#terminal-multiplexer-zellij) → [QUICK-REF](./QUICK-REFERENCE.md#zellij)
- **Aliases:** [COMPONENT-MAP](./COMPONENT-MAP.md#aliases-do-sistema) → [MODULES-INDEX](./MODULES-INDEX.md#aliases)
- **Segurança:** [MODULES-INDEX](./MODULES-INDEX.md#segurança) → [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#security-layers)
- **ML/AI:** [MODULES-INDEX](./MODULES-INDEX.md#machine-learning) → [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#mlai-stack)

### Por Tarefa
- **Rebuild sistema:** [QUICK-REFERENCE](./QUICK-REFERENCE.md#sistema-nixos)
- **Modificar keybindings:** [QUICK-REFERENCE](./QUICK-REFERENCE.md#keybindings-importantes)
- **Adicionar alias:** [QUICK-REFERENCE](./QUICK-REFERENCE.md#para-adicionar-aliases)
- **Troubleshooting:** [QUICK-REFERENCE](./QUICK-REFERENCE.md#troubleshooting)

### Por Diagrama
- **Fluxo de config:** [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#fluxo-de-configuração)
- **Desktop stack:** [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#desktop-environment-stack)
- **Shell stack:** [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#shell-environment-stack)
- **Security layers:** [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#security-layers)
- **Rebuild flow:** [VISUAL-ARCH](./VISUAL-ARCHITECTURE.md#rebuild--testing-flow)

---

## 📈 Estatísticas do Sistema

- **Total de arquivos .nix:** 198
- **Total de módulos:** ~130
- **ML models size:** 3.8G
- **Repository size:** 6.9G
- **Total directories:** 647
- **Total files:** 924
- **Aliases definidos:** 50+
- **Funções customizadas:** 5
- **Plugins Zsh:** 9

---

## 🆘 Precisa de Ajuda?

### Para entender o sistema
→ Comece com [VISUAL-ARCHITECTURE.md](./VISUAL-ARCHITECTURE.md)

### Para encontrar onde está algo
→ Use [COMPONENT-MAP.md](./COMPONENT-MAP.md)

### Para uso diário e comandos
→ Consulte [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

### Para detalhes de um módulo
→ Procure em [MODULES-INDEX.md](./MODULES-INDEX.md)

---

## 📝 Outros Documentos Úteis

### Guias Gerais
- `/etc/nixos/docs/guides/MULTI-HOST-SETUP.md` - Setup multi-host
- `/etc/nixos/docs/guides/SECRETS.md` - Gestão de secrets (SOPS)
- `/etc/nixos/docs/guides/SSH-CONFIGURATION.md` - Configuração SSH

### Guias Específicos
- `~/.config/hypr/GUIA-RAPIDO.md` - Hyprland quick guide
- `~/.config/zellij/GUIA-RAPIDO.md` - Zellij quick guide

### Documentação Externa
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Wiki](https://nixos.wiki/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Zellij Docs](https://zellij.dev/)

---

## 🔄 Manutenção da Documentação

Esta documentação deve ser atualizada quando:
- Novos módulos são adicionados
- Estrutura de diretórios muda
- Componentes principais são modificados
- Novos sistemas/hosts são adicionados

**Para atualizar:**
1. Edite os arquivos .md apropriados
2. Mantenha consistência entre os documentos
3. Atualize a data de modificação
4. Verifique links internos

---

**Última atualização:** 2025-11-23
**Mantenedor:** Sistema NixOS kernelcore
**Localização:** `/etc/nixos/docs/architecture/`
