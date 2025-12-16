# Packages Module - Isolated Per-Package Architecture

Templates and maintained packages for external software not in nixpkgs.

## Structure

```
packages/
├── _templates/              # Templates for new packages
│   ├── tar-package/
│   ├── deb-package/
│   └── npm-package/
├── zellij/                  # Each package is 100% self-contained
├── protonpass/
├── gemini-cli/
└── ...
```

## Creating a New Package

```bash
# 1. Copy the appropriate template
cp -r _templates/tar-package mypackage

# 2. Edit default.nix with your package details
$EDITOR mypackage/default.nix

# 3. Add source file (if local)
cp ~/Downloads/mypackage.tar.gz mypackage/

# 4. The package is auto-imported via default.nix
```

## Design Principles

- **100% Isolation**: Each package contains all its build logic
- **Self-Contained**: No shared libs, no cross-package dependencies
- **Easy Debugging**: Problems are isolated to single folders
- **Copy-Paste Safe**: Clone a template without breaking anything
