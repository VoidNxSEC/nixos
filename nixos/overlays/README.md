# Overlays

This directory contains Nix overlays to customize package behavior.

## Structure

```
overlays/
├── default.nix          # Main entry point - imports all overlays
├── python-packages.nix  # Python package fixes (test failures)
└── README.md           # This file
```

## Usage

Overlays are automatically imported in `flake.nix`:

```nix
overlays = import ./overlays;
```

## Adding New Overlays

1. Create a new `.nix` file in this directory (e.g., `custom-packages.nix`)
2. Add it to `default.nix`:
   ```nix
   [
     (import ./python-packages.nix)
     (import ./custom-packages.nix)  # Your new overlay
   ]
   ```

## Current Overlays

### python-packages.nix

Disables tests for Python packages that have flaky or resource-intensive tests:

- **mercantile**: CLI tests fail with incorrect output
- **wandb**: Tests fail with "can't start new thread" (resource exhaustion)
- **jax**: Tests fail with "can't start new thread" (resource exhaustion)

These packages work correctly at runtime but have issues during Nix build sandbox testing.
