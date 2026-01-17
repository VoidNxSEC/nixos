# General SSH Configuration
# Usage: Import in /etc/nixos/hosts/kernelcore/home/home.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.ssh = {
    enable = true;

    # Global Settings
    compression = true;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;

    # Host Configurations
    matchBlocks = {
      # GitLab
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_gitlab";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # GitHub
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # General Defaults (Wildcard)
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
          TCPKeepAlive = "yes";
        };
      };
    };
  };
}
