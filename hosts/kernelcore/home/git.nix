{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # ═══════════════════════════════════════════════════════════
    # Default Configuration (GitHub)
    # ═══════════════════════════════════════════════════════════
    userName = "marcosfpina";
    userEmail = "sec@voidnxlabs.com";

    # Default GPG key (GitHub)
    signing = {
      key = "5606AB430E95F5AD"; # marcos (gh) <sec@voidnxlabs.com>
      signByDefault = true;
    };

    # ═══════════════════════════════════════════════════════════
    # General Configuration
    # ═══════════════════════════════════════════════════════════
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      pull.rebase = false;

      # Security configurations
      commit.gpgsign = true;
      tag.gpgsign = true;

      # Performance optimizations
      core.preloadindex = true;
      core.fscache = true;
      gc.auto = 256;

      # Better diffs
      diff.algorithm = "histogram";

      # Colorful output
      color.ui = true;

      # Hooks configuration
      core.hooksPath = ".githooks";

      # URL rewrites
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      url."git@github.com:".insteadOf = "https://github.com/";

      # Push configuration
      push.autoSetupRemote = true;
      push.default = "current";
    };

    # ═══════════════════════════════════════════════════════════
    # Aliases
    # ═══════════════════════════════════════════════════════════
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      df = "diff";
      lg = "log --oneline --graph --decorate --all";
      lol = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      amend = "commit --amend --no-edit";
      undo = "reset --soft HEAD^";

      # Show which key is being used
      show-key = "!git config user.signingkey";
    };

    # ═══════════════════════════════════════════════════════════
    # Conditional Includes (por diretório/repositório)
    # ═══════════════════════════════════════════════════════════
    includes = [
      # GitLab repos - use different GPG key
      {
        condition = "gitdir:~/gitlab/";
        contents = {
          user = {
            email = "sec@voidnx.com";
            signingkey = "AE2BED94191C531A"; # Marcos (Hey there !) <sec@voidnx.com>
          };
        };
      }
      {
        condition = "gitdir:~/projects/gitlab/";
        contents = {
          user = {
            email = "sec@voidnx.com";
            signingkey = "AE2BED94191C531A";
          };
        };
      }
      {
        condition = "gitdir:~/work/";
        contents = {
          user = {
            email = "sec@voidnx.com";
            signingkey = "AE2BED94191C531A";
          };
        };
      }
      # Add more conditional includes as needed
    ];

    lfs.enable = true;
  };
}
