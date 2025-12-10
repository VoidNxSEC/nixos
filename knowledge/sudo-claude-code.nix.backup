{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.system.sudo-claude-code;
in
{
  options.kernelcore.system.sudo-claude-code = {
    enable = mkEnableOption "Enable passwordless sudo for Claude Code operations";

    allowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "kernelcore" ];
      description = "Users allowed to run Claude Code operations without password";
    };

    allowedCommands = mkOption {
      type = types.listOf types.str;
      default = [
        "nixos-rebuild"
        "systemctl"
        "journalctl"
        "docker"
        "nix"
        "nix-store"
        "nix-collect-garbage"
      ];
      description = "Commands allowed to run without password";
    };
  };

  config = mkIf cfg.enable {
    security.sudo.extraRules = [
      {
        users = cfg.allowedUsers;
        commands = [
          # NixOS rebuild operations (allow via current-system symlink to avoid hash changes)
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          # Also allow via Nix store path (for consistency)
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          # System service management
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          # Journal access
          {
            command = "/run/current-system/sw/bin/journalctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/journalctl";
            options = [ "NOPASSWD" ];
          }
          # Docker operations
          {
            command = "/run/current-system/sw/bin/docker";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.docker}/bin/docker";
            options = [ "NOPASSWD" ];
          }
          # Nix operations
          {
            command = "/run/current-system/sw/bin/nix";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.nix.package}/bin/nix";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.nix.package}/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.nix.package}/bin/nix-collect-garbage";
            options = [ "NOPASSWD" ];
          }
          # File system operations (for log management, backups, etc.)
          {
            command = "/run/current-system/sw/bin/truncate";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/truncate";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mkdir";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/mkdir";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/cp";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/cp";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/mv";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/rm";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/chmod";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/chmod";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/chown";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/chown";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/ls";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils}/bin/ls";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Log sudo operations for security audit
    security.sudo.extraConfig = ''
      Defaults    log_output
      Defaults    logfile="/var/log/sudo.log"
      Defaults    !syslog
    '';
  };
}
