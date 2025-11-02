{ config, pkgs, lib, ... }:

# ============================================================
# System Utility Aliases
# ============================================================

{
  environment.shellAliases = {
    # List
    "ll" = "ls -lah";
    "la" = "ls -A";
    "l" = "ls -CF";

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
  };
}
