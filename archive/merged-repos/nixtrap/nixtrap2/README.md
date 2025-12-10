# NixOS i3 Modern Setup - Command Reference

## 🎨 Theme Management
- `theme-toggle` / `i3-theme-toggle` - Alterna entre tema claro/escuro
- `theme-dark` / `i3-theme-dark` - Aplica tema escuro
- `theme-light` / `i3-theme-light` - Aplica tema claro

## 🔧 System Management
- `nrs` / `nixos-rebuild-switch` - Aplica configuração NixOS
- `nrt` / `nixos-rebuild-test` - Testa configuração sem persistir
- `nup` / `nixos-update` - Atualiza inputs do flake
- `ncl` / `nixos-cleanup` - Limpa sistema (garbage collection)
- `ngen` / `nixos-generations` - Gerencia gerações do sistema

## 📊 System Monitoring
- `status` / `system-status` - Relatório completo do sistema
- `hwinfo` / `hardware-info` - Informações de hardware
- `svc` / `service-manager` - Gerenciador de serviços (GUI)
- `perf` / `performance-monitor` - Monitor de performance (GUI)

## 🌐 Cache Management
- `cache-status` - Status do servidor binary cache
- `cache-restart` - Reinicia serviços do cache

## ⚡ Quick Actions
- `qs` / `quick-settings` - Painel de configurações rápidas
- `wifi` / `toggle-wifi` - Toggle WiFi
- `bt` / `toggle-bluetooth` - Toggle Bluetooth
- `pm` / `power-menu` - Menu de energia

## 📁 File Operations
- `ll` - Lista detalhada de arquivos
- `tree2` / `tree3` - Árvore de diretórios (2/3 níveis)
- `duf` / `ncdu` - Analisador de uso de disco
- `du1` - Uso de disco (1 nível)

## 🔨 Development
- `edit-config` - Edita configuration.nix
- `edit-home` - Edita home.nix  
- `flake-update` - Atualiza flake na pasta atual
- `dev-setup` - Configuração completa ambiente desenvolvimento
- `gpg-setup` - Configuração e verificação chaves GPG
- `ssh-setup` - Configuração e verificação chaves SSH

## 🔐 Security & Git Configuration
- **GPG Key ID**: `5606AB430E95F5AD`
- **SSH Fingerprint**: `SHA256:5u1XqWhX0ZzB/POQS1+sdmH/fGhHzX0BuZ8G0+/SYY8`
- **Git User**: `voidnxlab <pina@voidnx.com>`
- **Auto-signing**: Habilitado para todos os commits

## ⌨️ Keyboard Shortcuts (Super/Windows Key)

### Applications
- `Super+Return` - Terminal (Alacritty)
- `Super+D` / `Super+Space` - Launcher (Rofi)
- `Super+W` - Firefox
- `Super+B` - Vivaldi
- `Super+E` - File Manager (Thunar)
- `Super+M` - Email (Thunderbird)

### System Controls
- `Super+T` - Toggle Theme
- `Super+L` - Lock Screen
- `Super+Tab` - Window Switcher
- `Super+Ctrl+S` - Quick Settings Panel
- `Super+Ctrl+P` - Power Menu

### Window Management
- `Super+H/J/K/L` - Focus windows
- `Super+Shift+H/J/K/L` - Move windows
- `Super+Ctrl+H/J/K/L` - Resize windows
- `Super+F` - Fullscreen
- `Super+Shift+Space` - Toggle floating

### Workspaces
- `Super+1-9` - Switch to workspace
- `Super+Shift+1-9` - Move window to workspace
- `Super+[/]` - Previous/Next workspace

### Media Controls
- `Super+=/-` - Volume up/down
- `Super+Shift+=/-` - Brightness up/down
- `Super+Ctrl+M` - Mute toggle

### Quick Toggles
- `Super+Ctrl+W` - WiFi toggle
- `Super+Ctrl+B` - Bluetooth toggle
- `Super+Ctrl+N` - Notifications toggle

## 🎛️ System Services
- **nix-serve** - Binary cache server (port 5000)
- **nginx** - HTTPS proxy para cache (port 443)
- **bluetooth** - Bluetooth stack
- **NetworkManager** - Network management

## 📈 Performance Features
- **ZRAM** - 25% RAM para swap comprimido
- **Autotiling** - Organização automática de janelas
- **Polybar** - Barra de status moderna
- **Picom** - Compositor com transparência e sombras
- **Kernel Tuning** - Parâmetros otimizados para performance

## 🔄 Quick Start
1. Aplique a configuração: `nrs`
2. Configure tema inicial: `theme-dark`
3. Acesse configurações rápidas: `Super+Ctrl+S`
4. Monitore sistema: `status`

*Última atualização: 2025-10-26*