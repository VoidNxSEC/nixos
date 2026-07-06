{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.kernelcore.shell.nixosExplorer = {
    enable = mkEnableOption "Enable NixOS configuration exploration tools";
  };

  config = mkIf config.kernelcore.shell.nixosExplorer.enable {
    environment.systemPackages = [
      # ============================================================
      # NIXOS CONFIGURATION EXPLORER
      # ============================================================
      (pkgs.writeShellScriptBin "nixos-explore" ''
                #!/usr/bin/env bash
                # NixOS Configuration Explorer - Interactive tool

                RED='\033[0;31m'
                GREEN='\033[0;32m'
                YELLOW='\033[1;33m'
                BLUE='\033[0;34m'
                CYAN='\033[0;36m'
                BOLD='\033[1m'
                NC='\033[0m'

                show_help() {
                  cat << EOF
        ╔══════════════════════════════════════════════════════════════╗
        ║           NixOS Configuration Explorer v1.0                  ║
        ╚══════════════════════════════════════════════════════════════╝

        ''${CYAN}USAGE:''${NC}
          nixos-explore <command> [args]

        ''${YELLOW}COMMANDS:''${NC}

        ''${GREEN}1. Configuration Discovery:''${NC}
          ''${BOLD}option <name>''${NC}        - Show value and description of an option
          ''${BOLD}search <term>''${NC}        - Search for options matching term
          ''${BOLD}all''${NC}                  - List all available options (WARNING: HUGE)
          ''${BOLD}current <path>''${NC}       - Show current value of a config path

        ''${GREEN}2. System State:''${NC}
          ''${BOLD}nix-config''${NC}           - Show all Nix daemon settings
          ''${BOLD}services''${NC}             - List all systemd services and their state
          ''${BOLD}packages''${NC}             - List all installed packages
          ''${BOLD}kernelcore''${NC}           - Show all kernelcore.* options

        ''${GREEN}3. Interactive:''${NC}
          ''${BOLD}repl''${NC}                 - Open interactive Nix REPL (explore freely)
          ''${BOLD}diff''${NC}                 - Diff current vs previous generation

        ''${GREEN}4. Specific Areas:''${NC}
          ''${BOLD}gpu''${NC}                  - Show GPU-related config
          ''${BOLD}memory''${NC}               - Show memory-related config
          ''${BOLD}security''${NC}             - Show security-related config
          ''${BOLD}networking''${NC}           - Show network-related config

        ''${CYAN}EXAMPLES:''${NC}
          nixos-explore option nix.settings.max-jobs
          nixos-explore search "ollama"
          nixos-explore nix-config | grep timeout
          nixos-explore kernelcore
          nixos-explore repl

        ''${CYAN}TIP:''${NC} Use ''${BOLD}nixos-explore repl''${NC} for best exploration experience!
        EOF
                }

                if [ $# -eq 0 ]; then
                  show_help
                  exit 0
                fi

                COMMAND="$1"
                shift

                case "$COMMAND" in
                  option)
                    if [ -z "$1" ]; then
                      echo -e "''${RED}Error: Please provide an option name''${NC}"
                      echo "Example: nixos-explore option nix.settings.max-jobs"
                      exit 1
                    fi
                    echo -e "''${CYAN}Querying option: ''${BOLD}$1''${NC}"
                    nixos-option "$1"
                    ;;

                  search)
                    if [ -z "$1" ]; then
                      echo -e "''${RED}Error: Please provide a search term''${NC}"
                      exit 1
                    fi
                    echo -e "''${CYAN}Searching for: ''${BOLD}$1''${NC}"
                    nixos-option -r ".*$1.*" | head -50
                    echo ""
                    echo -e "''${YELLOW}(Showing first 50 results)''${NC}"
                    ;;

                  all)
                    echo -e "''${YELLOW}WARNING: This will show thousands of options!''${NC}"
                    read -p "Continue? (y/N) " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                      nixos-option | less
                    fi
                    ;;

                  current)
                    if [ -z "$1" ]; then
                      echo -e "''${RED}Error: Please provide a config path''${NC}"
                      echo "Example: nixos-explore current config.nix.settings.max-jobs"
                      exit 1
                    fi
                    echo -e "''${CYAN}Evaluating: ''${BOLD}$1''${NC}"
                    nix-instantiate --eval '<nixpkgs/nixos>' -A "$1" 2>/dev/null || \
                      echo -e "''${RED}Error: Invalid path or value''${NC}"
                    ;;

                  nix-config)
                    echo -e "''${CYAN}''${BOLD}Nix Daemon Configuration:''${NC}"
                    nix show-config | ${pkgs.bat}/bin/bat --paging=never --color=always -l ini
                    ;;

                  services)
                    echo -e "''${CYAN}''${BOLD}Active Systemd Services:''${NC}"
                    systemctl list-units --type=service --state=running --no-pager | \
                      ${pkgs.bat}/bin/bat --paging=never --color=always -l log
                    ;;

                  packages)
                    echo -e "''${CYAN}''${BOLD}Installed Packages:''${NC}"
                    nix-env -q | wc -l
                    echo -e "''${YELLOW}Use 'nix-env -q' for full list''${NC}"
                    ;;

                  kernelcore)
                    echo -e "''${CYAN}''${BOLD}Kernelcore Options:''${NC}"
                    nixos-option -r "kernelcore.*" | head -100
                    echo ""
                    echo -e "''${YELLOW}(Showing first 100 results)''${NC}"
                    ;;

                  gpu)
                    echo -e "''${CYAN}''${BOLD}GPU-Related Configuration:''${NC}"
                    nixos-option -r ".*gpu.*|.*nvidia.*|.*cuda.*" | head -50
                    ;;

                  memory)
                    echo -e "''${CYAN}''${BOLD}Memory-Related Configuration:''${NC}"
                    nixos-option -r ".*memory.*|.*swap.*|.*zram.*|.*oom.*" | head -50
                    ;;

                  security)
                    echo -e "''${CYAN}''${BOLD}Security-Related Configuration:''${NC}"
                    nixos-option -r "security.*|.*firewall.*|.*hardening.*" | head -50
                    ;;

                  networking)
                    echo -e "''${CYAN}''${BOLD}Network-Related Configuration:''${NC}"
                    nixos-option -r "networking.*|.*dns.*|.*vpn.*" | head -50
                    ;;

                  repl)
                    echo -e "''${GREEN}''${BOLD}Opening NixOS REPL...''${NC}"
                    echo -e "''${YELLOW}Tips:''${NC}"
                    echo "  - Type 'config.' and press TAB to explore"
                    echo "  - Try: config.nix.settings"
                    echo "  - Try: config.kernelcore"
                    echo "  - Type ':q' to quit"
                    echo ""
                    nix repl '<nixpkgs/nixos>'
                    ;;

                  diff)
                    echo -e "''${CYAN}''${BOLD}Configuration Diff (current vs previous):''${NC}"
                    sudo nix profile diff-closures --profile /nix/var/nix/profiles/system
                    ;;

                  help|--help|-h)
                    show_help
                    ;;

                  *)
                    echo -e "''${RED}Unknown command: $COMMAND''${NC}"
                    echo ""
                    show_help
                    exit 1
                    ;;
                esac
      '')

      # Quick aliases for common queries
      (pkgs.writeShellScriptBin "nix-find" ''
        #!/usr/bin/env bash
        # Quick search for Nix options
        nixos-explore search "$@"
      '')

      (pkgs.writeShellScriptBin "nix-show" ''
        #!/usr/bin/env bash
        # Quick show option value
        nixos-explore option "$@"
      '')

      (pkgs.writeShellScriptBin "nixos-diff" ''
        #!/usr/bin/env bash
        # Show diff between generations
        sudo nix profile diff-closures --profile /nix/var/nix/profiles/system
      '')
    ];

    # Shell aliases
    programs.zsh.shellAliases = {
      "nxe" = "nixos-explore";
      "nxrepl" = "nix repl '<nixpkgs/nixos>'";
      "nxsearch" = "nixos-explore search";
      "nxopt" = "nixos-explore option";
      "nxconf" = "nix show-config";
    };

    programs.bash.shellAliases = {
      "nxe" = "nixos-explore";
      "nxrepl" = "nix repl '<nixpkgs/nixos>'";
      "nxsearch" = "nixos-explore search";
      "nxopt" = "nixos-explore option";
      "nxconf" = "nix show-config";
    };
  };
}
