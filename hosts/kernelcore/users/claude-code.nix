{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.users.claude-code;
in
{
  options.kernelcore.services.users.claude-code = {
    enable = mkEnableOption "Enable Claude Code dedicated user with special powers";

    userName = mkOption {
      type = types.str;
      default = "claude-code";
      description = "Username for Claude Code service";
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/var/lib/claude-code";
      description = "Home directory for Claude Code user";
    };

    allowedGroups = mkOption {
      type = types.listOf types.str;
      default = [
        "wheel" # Sudo access
        "docker" # Docker management
        "libvirtd" # Virtualization
        "video" # GPU access
        "nvidia" # NVIDIA GPU
        "render" # Rendering
        "audio" # Audio if needed
      ];
      description = "Groups to add Claude Code user to";
    };

    sudoNoPasswd = mkOption {
      type = types.bool;
      default = true;
      description = "Allow passwordless sudo for system operations";
    };

    nixTrusted = mkOption {
      type = types.bool;
      default = true;
      description = "Add user to Nix trusted users for builds";
    };
  };

  config = mkIf cfg.enable {
    # Create the dedicated user
    users.users.${cfg.userName} = {
      isSystemUser = true;
      description = "Claude Code AI Assistant - System Operations User";
      home = cfg.homeDirectory;
      createHome = true;
      group = cfg.userName;
      extraGroups = cfg.allowedGroups;

      # SSH key for automated operations (will be generated on first boot)
      openssh.authorizedKeys.keys = [
        # Add your SSH public key here for remote operations if needed
      ];

      # Shell for interactive sessions
      shell = pkgs.bash;

      # Packages available to Claude Code user
      packages = with pkgs; [
        git
        curl
        wget
        jq
        ripgrep
        fd
        bat
        htop
        docker
        kubectl
        nixos-rebuild
        nix-tree
      ];
    };

    # Create matching group
    users.groups.${cfg.userName} = { };

    # Passwordless sudo for system operations (confined to safe commands)
    security.sudo.extraRules = mkIf cfg.sudoNoPasswd [
      {
        users = [ cfg.userName ];
        commands = [
          # NixOS rebuild operations
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          # System service management
          {
            command = "${pkgs.systemd}/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          # Docker operations
          {
            command = "${pkgs.docker}/bin/docker";
            options = [ "NOPASSWD" ];
          }
          # Nix operations
          {
            command = "${config.nix.package}/bin/nix";
            options = [ "NOPASSWD" ];
          }
          # Journal access
          {
            command = "${pkgs.systemd}/bin/journalctl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Add to Nix trusted users
    nix.settings.trusted-users = mkIf cfg.nixTrusted [ cfg.userName ];

    # Create workspace directories
    systemd.tmpfiles.rules = [
      "d ${cfg.homeDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/.ssh 0700 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/workspace 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/logs 0750 ${cfg.userName} ${cfg.userName} -"
    ];

    # Environment setup for Claude Code operations
    environment.variables = {
      CLAUDE_CODE_USER = cfg.userName;
      CLAUDE_CODE_HOME = cfg.homeDirectory;
      ANTHROPIC_MODEL = "claude-sonnet-4-5-20250929";
    };
  };
}
