#!/bin/bash
# ============================================================
# NixOS Power User Aliases
# ============================================================
alias nx='cd /etc/nixos'
alias nx-flake='sudo nvim /etc/nixos/flake.nix'

alias nxc-mod='cd /etc/nixos/modules'
alias nx-mod='sudo nvim /etc/nixos/modules'

alias nxc-home='cd /etc/nixos/hosts/kernelcore/home/'
alias nx-home='sudo nvim /etc/nixos/hosts/kernelcore/home/home.nix'
alias nx-config='sudo nvim /etc/nixos/hosts/kernelcore/configuration.nix'
alias nx-aliases='sudo nvim /etc/nixos/hosts/kernelcore/home/aliases'
alias nxc-aliases='cd /etc/nixos/hosts/kernelcore/home/aliases'

alias nx-shell='sudo nvim /etc/nixos/lib/shell.nix'
alias nx-jup='sudo $EDITOR /etc/nixos/modules/development/jupyter.nix'
alias nx-env='sudo nvim /etc/nixos/modules/development/environments.nix'
alias nx-container='sudo nvim /etc/nixos/modules/containers/nixos-containers.nix'
alias nx-docker='sudo nvim /etc/nixos/modules/containers/docker.nix'

# Wide Running Job Aliases
alias chat='python koboldcpp.py L3-8B-Stheno-v3.2-Q4_K_S.gguf --sdmodel Anything-V3.0-pruned-fp16.safetensors 8080 --host localhost --gpulayers 40  --usecuda all --usecublas all --usehipblas'


alias ollama-run='ollama run '
# ============================================================
# 🔧 NIXOS SYSTEM MANAGEMENT
# ============================================================

# Rebuild and switch configuration
alias nrs='sudo nixos-rebuild switch'

# Rebuild and switch with specific configuration file
alias nrs-config='sudo nixos-rebuild switch -I nixos-config='

# Test configuration without switching
alias nrt='sudo nixos-rebuild test'

# Build configuration without activating
alias nrb='sudo nixos-rebuild build'

# Build and switch with verbose output
alias nrsv='sudo nixos-rebuild switch --show-trace'

# Rollback to previous generation
alias nrr='sudo nixos-rebuild switch --rollback'

# Edit NixOS configuration
alias nx-dots='$EDITOR ~/.config/NixHM/'

# Edit home-manager configuration
alias nx-home='sudo $EDITOR /etc/nixos/hosts/kernelcore/home/home.nix'

# List all NixOS generations
alias nix-list='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system'

# ============================================================
# 📦 NIX PACKAGE & DEVELOPMENT
# ============================================================

# Garbage collection - delete old generations
alias nixgc='sudo nix-collect-garbage -d'

# Aggressive garbage collection with optimization
alias nixgc-full='sudo nix-collect-garbage -d && sudo nix-store --optimize'

# Update all channels
alias up='sudo nix-channel --update'

# Search for packages
alias nx-pkgs='nix search nixpkgs'

# Install package
alias nxi='nix-env -iA nixpkgs.'

# Remove package
alias nxr='nix-env -e'

# List installed packages
alias nxl='nix-env -q'

# Enter nix-shell with packages
alias nxsh='nix-shell -p'

# Develop with flakes
alias nxdev='nix develop'

# Build flake
alias nxbuild='nix build'

# Run package from nixpkgs
alias nxrun='nix run nixpkgs#'

alias check='sudo nix flake check'

# Update flake inputs
alias update='sudo nix flake update'

# Show flake metadata
alias meta='nix flake show'

# ============================================================
# 🐳 DOCKER & CONTAINERS
# ============================================================

# Docker compose up in detached mode
alias dcu='docker compose up -d'

# Docker compose down
alias dcd='docker compose down'

# Docker compose down with volumes
alias dcdv='docker compose down -v'

# Docker compose logs with follow
alias dcl='docker compose logs -f'

# Docker compose restart
alias dcr='docker compose restart'

# Docker compose pull all images
alias dcp='docker compose pull'

# List running containers
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# List all containers including stopped
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Docker stats for running containers with exposed links
dstats() {
    echo "📊 Docker Container Stats"
    echo "================================"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo ""
    echo "🔗 Exposed Services & Links"
    echo "================================"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "^(NAMES|.*0\.0\.0\.0)" | sed 's/0.0.0.0://g' | sed 's/->/\t→\t/g'
}

# Remove all stopped containers
alias dclean='docker container prune -f'

# Remove unused images
alias dimgclean='docker image prune -a -f'

# Complete docker cleanup
alias dnuke='docker system prune -a --volumes -f'

# Docker logs with tail
alias dlogs='docker logs -f --tail=100'

# Enter container bash
alias dexec='docker exec -it'

# Show docker disk usage
alias ddu='docker system df'

# ============================================================
# 🔀 GIT OPERATIONS
# ============================================================

# Git status short format
alias gs='git status -sb'

# Git add all
alias ga='git add .'

# Git commit with message
alias gc='git commit -m'

# Git commit amend
alias gca='git commit --amend'

# Git push
alias gp='git push'

# Git push force with lease (safer)
alias gpf='git push --force-with-lease'

# Git pull with rebase
alias gpl='git pull --rebase'

# Git log pretty format
alias gl='git log --oneline --decorate --graph --all -20'

# Git log with stats
alias gls='git log --stat -5'

# Git diff
alias gd='git diff'

# Git diff staged
alias gds='git diff --staged'

# Git branch list
alias gb='git branch -v'

# Git checkout
alias gco='git checkout'

# Git checkout new branch
alias gcb='git checkout -b'

# Git stash with message
alias gst='git stash save'

# Git stash pop
alias gstp='git stash pop'

# Git fetch all
alias gf='git fetch --all --prune'

# ============================================================
# 📊 SYSTEM MONITORING
# ============================================================

# Human-readable disk usage
alias df='df -h'

# Disk usage of current directory
alias du='du -sh'

# Disk usage sorted by size
alias dus='du -sh * | sort -hr'

# List processes sorted by CPU
alias pscpu='ps auxf | sort -nr -k 3 | head -20'

# List processes sorted by Memory
alias psmem='ps auxf | sort -nr -k 4 | head -20'

# Show listening ports
alias ports='sudo netstat -tulpn | grep LISTEN'

# Alternative: show listening ports with ss
alias portsss='sudo ss -tulpn'

# Memory usage
alias meminfo='free -h'

# Watch memory usage
alias memwatch='watch -n 1 free -h'

# Top with better defaults
alias htop='htop -d 10'

# Network connections
alias netstat-count='netstat -an | grep ESTABLISHED | wc -l'

# Show all open network connections
alias connections='sudo lsof -i -P -n'

# ============================================================
# 📁 FILE SYSTEM & NAVIGATION
# ============================================================

# List with details and human-readable sizes
alias ll='ls -lah --color=auto'

# List sorted by modification time
alias lt='ls -lath --color=auto'

# List sorted by size
alias lsize='ls -lahS --color=auto'

# Quick navigation to NixOS config
alias cdnix='cd /etc/nixos'

# Quick navigation to home-manager config
alias cdhm='cd ~/.config/home-manager'

# Quick navigation to nixpkgs config
alias cdnixpkgs='cd ~/.config/nixpkgs'

# Show directory tree (limited depth)
alias tree='tree -L 2 -C'

# Find files by name
alias fname='find . -name'

# Grep with color and line numbers
alias grep='grep --color=auto -n'

# ============================================================
# 🚀 DEVELOPMENT SERVERS
# ============================================================

# Python HTTP server on port 8000
alias serve='python -m http.server 8000'

# Alternative port for Python server
alias serve8080='python -m http.server 8080'

# Node.js simple server
alias nodeserve='npx http-server -p 3000'

# ============================================================
# 🎯 FUNCTIONS
# ============================================================

# Rebuild NixOS with specific host
nrs-host() {
    if [ -z "$1" ]; then
        echo "Usage: nrs-host <hostname>"
        return 1
    fi
    sudo nixos-rebuild switch --flake ".#$1"
}

# Search and install package in one go
nx-flake-find-go() {
    if [ -z "$1" ]; then
        echo "Usage: nix-find-install <package-name>"
        return 1
    fi
    echo "Searching for: $1"
    nix search nixpkgs "$1" | head -20
    echo ""
    read -p "Install package? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        nix-Env -iA "nixpkgs.$1"
    fi
}

# Enter directory and list contents
cdls() {
    if [ -z "$1" ]; then
        cd && ls -lah
    else
        cd "$1" && ls -lah
    fi
}

# Create directory and enter it
mkcd() {
    if [ -z "$1" ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Find and kill process by name
killbyname() {
    if [ -z "$1" ]; then
        echo "Usage: killbyname <process-name>"
        return 1
    fi
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs -r kill -9
    echo "Killed all processes matching: $1"
}

# Start development environment for common stacks
dev-env() {
    local env_type="${1:-generic}"
    
    case "$env_type" in
        node)
            nix-shell -p nodejs nodePackages.npm nodePackages.typescript
            ;;
        python)
            nix-shell -p python3 python3Packages.pip python3Packages.virtualenv
            ;;
        rust)
            nix-shell -p rustc cargo rust-analyzer rustfmt clippy
            ;;
        go)
            nix-shell -p go gopls gotools
            ;;
        java)
            nix-shell -p jdk maven
            ;;
        *)
            echo "Usage: dev-env <node|python|rust|go|java>"
            echo "Starting generic environment..."
            nix-shell -p gcc gnumake cmake
            ;;
    esac
}

# Quick docker compose with specific file
dcomp() {
    if [ -z "$1" ]; then
        echo "Usage: dcomp <docker-compose-file.yml> [command]"
        echo "Example: dcomp ~/services/docker-compose.yml up -d"
        return 1
    fi
    
    local compose_file="$1"
    shift
    docker compose -f "$compose_file" "$@"
}

# Show NixOS system info
nixinfo() {
    echo "╔════════════════════════════════════════╗"
    echo "║       NixOS System Information        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "📦 NixOS Version:"
    nixos-version
    echo ""
    echo "🔧 Current Generation:"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1
    echo ""
    echo "💾 Nix Store Size:"
    du -sh /nix/store 2>/dev/null || echo "Unable to calculate"
    echo ""
    echo "🗑️  Old Generations:"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l
    echo ""
    echo "📊 Installed User Packages:"
    nix-env -q | wc -l
}

# Backup NixOS configuration
nix-backup() {
    local backup_dir="${1:-$HOME/nixos-backup-$(date +%Y%m%d-%H%M%S)}"
    
    echo "Creating backup in: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Copy NixOS configuration
    sudo cp -r /etc/nixos "$backup_dir/"
    
    # Copy home-manager config if it exists
    if [ -d "$HOME/.config/home-manager" ]; then
        cp -r "$HOME/.config/home-manager" "$backup_dir/"
    fi
    
    # Copy nixpkgs config if it exists
    if [ -d "$HOME/.config/nixpkgs" ]; then
        cp -r "$HOME/.config/nixpkgs" "$backup_dir/"
    fi
    
    # List installed packages
    nix-env -q > "$backup_dir/user-packages.txt"
    
    # List generations
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system > "$backup_dir/system-generations.txt"
    
    echo "✓ Backup complete: $backup_dir"
}

# Test NixOS configuration without switching
nix-test-config() {
    echo "🧪 Testing NixOS configuration..."
    sudo nixos-rebuild build
    
    if [ $? -eq 0 ]; then
        echo "✓ Configuration builds successfully!"
        echo ""
        read -p "Activate as test? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo nixos-rebuild test
            echo "✓ Test configuration activated (will revert on reboot)"
        fi
    else
        echo "✗ Configuration has errors!"
        return 1
    fi
}

# Help function
nix-help() {
    echo "🚀 NixOS Power User Aliases"
    echo ""
    echo "System Management:"
    echo "  nrs              - Rebuild and switch"
    echo "  nrt              - Test configuration"
    echo "  nrb              - Build without activating"
    echo "  nrr              - Rollback to previous"
    echo "  nixcfg           - Edit configuration.nix"
    echo "  hmcfg            - Edit home-manager config"
    echo "  nixgens          - List generations"
    echo ""
    echo "Package Management:"
    echo "  nixgc            - Garbage collect old generations"
    echo "  nixgc-full       - Full cleanup with optimization"
    echo "  nixup            - Update channels"
    echo "  nixs <query>     - Search packages"
    echo "  nixi <pkg>       - Install package"
    echo "  nixr <pkg>       - Remove package"
    echo "  nixsh <pkg>      - Nix-shell with package"
    echo ""
    echo "Docker:"
    echo "  dcu              - Compose up detached"
    echo "  dcd              - Compose down"
    echo "  dcl              - Follow compose logs"
    echo "  dps              - List containers"
    echo "  dclean           - Remove stopped containers"
    echo "  dnuke            - Full docker cleanup"
    echo ""
    echo "Git:"
    echo "  gs               - Status short"
    echo "  ga               - Add all"
    echo "  gc \"msg\"         - Commit with message"
    echo "  gp               - Push"
    echo "  gpl              - Pull with rebase"
    echo "  gl               - Pretty log graph"
    echo ""
    echo "Monitoring:"
    echo "  pscpu            - Top CPU processes"
    echo "  psmem            - Top memory processes"
    echo "  ports            - Show listening ports"
    echo "  meminfo          - Memory usage"
    echo "  connections      - Network connections"
    echo ""
    echo "Functions:"
    echo "  nrs-host <name>  - Rebuild with flake host"
    echo "  dev-env <type>   - Enter dev environment"
    echo "  nixinfo          - Show system information"
    echo "  nix-backup       - Backup configurations"
    echo "  nix-test-config  - Test configuration safely"
    echo "  mkcd <dir>       - Make and enter directory"
    echo "  cdls [dir]       - CD and list contents"
    echo "  nix-help         - Show this help"
}

# ============================================================
# 🔄 EXPORT FUNCTIONS
# ============================================================

export -f nrs-host
export -f nx-flake-find-go
export -f cdls
export -f mkcd
export -f killbyname
export -f dev-env
export -f dcomp
export -f nixinfo
export -f nix-backup
export -f nix-test-config
export -f nix-help

# ============================================================
# ✓ INITIALIZATION
# ============================================================

#echo "✓ NixOS aliases loaded! Type 'nix-help' for commands"
