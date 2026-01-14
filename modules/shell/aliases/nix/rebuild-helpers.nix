{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# NixOS Rebuild Helpers - Colorized & Enhanced
# ============================================================
# Advanced rebuild commands with visual feedback
# Version: 1.0.0
# ============================================================

let
  # Colorized rebuild script with progress indicators
  nixosRebuildScript = pkgs.writeShellScriptBin "rebuild" ''
    #!/usr/bin/env bash
    # NixOS Rebuild Helper with Colors and Progress
    # Usage: rebuild [switch|test|boot|check] [options]

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
    BOLD='\033[1m'

    # Icons
    ROCKET="🚀"
    CHECK="✅"
    WARN="⚠️ "
    ERROR="❌"
    GEAR="⚙️ "
    CLEAN="🧹"
    INFO="ℹ️ "

    # Configuration
    FLAKE_PATH="/etc/nixos"
    HOST="kernelcore"
    MAX_JOBS="4"
    CORES="4"

    # Print colored message
    print_msg() {
        local color=$1
        local icon=$2
        local msg=$3
        echo -e "''${color}''${icon} ''${msg}''${NC}"
    }

    # Print header
    print_header() {
        echo ""
        echo -e "''${CYAN}╔════════════════════════════════════════════════════════╗''${NC}"
        echo -e "''${CYAN}║''${WHITE}''${BOLD}          NixOS Rebuild - kernelcore              ''${CYAN}║''${NC}"
        echo -e "''${CYAN}╚════════════════════════════════════════════════════════╝''${NC}"
        echo ""
    }

    # Show usage
    show_usage() {
        print_header
        echo -e "''${WHITE}''${BOLD}Usage:''${NC}"
        echo -e "  rebuild [command] [options]"
        echo ""
        echo -e "''${WHITE}''${BOLD}Commands:''${NC}"
        echo -e "  ''${GREEN}switch''${NC}      - Build and activate configuration (default)"
        echo -e "  ''${YELLOW}test''${NC}        - Build and activate, but don't add to bootloader"
        echo -e "  ''${BLUE}boot''${NC}        - Build and add to bootloader, activate on next boot"
        echo -e "  ''${CYAN}check''${NC}       - Check flake without building"
        echo -e "  ''${MAGENTA}trace''${NC}       - Switch with --show-trace for debugging"
        echo ""
        echo -e "''${WHITE}''${BOLD}Performance Modes:''${NC}"
        echo -e "  ''${GREEN}balanced''${NC}    - rebuild balanced (default: --max-jobs 4 --cores 4)"
        echo -e "  ''${YELLOW}safe''${NC}        - rebuild safe (--max-jobs 1 --cores 4)"
        echo -e "  ''${RED}aggressive''${NC}  - rebuild aggressive (--max-jobs 6 --cores 2)"
        echo ""
        echo -e "''${WHITE}''${BOLD}Examples:''${NC}"
        echo -e "  rebuild                    # Switch with balanced settings"
        echo -e "  rebuild test               # Test build without adding to bootloader"
        echo -e "  rebuild switch safe        # Safe mode (low resource usage)"
        echo -e "  rebuild trace              # Switch with detailed trace"
        echo -e "  rebuild check              # Validate flake only"
        echo ""
    }

    # Parse arguments
    COMMAND="switch"
    MODE="balanced"
    EXTRA_ARGS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            switch|test|boot)
                COMMAND=$1
                shift
                ;;
            check)
                COMMAND="check"
                shift
                ;;
            trace)
                COMMAND="switch"
                EXTRA_ARGS+=("--show-trace")
                shift
                ;;
            safe)
                MODE="safe"
                MAX_JOBS="1"
                CORES="4"
                shift
                ;;
            balanced)
                MODE="balanced"
                MAX_JOBS="4"
                CORES="4"
                shift
                ;;
            aggressive)
                MODE="aggressive"
                MAX_JOBS="6"
                CORES="2"
                shift
                ;;
            -h|--help|help)
                show_usage
                exit 0
                ;;
            *)
                EXTRA_ARGS+=("$1")
                shift
                ;;
        esac
    done

    print_header

    # Check command
    if [ "$COMMAND" == "check" ]; then
        print_msg "$BLUE" "$INFO" "Running flake check..."
        nix flake check "$FLAKE_PATH" "''${EXTRA_ARGS[@]}"
        exit $?
    fi

    # Show configuration
    print_msg "$CYAN" "$GEAR" "Configuration:"
    echo -e "  ''${WHITE}Flake:''${NC}      $FLAKE_PATH#$HOST"
    echo -e "  ''${WHITE}Command:''${NC}    $COMMAND"
    echo -e "  ''${WHITE}Mode:''${NC}       $MODE"
    echo -e "  ''${WHITE}Max Jobs:''${NC}   $MAX_JOBS"
    echo -e "  ''${WHITE}Cores:''${NC}      $CORES"
    if [ ''${#EXTRA_ARGS[@]} -gt 0 ]; then
        echo -e "  ''${WHITE}Extra:''${NC}      ''${EXTRA_ARGS[*]}"
    fi
    echo ""

    # Confirm for switch/boot
    if [ "$COMMAND" == "switch" ] || [ "$COMMAND" == "boot" ]; then
        print_msg "$YELLOW" "$WARN" "This will modify your system configuration."
        read -p "Continue? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
            print_msg "$RED" "$ERROR" "Rebuild cancelled."
            exit 1
        fi
    fi

    # Build command
    print_msg "$BLUE" "$ROCKET" "Starting rebuild..."
    echo ""

    START_TIME=$(date +%s)

    sudo nixos-rebuild "$COMMAND" \
        --flake "$FLAKE_PATH#$HOST" \
        --max-jobs "$MAX_JOBS" \
        --cores "$CORES" \
        --keep-going \
        "''${EXTRA_ARGS[@]}"

    EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        print_msg "$GREEN" "$CHECK" "Rebuild completed successfully!"
        echo -e "  ''${WHITE}Duration:''${NC} ''${DURATION}s"
        echo ""

        if [ "$COMMAND" == "switch" ]; then
            print_msg "$CYAN" "$INFO" "Configuration activated. Changes are live!"
        elif [ "$COMMAND" == "boot" ]; then
            print_msg "$CYAN" "$INFO" "Configuration will activate on next boot."
        fi
    else
        print_msg "$RED" "$ERROR" "Rebuild failed with exit code $EXIT_CODE"
        echo -e "  ''${WHITE}Duration:''${NC} ''${DURATION}s"
        echo ""
        print_msg "$YELLOW" "$INFO" "Try running with 'trace' for more details:"
        echo -e "  ''${WHITE}rebuild trace''${NC}"
    fi

    echo ""
    exit $EXIT_CODE
  '';

  # Quick rebuild aliases with colors
  quickRebuild = pkgs.writeShellScriptBin "rb" ''
    #!/usr/bin/env bash
    # Quick rebuild - just calls rebuild with args
    ${nixosRebuildScript}/bin/rebuild "$@"
  '';

  # Generation management script
  generationsScript = pkgs.writeShellScriptBin "generations" ''
    #!/usr/bin/env bash
    # NixOS Generations Manager with Colors

    # Colors
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
    BOLD='\033[1m'

    echo -e "''${CYAN}╔════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║''${WHITE}''${BOLD}          NixOS System Generations                ''${CYAN}║''${NC}"
    echo -e "''${CYAN}╚════════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Get current generation
    CURRENT=$(readlink /nix/var/nix/profiles/system | grep -oP '\d+$')

    echo -e "''${WHITE}''${BOLD}System Generations:''${NC}"
    echo ""

    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | while read line; do
        if echo "$line" | grep -q "^  *$CURRENT "; then
            echo -e "''${GREEN}➜ $line (current)''${NC}"
        else
            echo -e "  $line"
        fi
    done

    echo ""
    echo -e "''${CYAN}Commands:''${NC}"
    echo -e "  ''${WHITE}rollback''${NC}           - Rollback to previous generation"
    echo -e "  ''${WHITE}rebuild switch''${NC}     - Build and activate new generation"
    echo ""
  '';

  # Cleanup script
  cleanupScript = pkgs.writeShellScriptBin "nixos-cleanup" ''
    #!/usr/bin/env bash
    # NixOS Cleanup - Remove old generations and optimize store

    # Colors
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'

    echo -e "''${CYAN}╔════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${CYAN}║''${WHITE}          NixOS System Cleanup                    ''${CYAN}║''${NC}"
    echo -e "''${CYAN}╚════════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Store size before
    BEFORE=$(du -sh /nix/store 2>/dev/null | cut -f1)
    echo -e "''${WHITE}Store size before:''${NC} $BEFORE"
    echo ""

    # Count generations
    GENS=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l)
    echo -e "''${CYAN}🔍 Current generations:''${NC} $GENS"
    echo ""

    # Ask for confirmation
    echo -e "''${YELLOW}⚠️  This will:''${NC}"
    echo "  1. Remove all generations older than 7 days"
    echo "  2. Run garbage collection"
    echo "  3. Optimize Nix store (deduplicate files)"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 1
    fi

    echo ""
    echo -e "''${CYAN}🧹 Removing old generations...''${NC}"
    sudo nix-collect-garbage --delete-older-than 7d

    echo ""
    echo -e "''${CYAN}🗑️  Running garbage collection...''${NC}"
    sudo nix-collect-garbage -d

    echo ""
    echo -e "''${CYAN}⚡ Optimizing store...''${NC}"
    sudo nix-store --optimize

    # Store size after
    AFTER=$(du -sh /nix/store 2>/dev/null | cut -f1)
    echo ""
    echo -e "''${GREEN}✅ Cleanup complete!''${NC}"
    echo -e "''${WHITE}Store size before:''${NC} $BEFORE"
    echo -e "''${WHITE}Store size after:''${NC}  $AFTER"
    echo ""

    # New generation count
    NEW_GENS=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l)
    echo -e "''${WHITE}Generations:''${NC} $GENS → $NEW_GENS"
    echo ""
  '';

in
{
  # Install helper scripts
  environment.systemPackages = [
    nixosRebuildScript
    quickRebuild
    generationsScript
    cleanupScript
  ];

  # Enhanced aliases
  environment.shellAliases = {
    # Main rebuild command
    "rebuild" = "rebuild";
    "rb" = "rb"; # Quick alias

    # Specific rebuild modes
    "rebuild-safe" = "rebuild switch safe";
    "rebuild-test" = "rebuild test";
    "rebuild-boot" = "rebuild boot";
    "rebuild-trace" = "rebuild trace";
    "rebuild-check" = "rebuild check";

    # Generation management
    "gens" = "generations";
    "rollback" = "sudo nixos-rebuild switch --rollback";

    # Cleanup
    "cleanup" = "nixos-cleanup";

    # Quick info
    "nix-size" = "du -sh /nix/store";
  };

  # Shell init - add welcome message
  programs.bash.interactiveShellInit = ''
    # NixOS rebuild helper hint (only show once per session)
    if [ -z "$NIXOS_REBUILD_HINT_SHOWN" ]; then
      echo -e "\033[0;36mℹ️  NixOS helpers available: \033[1;37mrebuild\033[0m, \033[1;37mrb\033[0m, \033[1;37mgens\033[0m, \033[1;37mcleanup\033[0m"
      echo -e "\033[0;36m   Type '\033[1;37mrebuild --help\033[0;36m' for usage\033[0m"
      export NIXOS_REBUILD_HINT_SHOWN=1
    fi
  '';

  programs.zsh.interactiveShellInit = ''
    # NixOS rebuild helper hint (only show once per session)
    if [ -z "$NIXOS_REBUILD_HINT_SHOWN" ]; then
      echo -e "\033[0;36mℹ️  NixOS helpers available: \033[1;37mrebuild\033[0m, \033[1;37mrb\033[0m, \033[1;37mgens\033[0m, \033[1;37mcleanup\033[0m"
      echo -e "\033[0;36m   Type '\033[1;37mrebuild --help\033[0;36m' for usage\033[0m"
      export NIXOS_REBUILD_HINT_SHOWN=1
    fi
  '';
}
