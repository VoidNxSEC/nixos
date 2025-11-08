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
          # Journal access
          {
            command = "${pkgs.systemd}/bin/journalctl";
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
          {
            command = "${config.nix.package}/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.nix.package}/bin/nix-collect-garbage";
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
