# Shell Configuration Module

Modern, modular shell configuration with Zsh + Powerlevel10k or Bash with Starship.

## Features

### Zsh Configuration
- 🎨 **Powerlevel10k Theme** - Beautiful and fast prompt
- 🚀 **Advanced Auto-completion** - Fuzzy matching, case-insensitive, categorized
- 📝 **Syntax Highlighting** - Real-time command validation
- 💡 **Auto-suggestions** - Fish-like suggestions from history
- 🔧 **Oh-My-Zsh** - With curated plugins
- ⚡ **Performance Optimized** - Instant prompt, caching enabled

### Bash Configuration (Alternative)
- ⭐ **Starship Prompt** - Fast, minimal prompt
- 🛠️ **Same aliases** - Consistency between shells
- 📚 **Enhanced history** - Better history management

### Advanced Completion Features
- **Fuzzy matching** - Typo tolerance in completions
- **Case-insensitive** - `cd Doc` → `cd Documents`
- **Colored menus** - Visual categorization
- **Smart suggestions** - Context-aware completions
- **Process completion** - Enhanced `kill` command
- **SSH/SCP completion** - Hostname auto-completion
- **Docker completion** - Full Docker command support
- **Git completion** - Enhanced git command support
- **AWS CLI completion** - Cloud command completions

### Integrated Tools
- **eza** - Modern `ls` with icons and git integration
- **bat** - Better `cat` with syntax highlighting
- **ripgrep** - Faster `grep` with smart defaults
- **fd** - User-friendly `find` alternative
- **fzf** - Fuzzy finder for files and history
- **zoxide** - Smarter `cd` that learns your habits
- **direnv** - Directory-based environments

## Configuration Options

In `home.nix`:

```nix
myShell = {
  enable = true;                  # Enable custom shell config
  defaultShell = "zsh";           # Options: "zsh" or "bash"
  enablePowerlevel10k = true;     # Enable P10k theme (zsh only)
  enableNerdFonts = true;         # Enable Nerd Font support
};
```

## Switching Shells

### Switch to Zsh
```bash
# Edit home.nix
myShell.defaultShell = "zsh";

# Rebuild
home-manager switch --flake /etc/nixos#kernelcore

# Or use alias (if set)
chsh -s $(which zsh)
exec zsh
```

### Switch to Bash
```bash
# Edit home.nix
myShell.defaultShell = "bash";

# Rebuild
home-manager switch --flake /etc/nixos#kernelcore
```

## Customization

### Powerlevel10k Prompt
To customize the Powerlevel10k prompt:
```bash
p10k configure
```

This will run an interactive wizard to customize:
- Prompt style (lean, classic, rainbow, pure)
- Character set (Unicode, ASCII, Nerd Fonts)
- Prompt colors
- Prompt elements
- Transient prompt

The configuration is saved to `~/.p10k.zsh` and sourced automatically.

### Adding Aliases
Add aliases in either:
- `/etc/nixos/modules/shell/aliases/` - System-wide (via NixOS modules)
- `./shell/zsh.nix` or `./shell/bash.nix` - Home-manager specific

### Adding Completions
Completions are automatically loaded from:
- Oh-My-Zsh plugins
- System packages with zsh completions
- Nix-installed completions

To add custom completions, edit the `completionInit` section in `zsh.nix`.

## Aliases

### Navigation
- `ll` - Detailed list with icons and git status
- `la` - List all files
- `lt` - Tree view
- `..`, `...`, `....` - Quick parent directory navigation

### Git
- `gs` - git status
- `ga` - git add
- `gc` - git commit -m
- `gp` - git push
- `gl` - Pretty git log

### Docker
- `dps` - Pretty docker ps
- `dimg` - List images
- `dstop` - Stop all containers
- `dclean` - Clean up system

### System
- `cat` → `bat` - Syntax highlighted cat
- `grep` → `rg` - Faster grep
- `ls` → `eza` - Modern ls

## Key Bindings (Zsh)

- `Ctrl + R` - Fuzzy history search
- `Ctrl + T` - Fuzzy file finder
- `Alt + C` - Fuzzy directory change
- `↑/↓` - History substring search
- `Ctrl + ←/→` - Word navigation
- `Tab` - Smart completion with menu

## Functions

### `up [n]`
Navigate up N directories
```bash
up 3  # cd ../../..
```

### `extract <file>`
Extract any archive format
```bash
extract file.tar.gz
```

### `backup <file>`
Quick backup with timestamp
```bash
backup important.conf
```

### `mkcd <dir>`
Create directory and cd into it
```bash
mkcd new-project
```

### `note <message>`
Quick note taking
```bash
note "Remember to check logs"
```

## Performance

- **Instant Prompt** - Powerlevel10k instant prompt for sub-10ms startup
- **Completion Caching** - Cached at `~/.zsh/cache`
- **Lazy Loading** - Plugins load on-demand
- **Optimized History** - Fast history search with sharing

## Troubleshooting

### Prompt looks broken
Make sure you have a Nerd Font installed and set in your terminal:
- JetBrainsMono Nerd Font (recommended)
- FiraCode Nerd Font
- Hack Nerd Font

### Completions not working
```bash
# Rebuild completion cache
rm -rf ~/.zsh/cache
autoload -Uz compinit && compinit
```

### Slow startup
```bash
# Profile zsh startup
zsh -xv
```

### P10k instant prompt warnings
These are usually safe to ignore, but you can disable instant prompt:
```bash
# In home.nix
myShell.enablePowerlevel10k = false;
```

## Files

```
shell/
├── README.md          # This file
├── default.nix        # Main module entry
├── options.nix        # Configuration options
├── zsh.nix           # Zsh configuration
├── bash.nix          # Bash configuration
└── p10k.zsh          # Powerlevel10k theme config
```

## Resources

- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Oh My Zsh](https://ohmyz.sh/)
- [Zsh Guide](http://zsh.sourceforge.net/Guide/)
- [Advanced Completion](https://thevaluable.dev/zsh-completion-guide-examples/)
