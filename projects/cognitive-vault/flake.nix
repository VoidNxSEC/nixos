{
  description = "CognitiveVault - Hybrid Rust/Go Password Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        vaultCore = pkgs.callPackage ./core/default.nix {};
        cvault = pkgs.callPackage ./cli/default.nix { inherit vaultCore; };
      in
      {
        packages.default = cvault;
        packages.cvault = cvault;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust Toolchain
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" ];
            })
            
            # Go Toolchain
            go
            gopls
            gotools
            go-tools

            # Build Tools
            gcc
            pkg-config
            protobuf
            
            # Libraries often needed
            openssl
            sqlite
          ];

          # Environment variables
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          CGO_ENABLED = "1";
          
          shellHook = ''
            export CGO_CFLAGS="-I$PWD/core/include"
            # Default to debug build for dev shell
            export CGO_LDFLAGS="-L$PWD/core/target/debug -Wl,-rpath,$PWD/core/target/debug"
            echo "CognitiveVault Dev Environment Loaded 🛡️"
          '';
        };
      }
    );
}
