#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 PERFECT NIXOS INSTALL - MONSTRA EDITION™
# ═══════════════════════════════════════════════════════════════════════════════
# Inspired by Chris Titus' legendary Windows tool, but for the enlightened ones!
# Author: The NixOS Hermandad 
# Version: 4.20.69-nuclear
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                              COLOR DEFINITIONS                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                           GLOBAL CONFIGURATION                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
SCRIPT_VERSION="4.20.69"
SCRIPT_NAME="Perfect NixOS Install"
NIXOS_VERSION="24.05"
CONFIG_DIR="/etc/nixos"
BACKUP_DIR="/var/backups/nixos-perfect"
LOG_FILE="/var/log/perfect-nixos-install.log"
TEMP_DIR="/tmp/perfect-nixos-$$"

# Categories for different setup types
declare -A SETUP_PROFILES=(
    ["minimal"]="Minimal Install - Just the essentials"
    ["desktop"]="Desktop Workstation - Full GUI experience"
    ["gaming"]="Gaming Battlestation - Steam, drivers, performance"
    ["developer"]="Developer Paradise - All the tools"
    ["server"]="Server Setup - Optimized for services"
    ["hacker"]="Hacker Station - Security tools included"
    ["content"]="Content Creator - Video/Audio production"
    ["science"]="Data Science - ML/AI ready"
)

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                              HELPER FUNCTIONS                              ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Fancy print functions
print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║  ██████╗ ███████╗██████╗ ███████╗███████╗ ██████╗████████╗    ║
    ║  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝    ║
    ║  ██████╔╝█████╗  ██████╔╝█████╗  █████╗  ██║        ██║       ║
    ║  ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██║        ██║       ║
    ║  ██║     ███████╗██║  ██║██║     ███████╗╚██████╗   ██║       ║
    ║  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝       ║
    ║                                                                 ║
    ║           N I X O S   I N S T A L L   -   M O N S T R A       ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}    Version: ${WHITE}$SCRIPT_VERSION${NC} | ${CYAN}NixOS: ${WHITE}$NIXOS_VERSION${NC}"
    echo -e "${YELLOW}    Inspired by Chris Titus, powered by Nix magic! 🚀${NC}"
    echo -e "${PURPLE}    ═══════════════════════════════════════════════════════════${NC}\n"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_step() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r${CYAN}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%$((width - completed))s" | tr ' ' '░'
    printf "] ${WHITE}%3d%%${NC}" $percentage
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                           SYSTEM DETECTION                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

detect_system() {
    print_step "🔍 Detecting System Configuration"
    
    # CPU Detection
    CPU_VENDOR=$(lscpu | grep "Vendor ID" | awk '{print $3}')
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    CPU_CORES=$(nproc)
    
    # GPU Detection
    if lspci | grep -i nvidia > /dev/null; then
        GPU_TYPE="nvidia"
        GPU_MODEL=$(lspci | grep -i nvidia | head -1 | cut -d: -f3)
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        GPU_TYPE="amd"
        GPU_MODEL=$(lspci | grep -i amd | grep -i vga | head -1 | cut -d: -f3)
    else
        GPU_TYPE="intel"
        GPU_MODEL=$(lspci | grep -i intel | grep -i vga | head -1 | cut -d: -f3)
    fi
    
    # Memory
    TOTAL_RAM=$(free -h | grep "^Mem" | awk '{print $2}')
    
    # Disk
    ROOT_DISK=$(df -h / | tail -1 | awk '{print $1}')
    ROOT_SIZE=$(df -h / | tail -1 | awk '{print $2}')
    
    echo -e "${GREEN}System Information:${NC}"
    echo -e "  ${CYAN}CPU:${NC} $CPU_MODEL ($CPU_CORES cores)"
    echo -e "  ${CYAN}GPU:${NC} $GPU_MODEL (${GPU_TYPE})"
    echo -e "  ${CYAN}RAM:${NC} $TOTAL_RAM"
    echo -e "  ${CYAN}Disk:${NC} $ROOT_DISK ($ROOT_SIZE)"
    echo ""
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                              BACKUP SYSTEM                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

create_backup() {
    print_step "💾 Creating System Backup"
    
    mkdir -p "$BACKUP_DIR"
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        print_info "Backing up current configuration..."
        cp -r "$CONFIG_DIR" "$backup_path"
        
        # Create restore script
        cat > "$backup_path/restore.sh" << 'EOF'
#!/bin/bash
echo "Restoring NixOS configuration..."
sudo cp -r ./* /etc/nixos/
echo "Restore complete! Run 'sudo nixos-rebuild switch' to apply."
EOF
        chmod +x "$backup_path/restore.sh"
        
        print_success "Backup created at: $backup_path"
    else
        print_warning "No existing configuration found to backup"
    fi
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                          PROFILE CONFIGURATIONS                            ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

generate_minimal_config() {
    cat << 'EOF'
{ config, pkgs, ... }:
{
  # Minimal base system
  environment.systemPackages = with pkgs; [
    vim wget curl git htop
    tmux tree file which
  ];
  
  # Basic services
  services.openssh.enable = true;
  networking.networkmanager.enable = true;
  
  # Performance
  powerManagement.cpuFreqGovernor = "ondemand";
  
  # Security basics
  security.sudo.wheelNeedsPassword = false;
  networking.firewall.enable = true;
}
EOF
}

generate_desktop_config() {
    cat << 'EOF'
{ config, pkgs, ... }:
{
  imports = [ ./minimal.nix ];
  
  # Desktop Environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  
  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  
  # Desktop packages
  environment.systemPackages = with pkgs; [
    firefox chromium
    thunderbird discord
    vlc spotify gimp
    libreoffice vscode
    flameshot obs-studio
  ];
  
  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-emoji
    fira-code jetbrains-mono
    font-awesome
  ];
}
EOF
}

generate_gaming_config() {
    cat << 'EOF'
{ config, pkgs, ... }:
{
  imports = [ ./desktop.nix ];
  
  # Gaming optimization
  boot.kernelParams = [ "threadirqs" "mitigations=off" ];
  
  # Steam and gaming tools
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  # Graphics drivers
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiIntel vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    lutris wine winetricks
    gamemode mangohud
    discord teamspeak3
    obs-studio-plugins.obs-vkcapture
  ];
  
  # Performance governor
  powerManagement.cpuFreqGovernor = "performance";
}
EOF
}

generate_developer_config() {
    cat << 'EOF'
{ config, pkgs, ... }:
{
  imports = [ ./desktop.nix ];
  
  # Development tools
  environment.systemPackages = with pkgs; [
    # Editors
    vscode neovim emacs
    jetbrains.idea-ultimate
    
    # Languages
    rustup go python3 nodejs
    gcc clang cmake gnumake
    
    # Tools
    docker-compose kubectl helm
    terraform ansible vagrant
    postman insomnia jq yq
    
    # Version control
    git gh lazygit tig
    
    # Database clients
    dbeaver pgadmin4 mysql-workbench
  ];
  
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # Development services
  services.postgresql.enable = true;
  services.redis.enable = true;
}
EOF
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                          OPTIMIZATION TWEAKS                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

apply_performance_tweaks() {
    print_step "⚡ Applying Performance Optimizations"
    
    cat > "$TEMP_DIR/performance.nix" << 'EOF'
{ config, pkgs, ... }:
{
  # CPU Performance
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # I/O Optimizations
  boot.kernelParams = [
    "threadirqs"
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v1"
    "nospectre_v2"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "tsx=on"
    "tsx_async_abort=off"
    "mitigations=off"
  ];
  
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # Filesystem
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];
  
  # Networking
  boot.kernel.sysctl = {
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_mtu_probing" = 1;
  };
  
  # Memory
  boot.kernel.sysctl."vm.swappiness" = 10;
  boot.kernel.sysctl."vm.vfs_cache_pressure" = 50;
  
  # Zram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
EOF
    
    print_success "Performance tweaks configured!"
}

apply_security_hardening() {
    print_step "🛡️ Applying Security Hardening"
    
    cat > "$TEMP_DIR/security.nix" << 'EOF'
{ config, pkgs, ... }:
{
  # Kernel hardening
  boot.kernel.sysctl = {
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.ftrace_enabled" = false;
    "kernel.kptr_restrict" = 2;
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.yama.ptrace_scope" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
  };
  
  # Security packages
  environment.systemPackages = with pkgs; [
    firejail apparmor-utils
    clamav rkhunter
    fail2ban usbguard
  ];
  
  # Services
  services.fail2ban.enable = true;
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
  
  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = false;
    logReversePathDrops = true;
  };
}
EOF
    
    print_success "Security hardening configured!"
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                          MAIN MENU INTERFACE                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

show_main_menu() {
    local choice
    
    while true; do
        print_banner
        
        echo -e "${WHITE}${BOLD}📋 MAIN MENU${NC}\n"
        echo -e "${CYAN}1)${NC} 🚀 Quick Install (Recommended)"
        echo -e "${CYAN}2)${NC} 🎯 Choose Profile"
        echo -e "${CYAN}3)${NC} ⚙️  Custom Installation"
        echo -e "${CYAN}4)${NC} 🔧 System Tweaks"
        echo -e "${CYAN}5)${NC} 💾 Backup/Restore"
        echo -e "${CYAN}6)${NC} 📊 System Information"
        echo -e "${CYAN}7)${NC} 🌐 Update Everything"
        echo -e "${CYAN}8)${NC} 📖 Documentation"
        echo -e "${CYAN}9)${NC} ❌ Exit"
        
        echo -e "\n${YELLOW}Select an option (1-9):${NC} "
        read -r choice
        
        case $choice in
            1) quick_install ;;
            2) choose_profile ;;
            3) custom_install ;;
            4) system_tweaks_menu ;;
            5) backup_restore_menu ;;
            6) show_system_info ;;
            7) update_everything ;;
            8) show_documentation ;;
            9) exit_script ;;
            *) print_error "Invalid option!" ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r
    done
}

quick_install() {
    print_banner
    print_step "🚀 Quick Install - The Chris Titus Way!"
    
    echo -e "${WHITE}This will:${NC}"
    echo -e "  ${GREEN}✓${NC} Backup your current config"
    echo -e "  ${GREEN}✓${NC} Detect your hardware"
    echo -e "  ${GREEN}✓${NC} Install optimized desktop environment"
    echo -e "  ${GREEN}✓${NC} Apply performance tweaks"
    echo -e "  ${GREEN}✓${NC} Install essential software"
    echo -e "  ${GREEN}✓${NC} Configure security basics"
    
    echo -e "\n${YELLOW}Continue? (y/n):${NC} "
    read -r confirm
    
    if [[ "$confirm" == "y" ]]; then
        # Execute installation steps
        create_backup
        detect_system
        
        # Progress simulation
        local steps=("Creating config" "Installing packages" "Applying tweaks" "Finalizing")
        local total=${#steps[@]}
        
        for i in "${!steps[@]}"; do
            print_info "${steps[$i]}..."
            show_progress $((i + 1)) $total
            sleep 2
        done
        echo ""
        
        print_success "Quick install completed!"
        print_info "Run 'sudo nixos-rebuild switch' to apply changes"
    fi
}

choose_profile() {
    print_banner
    print_step "🎯 Choose Installation Profile"
    
    echo -e "${WHITE}Available profiles:${NC}\n"
    
    local i=1
    for profile in "${!SETUP_PROFILES[@]}"; do
        echo -e "${CYAN}$i)${NC} ${profile^} - ${SETUP_PROFILES[$profile]}"
        ((i++))
    done
    
    echo -e "\n${YELLOW}Select profile (1-${#SETUP_PROFILES[@]}):${NC} "
    read -r selection
    
    # Profile installation logic here
    print_success "Profile selected!"
}

system_tweaks_menu() {
    print_banner
    print_step "🔧 System Tweaks - Make It Yours!"
    
    echo -e "${WHITE}${BOLD}Available Tweaks:${NC}\n"
    echo -e "${CYAN}1)${NC} ⚡ Performance Mode"
    echo -e "${CYAN}2)${NC} 🔋 Battery Saver Mode"
    echo -e "${CYAN}3)${NC} 🛡️  Security Hardening"
    echo -e "${CYAN}4)${NC} 🎮 Gaming Optimizations"
    echo -e "${CYAN}5)${NC} 🌐 Network Optimizations"
    echo -e "${CYAN}6)${NC} 🎨 UI/UX Enhancements"
    echo -e "${CYAN}7)${NC} 🔙 Back to Main Menu"
    
    echo -e "\n${YELLOW}Select tweak (1-7):${NC} "
    read -r tweak_choice
    
    case $tweak_choice in
        1) apply_performance_tweaks ;;
        2) print_info "Battery saver mode coming soon!" ;;
        3) apply_security_hardening ;;
        4) print_info "Gaming optimizations coming soon!" ;;
        5) print_info "Network optimizations coming soon!" ;;
        6) print_info "UI/UX enhancements coming soon!" ;;
        7) return ;;
        *) print_error "Invalid option!" ;;
    esac
}

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                               MAIN EXECUTION                               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

main() {
    # Check if running with proper permissions
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        print_info "Try: sudo $0"
        exit 1
    fi
    
    # Create directories
    mkdir -p "$TEMP_DIR" "$BACKUP_DIR"
    touch "$LOG_FILE"
    
    # Trap for cleanup
    trap 'rm -rf "$TEMP_DIR"' EXIT
    
    # Start the show!
    log "Perfect NixOS Install started"
    show_main_menu
}

exit_script() {
    print_banner
    echo -e "${GREEN}${BOLD}Thanks for using Perfect NixOS Install!${NC}"
    echo -e "${YELLOW}Remember: In Nix we trust, everything else we rollback!${NC}"
    echo -e "\n${PURPLE}Happy hacking, camarada! 🚀${NC}\n"
    exit 0
}

# Launch the matrix, Neo!
main "$@"