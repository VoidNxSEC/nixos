{ ... }:

# ═══════════════════════════════════════════════════════════
# DESENVOLVIMENTO — toolchains, jupyter, CI/CD, tools, shell helpers
# ═══════════════════════════════════════════════════════════

{
  kernelcore.development = {
    rust.enable = true;
    go.enable = true;
    python.enable = true;
    nodejs.enable = true;
    nix.enable = true;
    lua.enable = true;
    editor.enable = true;
    jupyter = {
      enable = true;
      kernels = {
        python.enable = true;
        rust.enable = true;
        nodejs.enable = true;
        nix.enable = true;
      };
      extensions.enable = true;
    };

    cicd = {
      enable = true;
      platforms = {
        github = true;
        gitlab = false;
        gitea = false;
      };
      pre-commit = {
        enable = true;
        formatCode = false;
        runTests = false;
        flakeCheckOnPush = false;
        autoCommit = true;
      };
    };
  };

  kernelcore.tools = {
    enable = true;
    intel.enable = true;
    secops.enable = true;
    nix-utils.enable = true;
    dev.enable = true;
    secrets.enable = true;
    diagnostics.enable = true;
    llm.enable = true;
    mcp.enable = true;
    arch-analyzer.enable = true;
  };

  kernelcore.debug.swissknife.enable = true;

  # ── Shell helpers ──
  kernelcore.shell = {
    serviceControl.enable = true; # GPU/ML service control & RAM optimization
    llamaSwapControl.enable = true; # LlamaSwap hot model reloading control
    config-audit.enable = true; # kernelcore.* cross-reference auditor + aliases
    nix-ops.enable = true;
    cli-helpers = {
      enable = true;
      flakePath = "/etc/nixos";
      hostName = "kernelcore";
    };
    # Training session logger
    trainingLogger = {
      enable = false;
      userLogDirectory = "\${HOME}/.training-logs";
      maxLogSize = "1G";
    };
  };

  environment.shellInit = ''
    export PATH="$HOME/.local/bin:$PATH"
    if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
      source ~/.nix-profile/etc/profile.d/nix.sh
    fi
  '';
}
