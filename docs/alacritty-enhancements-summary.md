# Alacritty Configuration - Correções e Enhancements

## 🔧 Correção do Parse Error

### Problema Original
```
Parse error at line 206 column 4
```

### Causa
Sintaxe TOML antiga/incorreta para hints:
```toml
# ❌ FORMATO ANTIGO (causava erro)
[hints]
enabled = [
  {
    regex = "...",
    hyperlinks = true,
    ...
  },
]
```

### Solução Aplicada
```toml
# ✅ FORMATO CORRETO (Alacritty 0.16+)
[[hints.enabled]]
regex = "..."
hyperlinks = true
post_processing = true
command = "xdg-open"

[hints.enabled.mouse]
enabled = true
mods = "None"

[hints.enabled.binding]
key = "U"
mods = "Control|Shift"
```

---

## 🚀 Enhancements Implementados

### 1. Módulo Home-Manager Dedicado
**Arquivo**: `/etc/nixos/hosts/kernelcore/home/alacritty.nix`

#### Estrutura Completa:
- ✅ Configuração declarativa via home-manager
- ✅ Integração automática com packages
- ✅ Gestão de dependências (JetBrainsMono Nerd Font)
- ✅ XDG MIME associations (default terminal)

### 2. Melhorias de Configuração

#### Performance & Rendering:
```nix
window = {
  blur = true;  # Background blur (compositor dependent)
  resize_increments = true;  # Better tiling WM integration
};

font = {
  builtin_box_drawing = true;  # Better anti-aliasing
};

env = {
  TERM = "alacritty";
  COLORTERM = "truecolor";  # Enhanced color support
};
```

#### Novos Keybindings:
```nix
# Quick Actions
Ctrl+Shift+N  → Create New Window
Ctrl+Shift+Q  → Quit
Ctrl+Shift+B  → Search Backward

# Enhanced clipboard
Ctrl+Right Click → Paste
```

#### Enhanced Hints System:
```nix
# 1. URL Detection (Ctrl+Shift+U)
- HTTP/HTTPS, FTP, SSH, Git, Magnet, IPFS, etc.
- Click to open with xdg-open

# 2. IP Address Detection (Ctrl+Shift+I)  ← NOVO
- Detect IP addresses (IPv4)
- Ctrl+Click to copy

# 3. Path Detection (Ctrl+Shift+P)  ← NOVO
- Filesystem path detection
- Shift+Click to select
```

### 3. Organização Modular

#### Antes:
```
~/.config/alacritty/alacritty.toml  (standalone)
```

#### Depois:
```
/etc/nixos/hosts/kernelcore/home/
├── alacritty.nix       ← Módulo declarativo
├── home.nix            ← Import do módulo
└── shell/              ← Outras configs

~/.config/alacritty/
└── alacritty.toml      ← Gerado pelo home-manager
```

---

## 📊 Comparação: Antes vs Depois

### Configuração Antiga (TOML manual)
- ❌ Parse error na linha 206
- ⚠️  Hints com sintaxe antiga
- ⚠️  Configuração manual (não declarativa)
- ⚠️  Sem gestão de dependências
- ⚠️  2 hints configurados

### Configuração Nova (Home-Manager)
- ✅ Parse válido (migrado com sucesso)
- ✅ Hints com sintaxe moderna
- ✅ Totalmente declarativo
- ✅ Dependências automáticas
- ✅ 3 hints configurados (URLs, IPs, Paths)
- ✅ Enhanced keybindings
- ✅ Background blur
- ✅ Better tiling WM support
- ✅ XDG MIME integration

---

## 🎯 Features Adicionadas

### 1. **Detecção de IP Addresses**
```nix
[[hints.enabled]]
regex = "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"
binding = { key = "I", mods = "Control|Shift" }
```
**Uso**: Ctrl+Shift+I para highlightar IPs, Ctrl+Click para copiar

### 2. **Detecção de Paths**
```nix
[[hints.enabled]]
regex = "(/?[\\w.-]+)+"
binding = { key = "P", mods = "Control|Shift" }
```
**Uso**: Ctrl+Shift+P para highlightar paths, Shift+Click para selecionar

### 3. **Background Blur (Wayland)**
```nix
window.blur = true;
```
**Resultado**: Terminal com efeito blur de fundo (compositor dependent)

### 4. **Tiling WM Integration**
```nix
window.resize_increments = true;
```
**Resultado**: Melhor comportamento com i3/Hyprland/Sway

### 5. **Enhanced Font Rendering**
```nix
font.builtin_box_drawing = true;
```
**Resultado**: Melhor anti-aliasing para box-drawing characters

### 6. **Clipboard Enhancements**
```nix
mouse.bindings = [
  { mouse = "Middle", action = "PasteSelection" }
  { mouse = "Right", mods = "Control", action = "Paste" }
]
```
**Resultado**: Ctrl+Right Click para colar

---

## 🧪 Testes Realizados

```bash
✅ Config file exists: ~/.config/alacritty/alacritty.toml
✅ Config syntax valid (alacritty migrate --dry-run)
✅ Home-manager module exists
✅ Parse test passed
✅ Alacritty version: 0.16.1
```

---

## 📦 Próximos Passos

### Para Aplicar as Mudanças:

1. **Home-Manager Rebuild**:
```bash
home-manager switch --flake /etc/nixos#kernelcore
```

2. **Ou System Rebuild** (se home-manager integrado):
```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

3. **Verificar Configuração**:
```bash
alacritty --version
alacritty msg config
```

4. **Testar Hints**:
- `Ctrl+Shift+U` → Highlight URLs
- `Ctrl+Shift+I` → Highlight IP addresses
- `Ctrl+Shift+P` → Highlight filesystem paths

---

## 🎨 Customizações Opcionais

### 1. Habilitar Alacritty Daemon (startup mais rápido)
Descomentar no `alacritty.nix`:
```nix
systemd.user.services.alacritty-server = {
  # ... (já configurado, apenas descomentar)
};
```

### 2. Adicionar Mais Hints
Exemplo - Hash detection:
```nix
[[hints.enabled]]
regex = "\\b[0-9a-f]{7,40}\\b"  # Git commit hashes
binding = { key = "H", mods = "Control|Shift" }
```

### 3. Temas Alternativos
Substituir seção `[colors]` por:
- Nord theme
- Dracula theme
- Tokyo Night theme
- One Dark theme

---

## 📚 Documentação

- **Config atual**: `~/.config/alacritty/alacritty.toml`
- **Módulo home-manager**: `/etc/nixos/hosts/kernelcore/home/alacritty.nix`
- **Docs oficiais**: https://alacritty.org/config-alacritty.html
- **Migração TOML**: https://github.com/alacritty/alacritty/blob/master/CHANGELOG.md

---

## ✅ Status Final

```
Parse Error:       ✅ CORRIGIDO
Home-Manager:      ✅ CRIADO
Enhancements:      ✅ IMPLEMENTADO
Testes:            ✅ PASSOU
Ready to Rebuild:  ✅ SIM
```

**Data**: 2025-11-27T04:00:00Z
**Versão**: Alacritty 0.16.1
**Configuração**: Totalmente declarativa via Home-Manager
