# Codex CLI
# Version: 0.56.0 (rust-v0.56.0)
# Source: https://github.com/openai/codex/releases/tag/rust-v0.56.0
#
# Method: "fhs" required because codex-x86_64-unknown-linux-gnu is a
# dynamically linked GNU binary that expects standard FHS paths.
# Unlike zellij (musl-static), codex needs libc, libgcc_s, and other
# system libraries that are only available in an FHS environment.
{
  codex = {
    enable = true;

    method = "fhs";

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
