# Package Sources

This directory contains generated sources for packages managed by `nvfetcher`.

## How to update

Run the update script from the project root:

```bash
./scripts/update-packages.sh
```

## How to add a new package

1. Edit `modules/packages/nvfetcher.toml` and add your package configuration.
   Example:
   ```toml
   [zellij]
   src.github = "zellij-org/zellij"
   fetch.url = "https://github.com/zellij-org/zellij/releases/download/$ver/zellij-x86_64-unknown-linux-musl.tar.gz"
   ```

2. Run `./scripts/update-packages.sh` to generate the new source definitions.

3. Import the generated sources in your package file:
   ```nix
   { pkgs, ... }:
   let
     sources = pkgs.callPackage ../../_sources/generated.nix { };
   in
   {
     kernelcore.packages.tar.packages.mypackage = {
       source.path = sources.mypackage.src;
       # ...
     };
   }
   ```
