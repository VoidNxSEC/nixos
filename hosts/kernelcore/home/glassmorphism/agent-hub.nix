# ============================================
# Agent Hub - AI Agent Integration with API Chat
# ============================================
# Full AI agent integration framework:
# - Local LLaMA.cpp API chat
# - Wofi-based quick prompt
# - Floating chat window for Hyprland
# - Agent status monitoring
# - Waybar integration
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # API Configuration - uses your local llama.cpp server
  llamaCppApi = {
    host = "127.0.0.1";
    port = 8080;
    model = "local"; # Name for display
  };

  # Color palette for agents
  colors = import ./colors.nix { inherit lib; };
in
{
  # Required packages
  home.packages = with pkgs; [
    jq
    curl
    wl-clipboard
    libnotify
  ];

  # ============================================
  # AGENT HUB SCRIPTS
  # ============================================
  home.file = {
    # AI Chat script - sends prompt to local LLaMA.cpp
    ".config/agent-hub/ai-chat.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - AI Chat API Client
        # Sends prompts to local LLaMA.cpp server
        # ============================================

        API_HOST="${llamaCppApi.host}"
        API_PORT="${toString llamaCppApi.port}"
        API_URL="http://$API_HOST:$API_PORT/v1/chat/completions"
        HISTORY_FILE="$HOME/.cache/agent-hub/chat-history.json"

        # Colors
        CYAN='\033[0;36m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        NC='\033[0m'

        # Ensure cache directory exists
        mkdir -p "$(dirname "$HISTORY_FILE")"

        # Check if API is available
        check_api() {
          curl -s --connect-timeout 2 "http://$API_HOST:$API_PORT/health" > /dev/null 2>&1
          return $?
        }

        # Send message to LLaMA.cpp
        send_message() {
          local prompt="$1"
          local response

          response=$(curl -s "$API_URL" \
            -H "Content-Type: application/json" \
            -d "{
              \"model\": \"${llamaCppApi.model}\",
              \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful AI assistant. Be concise and direct.\"},
                {\"role\": \"user\", \"content\": \"$prompt\"}
              ],
              \"temperature\": 0.7,
              \"max_tokens\": 2048,
              \"stream\": false
            }" 2>/dev/null)

          if [[ -n "$response" ]]; then
            echo "$response" | ${pkgs.jq}/bin/jq -r '.choices[0].message.content // .error.message // "No response"'
          else
            echo "Error: Could not connect to LLaMA.cpp API"
            return 1
          fi
        }

        # Interactive mode
        interactive_chat() {
          echo -e "''${CYAN}╔══════════════════════════════════════════════╗''${NC}"
          echo -e "''${CYAN}║      󰚩 Agent Hub - AI Chat                 ║''${NC}"
          echo -e "''${CYAN}╚══════════════════════════════════════════════╝''${NC}"
          echo ""

          if ! check_api; then
            echo -e "''${YELLOW}⚠ LLaMA.cpp API not available at $API_URL''${NC}"
            echo -e "''${YELLOW}  Start with: systemctl start llamacpp''${NC}"
            exit 1
          fi

          echo -e "''${GREEN}✓ Connected to LLaMA.cpp API''${NC}"
          echo "Type 'exit' or Ctrl+D to quit"
          echo ""

          while true; do
            echo -en "''${CYAN}You: ''${NC}"
            read -r prompt
            
            [[ -z "$prompt" ]] && continue
            [[ "$prompt" == "exit" ]] && break
            
            echo -en "''${GREEN}AI: ''${NC}"
            send_message "$prompt"
            echo ""
          done
        }

        # Quick prompt mode (from wofi)
        quick_prompt() {
          local prompt="$1"
          
          if ! check_api; then
            ${pkgs.libnotify}/bin/notify-send -a "Agent Hub" "󰚩 AI Chat" "LLaMA.cpp API not available"
            exit 1
          fi

          local response
          response=$(send_message "$prompt")
          
          if [[ -n "$response" ]]; then
            echo "$response" | ${pkgs.wl-clipboard}/bin/wl-copy
            ${pkgs.libnotify}/bin/notify-send -a "Agent Hub" "󰚩 AI Response" "$(echo "$response" | head -c 300)...\n\n✓ Copied to clipboard"
          fi
        }

        # Main
        case "''${1:-interactive}" in
          -q|--quick)
            shift
            quick_prompt "$*"
            ;;
          -c|--check)
            if check_api; then
              echo "API available at $API_URL"
              exit 0
            else
              echo "API not available"
              exit 1
            fi
            ;;
          *)
            interactive_chat
            ;;
        esac
      '';
    };

    # Main agent launcher menu (wofi-based)
    ".config/agent-hub/agent-launcher.sh" = {
      executable = true;
      text = ''
                #!/usr/bin/env bash
                # ============================================
                # Agent Hub - AI Agent Launcher
                # Quick access to AI coding assistants
                # ============================================

                # Menu options
                MENU="󰚩 AI Chat (Local LLaMA.cpp)
        󰋼 Quick Question
        󰧑 Codex - CLI Agent
        󰊤 Gemini - Google AI
        󰜈 Antigravity (Gemini CLI)
        ━━━━━━━━━━━━━━━━━━━━━━━━
        󰁖 Agent Status
        󰁔 Open Chat Terminal"

                # Show menu with wofi
                SELECTED=$(echo -e "$MENU" | wofi --dmenu --prompt="Agent Hub 󰚩" --width=400 --height=350 --cache-file=/dev/null)

                case "$SELECTED" in
                  "󰚩 AI Chat (Local LLaMA.cpp)")
                    # Open floating terminal with AI chat
                    alacritty --class="agent-hub-chat" -e "$HOME/.config/agent-hub/ai-chat.sh" &
                    ;;
                  "󰋼 Quick Question")
                    "$HOME/.config/agent-hub/quick-prompt.sh"
                    ;;
                  "󰧑 Codex - CLI Agent")
                    alacritty --class="agent-hub-codex" -e codex &
                    ;;
                  "󰊤 Gemini - Google AI")
                    alacritty --class="agent-hub-gemini" -e gemini-cli &
                    ;;
                  "󰜈 Antigravity (Gemini CLI)")
                    alacritty --class="agent-hub-antigravity" -e gemini &
                    ;;
                  "󰁖 Agent Status")
                    "$HOME/.config/agent-hub/agent-status.sh" | wofi --dmenu --prompt="Status" --width=500 --height=400 --cache-file=/dev/null
                    ;;
                  "󰁔 Open Chat Terminal")
                    alacritty --class="agent-hub-chat" -e "$HOME/.config/agent-hub/ai-chat.sh" &
                    ;;
                esac
      '';
    };

    # Quick prompt dialog - sends to local LLaMA.cpp
    ".config/agent-hub/quick-prompt.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Quick Prompt
        # Wofi input → LLaMA.cpp API → Clipboard
        # ============================================

        # Get prompt from wofi
        PROMPT=$(wofi --dmenu --prompt="Ask AI 󰋼" --width=700 --height=50 --lines=1)

        [[ -z "$PROMPT" ]] && exit 0

        # Show loading notification
        ${pkgs.libnotify}/bin/notify-send -a "Agent Hub" "󰋼 Thinking..." "$PROMPT" &

        # Send to AI
        "$HOME/.config/agent-hub/ai-chat.sh" --quick "$PROMPT"
      '';
    };

    # Agent status checker with API health
    ".config/agent-hub/agent-status.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Status Checker
        # ============================================

        echo "󰚩 Agent Hub Status"
        echo "════════════════════════════════════════"
        echo ""

        # LLaMA.cpp API
        if curl -s --connect-timeout 2 "http://${llamaCppApi.host}:${toString llamaCppApi.port}/health" > /dev/null 2>&1; then
          echo "󰊤 LLaMA.cpp API: ✅ Online (port ${toString llamaCppApi.port})"
        else
          echo "󰊤 LLaMA.cpp API: ❌ Offline"
        fi

        # LLaMA.cpp Service
        if systemctl is-active --quiet llamacpp.service 2>/dev/null; then
          echo "󰊤 LLaMA.cpp Service: ✅ Running"
        else
          echo "󰊤 LLaMA.cpp Service: 󰋗 Stopped"
        fi

        # Codex CLI
        if command -v codex &> /dev/null; then
          echo "󰧑 Codex: ✅ Available"
        else
          echo "󰧑 Codex: ❌ Not installed"
        fi

        # Gemini CLI
        if command -v gemini-cli &> /dev/null; then
          echo "󰊤 Gemini CLI: ✅ Available"
        else
          echo "󰊤 Gemini CLI: ❌ Not installed"
        fi

        # Antigravity (gemini command)
        if command -v gemini &> /dev/null; then
          echo "󰜈 Antigravity: ✅ Available"
        else
          echo "󰜈 Antigravity: ❌ Not installed"
        fi

        # VSCode with Roo
        if pgrep -f "code" &> /dev/null; then
          echo "󰚩 VSCode: ✅ Running"
        else
          echo "󰚩 VSCode: 󰋗 Not running"
        fi

        echo ""
        echo "════════════════════════════════════════"
      '';
    };

    # Waybar module with API status (OPTIMIZED)
    ".config/agent-hub/waybar-module.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Waybar Module (OPTIMIZED)
        # JSON output for waybar custom module
        # Optimizations:
        # - Reduced timeout for API check
        # - Efficient process checking
        # - Single pgrep call for all agents
        # ============================================

        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/agent-hub"
        mkdir -p "$CACHE_DIR"

        ACTIVE=0
        TOOLTIP="󰚩 AI Agent Hub\n━━━━━━━━━━━━━━━━━━━━━━"

        # Check LLaMA.cpp API (short timeout)
        if timeout 0.5s bash -c "exec 3<>/dev/tcp/${llamaCppApi.host}/${toString llamaCppApi.port}" 2>/dev/null; then
          ((ACTIVE++))
          TOOLTIP+="\n󰊤 LLaMA.cpp: Online"
        else
          TOOLTIP+="\n󰊤 LLaMA.cpp: Offline"
        fi

        # Check active agents with single pgrep
        agents=$(pgrep -f "codex|gemini" 2>/dev/null || true)

        if echo "$agents" | grep -q "codex"; then
          ((ACTIVE++))
          TOOLTIP+="\n󰧑 Codex: Active"
        fi

        if echo "$agents" | grep -q "gemini"; then
          ((ACTIVE++))
          TOOLTIP+="\n󰊤 Gemini: Active"
        fi

        TOOLTIP+="\n\nClick: Open Agent Hub\nRight-click: Quick Prompt"

        # Output JSON
        if ((ACTIVE > 0)); then
          echo "{\"text\": \"󰚩\", \"tooltip\": \"$TOOLTIP\", \"class\": \"active\", \"alt\": \"$ACTIVE\"}"
        else
          echo "{\"text\": \"󰚩\", \"tooltip\": \"$TOOLTIP\", \"class\": \"inactive\", \"alt\": \"0\"}"
        fi
      '';
    };
  };

  # ============================================
  # DESKTOP ENTRY
  # ============================================
  xdg.desktopEntries.agent-hub = {
    name = "Agent Hub";
    genericName = "AI Agent Launcher";
    comment = "Launch and manage AI coding assistants";
    exec = "${config.home.homeDirectory}/.config/agent-hub/agent-launcher.sh";
    icon = "utilities-terminal";
    terminal = false;
    type = "Application";
    categories = [
      "Development"
      "Utility"
    ];
  };

  xdg.desktopEntries.ai-chat = {
    name = "AI Chat";
    genericName = "Local AI Chat";
    comment = "Chat with local LLaMA.cpp AI";
    exec = "alacritty --class agent-hub-chat -e ${config.home.homeDirectory}/.config/agent-hub/ai-chat.sh";
    icon = "utilities-terminal";
    terminal = false;
    type = "Application";
    categories = [
      "Development"
      "Utility"
    ];
  };
}
