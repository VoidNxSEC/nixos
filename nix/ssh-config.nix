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

    # Disable default configuration (we configure everything explicitly)
    enableDefaultConfig = false;

    # Host Configurations
    matchBlocks = {
      # GitLab
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_gitlab";
        identitiesOnly = true;
        compression = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
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
        compression = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # General Defaults (Wildcard)
      "*" = {
        compression = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          AddKeysToAgent = "yes";
          TCPKeepAlive = "yes";
        };
      };
    };
  };
}
