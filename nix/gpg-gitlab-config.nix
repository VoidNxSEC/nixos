# GPG Configuration for Git Commit Signing (GitLab)
# This module configures GPG for signing commits and tags
#
# Usage:
#   1. Copy this file to your NixOS configuration directory
#   2. Import in your configuration.nix or home-manager config
#   3. Rebuild: sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ═══════════════════════════════════════════════════════════════
  # GPG Configuration
  # ═══════════════════════════════════════════════════════════════

  programs.gpg = {
    enable = true;
    settings = {
      # Use GPG agent
      use-agent = true;

      # Default key for signing (NEW key)
      default-key = "EC57E3FB66D01693"; # voidnx (hey dog) <sec@voidnx.com>

      # Key server configuration
      keyserver = "hkps://keys.openpgp.org";

      # Additional settings for better UX
      no-greeting = true;
      no-permission-warning = true;

      # Stronger algorithms
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # GPG Agent Configuration
  # ═══════════════════════════════════════════════════════════════

  programs.gpg.agent = {
    enable = true;
    enableSSHSupport = true;

    # Cache settings (24 hours)
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;

    # Pinentry program (choose one based on your environment)
    pinentryPackage = pkgs.pinentry-gnome3; # For GNOME/GTK
    # pinentryPackage = pkgs.pinentry-qt;    # For KDE/Qt
    # pinentryPackage = pkgs.pinentry-curses; # For terminal only
  };

  # ═══════════════════════════════════════════════════════════════
  # Git Configuration for GPG Signing
  # ═══════════════════════════════════════════════════════════════

  programs.git = {
    enable = true;

    # User identity
    userName = "marcosfpina";
    userEmail = "sec@voidnx.com";

    # GPG signing configuration
    signing = {
      key = "EC57E3FB66D01693"; # NEW GPG key
      signByDefault = true; # Sign all commits automatically
    };

    extraConfig = {
      # GPG program
      gpg.program = "${pkgs.gnupg}/bin/gpg";

      # Commit settings
      commit.gpgsign = true;
      tag.gpgsign = true;

      # GitLab-specific settings
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";

      # Push configuration
      push.autoSetupRemote = true;
      push.default = "current";

      # Pull strategy
      pull.rebase = true;

      # Modern Git features
      init.defaultBranch = "main";
      core.editor = "vim";

      # Performance
      core.preloadindex = true;
      core.fscache = true;

      # Color output
      color.ui = "auto";
    };

    # Git aliases for productivity
    aliases = {
      st = "status -sb";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      last = "log -1 HEAD";
      unstage = "reset HEAD --";

      # GitLab-specific aliases
      mr = "!sh -c 'git push -o merge_request.create -o merge_request.target=$1' -";
      wip = "!git commit -m 'WIP' --no-verify";
    };
  };

  # ═══════════════════════════════════════════════════════════════
  # Environment Variables
  # ═══════════════════════════════════════════════════════════════

  environment.sessionVariables = {
    GPG_TTY = "$(tty)";
  };

  # ═══════════════════════════════════════════════════════════════
  # Required Packages
  # ═══════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-gnome3 # or pinentry-qt, pinentry-curses
    git
    openssh
  ];
}
