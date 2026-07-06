# Hyprland Keybindings Reference

> **System**: NixOS with Hyprland (Glassmorphism Edition)
> **Last Updated**: 2025-12-16
> **Config Location**: `/home/user/nixos/hosts/kernelcore/home/hyprland.nix`

---

## Quick Reference Card

### Essential Shortcuts

| Key | Action | Notes |
|-----|--------|-------|
| `Super + Return` | Terminal (Kitty + Zellij) | Primary terminal |
| `Super + D` | Application Launcher (Wofi) | App menu |
| `Super + Q` | Close Window | Kill active window |
| `Super + M` | Exit Hyprland | Logout |
| `Super + Escape` | Power Menu (Wlogout) | Shutdown/reboot options |

---

## Terminal Launchers

Hyprland provides **5 terminal variants** for different use cases:

| Keybind | Terminal | Multiplexer | Use Case |
|---------|----------|-------------|----------|
| `Super + Return` | Kitty | Zellij (main) | **Primary** - GPU-accelerated, graphics protocol |
| `Super + Shift + Return` | Alacritty | Zellij (alt) | **Secondary** - Lightweight fallback |
| `Super + Ctrl + Return` | Kitty | None | Plain Kitty (no multiplexer) |
| `Super + Ctrl + Shift + Return` | Alacritty | None | Plain Alacritty (no multiplexer) |
| `Super + Alt + Return` | Foot | Bash | **Emergency** - Minimal terminal |

**Recommendation**: Use `Super + Return` (Kitty + Zellij) for daily work. The others are fallbacks.

---

## Application Launchers

| Keybind | Action | Description |
|---------|--------|-------------|
| `Super + D` | Wofi (drun mode) | Launch applications by name |
| `Super + Shift + D` | Wofi (run mode) | Execute commands directly |
| `Super + E` | Nemo | File manager |

---

## Window Management

### Basic Actions

| Keybind | Action |
|---------|--------|
| `Super + Q` | Kill active window |
| `Super + F` | Fullscreen (no gaps) |
| `Super + Shift + F` | Maximize (keep gaps) |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudotile |
| `Super + J` | Toggle split direction |

### Window Groups (Tabbed Windows)

| Keybind | Action |
|---------|--------|
| `Super + G` | Toggle group mode |
| `Super + Tab` | Next window in group |
| `Super + Shift + Tab` | Previous window in group |

---

## Focus Movement

### Arrow Keys

| Keybind | Direction |
|---------|-----------|
| `Super + ←` | Focus left |
| `Super + →` | Focus right |
| `Super + ↑` | Focus up |
| `Super + ↓` | Focus down |

### Vim Keys

| Keybind | Direction | Mnemonic |
|---------|-----------|----------|
| `Super + H` | Focus left | **H**jkl (vim left) |
| `Super + L` | Focus right | hj**L** (vim right) |
| `Super + K` | Focus up | hj**K** (vim up) |
| `Super + ;` | Focus down | **⚠️ Non-standard** (should be `J`) |

**Note**: `Super + ;` for down is unusual. Vim users expect `J` for down. This may be updated in future refinements.

---

## Window Movement

### Arrow Keys

| Keybind | Action |
|---------|--------|
| `Super + Shift + ←` | Move window left |
| `Super + Shift + →` | Move window right |
| `Super + Shift + ↑` | Move window up |
| `Super + Shift + ↓` | Move window down |

### Vim Keys

| Keybind | Action |
|---------|--------|
| `Super + Shift + H` | Move window left |
| `Super + Shift + L` | Move window right |
| `Super + Shift + K` | Move window up |
| `Super + Shift + J` | Move window down |

---

## Window Resizing

Resize active window (hold keys for continuous resizing):

### Arrow Keys

| Keybind | Action |
|---------|--------|
| `Super + Ctrl + ←` | Shrink width (-50px) |
| `Super + Ctrl + →` | Grow width (+50px) |
| `Super + Ctrl + ↑` | Shrink height (-50px) |
| `Super + Ctrl + ↓` | Grow height (+50px) |

### Vim Keys

| Keybind | Action |
|---------|--------|
| `Super + Ctrl + H` | Shrink width |
| `Super + Ctrl + L` | Grow width |
| `Super + Ctrl + K` | Shrink height |
| `Super + Ctrl + J` | Grow height |

---

## Workspace Management

### Switch Workspaces

| Keybind | Workspace |
|---------|-----------|
| `Super + 1` | Workspace 1 |
| `Super + 2` | Workspace 2 |
| `Super + 3` | Workspace 3 |
| `Super + 4` | Workspace 4 |
| `Super + 5` | Workspace 5 |
| `Super + 6` | Workspace 6 |
| `Super + 7` | Workspace 7 |
| `Super + 8` | Workspace 8 |
| `Super + 9` | Workspace 9 |
| `Super + 0` | Workspace 10 |

### Move Windows to Workspaces

| Keybind | Action |
|---------|--------|
| `Super + Shift + 1-0` | Move active window to workspace 1-10 |

### Workspace Scrolling

| Keybind | Action |
|---------|--------|
| `Super + Mouse Wheel Down` | Next workspace |
| `Super + Mouse Wheel Up` | Previous workspace |

### Special Workspace (Scratchpad)

| Keybind | Action |
|---------|--------|
| `Super + S` | Toggle scratchpad visibility |
| `Super + Shift + S` | Move window to scratchpad |

**Use Case**: Hide/show windows quickly (e.g., music player, notes) without switching workspaces.

---

## Workspace Recommendations

Define workspace purposes for better organization:

| Workspace | Purpose | Suggested Applications |
|-----------|---------|------------------------|
| **1** | Primary Development | Code editors, terminals |
| **2** | Secondary Development | Documentation, testing |
| **3** | Web Browsing | Firefox, Brave |
| **4** | Communication | Discord, email clients |
| **5** | Media/Entertainment | MPV, Spotify |
| **6** | System Monitoring | btop, system tools |
| **7** | Research/Notes | Obsidian, PDF viewers |
| **8** | Graphics/Design | GIMP, Inkscape |
| **9** | Virtual Machines | VMs, containers |
| **10** | Miscellaneous | Temporary workspace |

---

## Screenshots

### Interactive (with Swappy editor)

| Keybind | Action |
|---------|--------|
| `Print` | Select region → Edit in Swappy |
| `Shift + Print` | Fullscreen → Edit in Swappy |

### Direct to File

| Keybind | Action |
|---------|--------|
| `Ctrl + Print` | Select region → Save to `~/Pictures/` |
| `Ctrl + Shift + Print` | Fullscreen → Save to `~/Pictures/` |

### Copy to Clipboard

| Keybind | Action |
|---------|--------|
| `Super + Print` | Select region → Copy to clipboard |

**File Naming**: `screenshot-YYYYMMDD-HHMMSS.png`

---

## Media Controls

### Playback

| Keybind | Action |
|---------|--------|
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86AudioStop` | Stop playback |
| `XF86AudioMute` | Toggle mute |

### Volume

| Keybind | Action |
|---------|--------|
| `XF86AudioRaiseVolume` | Volume +5% (repeatable) |
| `XF86AudioLowerVolume` | Volume -5% (repeatable) |

### Brightness (Laptops)

| Keybind | Action |
|---------|--------|
| `XF86MonBrightnessUp` | Brightness +5% (repeatable) |
| `XF86MonBrightnessDown` | Brightness -5% (repeatable) |

---

## System Actions

### Lock & Power

| Keybind | Action |
|---------|--------|
| `Super + Ctrl + L` | Lock screen (Hyprlock) |
| `Super + Escape` | Power menu (Wlogout) |
| `Super + M` | Exit Hyprland |

**Idle Behavior** (Hypridle):
- 5 minutes idle → Screen locks automatically
- 10 minutes idle → Display turns off (DPMS)
- 30 minutes idle → System suspend (disabled by default)

### Notifications

| Keybind | Action |
|---------|--------|
| `Super + N` | Dismiss current notification |
| `Super + Shift + N` | Dismiss all notifications |

### UI Reload

| Keybind | Action |
|---------|--------|
| `Super + Shift + W` | Reload Waybar |

---

## Mouse Bindings

| Keybind | Action |
|---------|--------|
| `Super + Left Click Drag` | Move window |
| `Super + Right Click Drag` | Resize window |

---

## Miscellaneous

| Keybind | Action |
|---------|--------|
| `Super + Shift + C` | Color picker (Hyprpicker) |

---

## Keybinding Conflicts

### Identified Issues

1. **Focus Down with Vim Keys**:
   - Current: `Super + ;` (semicolon)
   - Expected: `Super + J` (standard vim down)
   - **Conflict**: `Super + J` is used for "toggle split"
   - **Recommendation**: Consider remapping toggle split to `Super + T` or `Super + \`

2. **Multiple Terminal Launchers**:
   - 5 different terminal combinations configured
   - **Recommendation**: Most users only need 1-2 variants

### No Conflicts Detected

All other keybindings are properly scoped with modifier combinations.

---

## Design Philosophy

### Modifier Key Usage

- **Super** (alone): Primary actions (launch, switch)
- **Super + Shift**: Secondary actions (move, alternative mode)
- **Super + Ctrl**: Tertiary actions (resize, system)
- **Super + Alt**: Emergency/rare actions

### Ergonomics

- **Most common actions** use easy keys (Return, D, Q, F)
- **Window focus** supports both arrows (intuitive) and vim keys (efficient)
- **Repeatable actions** (volume, brightness, resize) use `binde` for hold-to-repeat

### Consistency

- Arrow keys and vim keys mirror each other
- Shift modifier = move/alternative
- Ctrl modifier = resize/system-level

---

## Tips for New Users

1. **Start with arrow keys**: More intuitive than vim keys
2. **Master Super + D**: Application launcher is your gateway
3. **Learn workspace switching**: `Super + 1-9` for quick navigation
4. **Use scratchpad**: `Super + S` for frequently accessed windows
5. **Screenshot workflow**: `Print` for interactive, `Super + Print` for quick clipboard

---

## Advanced Usage

### Window Groups (Tabbed Windows)

1. Open multiple windows
2. Press `Super + G` to enable group mode
3. Drag windows on top of each other to create tabs
4. Use `Super + Tab` to cycle through tabs
5. Press `Super + G` again to ungroup

### Floating Window Workflow

1. Press `Super + V` to float a window
2. Use `Super + Left Click Drag` to position
3. Use `Super + Right Click Drag` to resize
4. Press `Super + V` again to tile

### Multi-Monitor Tips

- Workspaces follow monitors automatically
- Use `Super + Shift + ←/→` to move windows between monitors
- Mouse wheel workspace switching is per-monitor

---

## Configuration Location

All keybindings are defined in:
```
/home/user/nixos/hosts/kernelcore/home/hyprland.nix
Lines 382-534
```

**Modification**: Edit the file and run:
```bash
nixos-rebuild switch --flake /etc/nixos#kernelcore
```

---

## Related Documentation

- [Hyprland Configuration](../hosts/kernelcore/home/hyprland.nix)
- [Glassmorphism Design System](./GLASSMORPHISM-DESIGN-SYSTEM.md)
- [Hyprland Wiki - Binds](https://wiki.hyprland.org/Configuring/Binds/)
- [Window Rules](https://wiki.hyprland.org/Configuring/Window-Rules/)

---

**Version**: 1.0.0
**Generated**: Phase 4 - Hyprland Design Overhaul
**Quality**: GOLD
