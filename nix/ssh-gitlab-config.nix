# SSH Configuration for GitLab Integration
# Integrates with existing git.nix configuration
#
# Usage: Import in /etc/nixos/hosts/kernelcore/home/home.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ═══════════════════════════════════════════════════════════════
  # SSH Configuration for GitLab + GitHub
  # ═══════════════════════════════════════════════════════════════

  programs.ssh = {
    enable = true;

    # SSH client configuration
    extraConfig = ''
      # GitLab Configuration
      Host gitlab.com
        HostName gitlab.com
        User git
        IdentityFile ~/.ssh/id_ed25519_gitlab
        IdentitiesOnly yes
        PreferredAuthentications publickey

      # GitHub Configuration (existing key)
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes
        PreferredAuthentications publickey

      # General SSH Settings
      Host *
        AddKeysToAgent yes
        Compression yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
    '';
  };

  # ═══════════════════════════════════════════════════════════════
  # Note: Authorized keys for SSH server should be configured at
  # system level, not in home-manager
  # ═══════════════════════════════════════════════════════════════
}
