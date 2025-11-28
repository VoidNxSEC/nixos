{
  description = "SecureLLM Bridge - Unified LLM API with Security & MCP Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        };

        # Rust workspace build
        rustPackage = pkgs.rustPlatform.buildRustPackage {
          pname = "securellm-bridge";
          version = "0.1.0";
          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            rustToolchain
          ];

          buildInputs = with pkgs; [
            openssl
            sqlite
          ];

          # Build all workspace members
          buildPhase = ''
            cargo build --release --workspace
          '';

          installPhase = ''
            mkdir -p $out/bin

            # Install binaries from all crates
            for bin in target/release/securellm*; do
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                cp "$bin" $out/bin/
              fi
            done

            # Install CLI if exists
            if [ -f target/release/cli ]; then
              cp target/release/cli $out/bin/securellm-cli
            fi
          '';

          meta = with pkgs.lib; {
            description = "Secure LLM API proxy with enterprise-grade security";
            homepage = "https://github.com/securellm/bridge";
            license = with licenses; [
              mit
              asl20
            ];
            maintainers = [ "kernelcore" ];
          };
        };

        # MCP Server (TypeScript/Node.js)
        mcpServer = pkgs.buildNpmPackage {
          pname = "securellm-bridge-mcp";
          version = "2.0.0";
          src = ./mcp-server;

          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated on first build

          nativeBuildInputs = with pkgs; [
            nodejs
            python3
            pkg-config
          ];

          buildInputs = with pkgs; [
            sqlite
          ];

          buildPhase = ''
            npm run build
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib/mcp-server

            # Copy build output
            cp -r build $out/lib/mcp-server/
            cp package.json $out/lib/mcp-server/
            cp -r node_modules $out/lib/mcp-server/

            # Create executable wrapper
            cat > $out/bin/securellm-mcp <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.nodejs}/bin/node $out/lib/mcp-server/build/src/index.js "\$@"
            EOF
            chmod +x $out/bin/securellm-mcp
          '';

          meta = with pkgs.lib; {
            description = "MCP server for SecureLLM Bridge IDE integration";
            license = licenses.mit;
            maintainers = [ "kernelcore" ];
          };
        };

      in
      {
        packages = {
          default = rustPackage;
          rust = rustPackage;
          mcp = mcpServer;

          # Combined package with both Rust and MCP
          all = pkgs.symlinkJoin {
            name = "securellm-bridge-all";
            paths = [
              rustPackage
              mcpServer
            ];
          };
        };

        apps = {
          default = {
            type = "app";
            program = "${rustPackage}/bin/securellm-cli";
          };

          mcp = {
            type = "app";
            program = "${mcpServer}/bin/securellm-mcp";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain
            rustToolchain
            cargo-watch
            cargo-edit

            # Node.js for MCP server
            nodejs
            nodePackages.typescript
            nodePackages.npm

            # Build dependencies
            pkg-config
            openssl
            sqlite

            # Development tools
            git
            ripgrep
            fd
          ];

          shellHook = ''
            echo "🦀 SecureLLM Bridge Development Environment"
            echo "  Rust: $(rustc --version)"
            echo "  Node: $(node --version)"
            echo ""
            echo "Commands:"
            echo "  cargo build         - Build Rust workspace"
            echo "  cargo test          - Run Rust tests"
            echo "  cd mcp-server && npm run build  - Build MCP server"
            echo "  nix build .#rust    - Build Rust package"
            echo "  nix build .#mcp     - Build MCP server"
            echo "  nix build .#all     - Build both"
          '';
        };

        # Checks for CI/CD
        checks = {
          rust-build = rustPackage;
          mcp-build = mcpServer;
        };
      }
    );
}
