# Referência Rápida - Arquitetura do Sistema

**Host:** kernelcore | **Data:** 2025-11-23

---

## 🎯 Localização Rápida dos Componentes

### Shell (Zsh)
```bash
# Configuração NixOS (EDITAR AQUI)
/etc/nixos/hosts/kernelcore/home/shell/zsh.nix

# Tema Powerlevel10k
/etc/nixos/hosts/kernelcore/home/shell/p10k.zsh

# Arquivo gerado (NÃO EDITAR)
~/.zshrc

# Aplicar mudanças
home-manager switch --flake /etc/nixos#kernelcore@kernelcore
```

### Desktop (Hyprland)
```bash
# Módulo do sistema
/etc/nixos/modules/desktop/hyprland.nix

# Configuração do usuário (EDITAR AQUI)
~/.config/hypr/hyprland.conf

# Guia rápido
~/.config/hypr/GUIA-RAPIDO.md

# Recarregar config
hyprctl reload
# ou
SUPER+SHIFT+R
```

### Terminal Multiplexer (Zellij)
```bash
# Definição do pacote
/etc/nixos/modules/packages/tar-packages/packages/zellij.nix

# Configuração (EDITAR AQUI)
~/.config/zellij/config.kdl

# Guia rápido
~/.config/zellij/GUIA-RAPIDO.md

# Iniciar
zellij
```

### Aliases
```bash
# Aliases modulares
/etc/nixos/modules/shell/aliases/

# Aliases inline no zsh.nix
/etc/nixos/hosts/kernelcore/home/shell/zsh.nix (linhas 124-197)

# Ver todos aliases
alias
```

---

## 📂 Estrutura de Diretórios Essencial

```
/etc/nixos/
├── flake.nix                    # Entry point principal
├── hosts/kernelcore/
│   ├── configuration.nix        # Config do sistema
│   ├── hardware-configuration.nix
│   └── home/
│       ├── home.nix             # Home Manager config
│       └── shell/
│           ├── zsh.nix          ★ ZSH CONFIG
│           └── p10k.zsh         ★ PROMPT CONFIG
├── modules/
│   ├── desktop/
│   │   └── hyprland.nix         ★ HYPRLAND MODULE
│   ├── packages/
│   │   └── tar-packages/
│   │       └── packages/
│   │           └── zellij.nix   ★ ZELLIJ PACKAGE
│   ├── shell/
│   │   └── aliases/             ★ ALIASES MODULARES
│   ├── security/                # Hardening & security
│   ├── hardware/                # Drivers (NVIDIA, Intel, etc)
│   ├── ml/                      # ML/AI stack
│   └── services/                # Systemd services
└── docs/
    └── architecture/            ★ VOCÊ ESTÁ AQUI
        ├── COMPONENT-MAP.md
        ├── VISUAL-ARCHITECTURE.md
        └── QUICK-REFERENCE.md
```

---

## ⚡ Comandos Essenciais

### Sistema NixOS

```bash
# Rebuild do sistema (system-level)
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Rebuild apenas teste (não ativa)
sudo nixos-rebuild test --flake /etc/nixos#kernelcore

# Build sem switch
sudo nixos-rebuild build --flake /etc/nixos#kernelcore

# Verificar configuração
nix flake check /etc/nixos

# Listar gerações
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Voltar para geração anterior
sudo nixos-rebuild switch --rollback
```

### Home Manager

```bash
# Rebuild home-manager (user-level)
home-manager switch --flake /etc/nixos#kernelcore@kernelcore

# Build sem switch
home-manager build --flake /etc/nixos#kernelcore@kernelcore

# Listar gerações
home-manager generations
```

### Hyprland

```bash
# Recarregar configuração
hyprctl reload

# Ver keybindings
hyprctl binds

# Info do monitor
hyprctl monitors

# Listar janelas
hyprctl clients

# Reload waybar
killall waybar && waybar &
```

### Zellij

```bash
# Iniciar
zellij

# Iniciar com sessão específica
zellij attach nome-sessao

# Listar sessões
zellij list-sessions

# Deletar sessão
zellij delete-session nome-sessao

# Keybindings principais:
# Alt+t         - Nova tab
# Alt+w         - Fechar tab
# Alt+h/j/k/l   - Criar panes
# Alt+arrows    - Navegar panes
# Alt+f         - Fullscreen
# Alt+s         - Modo scroll
```

### Zsh

```bash
# Recarregar config
source ~/.zshrc
# ou
exec zsh

# Ver plugins carregados
echo $plugins

# Reconfigurar Powerlevel10k
p10k configure

# Ver aliases
alias

# Ver funções
functions
```

---

## 🔧 Edição de Configurações

### Para modificar Zsh:

1. Edite: `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix`
2. Rebuild: `home-manager switch --flake /etc/nixos#kernelcore@kernelcore`
3. Recarregue: `exec zsh` ou abra novo terminal

### Para modificar Hyprland:

1. Edite: `~/.config/hypr/hyprland.conf`
2. Recarregue: `hyprctl reload` ou `SUPER+SHIFT+R`

### Para modificar Zellij:

1. Edite: `~/.config/zellij/config.kdl`
2. Reinicie zellij ou inicie nova sessão

### Para adicionar aliases:

**Opção 1:** Inline no zsh.nix
```nix
# /etc/nixos/hosts/kernelcore/home/shell/zsh.nix
shellAliases = {
  myalias = "echo hello";
  ...
};
```

**Opção 2:** Criar módulo em aliases/
```nix
# /etc/nixos/modules/shell/aliases/custom/myaliases.nix
{
  programs.zsh.shellAliases = {
    myalias = "echo hello";
  };
}
```

---

## 📊 Componentes por Categoria

### Desktop Environment
| Componente | Arquivo Config | Localização Módulo |
|-----------|---------------|-------------------|
| Hyprland | `~/.config/hypr/hyprland.conf` | `/etc/nixos/modules/desktop/hyprland.nix` |
| Waybar | `~/.config/waybar/config` | Incluído no módulo hyprland |
| Wofi | `~/.config/wofi/` | Incluído no módulo hyprland |
| Dunst | `~/.config/dunst/` | Incluído no módulo hyprland |

### Shell Environment
| Componente | Arquivo Config | Localização Módulo |
|-----------|---------------|-------------------|
| Zsh | `~/.zshrc` (gerado) | `/etc/nixos/hosts/kernelcore/home/shell/zsh.nix` |
| Powerlevel10k | `~/.p10k.zsh` | `/etc/nixos/hosts/kernelcore/home/shell/p10k.zsh` |
| Bash | `~/.bashrc` | `/etc/nixos/hosts/kernelcore/home/shell/bash.nix` |

### Terminal
| Componente | Arquivo Config | Localização Módulo |
|-----------|---------------|-------------------|
| Alacritty | `~/.config/alacritty/` | Configurado via home-manager |
| Zellij | `~/.config/zellij/config.kdl` | `/etc/nixos/modules/packages/tar-packages/packages/zellij.nix` |

### Segurança
| Componente | Localização Módulo |
|-----------|-------------------|
| Hardening | `/etc/nixos/modules/security/hardening.nix` |
| Kernel | `/etc/nixos/modules/security/kernel.nix` |
| Network | `/etc/nixos/modules/security/network.nix` |
| SSH | `/etc/nixos/modules/security/ssh.nix` |
| Auditd | `/etc/nixos/modules/security/audit.nix` |
| AIDE | `/etc/nixos/modules/security/aide.nix` |

### Hardware
| Componente | Localização Módulo |
|-----------|-------------------|
| NVIDIA | `/etc/nixos/modules/hardware/nvidia.nix` |
| Intel | `/etc/nixos/modules/hardware/intel.nix` |
| Bluetooth | `/etc/nixos/modules/hardware/bluetooth.nix` |
| Thermal | `/etc/nixos/modules/hardware/thermal-profiles.nix` |

### Machine Learning
| Componente | Localização Módulo |
|-----------|-------------------|
| Ollama GPU Manager | `/etc/nixos/modules/ml/ollama-gpu-manager.nix` |
| Llama Models | `/etc/nixos/modules/ml/llama.nix` |
| Model Storage | `/etc/nixos/modules/ml/models-storage.nix` |
| VRAM Intelligence | `/etc/nixos/modules/ml/offload/vram-intelligence.nix` |

---

## 🎨 Temas e Cores

### Hyprland
```
Border (ativo):   rgba(7aa2f7ee) → rgba(7fdbcaee) 45deg gradient
Border (inativo): rgba(29323aaa)
Opacity (ativo):  0.96
Opacity (inativo): 0.88
Terminal opacity: 0.94
Rounding: 8px
Blur: enabled (size 5, passes 2)
```

### Zellij (Gruvbox Dark)
```
fg:      #ebdbb2
bg:      #282828
black:   #3c3836
red:     #cc241d
green:   #98971a
yellow:  #d79921
blue:    #458588
magenta: #b16286
cyan:    #689d6a
white:   #a89984
orange:  #d65d0e
```

### Powerlevel10k
```
Configuração customizada em ~/.p10k.zsh
Instant prompt habilitado
```

---

## 🔑 Keybindings Importantes

### Hyprland
| Atalho | Ação |
|--------|------|
| `SUPER + Return` | Terminal (Alacritty) |
| `SUPER + D` | Launcher (Wofi) |
| `SUPER + Q` | Fechar janela |
| `SUPER + F` | Fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + h/j/k/l` | Mover foco (vim-style) |
| `SUPER + SHIFT + h/j/k/l` | Mover janela |
| `SUPER + CTRL + h/j/k/l` | Resize janela |
| `SUPER + 1-9` | Workspace 1-9 |
| `SUPER + L` | Lock screen |

### Zellij
| Atalho | Ação |
|--------|------|
| `Alt + t` | Nova tab |
| `Alt + w` | Fechar tab |
| `Alt + n/p` | Próxima/anterior tab |
| `Alt + h/j/k/l` | Criar pane (esquerda/baixo/cima/direita) |
| `Alt + arrows` | Navegar entre panes |
| `Alt + f` | Fullscreen pane |
| `Alt + s` | Modo scroll |
| `Alt + x` | Fechar pane |
| `Alt + r` | Renomear tab |

### Zsh
| Atalho | Ação |
|--------|------|
| `↑ / ↓` | History substring search |
| `Ctrl + →/←` | Word navigation |
| `Ctrl + R` | FZF history search |
| `Ctrl + T` | FZF file search |
| `Tab` | Autocompletion |

---

## 🛠️ Troubleshooting

### Zsh não carrega config
```bash
# Verificar se ~/.zshrc existe
ls -la ~/.zshrc

# Rebuild home-manager
home-manager switch --flake /etc/nixos#kernelcore@kernelcore

# Reiniciar shell
exec zsh
```

### Hyprland não inicia
```bash
# Ver logs
journalctl -u display-manager -xe

# Verificar configuração
hyprctl version

# Testar config
Hyprland
```

### Zellij não encontra config
```bash
# Verificar localização
echo $ZELLIJ_CONFIG_DIR

# Verificar arquivo
ls -la ~/.config/zellij/config.kdl

# Iniciar com config explícita
zellij --config ~/.config/zellij/config.kdl
```

### Sistema não builda
```bash
# Verificar sintaxe
nix flake check /etc/nixos

# Ver erro detalhado
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --show-trace

# Verificar git status
cd /etc/nixos && git status
```

---

## 📚 Documentação Relacionada

### Arquitetura
- [COMPONENT-MAP.md](./COMPONENT-MAP.md) - Mapa completo de componentes
- [VISUAL-ARCHITECTURE.md](./VISUAL-ARCHITECTURE.md) - Diagramas visuais

### Guias
- `/etc/nixos/docs/guides/MULTI-HOST-SETUP.md` - Setup multi-host
- `/etc/nixos/docs/guides/SECRETS.md` - Gestão de secrets
- `/etc/nixos/docs/guides/SSH-CONFIGURATION.md` - Config SSH

### Guias Rápidos
- `~/.config/hypr/GUIA-RAPIDO.md` - Hyprland quick guide
- `~/.config/zellij/GUIA-RAPIDO.md` - Zellij quick guide

### NixOS Docs
- https://nixos.org/manual/nixos/stable/
- https://nixos.wiki/

### Home Manager
- https://nix-community.github.io/home-manager/

---

## 🔍 Busca Rápida

```bash
# Encontrar todos arquivos .nix
find /etc/nixos -name "*.nix" -type f

# Buscar por palavra-chave nos configs
grep -r "hyprland" /etc/nixos/modules/

# Listar todos módulos
ls /etc/nixos/modules/*/

# Ver estrutura
tree /etc/nixos -L 3
```

---

## 📈 Estatísticas

- **Arquivos .nix:** 198
- **Módulos:** ~130
- **Aliases definidos:** 50+
- **Funções customizadas:** 5
- **Plugins Zsh:** 9
- **ML models size:** 3.8G
- **Repo size:** 6.9G

---

**Última atualização:** 2025-11-23
