# ============================================
# Agent Hub - AI Agent Integration Placeholder
# ============================================
# Future AI agent integration framework for:
# - Systray icon with quick agent access
# - Chat/prompt window for AI agents
# - Agent status monitoring
# - Quick action dispatching
#
# This is a PLACEHOLDER module - expand as needed
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Available agents configuration
  agents = {
    roo = {
      name = "Roo (Claude)";
      icon = "󰚩";
      color = "#00d4ff";
      command = "code --goto";
      description = "VSCode AI assistant powered by Claude";
    };
    codex = {
      name = "Codex";
      icon = "󰧑";
      color = "#7c3aed";
      command = "codex";
      description = "OpenAI Codex CLI agent";
    };
    gemini = {
      name = "Gemini";
      icon = "󰊤";
      color = "#4285f4";
      command = "gemini-cli";
      description = "Google Gemini CLI agent";
    };
    ollama = {
      name = "Ollama";
      icon = "󰊠";
      color = "#22c55e";
      command = "ollama run";
      description = "Local LLM via Ollama";
    };
  };
in
{
  # ============================================
  # AGENT HUB SCRIPTS
  # ============================================
  home.file = {
    # Main agent launcher menu (wofi-based)
    ".config/agent-hub/agent-launcher.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - AI Agent Launcher
        # Quick access to AI coding assistants
        # ============================================

        # Define agents
        declare -A AGENTS=(
          ["󰚩 Roo (Claude) - VSCode AI Assistant"]="code"
          ["󰧑 Codex - CLI Agent"]="alacritty -e codex"
          ["󰊤 Gemini - Google AI"]="alacritty -e gemini-cli"
          ["󰊠 Ollama - Local LLM"]="alacritty -e ollama run llama3"
          ["󰋼 Quick Question"]="agent-quick-prompt"
        )

        # Build menu
        MENU=""
        for key in "''${!AGENTS[@]}"; do
          MENU+="$key\n"
        done

        # Show menu with wofi
        SELECTED=$(echo -e "$MENU" | wofi --dmenu --prompt="Agent Hub 󰚩" --width=450 --height=280 --cache-file=/dev/null)

        if [[ -n "$SELECTED" ]]; then
          CMD="''${AGENTS[$SELECTED]}"
          if [[ -n "$CMD" ]]; then
            eval "$CMD" &
          fi
        fi
      '';
    };

    # Quick prompt dialog
    ".config/agent-hub/quick-prompt.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Quick Prompt
        # Send quick questions to AI agents
        # ============================================

        # Get prompt from wofi
        PROMPT=$(wofi --dmenu --prompt="Ask AI 󰋼" --width=600 --height=50 --lines=1)

        if [[ -z "$PROMPT" ]]; then
          exit 0
        fi

        # Select agent
        AGENTS="󰚩 Claude (via API)\n󰊤 Gemini\n󰊠 Ollama (Local)"
        AGENT=$(echo -e "$AGENTS" | wofi --dmenu --prompt="Select Agent" --width=300 --height=150 --cache-file=/dev/null)

        case "$AGENT" in
          "󰚩 Claude (via API)")
            # Placeholder - would require Claude API
            notify-send -a "Agent Hub" "󰚩 Claude" "API integration coming soon"
            ;;
          "󰊤 Gemini")
            # Use gemini-cli if available
            if command -v gemini-cli &> /dev/null; then
              RESPONSE=$(echo "$PROMPT" | gemini-cli 2>/dev/null)
              if [[ -n "$RESPONSE" ]]; then
                echo "$RESPONSE" | wl-copy
                notify-send -a "Agent Hub" "󰊤 Gemini Response" "$(echo "$RESPONSE" | head -c 200)...\n\nCopied to clipboard!"
              fi
            else
              notify-send -a "Agent Hub" "󰊤 Gemini" "gemini-cli not installed"
            fi
            ;;
          "󰊠 Ollama (Local)")
            # Use ollama if available
            if command -v ollama &> /dev/null; then
              notify-send -a "Agent Hub" "󰊠 Ollama" "Processing..."
              RESPONSE=$(ollama run llama3 "$PROMPT" 2>/dev/null)
              if [[ -n "$RESPONSE" ]]; then
                echo "$RESPONSE" | wl-copy
                notify-send -a "Agent Hub" "󰊠 Ollama Response" "$(echo "$RESPONSE" | head -c 200)...\n\nCopied to clipboard!"
              fi
            else
              notify-send -a "Agent Hub" "󰊠 Ollama" "ollama not installed or not running"
            fi
            ;;
        esac
      '';
    };

    # Agent status checker
    ".config/agent-hub/agent-status.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Status Checker
        # Check availability of AI agents
        # ============================================

        echo "Agent Hub Status"
        echo "════════════════════════════════════════"
        echo ""

        # Check Roo/Claude Code
        if pgrep -f "claude" &> /dev/null || pgrep -f "roo-code" &> /dev/null; then
          echo "󰚩 Roo (Claude): ✅ Running"
        else
          echo "󰚩 Roo (Claude): 󰋗 Not active"
        fi

        # Check Codex
        if command -v codex &> /dev/null; then
          echo "󰧑 Codex: ✅ Available"
        else
          echo "󰧑 Codex: ❌ Not installed"
        fi

        # Check Gemini CLI
        if command -v gemini-cli &> /dev/null; then
          echo "󰊤 Gemini CLI: ✅ Available"
        else
          echo "󰊤 Gemini CLI: ❌ Not installed"
        fi

        # Check Ollama
        if command -v ollama &> /dev/null; then
          if curl -s localhost:11434 &> /dev/null; then
            MODELS=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
            echo "󰊠 Ollama: ✅ Running ($MODELS models)"
          else
            echo "󰊠 Ollama: 󰋗 Installed but not running"
          fi
        else
          echo "󰊠 Ollama: ❌ Not installed"
        fi

        # Check LLaMA.cpp
        if systemctl is-active --quiet llamacpp.service 2>/dev/null; then
          echo "󰊤 LLaMA.cpp: ✅ Service running"
        else
          echo "󰊤 LLaMA.cpp: 󰋗 Service not active"
        fi

        echo ""
        echo "════════════════════════════════════════"
      '';
    };

    # Waybar module configuration (JSON output for custom module)
    ".config/agent-hub/waybar-module.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ============================================
        # Agent Hub - Waybar Module
        # JSON output for waybar custom module
        # ============================================

        # Count active agents
        ACTIVE=0
        TOOLTIP="AI Agent Hub\n━━━━━━━━━━━━━━━━━━━━━━"

        # Check various agents
        if pgrep -f "claude" &> /dev/null; then
          ((ACTIVE++))
          TOOLTIP+="\n󰚩 Claude: Active"
        fi

        if pgrep -f "codex" &> /dev/null; then
          ((ACTIVE++))
          TOOLTIP+="\n󰧑 Codex: Active"
        fi

        if curl -s localhost:11434 &> /dev/null 2>&1; then
          ((ACTIVE++))
          TOOLTIP+="\n󰊠 Ollama: Running"
        fi

        if systemctl is-active --quiet llamacpp.service 2>/dev/null; then
          ((ACTIVE++))
          TOOLTIP+="\n󰊤 LLaMA.cpp: Running"
        fi

        TOOLTIP+="\n\nClick to open Agent Hub"

        # Output JSON
        if [[ $ACTIVE -gt 0 ]]; then
          echo "{\"text\": \"󰚩 $ACTIVE\", \"tooltip\": \"$TOOLTIP\", \"class\": \"active\"}"
        else
          echo "{\"text\": \"󰚩\", \"tooltip\": \"$TOOLTIP\", \"class\": \"inactive\"}"
        fi
      '';
    };
  };

  # ============================================
  # DESKTOP ENTRY FOR AGENT HUB
  # ============================================
  xdg.desktopEntries.agent-hub = {
    name = "Agent Hub";
    genericName = "AI Agent Launcher";
    comment = "Launch and manage AI coding assistants";
    exec = "${config.home.homeDirectory}/.config/agent-hub/agent-launcher.sh";
    icon = "utilities-terminal"; # Using standard icon
    terminal = false;
    type = "Application";
    categories = [
      "Development"
      "Utility"
    ];
  };

  # ============================================
  # FUTURE EXPANSION NOTES
  # ============================================
  # TODO: When expanding this module, consider:
  #
  # 1. GTK4/Libadwaita app for native systray icon
  #    - Use gtk4-layer-shell for Wayland integration
  #    - Real-time agent status monitoring
  #    - Quick action buttons
  #
  # 2. Dedicated chat window
  #    - Floating Hyprland window rule
  #    - WebView for rich markdown rendering
  #    - History persistence
  #
  # 3. Agent orchestration
  #    - Route tasks to appropriate agents
  #    - Chain multiple agents for complex tasks
  #    - Cost/performance optimization
  #
  # 4. MCP integration
  #    - Connect to existing MCP server
  #    - Shared context between agents
  #    - Tool/resource access
  #
  # 5. Keyboard shortcuts
  #    - Global hotkey for quick prompt
  #    - Agent-specific shortcuts
  #    - Context-aware suggestions
}
