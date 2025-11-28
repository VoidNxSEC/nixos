{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# System Utility Aliases
# ============================================================

{
  environment.shellAliases = {
    # NOTE: List aliases (ll, la, l, ls) are now in navigation.nix with eza

    # Grep with color
    "grep" = "grep --color=auto";
    "fgrep" = "fgrep --color=auto";
    "egrep" = "egrep --color=auto";

    # Safety
    "rm" = "rm -i";
    "cp" = "cp -i";
    "mv" = "mv -i";

    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";

    # Disk usage
    "df" = "df -h";
    "du" = "du -h";
    "duh" = "du -h --max-depth=1 | sort -hr";

    # Process
    "psg" = "ps aux | grep -v grep | grep -i -e VSZ -e";
    "topcpu" = "ps aux --sort=-%cpu | head -10";
    "topmem" = "ps aux --sort=-%mem | head -10";

    # Network
    "ports" = "netstat -tulanp";
    "myip" = "curl -s ifconfig.me";

    # Git shortcuts
    "gs" = "git status";
    "ga" = "git add";
    "gc" = "git commit -m";
    "gp" = "git push";
    "gl" = "git log --oneline -10";

    # ============================================================
    # ALIAS MANAGEMENT & DEBUGGING
    # ============================================================

    # Show all active aliases (sorted)
    "aliases" = "alias | sort";

    # Find where an alias is defined in NixOS config
    "alias-find" = "grep -r --color=always -n -A 2 -B 1 --include='*.nix' -e '\"$1\"' /etc/nixos/modules/shell/aliases/ 2>/dev/null || echo 'Alias not found in config files'";

    # Search for aliases matching a pattern
    "alias-search" = "alias | grep --color=always -i";

    # Show all alias definition files
    "alias-files" = "find /etc/nixos/modules/shell/aliases -name '*.nix' -type f -exec echo '{}' \\; -exec head -1 '{}' \\; -exec echo '' \\;";

    # List aliases by category
    "alias-docker" = "grep -h '=' /etc/nixos/modules/shell/aliases/docker/*.nix 2>/dev/null | grep -v '^#' | sort";
    "alias-k8s" = "grep -h '=' /etc/nixos/modules/shell/aliases/kubernetes/*.nix 2>/dev/null | grep -v '^#' | sort";
    "alias-nix" = "grep -h '=' /etc/nixos/modules/shell/aliases/nix/*.nix 2>/dev/null | grep -v '^#' | sort";
    "alias-nav" = "grep -h '=' /etc/nixos/modules/shell/aliases/system/navigation.nix 2>/dev/null | grep -v '^#' | sort";

    # Show what command will actually run (resolves aliases)
    "what" = "type -a";

    # Count total aliases
    "alias-count" = "alias | wc -l";

    # Show most recently added aliases (from git)
    "alias-recent" = "cd /etc/nixos && git log --all --oneline --grep='alias' -10 && cd -";

    # Advanced alias inspector (interactive tool)
    "ai" = "/etc/nixos/scripts/alias-inspector.sh";
    "alias-info" = "/etc/nixos/scripts/alias-inspector.sh info";
    "alias-trace" = "/etc/nixos/scripts/alias-inspector.sh trace";
  };
}
