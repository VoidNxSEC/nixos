# Codex CLI
# Version: 0.56.0 (rust-v0.56.0)
# Source: https://github.com/openai/codex/releases/tag/rust-v0.56.0
{
  codex = {
    enable = true;

    method = "native";

    source = {
      url = "https://github.com/openai/codex/releases/download/rust-v0.56.0/codex-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "3aafd4ea76f3d72c15877ae372da072377c58477547606b05228abc6b8bb1114";
    };

    wrapper = {
      executable = "codex-x86_64-unknown-linux-gnu";
      environmentVariables = { };
    };

    sandbox = {
      enable = false;
    };

    audit = {
      enable = false;
    };

    desktopEntry = null;
  };
}
