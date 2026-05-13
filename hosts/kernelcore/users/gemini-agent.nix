{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.services.users.gemini-agent;
in
{
  options.kernelcore.services.users.gemini-agent = {
    enable = mkEnableOption "Enable Gemini Agent dedicated user";

    userName = mkOption {
      type = types.str;
      default = "gemini-agent";
      description = "Username for Gemini Agent service";
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/var/lib/gemini-agent";
      description = "Home directory for Gemini Agent user";
    };

    allowedGroups = mkOption {
      type = types.listOf types.str;
      default = [
        "wheel"
        "docker"
        "libvirtd"
        "video"
        "nvidia"
        "render"
      ];
      description = "Groups to add Gemini Agent user to";
    };

    sudoNoPasswd = mkOption {
      type = types.bool;
      default = true;
      description = "Allow passwordless sudo for system operations";
    };
  };

  config = mkIf cfg.enable {
    users.users."${cfg.userName}" = {
      isSystemUser = true;
      description = "Gemini Agent AI Assistant";
      home = cfg.homeDirectory;
      createHome = true;
      group = cfg.userName;
      extraGroups = cfg.allowedGroups ++ [ "mcp-shared" ]; # Add shared knowledge DB access
      shell = pkgs.bash;
      packages = with pkgs; [
        nodejs_22 # Required for MCP server stdio connection
        git
        nix
        coreutils
        findutils
        # Note: gemini-cli is installed system-wide via kernelcore.packages.gemini-cli
      ];
    };

    users.groups."${cfg.userName}" = { };

    security.sudo.extraRules = mkIf cfg.sudoNoPasswd [
      {
        users = [ cfg.userName ];
        commands = [
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.docker}/bin/docker";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.nix.package}/bin/nix";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.homeDirectory} 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/.ssh 0700 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/dev 0750 ${cfg.userName} ${cfg.userName} -"
      "d ${cfg.homeDirectory}/workspace 0750 ${cfg.userName} ${cfg.userName} -"
    ];
  };
}
