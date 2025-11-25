{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.applications.zellij;

  # Optimized Zellij configuration in KDL format
  zellijConfig = ''
    // Zellij Configuration - Managed by NixOS
    // Performance optimized for low latency and minimal resource usage

    // UI Settings - Balanced for usability and performance
    theme "gruvbox-dark"
    default_shell "bash"
    pane_frames true              // Keep frames for better visibility
    simplified_ui false           // Full UI for better UX
    default_layout "compact"
    default_mode "normal"
    mouse_mode true
    copy_on_select true           // Enable copy on select (essential UX)
    copy_command "wl-copy"        // Wayland clipboard
    scrollback_editor "nvim"

    // Performance optimizations (kept reasonable)
    session_serialization true    // Keep session saves (useful feature)
    mirror_session true           // Efficient session mirroring

    // Cache settings - aggressive cleanup
    on_force_close "quit"        // Clean exit

    // Keybindings - Optimized layout
    keybinds {
        normal {
            // Disable accidental quit
            unbind "Ctrl q"

            // Tabs management
            bind "Alt t" { NewTab; }
            bind "Alt w" { CloseTab; }
            bind "Alt n" { GoToNextTab; }
            bind "Alt p" { GoToPreviousTab; }
            bind "Alt 1" { GoToTab 1; }
            bind "Alt 2" { GoToTab 2; }
            bind "Alt 3" { GoToTab 3; }
            bind "Alt 4" { GoToTab 4; }
            bind "Alt 5" { GoToTab 5; }

            // Panes management
            bind "Alt h" { NewPane "Left"; }
            bind "Alt j" { NewPane "Down"; }
            bind "Alt k" { NewPane "Up"; }
            bind "Alt l" { NewPane "Right"; }

            // Navigation
            bind "Alt Left" { MoveFocus "Left"; }
            bind "Alt Down" { MoveFocus "Down"; }
            bind "Alt Up" { MoveFocus "Up"; }
            bind "Alt Right" { MoveFocus "Right"; }

            // Resize
            bind "Alt +" { Resize "Increase"; }
            bind "Alt -" { Resize "Decrease"; }

            // Actions
            bind "Alt x" { CloseFocus; }
            bind "Alt f" { ToggleFocusFullscreen; }
            bind "Alt s" { SwitchToMode "scroll"; }
            bind "Alt c" { SwitchToMode "copy"; }
            bind "Alt r" { SwitchToMode "RenameTab"; TabNameInput 0; }
        }

        scroll {
            bind "Esc" { SwitchToMode "Normal"; }
            bind "q" { SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "PageDown" { PageScrollDown; }
            bind "PageUp" { PageScrollUp; }
            bind "Space" { SwitchToMode "copy"; }
        }

        copy {
            bind "Esc" { SwitchToMode "Normal"; }
            bind "q" { SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "v" { ToggleActiveSyncTab; }
            bind "y" { Copy; SwitchToMode "Normal"; }
            bind "Enter" { Copy; SwitchToMode "Normal"; }
        }

        renametab {
            bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
            bind "Enter" { SwitchToMode "Normal"; }
        }
    }

    // Theme - Gruvbox Dark
    themes {
        gruvbox-dark {
            fg "#ebdbb2"
            bg "#282828"
            black "#3c3836"
            red "#cc241d"
            green "#98971a"
            yellow "#d79921"
            blue "#458588"
            magenta "#b16286"
            cyan "#689d6a"
            white "#a89984"
            orange "#d65d0e"
        }
    }
  '';

  # Cleanup script for Zellij cache
  cleanupScript = pkgs.writeShellScriptBin "zellij-cleanup" ''
    #!/usr/bin/env bash
    # Zellij Cache Cleanup Script
    # Removes old session data and optimizes cache

    CACHE_DIR="$HOME/.cache/zellij"
    MAX_CACHE_SIZE_MB=50

    if [ ! -d "$CACHE_DIR" ]; then
        echo "No Zellij cache found."
        exit 0
    fi

    echo "🧹 Cleaning Zellij cache..."

    # Get current cache size
    CURRENT_SIZE=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
    echo "Current cache size: ''${CURRENT_SIZE}MB"

    # Remove old session directories (older than 7 days)
    find "$CACHE_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

    # Remove large cache files (>5MB) that aren't currently in use
    find "$CACHE_DIR" -type f -size +5M ! -newermt "1 day ago" -delete 2>/dev/null

    # Clean empty directories
    find "$CACHE_DIR" -type d -empty -delete 2>/dev/null

    # Get new cache size
    NEW_SIZE=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
    FREED=$((CURRENT_SIZE - NEW_SIZE))

    echo "✅ Cleanup complete!"
    echo "New cache size: ''${NEW_SIZE}MB"
    echo "Space freed: ''${FREED}MB"

    if [ "$NEW_SIZE" -gt "$MAX_CACHE_SIZE_MB" ]; then
        echo "⚠️  Cache still large (>''${MAX_CACHE_SIZE_MB}MB). Consider manual cleanup."
    fi
  '';

  # Optimized Zellij wrapper
  zellijWrapper = pkgs.writeShellScriptBin "zellij-optimized" ''
    #!/usr/bin/env bash
    # Zellij optimized launcher

    # Set performance environment variables
    export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
    export ZELLIJ_CONFIG_FILE="$HOME/.config/zellij/config.kdl"

    # Disable session serialization for performance
    export ZELLIJ_SESSION_SERIALIZATION=false

    # Run cleanup if cache is too large (>100MB)
    CACHE_SIZE=$(du -sm "$HOME/.cache/zellij" 2>/dev/null | cut -f1)
    if [ "$CACHE_SIZE" -gt 100 ]; then
        echo "⚠️  Large cache detected (''${CACHE_SIZE}MB). Running cleanup..."
        ${cleanupScript}/bin/zellij-cleanup
    fi

    # Launch Zellij
    exec ${pkgs.zellij}/bin/zellij "$@"
  '';

in
{
  options.kernelcore.applications.zellij = {
    enable = mkEnableOption "Zellij terminal multiplexer with optimized configuration";

    autoCleanup = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic cache cleanup via systemd timer";
    };

    cleanupInterval = mkOption {
      type = types.str;
      default = "daily";
      description = "Interval for cache cleanup (daily, weekly, monthly)";
    };

    maxCacheSizeMB = mkOption {
      type = types.int;
      default = 50;
      description = "Maximum cache size in MB before cleanup is triggered";
    };
  };

  config = mkIf cfg.enable {
    # Install Zellij and utilities
    environment.systemPackages = with pkgs; [
      zellij
      cleanupScript
      zellijWrapper
    ];

    # Create config directory and file via home-manager or environment
    environment.etc."zellij/config.kdl" = {
      text = zellijConfig;
      mode = "0644";
    };

    # XDG user directories setup
    system.userActivationScripts.zellijConfig = ''
      mkdir -p $HOME/.config/zellij
      ln -sf /etc/zellij/config.kdl $HOME/.config/zellij/config.kdl

      # Create cache directory with proper permissions
      mkdir -p $HOME/.cache/zellij
      chmod 700 $HOME/.cache/zellij
    '';

    # Systemd user service for cache cleanup
    systemd.user.services.zellij-cleanup = mkIf cfg.autoCleanup {
      description = "Zellij cache cleanup service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cleanupScript}/bin/zellij-cleanup";
      };
    };

    # Systemd timer for automatic cleanup
    systemd.user.timers.zellij-cleanup = mkIf cfg.autoCleanup {
      description = "Zellij cache cleanup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.cleanupInterval;
        Persistent = true;
      };
    };

    # Environment variables for all users
    environment.sessionVariables = {
      ZELLIJ_CONFIG_DIR = "$HOME/.config/zellij";
      ZELLIJ_CONFIG_FILE = "$HOME/.config/zellij/config.kdl";
    };

    # Shell aliases
    programs.bash.shellAliases = {
      zj = "zellij";
      zja = "zellij attach --create";
      zjl = "zellij list-sessions";
      zjk = "zellij kill-session";
      zjc = "zellij-cleanup";
    };

    programs.zsh.shellAliases = {
      zj = "zellij";
      zja = "zellij attach --create";
      zjl = "zellij list-sessions";
      zjk = "zellij kill-session";
      zjc = "zellij-cleanup";
    };
  };
}
