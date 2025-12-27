# Codex CLI
# Version: 0.56.0 (rust-v0.56.0)
# Source: Local storage (musl static binary)
#
# Method: "native" used because codex-x86_64-unknown-linux-musl is a
# statically linked musl binary that doesn't require FHS environment.
# Unlike GNU binaries, musl binaries are self-contained and don't need
# system libraries, making them ideal for direct Nix integration.
{
  codex = {
    enable = true;

    method = "native";

    source = {
      path = ../storage/codex-x86_64-unknown-linux-musl.tar.gz;
      sha256 = "ebbeb9b5fb391fdb6300ea02b8ca9ac70e8681e13e5e6c73ad3766be28e58db1";
    };

    wrapper = {
      executable = "codex-x86_64-unknown-linux-musl";
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
