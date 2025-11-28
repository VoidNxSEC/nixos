{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Advanced Navigation & Listing Aliases
# Modern file browsing with eza and tree
# ============================================================

let
  # Common ignore patterns for development artifacts
  ignorePatterns = [
    "node_modules"
    "target"
    "build"
    "dist"
    ".next"
    ".nuxt"
    "*.db"
    "*.db-shm"
    "*.db-wal"
    "*.map"
    "*.js.map"
    "*.css.map"
    "*.pyc"
    "__pycache__"
    ".cache"
    ".pytest_cache"
    ".mypy_cache"
    ".ruff_cache"
    "coverage"
    ".coverage"
    "*.egg-info"
    ".venv"
    "venv"
    ".DS_Store"
    "Thumbs.db"
  ];

  # Build tree ignore pattern string
  treeIgnore = lib.concatMapStringsSep "|" (p: p) ignorePatterns;

  # Build eza ignore globs
  ezaIgnore = lib.concatMapStringsSep " " (p: "--ignore-glob '${p}'") ignorePatterns;
in
{
  environment.shellAliases = {
    # ============================================================
    # EZA - Modern replacement for ls
    # ============================================================

    # Basic listing (replace ls)
    "ls" = "eza --group-directories-first --color=always ${ezaIgnore}";
    "ll" = "eza -lah --git --group-directories-first --color=always ${ezaIgnore}";
    "la" = "eza -a --group-directories-first --color=always ${ezaIgnore}";
    "l" = "eza -lh --git --group-directories-first --color=always ${ezaIgnore}";

    # Tree views with eza
    "lt" = "eza --tree --level=2 --group-directories-first --color=always ${ezaIgnore}";
    "lt3" = "eza --tree --level=3 --group-directories-first --color=always ${ezaIgnore}";
    "lt4" = "eza --tree --level=4 --group-directories-first --color=always ${ezaIgnore}";
    "lta" = "eza --tree --level=2 -a --group-directories-first --color=always ${ezaIgnore}";

    # Detailed tree with git status
    "ltg" = "eza --tree --level=2 --long --git --group-directories-first --color=always ${ezaIgnore}";
    "ltg3" = "eza --tree --level=3 --long --git --group-directories-first --color=always ${ezaIgnore}";

    # Only directories
    "lsd" = "eza -D --color=always ${ezaIgnore}";
    "ltd" = "eza --tree --level=2 -D --color=always ${ezaIgnore}";

    # Only files
    "lsf" = "eza -f --color=always ${ezaIgnore}";

    # Sort by size
    "lss" = "eza -lah --sort=size --color=always ${ezaIgnore}";

    # Sort by modified time (newest first)
    "lst" = "eza -lah --sort=modified --color=always ${ezaIgnore}";
    "lsr" = "eza -lah --sort=modified --reverse --color=always ${ezaIgnore}"; # oldest first

    # Recently modified (last 10)
    "recent" = "eza -lah --sort=modified --color=always ${ezaIgnore} | head -11";

    # Show hidden files only
    "lh" = "eza -d .* --color=always";

    # Grid view
    "lg" = "eza --grid --color=always ${ezaIgnore}";

    # One file per line
    "l1" = "eza -1 --color=always ${ezaIgnore}";

    # ============================================================
    # TREE - Classic tree command with smart ignores
    # ============================================================

    # Tree with ignore patterns
    "tree" = "command tree -C -I '${treeIgnore}'";
    "tree2" = "command tree -C -L 2 -I '${treeIgnore}'";
    "tree3" = "command tree -C -L 3 -I '${treeIgnore}'";
    "tree4" = "command tree -C -L 4 -I '${treeIgnore}'";

    # Tree with all files (including hidden)
    "treea" = "command tree -Ca -I '${treeIgnore}'";
    "treea2" = "command tree -Ca -L 2 -I '${treeIgnore}'";
    "treea3" = "command tree -Ca -L 3 -I '${treeIgnore}'";

    # Tree with full paths
    "treef" = "command tree -Cf -I '${treeIgnore}'";

    # Tree directories only
    "treed" = "command tree -Cd -I '${treeIgnore}'";
    "treed2" = "command tree -Cd -L 2 -I '${treeIgnore}'";
    "treed3" = "command tree -Cd -L 3 -I '${treeIgnore}'";

    # Tree with file sizes
    "trees" = "command tree -Ch -s -I '${treeIgnore}'";
    "trees2" = "command tree -Ch -s -L 2 -I '${treeIgnore}'";

    # Tree with permissions
    "treep" = "command tree -Cp -I '${treeIgnore}'";

    # Tree JSON output (for parsing)
    "treej" = "command tree -J -I '${treeIgnore}'";

    # ============================================================
    # PROJECT NAVIGATION - Smart project browsing
    # ============================================================

    # Show project structure (ignore all build artifacts)
    "proj" = "eza --tree --level=3 --group-directories-first --color=always ${ezaIgnore} -I '.git'";
    "projf" = "eza --tree --level=4 --group-directories-first --color=always ${ezaIgnore} -I '.git'";

    # Show only source files (common patterns)
    "src" = "eza --tree --level=3 --color=always ${ezaIgnore} -I '.git|*.lock|*.json|*.yaml|*.yml|*.toml|*.md'";

    # Show only config files
    "cfg" = "eza -lah --color=always --ignore-glob '*.rs' --ignore-glob '*.ts' --ignore-glob '*.js' --ignore-glob '*.py' | grep -E '\\.(nix|toml|yaml|yml|json|conf|config)$'";

    # Show git-tracked files only
    "lsg" = "git ls-files | eza --stdin --color=always";
    "ltgit" = "git ls-files | eza --stdin --tree --color=always";

    # Show modified files with git status
    "lsm" = "git status --short | awk '{print $2}' | eza --stdin --long --git --color=always";

    # ============================================================
    # SPECIALIZED VIEWS
    # ============================================================

    # NixOS modules view
    "nixmod" = "eza --tree --level=3 --color=always ${ezaIgnore} modules/";
    "nixsvc" = "eza --tree --level=2 --color=always ${ezaIgnore} modules/services/";
    "nixml" = "eza --tree --level=3 --color=always ${ezaIgnore} modules/ml/";

    # Show large files
    "large" = "eza -lah --sort=size --reverse --color=always ${ezaIgnore} | tail -20";

    # Show largest directories
    "dsize" = "du -h --max-depth=1 2>/dev/null | sort -hr | head -20";

    # Count files by type
    "fcount" = "find . -type f | sed 's/.*\\.//' | sort | uniq -c | sort -rn | head -20";

    # ============================================================
    # QUICK NAVIGATION
    # ============================================================

    # Common directories (enhanced)
    "home" = "cd ~ && ll";
    "nixos" = "cd /etc/nixos && ll";
    "nixmod-cd" = "cd /etc/nixos/modules && ll";
    "ml" = "cd /etc/nixos/modules/ml && proj";

    # Go back and list
    "cdl" = "cd - && ll";

    # ============================================================
    # SEARCH & FIND (with ignore patterns)
    # ============================================================

    # Find files excluding build artifacts
    "ff" = "find . -type f -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.git/*' -name";

    # Find directories excluding build artifacts
    "fd" = "find . -type d -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.git/*' -name";

    # Find recently modified files (last 24h)
    "frecent" = "find . -type f -mtime -1 -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/build/*' | eza --stdin --long --color=always";

    # ============================================================
    # DEVELOPMENT HELPERS
    # ============================================================

    # Show all TypeScript files
    "lsts" = "find . -name '*.ts' -not -path '*/node_modules/*' -not -path '*/build/*' | eza --stdin --color=always";

    # Show all Rust files
    "lsrs" = "find . -name '*.rs' -not -path '*/target/*' | eza --stdin --color=always";

    # Show all Nix files
    "lsnix" = "find . -name '*.nix' | eza --stdin --color=always";

    # Show all Python files
    "lspy" = "find . -name '*.py' -not -path '*/__pycache__/*' -not -path '*/.venv/*' | eza --stdin --color=always";

    # Check if artifacts exist (for cleanup)
    "artifacts" = "echo 'Checking for build artifacts...' && find . -type d \\( -name node_modules -o -name target -o -name build -o -name dist \\) -not -path '*/.git/*' 2>/dev/null";

    # Show artifact sizes
    "artifacts-size" = "du -sh **/node_modules **/target **/build **/dist 2>/dev/null | sort -hr";
  };
}
