# 🌊 Niri Configuration - Glassmorphism Edition

## O Paradigma Niri: Scrolling Compositor

Enquanto o Hyprland opera com **workspaces discretos** (1, 2, 3...) onde janelas são "tiles" em um grid, Niri é fundamentalmente diferente:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HYPRLAND MENTAL MODEL                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   [Workspace 1]         [Workspace 2]         [Workspace 3]                │
│   ┌─────┬─────┐        ┌───────────┐         ┌─────┬─────┐                │
│   │     │     │        │           │         │     │     │                │
│   │ A   │ B   │        │     C     │         │ D   │ E   │                │
│   │     │     │        │           │         │     │     │                │
│   └─────┴─────┘        └───────────┘         └─────┴─────┘                │
│                                                                             │
│   → Workspaces são containers isolados                                      │
│   → Janelas ficam "presas" em um workspace                                  │
│   → Navegação: Super+1, Super+2, Super+3...                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            NIRI MENTAL MODEL                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ← ← ← ← ← ← ← ←     INFINITE HORIZONTAL SCROLL      → → → → → → → → →    │
│                                                                             │
│   ┌─────┐  ┌─────┐  ┌─────┐  ┌───────────┐  ┌─────┐  ┌─────┐  ┌─────┐     │
│   │     │  │     │  │     │  │           │  │     │  │     │  │     │     │
│   │ A   │  │ B   │  │ C   │  │     D     │  │ E   │  │ F   │  │ G   │     │
│   │     │  │     │  │     │  │           │  │     │  │     │  │     │     │
│   └─────┘  └─────┘  └─────┘  └───────────┘  └─────┘  └─────┘  └─────┘     │
│     │        │                     │                    │                  │
│     └────────┴─────────────────────┴────────────────────┘                  │
│                    ↑ VIEWPORT (o que você vê) ↑                            │
│                                                                             │
│   → Janelas são COLUNAS em uma fita infinita                               │
│   → Você SCROLLA horizontalmente entre elas                                │
│   → Colunas podem ter múltiplas janelas empilhadas verticalmente           │
│   → Navegação: Mod+H/L (scroll) ou Mod+Shift+H/L (move)                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Conceitos-Chave

### Colunas vs Tiles

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COLUNA COM MÚLTIPLAS JANELAS                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│         Coluna 1        Coluna 2           Coluna 3                        │
│        ┌───────┐       ┌───────┐          ┌───────┐                        │
│        │ Win A │       │ Win C │          │ Win E │                        │
│        ├───────┤       │       │          │       │                        │
│        │ Win B │       │       │          │       │                        │
│        └───────┘       └───────┘          └───────┘                        │
│                                                                             │
│   - Mod+J/K navega DENTRO da coluna (vertical)                             │
│   - Mod+H/L navega ENTRE colunas (horizontal)                              │
│   - Mod+[ consome janela para coluna (merge)                               │
│   - Mod+] expele janela da coluna (split)                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Larguras Preset

O Niri tem larguras predefinidas que você cicla com `Mod+R`:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PRESET COLUMN WIDTHS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   33% ───────────→   50% ───────────→   66% ───────────→   100%            │
│   ┌─────┐            ┌───────┐          ┌──────────┐       ┌─────────────┐ │
│   │     │            │       │          │          │       │             │ │
│   │ 1/3 │            │  1/2  │          │   2/3    │       │    FULL     │ │
│   │     │            │       │          │          │       │             │ │
│   └─────┘            └───────┘          └──────────┘       └─────────────┘ │
│                                                                             │
│   Mod+R cicla entre essas larguras                                         │
│   Mod+Ctrl+H/L ajusta manualmente (-10% / +10%)                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Mapeamento de Keybindings: Hyprland → Niri

| Ação | Hyprland | Niri |
|------|----------|------|
| **Navegação** | | |
| Foco esquerda | `Mod+H` | `Mod+H` (coluna anterior) |
| Foco direita | `Mod+L` | `Mod+L` (próxima coluna) |
| Foco cima | `Mod+K` | `Mod+K` (janela acima na coluna) |
| Foco baixo | `Mod+J` | `Mod+J` (janela abaixo na coluna) |
| **Mover janelas** | | |
| Mover esquerda | `Mod+Shift+H` | `Mod+Shift+H` (mover coluna) |
| Mover direita | `Mod+Shift+L` | `Mod+Shift+L` (mover coluna) |
| **Workspaces** | | |
| Ir para workspace | `Mod+1-9` | `Mod+1-5` (named workspaces) |
| Mover para workspace | `Mod+Shift+1-9` | `Mod+Shift+1-5` |
| **Layout** | | |
| Fullscreen | `Mod+F` | `Mod+Shift+F` |
| Maximize | N/A | `Mod+F` (maximize column) |
| Toggle float | `Mod+V` | `Mod+V` |
| **Resize** | | |
| Resize | `Mod+Ctrl+HJKL` | `Mod+Ctrl+H/L` (width) / `Mod+Ctrl+J/K` (height) |
| Cycle width | N/A | `Mod+R` |
| **Niri-specific** | | |
| Merge into column | N/A | `Mod+[` |
| Split from column | N/A | `Mod+]` |
| Center column | N/A | `Mod+Ctrl+C` |

## Instalação

### 1. Adicionar niri-flake ao flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Adicionar niri-flake
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, niri, ... }: {
    nixosConfigurations.kernelcore = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Módulo NixOS do Niri
        niri.nixosModules.niri
        
        # Habilitar Niri no sistema
        {
          programs.niri.enable = true;
          # Pacote do niri-flake (mais atualizado)
          programs.niri.package = niri.packages.x86_64-linux.niri-unstable;
        }
        
        home-manager.nixosModules.home-manager
        {
          home-manager.users.pina = {
            imports = [
              # Módulo home-manager do Niri
              niri.homeModules.niri
              
              # Suas configs
              ./hosts/kernelcore/home/glassmorphism  # Sistema de design
              ./hosts/kernelcore/home/niri.nix       # Config Niri (NOVO)
              ./hosts/kernelcore/home/waybar-niri.nix # Waybar adaptado
              # NÃO importar hyprland.nix
            ];
          };
        }
      ];
    };
  };
}
```

### 2. Estrutura de arquivos

```
hosts/kernelcore/home/
├── glassmorphism/           # ✅ Manter (funciona com Niri)
│   ├── default.nix
│   ├── colors.nix
│   ├── kitty.nix
│   ├── zellij.nix
│   ├── mako.nix
│   ├── wofi.nix
│   ├── waybar.nix           # ❌ Substituir por waybar-niri.nix
│   ├── wlogout.nix          # ✅ Funciona
│   ├── swappy.nix           # ✅ Funciona
│   ├── wallpaper.nix        # ✅ Funciona (swaybg)
│   ├── hyprlock.nix         # ❌ Substituir por swaylock
│   └── agent-hub.nix        # ✅ Funciona
├── hyprland.nix             # ❌ Comentar/remover
├── niri.nix                 # ✅ NOVO
├── waybar-niri.nix          # ✅ NOVO
└── alacritty.nix            # ✅ Manter
```

### 3. Modificar glassmorphism/default.nix

```nix
# Remover ou comentar a importação do hyprlock
imports = [
  ./colors.nix
  ./kitty.nix
  ./zellij.nix
  ./wallpaper.nix
  # ./waybar.nix      # ← Comentar (usar waybar-niri.nix separado)
  ./mako.nix
  ./wofi.nix
  # ./hyprlock.nix    # ← Comentar (usar swaylock)
  ./wlogout.nix
  ./swappy.nix
  ./agent-hub.nix
];
```

## Limitações do Niri vs Hyprland

| Feature | Hyprland | Niri |
|---------|----------|------|
| Blur effects | ✅ Completo | ⚠️ Básico (sem blur customizado) |
| Window opacity | ✅ Por janela | ✅ Por regra |
| Animations | ✅ Bezier customizáveis | ✅ Spring-based |
| Workspaces | Discretos (1-10) | Infinito + named |
| Tiling | Master-stack, dwindle | Scrolling columns |
| Plugins | ✅ Hyprland plugins | ❌ Não suporta |
| IPC | ✅ hyprctl | ✅ niri msg |
| XWayland | ✅ Completo | ✅ Completo |

## Dicas de Workflow

### 1. Pense em "Colunas", não "Tiles"

No Hyprland você pensa: "vou abrir essa janela do lado direito"
No Niri você pensa: "vou criar uma nova coluna à direita"

### 2. Use merge/expel para organizar

- `Mod+[` (consume): Pega a janela da coluna anterior e adiciona à sua coluna atual
- `Mod+]` (expel): Tira a janela do fundo da sua coluna e cria nova coluna

### 3. Named workspaces como "âncoras"

Os workspaces `dev`, `web`, `chat`, `media`, `sys` são pontos de referência fixos.
Você pode estar scrollando infinitamente e pular direto pra `Mod+1` (dev).

### 4. Center column é seu amigo

`Mod+Ctrl+C` centraliza a coluna focada - útil quando você se perde no scroll.

## Troubleshooting

### Waybar não mostra workspaces
O módulo `hyprland/workspaces` não funciona no Niri. Use o `custom/niri-workspaces` configurado em `waybar-niri.nix`.

### swaylock não funciona
Certifique-se que o PAM está configurado:
```nix
security.pam.services.swaylock = {};
```

### Janelas não têm transparência
Niri não tem blur compositor. A transparência depende das aplicações suportarem. Kitty e Alacritty funcionam.

### niri msg retorna erro
Verifique se o socket existe:
```bash
ls $XDG_RUNTIME_DIR/niri*.socket
```

## Comandos úteis

```bash
# Ver estado das janelas
niri msg windows

# Ver workspaces
niri msg workspaces

# Ver janela focada
niri msg focused-window

# Executar ação programaticamente
niri msg action spawn kitty
niri msg action focus-column-right
niri msg action maximize-column

# Reload config (sem reiniciar)
# Niri recarrega automaticamente quando o arquivo muda!

# Screenshot via IPC
niri msg action screenshot
```

## Referências

- [Niri GitHub](https://github.com/YaLTeR/niri)
- [niri-flake](https://github.com/sodiboo/niri-flake)
- [Niri Wiki](https://github.com/YaLTeR/niri/wiki)
- [KDL Config Reference](https://github.com/YaLTeR/niri/wiki/Configuration:-Overview)
