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
  # Authorized SSH Keys (if running SSH server)
  # ═══════════════════════════════════════════════════════════════

  users.users.kernelcore.openssh.authorizedKeys.keys = [
    # Existing personal key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB784LcoYl5UoXxJSbFk60gmPo7WGKn/jmK8gePkkUhw sec@voidnxlabs.com"

    # GitLab key (for remote access to this machine via GitLab CI/CD or similar)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyAHCfElZid7pLtp8lk9H5n8MTEpUfvSAVxxE6fFr5V sec@voidnxlabs.com"
  ];
}
