# Package Management Status /* TODO: Deprecated */

This document tracks the status of custom packages managed through the declarative package system in `modules/packages/*`.

## System Architecture Updates (2025-12-10)

The package management system has been refactored to use a shared library approach for better maintainability and code reuse.

### Shared Library (`modules/packages/lib/`)
- **`builders.nix`**: Contains generic `buildFHS` and `buildNative` functions used by `deb`, `tar`, and `js` packages.
- **`sandbox.nix`**: Contains centralized `bubblewrap` sandboxing logic and profiles.

## Package Categories

### 1. JS Packages (`modules/packages/js-packages/`)
Managed via `kernelcore.packages.js.packages.*`

**Status**: ✅ Standardized Schema Implemented

The `js-packages` module now supports a declarative schema compatible with `deb` and `tar` packages, enabling sandboxing and wrapper configuration.

#### gemini-cli
- **Status**: ✅ Configured
- **Location**: [`modules/packages/js-packages/gemini-cli.nix`](js-packages/gemini-cli.nix)
- **Version**: 0.21.0-nightly.20251210.d90356e8a
- **Build Type**: Node.js (`buildNpmPackage`)
- **Note**: Currently uses a custom module definition but can be migrated to the standard `packages` schema in the future.

---

### 2. Tar Packages (`modules/packages/tar-packages/`)
Managed via `kernelcore.packages.tar.packages.*`

**Status**: ✅ Refactored to use Shared Library

#### codex
- **Status**: ✅ Configured
- **Location**: [`modules/packages/tar-packages/packages/codex.nix`](tar-packages/packages/codex.nix)
- **Version**: 0.56.0 (rust-v0.56.0)
- **Build Method**: native (tar extraction + wrapper)

#### lynis
- **Status**: ✅ Ready to use
- **Location**: [`modules/packages/tar-packages/packages/lynis.nix`](tar-packages/packages/lynis.nix)
- **Version**: 3.1.6
- **Build Method**: native (shell script based)

---

### 3. Deb Packages (`modules/packages/deb-packages/`)
Managed via `kernelcore.packages.deb.packages.*`

**Status**: ✅ Refactored to use Shared Library

---

## Package System Architecture

```
modules/packages/
├── default.nix              # Main aggregator
├── lib/                     # Shared libraries (NEW)
│   ├── builders.nix         # Shared build logic (FHS, Native)
│   └── sandbox.nix          # Shared sandbox logic
├── deb-packages/            # .deb package management
│   ├── default.nix
│   ├── builder.nix          # Refactored to use lib
│   └── packages/
├── tar-packages/            # .tar.gz package management
│   ├── default.nix
│   ├── builder.nix          # Refactored to use lib
│   └── packages/
└── js-packages/             # Node.js/npm package management
    ├── default.nix
    ├── js-packages.nix      # Updated with full schema
    └── builder.nix          # New builder using lib
```

---

Last Updated: 2025-12-10
