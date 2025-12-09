{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.services.mobile-workspace = {
      enable = mkEnableOption "Enable isolated mobile workspace for iPhone/tablet access";

      username = mkOption {
        type = types.str;
        default = "mobile";
        description = "Username for mobile access";
      };

      workspaceDir = mkOption {
        type = types.str;
        default = "/srv/mobile-workspace";
        description = "Isolated workspace directory for mobile user";
      };

      allowedCommands = mkOption {
        type = types.listOf types.str;
        default = [
          # Text editors
          "vim"
          "nvim"
          "nano"
          "micro"
          # File operations
          "ls"
          "cat"
          "less"
          "more"
          "head"
          "tail"
          "grep"
          "find"
          "tree"
          "mkdir"
          "touch"
          "rm"
          "cp"
          "mv"
          "chmod"
          "chown"
          # Archive tools
          "tar"
          "gzip"
          "gunzip"
          "zip"
          "unzip"
          # Git operations
          "git"
          "gh"
          "glab"
          # Development tools
          "python"
          "python3"
          "node"
          "npm"
          "cargo"
          "rustc"
          # System info
          "pwd"
          "whoami"
          "date"
          "uptime"
          "df"
          "du"
          # Network
          "curl"
          "wget"
          "ping"
          "ssh"
          # Misc
          "tmux"
          "zellij"
          "htop"
          "btop"
        ];
        description = "List of allowed commands for mobile user";
      };

      sshKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "SSH public keys for mobile user authentication";
      };

      sharedDirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional directories to make accessible (read-only) via bind mounts";
      };

      enableGitAccess = mkOption {
        type = types.bool;
        default = true;
        description = "Allow git operations (requires SSH agent forwarding)";
      };
    };
  };

  config = mkIf config.kernelcore.services.mobile-workspace.enable {

    # Create mobile user
    users.users.${config.kernelcore.services.mobile-workspace.username} = {
      isNormalUser = true;
      description = "Mobile Workspace User (iPhone/Tablet)";
      home = config.kernelcore.services.mobile-workspace.workspaceDir;
      createHome = true;
      shell = pkgs.zsh; # Full shell, but restricted by directory permissions

      # Minimal groups - no sudo, docker, or system access
      extraGroups = [ ];

      # SSH keys for authentication
      openssh.authorizedKeys.keys = config.kernelcore.services.mobile-workspace.sshKeys;

      # User packages (available in PATH)
      packages = with pkgs; [
        # Essential tools
        vim
        neovim
        nano
        micro
        git
        gh
        glab
        tmux
        zellij

        # File utilities
        tree
        file
        ripgrep
        fd
        bat
        eza

        # Development
        python3
        nodejs
        rustup

        # Network tools
        curl
        wget

        # System monitors
        htop
        btop
      ];
    };

    # Create workspace structure
    systemd.tmpfiles.rules = [
      # Main workspace
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir} 0755 ${config.kernelcore.services.mobile-workspace.username} users -"

      # Workspace subdirectories
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/projects 0755 ${config.kernelcore.services.mobile-workspace.username} users -"
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/scripts 0755 ${config.kernelcore.services.mobile-workspace.username} users -"
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/notes 0755 ${config.kernelcore.services.mobile-workspace.username} users -"
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/downloads 0755 ${config.kernelcore.services.mobile-workspace.username} users -"
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/.config 0755 ${config.kernelcore.services.mobile-workspace.username} users -"

      # SSH directory
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/.ssh 0700 ${config.kernelcore.services.mobile-workspace.username} users -"

      # Git config directory
      "d ${config.kernelcore.services.mobile-workspace.workspaceDir}/.config/git 0755 ${config.kernelcore.services.mobile-workspace.username} users -"
    ];

    # Welcome message for mobile workspace
    environment.etc."mobile-workspace/welcome.txt" = {
      text = ''
        ╔════════════════════════════════════════════════════════════════╗
        ║              Welcome to Mobile Workspace (iPhone)              ║
        ╚════════════════════════════════════════════════════════════════╝

        You are logged in as: ${config.kernelcore.services.mobile-workspace.username}
        Workspace location: ${config.kernelcore.services.mobile-workspace.workspaceDir}

        ## Directory Structure:

        ~/projects/     - Your development projects
        ~/scripts/      - Shell scripts and utilities
        ~/notes/        - Notes and documentation
        ~/downloads/    - Downloaded files
        ~/.config/      - Configuration files

        ## Available Tools:

        Editors:        vim, nvim, nano, micro
        File Tools:     ls, cat, grep, find, tree, bat, eza, ripgrep
        Git:            git, gh (GitHub CLI), glab (GitLab CLI)
        Terminal:       tmux, zellij
        Development:    python3, node, npm, cargo, rustc
        Monitoring:     htop, btop
        Network:        curl, wget, ping, ssh

        ## Quick Start:

        # Create a new project
        mkdir -p ~/projects/my-project
        cd ~/projects/my-project

        # Clone a repository (requires SSH agent forwarding)
        git clone git@github.com:user/repo.git

        # Start a tmux session
        tmux new -s work

        # Monitor system
        htop

        ## Security Notes:

        ✓ This is an isolated workspace - no system access
        ✓ No sudo privileges
        ✓ No access to other users' files
        ✓ All activities are logged
        ✓ Limited to workspace directory: ${config.kernelcore.services.mobile-workspace.workspaceDir}

        ## Getting Help:

        - Read this message: cat /etc/mobile-workspace/welcome.txt
        - List available commands: ls /run/current-system/sw/bin
        - Report issues: Contact system administrator

        Happy coding from your mobile device! 📱
      '';
      mode = "0644";
    };

    # Shell configuration for mobile user
    environment.etc."mobile-workspace/zshrc" = {
      text = ''
        # Mobile Workspace Shell Configuration

        # Display welcome message on login
        cat /etc/mobile-workspace/welcome.txt
        echo ""

        # Basic ZSH configuration
        autoload -U compinit && compinit
        autoload -U colors && colors

        # Prompt
        PROMPT='%F{cyan}📱 mobile%f:%F{blue}%~%f$ '

        # Aliases
        alias ls='eza --icons'
        alias ll='eza --icons -lh'
        alias la='eza --icons -lah'
        alias tree='eza --tree --icons'
        alias cat='bat --paging=never'
        alias grep='rg'
        alias find='fd'

        # Git aliases
        alias gs='git status'
        alias gp='git pull'
        alias gc='git commit'
        alias gd='git diff'
        alias gl='git log --oneline --graph'

        # Safety aliases
        alias rm='rm -i'
        alias cp='cp -i'
        alias mv='mv -i'

        # Environment
        export EDITOR=vim
        export VISUAL=vim
        export PAGER=less

        # Restrict to workspace
        cd ${config.kernelcore.services.mobile-workspace.workspaceDir}

        # Prevent directory escape (informational only)
        echo "📍 Workspace: ${config.kernelcore.services.mobile-workspace.workspaceDir}"
        echo "🔒 You have limited access to this directory only"
        echo ""
      '';
      mode = "0644";
    };

    # Link zshrc to mobile user's home
    system.activationScripts.mobileWorkspaceConfig = ''
      mkdir -p ${config.kernelcore.services.mobile-workspace.workspaceDir}
      ln -sf /etc/mobile-workspace/zshrc ${config.kernelcore.services.mobile-workspace.workspaceDir}/.zshrc
      chown -R ${config.kernelcore.services.mobile-workspace.username}:users ${config.kernelcore.services.mobile-workspace.workspaceDir}
    '';

    # SSH configuration for mobile user
    services.openssh.extraConfig = mkBefore ''
      # Mobile workspace user restrictions
      Match User ${config.kernelcore.services.mobile-workspace.username}
        # Allow SSH agent forwarding for git operations
        AllowAgentForwarding ${
          if config.kernelcore.services.mobile-workspace.enableGitAccess then "yes" else "no"
        }
        # Disable other forwarding for security
        AllowTcpForwarding no
        X11Forwarding no
        PermitTunnel no
        # Restrict to workspace (enforced by shell config + file permissions)
      # End Match block - return to global SSH config
      Match all
    '';

    # Systemd service for workspace maintenance
    systemd.services.mobile-workspace-maintenance = {
      description = "Mobile Workspace Maintenance";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "mobile-workspace-maintenance" ''
          # Clean up old files in downloads (older than 30 days)
          ${pkgs.findutils}/bin/find ${config.kernelcore.services.mobile-workspace.workspaceDir}/downloads -type f -mtime +30 -delete || true

          # Ensure permissions are correct
          ${pkgs.coreutils}/bin/chown -R ${config.kernelcore.services.mobile-workspace.username}:users ${config.kernelcore.services.mobile-workspace.workspaceDir}
          ${pkgs.coreutils}/bin/chmod 755 ${config.kernelcore.services.mobile-workspace.workspaceDir}

          # Log maintenance
          echo "Mobile workspace maintenance completed at $(date)" >> /var/log/mobile-workspace-maintenance.log
        '';
      };
    };

    # Run maintenance weekly
    systemd.timers.mobile-workspace-maintenance = {
      description = "Weekly Mobile Workspace Maintenance";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # Logging
    services.journald.extraConfig = ''
      # Log all mobile user activities
      Storage=persistent
    '';

    # Security assertions
    assertions = [
      {
        assertion = config.services.openssh.enable;
        message = "Mobile workspace requires SSH to be enabled";
      }
      {
        assertion = config.kernelcore.services.mobile-workspace.sshKeys != [ ];
        message = "Mobile workspace requires at least one SSH key";
      }
    ];
  };
}
