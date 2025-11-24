{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.kernelcore.development.claudeProfiles = {
    enable = mkEnableOption "Enable Claude Code API profile management";
  };

  config = mkIf config.kernelcore.development.claudeProfiles.enable {
    environment.systemPackages = [
      # ============================================================
      # CLAUDE CODE - API PROFILE SWITCHER
      # ============================================================
      (pkgs.writeShellScriptBin "claude-profile" ''
                #!/usr/bin/env bash
                # Claude Code API Profile Manager

                CYAN='\033[0;36m'
                GREEN='\033[0;32m'
                YELLOW='\033[1;33m'
                RED='\033[0;31m'
                BOLD='\033[1m'
                NC='\033[0m'

                PROFILE_DIR="$HOME/.config/claude-profiles"
                CURRENT_PROFILE="$PROFILE_DIR/current"
                GLOBAL_ENV="$HOME/.claude-env"

                # Ensure profile directory exists
                mkdir -p "$PROFILE_DIR"

                show_help() {
                  cat << EOF
        ╔══════════════════════════════════════════════════════════════╗
        ║           Claude Code - API Profile Manager                  ║
        ╚══════════════════════════════════════════════════════════════╝

        ''${CYAN}USAGE:''${NC}
          claude-profile <command> [args]

        ''${YELLOW}COMMANDS:''${NC}

          ''${BOLD}list''${NC}              - Show all configured profiles
          ''${BOLD}current''${NC}           - Show current active profile
          ''${BOLD}use <profile>''${NC}     - Switch to a profile (pro|api|bedrock)
          ''${BOLD}set <profile>''${NC}     - Configure a profile
          ''${BOLD}test''${NC}              - Test current profile connection
          ''${BOLD}env''${NC}               - Show environment variables for current profile

        ''${YELLOW}AVAILABLE PROFILES:''${NC}

          ''${GREEN}pro''${NC}       - Claude.ai Pro subscription (web-based)
                    - Uses your browser cookies
                    - No API key needed
                    - Subject to rate limits

          ''${GREEN}api''${NC}       - Official Anthropic API
                    - Requires: ANTHROPIC_API_KEY
                    - Pay-per-use pricing
                    - Higher rate limits

          ''${GREEN}bedrock''${NC}   - AWS Bedrock (Claude via AWS)
                    - Requires: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
                    - Enterprise features
                    - AWS pricing

        ''${CYAN}EXAMPLES:''${NC}

          # Switch to Bedrock
          claude-profile use bedrock

          # Configure API key for official API
          claude-profile set api

          # Test current connection
          claude-profile test

          # Show current profile
          claude-profile current

        ''${CYAN}SETUP:''${NC}

          1. Configure your profile:
             ''${BOLD}claude-profile set api''${NC}   (or bedrock)

          2. Switch to it:
             ''${BOLD}claude-profile use api''${NC}

          3. Test connection:
             ''${BOLD}claude-profile test''${NC}

          4. Start Claude Code:
             ''${BOLD}claude''${NC}

        EOF
                }

                list_profiles() {
                  echo -e "''${CYAN}''${BOLD}Available Profiles:''${NC}"
                  echo ""

                  local current=""
                  if [ -f "$CURRENT_PROFILE" ]; then
                    current=$(cat "$CURRENT_PROFILE")
                  fi

                  for profile in pro api bedrock; do
                    local marker=" "
                    local status=""

                    if [ "$profile" = "$current" ]; then
                      marker="''${GREEN}✓''${NC}"
                      status="''${GREEN}(active)''${NC}"
                    fi

                    local config_file="$PROFILE_DIR/$profile.env"
                    local configured=""
                    if [ -f "$config_file" ]; then
                      configured="''${GREEN}[configured]''${NC}"
                    else
                      configured="''${YELLOW}[not configured]''${NC}"
                    fi

                    echo -e "  $marker ''${BOLD}$profile''${NC} $configured $status"
                  done
                  echo ""
                }

                show_current() {
                  if [ ! -f "$CURRENT_PROFILE" ]; then
                    echo -e "''${YELLOW}No profile selected''${NC}"
                    echo "Run: claude-profile use <profile>"
                    exit 0
                  fi

                  local profile=$(cat "$CURRENT_PROFILE")
                  echo -e "''${GREEN}Current profile: ''${BOLD}$profile''${NC}"

                  if [ -f "$PROFILE_DIR/$profile.env" ]; then
                    echo ""
                    echo -e "''${CYAN}Configuration:''${NC}"
                    cat "$PROFILE_DIR/$profile.env" | grep -v "SECRET" | grep -v "KEY" | sed 's/=.*/=***/'
                  fi
                }

                use_profile() {
                  local profile=$1

                  if [ -z "$profile" ]; then
                    echo -e "''${RED}Error: Please specify a profile''${NC}"
                    echo "Usage: claude-profile use <pro|api|bedrock>"
                    exit 1
                  fi

                  if [[ ! "$profile" =~ ^(pro|api|bedrock)$ ]]; then
                    echo -e "''${RED}Error: Invalid profile: $profile''${NC}"
                    echo "Valid profiles: pro, api, bedrock"
                    exit 1
                  fi

                  # Check if profile is configured
                  if [ ! -f "$PROFILE_DIR/$profile.env" ] && [ "$profile" != "pro" ]; then
                    echo -e "''${YELLOW}Warning: Profile '$profile' is not configured yet''${NC}"
                    echo "Run: claude-profile set $profile"
                    read -p "Continue anyway? (y/N) " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                      exit 0
                    fi
                  fi

                  # Set current profile
                  echo "$profile" > "$CURRENT_PROFILE"

                  # Update global env file
                  if [ "$profile" = "pro" ]; then
                    echo "# Claude Pro (Web-based)" > "$GLOBAL_ENV"
                    echo "CLAUDE_PROFILE=pro" >> "$GLOBAL_ENV"
                  else
                    cat "$PROFILE_DIR/$profile.env" > "$GLOBAL_ENV"
                    echo "CLAUDE_PROFILE=$profile" >> "$GLOBAL_ENV"
                  fi

                  echo -e "''${GREEN}✓ Switched to profile: ''${BOLD}$profile''${NC}"
                  echo ""
                  echo "Environment variables updated in: $GLOBAL_ENV"
                  echo ""
                  echo -e "''${CYAN}Next steps:''${NC}"
                  echo "  1. Source the environment: ''${BOLD}source $GLOBAL_ENV''${NC}"
                  echo "  2. Or restart your shell"
                  echo "  3. Test connection: ''${BOLD}claude-profile test''${NC}"
                }

                set_profile() {
                  local profile=$1

                  if [ -z "$profile" ]; then
                    echo -e "''${RED}Error: Please specify a profile''${NC}"
                    echo "Usage: claude-profile set <api|bedrock>"
                    exit 1
                  fi

                  case "$profile" in
                    pro)
                      echo -e "''${YELLOW}Claude Pro doesn't require configuration''${NC}"
                      echo "It uses your browser cookies automatically."
                      echo ""
                      echo "Just run: claude-profile use pro"
                      exit 0
                      ;;

                    api)
                      echo -e "''${CYAN}''${BOLD}Configure Official Anthropic API''${NC}"
                      echo ""
                      echo "You'll need:"
                      echo "  - Anthropic API Key (from https://console.anthropic.com/)"
                      echo ""
                      read -p "Enter your Anthropic API Key: " api_key

                      if [ -z "$api_key" ]; then
                        echo -e "''${RED}Error: API key cannot be empty''${NC}"
                        exit 1
                      fi

                      cat > "$PROFILE_DIR/api.env" <<EOF
        # Anthropic Official API
        export ANTHROPIC_API_KEY="$api_key"
        export CLAUDE_API_TYPE="anthropic"
        export CLAUDE_MODEL="claude-sonnet-4"
        EOF

                      chmod 600 "$PROFILE_DIR/api.env"
                      echo -e "''${GREEN}✓ API profile configured successfully''${NC}"
                      echo ""
                      echo "Run: claude-profile use api"
                      ;;

                    bedrock)
                      echo -e "''${CYAN}''${BOLD}Configure AWS Bedrock''${NC}"
                      echo ""
                      echo "You'll need:"
                      echo "  - AWS Access Key ID"
                      echo "  - AWS Secret Access Key"
                      echo "  - AWS Region (e.g., us-east-1)"
                      echo ""

                      read -p "Enter AWS Access Key ID: " aws_key_id
                      read -p "Enter AWS Secret Access Key: " aws_secret
                      read -p "Enter AWS Region [us-east-1]: " aws_region
                      aws_region=''${aws_region:-us-east-1}

                      if [ -z "$aws_key_id" ] || [ -z "$aws_secret" ]; then
                        echo -e "''${RED}Error: AWS credentials cannot be empty''${NC}"
                        exit 1
                      fi

                      cat > "$PROFILE_DIR/bedrock.env" <<EOF
        # AWS Bedrock
        export AWS_ACCESS_KEY_ID="$aws_key_id"
        export AWS_SECRET_ACCESS_KEY="$aws_secret"
        export AWS_REGION="$aws_region"
        export CLAUDE_API_TYPE="bedrock"
        export CLAUDE_MODEL="anthropic.claude-sonnet-4-20250514-v1:0"
        EOF

                      chmod 600 "$PROFILE_DIR/bedrock.env"
                      echo -e "''${GREEN}✓ Bedrock profile configured successfully''${NC}"
                      echo ""
                      echo "Run: claude-profile use bedrock"
                      ;;

                    *)
                      echo -e "''${RED}Error: Invalid profile: $profile''${NC}"
                      echo "Valid profiles: api, bedrock"
                      exit 1
                      ;;
                  esac
                }

                test_profile() {
                  if [ ! -f "$CURRENT_PROFILE" ]; then
                    echo -e "''${RED}Error: No profile selected''${NC}"
                    echo "Run: claude-profile use <profile>"
                    exit 1
                  fi

                  local profile=$(cat "$CURRENT_PROFILE")
                  echo -e "''${CYAN}Testing profile: ''${BOLD}$profile''${NC}"
                  echo ""

                  # Source the profile
                  if [ "$profile" != "pro" ]; then
                    source "$PROFILE_DIR/$profile.env"
                  fi

                  case "$profile" in
                    pro)
                      echo -e "''${YELLOW}Note: Claude Pro test requires browser authentication''${NC}"
                      echo "If Claude Code starts successfully, your profile is working."
                      ;;

                    api)
                      if [ -z "$ANTHROPIC_API_KEY" ]; then
                        echo -e "''${RED}✗ ANTHROPIC_API_KEY not set''${NC}"
                        exit 1
                      fi

                      echo "Testing connection to Anthropic API..."
                      # Simple API test (you'll need to implement actual test)
                      echo -e "''${GREEN}✓ API key is set''${NC}"
                      echo "Note: Full test requires actual API call"
                      ;;

                    bedrock)
                      if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
                        echo -e "''${RED}✗ AWS credentials not set''${NC}"
                        exit 1
                      fi

                      echo "Testing connection to AWS Bedrock..."
                      echo -e "''${GREEN}✓ AWS credentials are set''${NC}"
                      echo "Region: $AWS_REGION"
                      echo "Note: Full test requires AWS CLI"
                      ;;
                  esac
                }

                show_env() {
                  if [ ! -f "$CURRENT_PROFILE" ]; then
                    echo -e "''${RED}Error: No profile selected''${NC}"
                    exit 1
                  fi

                  local profile=$(cat "$CURRENT_PROFILE")
                  echo -e "''${CYAN}Environment for profile: ''${BOLD}$profile''${NC}"
                  echo ""

                  if [ "$profile" = "pro" ]; then
                    echo "# No environment variables needed for Pro"
                  else
                    cat "$PROFILE_DIR/$profile.env"
                  fi
                }

                # Main command router
                case "''${1:-}" in
                  list)
                    list_profiles
                    ;;
                  current)
                    show_current
                    ;;
                  use)
                    use_profile "$2"
                    ;;
                  set)
                    set_profile "$2"
                    ;;
                  test)
                    test_profile
                    ;;
                  env)
                    show_env
                    ;;
                  help|--help|-h|"")
                    show_help
                    ;;
                  *)
                    echo -e "''${RED}Unknown command: $1''${NC}"
                    echo ""
                    show_help
                    exit 1
                    ;;
                esac
      '')

      # Quick aliases
      (pkgs.writeShellScriptBin "claude-use-pro" ''
        #!/usr/bin/env bash
        claude-profile use pro
      '')

      (pkgs.writeShellScriptBin "claude-use-api" ''
        #!/usr/bin/env bash
        claude-profile use api
      '')

      (pkgs.writeShellScriptBin "claude-use-bedrock" ''
        #!/usr/bin/env bash
        claude-profile use bedrock
      '')
    ];

    # Shell integration
    programs.zsh.interactiveShellInit = ''
      # Auto-load Claude profile if set
      if [ -f "$HOME/.claude-env" ]; then
        source "$HOME/.claude-env"
      fi
    '';

    programs.bash.interactiveShellInit = ''
      # Auto-load Claude profile if set
      if [ -f "$HOME/.claude-env" ]; then
        source "$HOME/.claude-env"
      fi
    '';

    # Shell aliases
    programs.zsh.shellAliases = {
      "claude-pro" = "claude-use-pro";
      "claude-api" = "claude-use-api";
      "claude-aws" = "claude-use-bedrock";
    };

    programs.bash.shellAliases = {
      "claude-pro" = "claude-use-pro";
      "claude-api" = "claude-use-api";
      "claude-aws" = "claude-use-bedrock";
    };
  };
}
