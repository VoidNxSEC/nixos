{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "marcosfpina";
      user.email = "sec@voidnxlabs.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
      pull.rebase = false;

      # Security configurations
      user.signingkey = "5606AB430E95F5AD";
      commit.gpgsign = true;

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

      alias = {
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
      };
    };

    lfs.enable = true;
  };
}
