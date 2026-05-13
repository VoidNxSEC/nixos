# Advanced Navigation Aliases Guide

**Location**: `modules/shell/aliases/system/navigation.nix`

Modern file browsing with `eza` and `tree` - automatically ignoring build artifacts!

## 🎯 Quick Reference

### Basic Listing (replaces `ls`)

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza` | Modern colorized listing |
| `ll` | `eza -lah --git` | Long format with git status |
| `la` | `eza -a` | Show all files including hidden |
| `l` | `eza -lh --git` | Long format (no hidden) |

### 🌳 Tree Views

| Alias | Depth | Description |
|-------|-------|-------------|
| `lt` | 2 | Tree view (2 levels deep) |
| `lt3` | 3 | Tree view (3 levels) |
| `lt4` | 4 | Tree view (4 levels) |
| `lta` | 2 | Tree with hidden files |
| `ltg` | 2 | Tree with git status |
| `ltg3` | 3 | Tree with git status (3 levels) |

### 📂 Specialized Listing

| Alias | Description |
|-------|-------------|
| `lsd` | Directories only |
| `ltd` | Tree of directories only |
| `lsf` | Files only |
| `lss` | Sort by size (largest last) |
| `lst` | Sort by modified time (newest first) |
| `lsr` | Sort by modified time (oldest first) |
| `recent` | Last 10 modified files |
| `lh` | Hidden files only |
| `lg` | Grid view |
| `l1` | One file per line |

### 🎄 Tree Command (Classic)

All tree commands automatically ignore build artifacts!

| Alias | Description |
|-------|-------------|
| `tree` | Full tree |
| `tree2` | 2 levels deep |
| `tree3` | 3 levels deep |
| `tree4` | 4 levels deep |
| `treea` | Include hidden files |
| `treea2` | Hidden files, 2 levels |
| `treed` | Directories only |
| `trees` | With file sizes |
| `treep` | With permissions |
| `treej` | JSON output (for parsing) |

### 🚀 Project Navigation

| Alias | Description |
|-------|-------------|
| `proj` | Show project structure (3 levels) |
| `projf` | Full project structure (4 levels) |
| `src` | Show only source files |
| `cfg` | Show only config files |
| `lsg` | Git-tracked files only |
| `ltgit` | Git-tracked files (tree view) |
| `lsm` | Modified files with git status |

### 🔍 Smart Search

| Alias | Description |
|-------|-------------|
| `ff <name>` | Find files (excluding artifacts) |
| `fd <name>` | Find directories (excluding artifacts) |
| `frecent` | Recently modified files (24h) |
| `lsts` | All TypeScript files |
| `lsrs` | All Rust files |
| `lsnix` | All Nix files |
| `lspy` | All Python files |

### 📊 Size Analysis

| Alias | Description |
|-------|-------------|
| `large` | 20 largest files |
| `dsize` | 20 largest directories |
| `fcount` | Count files by type |
| `artifacts` | Find build artifact directories |
| `artifacts-size` | Size of all build artifacts |

### 🎯 Quick Navigation

| Alias | Description |
|-------|-------------|
| `home` | Go to ~ and list |
| `nixos` | Go to /etc/nixos and list |
| `nixmod-cd` | Go to modules/ and list |
| `ml` | Go to ML modules and show structure |
| `cdl` | Go back (cd -) and list |

### 📦 NixOS Specific

| Alias | Description |
|-------|-------------|
| `nixmod` | Tree view of all modules |
| `nixsvc` | Tree view of services |
| `nixml` | Tree view of ML modules |

## 🚫 Auto-Ignored Patterns

All aliases automatically ignore these build artifacts:

**Node/JS:**
- `node_modules/`
- `dist/`
- `build/`
- `.next/`
- `.nuxt/`
- `*.map`

**Rust:**
- `target/`

**Python:**
- `__pycache__/`
- `*.pyc`
- `.venv/`
- `venv/`
- `.pytest_cache/`
- `.mypy_cache/`
- `.ruff_cache/`
- `*.egg-info/`

**Databases:**
- `*.db`
- `*.db-shm`
- `*.db-wal`

**Cache:**
- `.cache/`
- `coverage/`
- `.coverage/`

**OS:**
- `.DS_Store`
- `Thumbs.db`

## 💡 Usage Examples

### Example 1: Explore a new project
```bash
cd ~/projects/my-app
proj              # See 3-level overview
src               # See only source files
cfg               # See only config files
```

### Example 2: Find what changed
```bash
lsm               # See modified files with git status
recent            # See last 10 modified files
frecent           # Files modified in last 24h
```

### Example 3: Clean up build artifacts
```bash
artifacts         # Find all artifact directories
artifacts-size    # See how much space they use
# Then manually delete if needed
```

### Example 4: NixOS development
```bash
nixos             # Go to /etc/nixos and list
nixmod            # See module structure
nixml             # See ML module structure
lsnix             # List all .nix files
```

### Example 5: Git workflow
```bash
lsg               # See all tracked files
ltgit             # Tree of tracked files
lsm               # Modified files
gs                # Git status (from utils.nix)
```

## 🎨 Color Coding

**eza** uses smart color coding:
- 🔵 Blue: Directories
- 🟢 Green: Executables
- 🟡 Yellow: Symlinks
- 🔴 Red: Archives
- ⚪ White: Regular files

**Git status indicators** (with `--git` flag):
- `M` Modified
- `N` New
- `I` Ignored
- `!` Untracked

## 🔧 Customization

To add more ignore patterns, edit:
```nix
# /etc/nixos/modules/shell/aliases/system/navigation.nix
ignorePatterns = [
  "node_modules"
  "target"
  # Add your patterns here
];
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## 📚 See Also

- **eza documentation**: `eza --help`
- **tree documentation**: `tree --help`
- Other aliases: `modules/shell/aliases/README.md`
- System utilities: `system/utils.nix` (grep, safety, disk, process, network, git)
