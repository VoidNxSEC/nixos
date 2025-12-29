{ ... }:

# ============================================================
# Packages Module - Isolated Per-Package Architecture
# ============================================================
# Each package is 100% self-contained in its own folder.
# No shared libraries, no cross-package dependencies.
# Easy debugging: problems are isolated to single folders.
# ============================================================

{
  imports = [
    # Templates (not imported, just for reference)
    # ./_templates/tar-package
    # ./_templates/deb-package
    # ./_templates/npm-package

    # Active packages - each is completely self-contained
    ./zellij
    ./gemini
    ./claude
    ./lynis
    ./hyprland
    ./appflowy
  ];
}
