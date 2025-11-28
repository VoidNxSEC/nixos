{
  description = "SecureLLM Bridge MCP Server - Model Context Protocol for IDE integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        mcpServer = pkgs.buildNpmPackage {
          pname = "securellm-bridge-mcp";
          version = "2.0.0";
          src = ./.;

          # This hash needs to be calculated on first build
          # Run: nix build 2>&1 | grep "got:" to get the correct hash
          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

          nativeBuildInputs = with pkgs; [
            nodejs
            python3 # Needed for better-sqlite3 native compilation
            pkg-config
          ];

          buildInputs = with pkgs; [
            sqlite
          ];

          buildPhase = ''
            export HOME=$TMPDIR
            npm run build
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib/mcp-server

            # Copy build artifacts
            cp -r build $out/lib/mcp-server/
            cp package.json $out/lib/mcp-server/
            cp -r node_modules $out/lib/mcp-server/

            # Copy TypeScript config for reference
            cp tsconfig.json $out/lib/mcp-server/ || true

            # Create executable wrapper
            cat > $out/bin/securellm-mcp <<'EOF'
            #!/usr/bin/env bash
            # SecureLLM Bridge MCP Server
            # Wrapper script for running the MCP server

            # Set default environment variables if not set
            : ''${PROJECT_ROOT:=/etc/nixos}
            : ''${KNOWLEDGE_DB_PATH:=/var/lib/mcp-knowledge/knowledge.db}
            : ''${ENABLE_KNOWLEDGE:=true}

            # Export for MCP server
            export PROJECT_ROOT
            export KNOWLEDGE_DB_PATH
            export ENABLE_KNOWLEDGE

            # Run the MCP server
            exec ${pkgs.nodejs}/bin/node $out/lib/mcp-server/build/src/index.js "$@"
            EOF
            chmod +x $out/bin/securellm-mcp

            # Create development wrapper (uses local build)
            cat > $out/bin/securellm-mcp-dev <<'EOF'
            #!/usr/bin/env bash
            # Development mode - runs from source directory

            DEV_DIR="''${1:-.}"
            if [ ! -f "$DEV_DIR/build/src/index.js" ]; then
              echo "Error: No build found in $DEV_DIR"
              echo "Run: cd $DEV_DIR && npm run build"
              exit 1
            fi

            : ''${PROJECT_ROOT:=$DEV_DIR}
            : ''${KNOWLEDGE_DB_PATH:=/var/lib/mcp-knowledge/knowledge.db}
            : ''${ENABLE_KNOWLEDGE:=true}

            export PROJECT_ROOT
            export KNOWLEDGE_DB_PATH
            export ENABLE_KNOWLEDGE

            exec ${pkgs.nodejs}/bin/node "$DEV_DIR/build/src/index.js"
            EOF
            chmod +x $out/bin/securellm-mcp-dev
          '';

          meta = with pkgs.lib; {
            description = "MCP server for SecureLLM Bridge with knowledge management";
            homepage = "https://github.com/securellm/bridge";
            license = licenses.mit;
            maintainers = [ "kernelcore" ];
            platforms = platforms.unix;
          };
        };

      in
      {
        packages = {
          default = mcpServer;
          mcp = mcpServer;
        };

        apps = {
          default = {
            type = "app";
            program = "${mcpServer}/bin/securellm-mcp";
          };

          mcp = {
            type = "app";
            program = "${mcpServer}/bin/securellm-mcp";
          };

          dev = {
            type = "app";
            program = "${mcpServer}/bin/securellm-mcp-dev";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js development
            nodejs
            nodePackages.typescript
            nodePackages.npm
            nodePackages.ts-node

            # Build dependencies
            python3
            pkg-config
            sqlite

            # MCP tools
            jq # For JSON manipulation

            # Development tools
            git
            ripgrep
            fd
          ];

          shellHook = ''
            echo "🔌 SecureLLM Bridge MCP Server - Development Environment"
            echo "  Node: $(node --version)"
            echo "  TypeScript: $(tsc --version)"
            echo "  npm: $(npm --version)"
            echo ""
            echo "Commands:"
            echo "  npm install             - Install dependencies"
            echo "  npm run build           - Build TypeScript"
            echo "  npm run watch           - Watch mode"
            echo "  npm test                - Run tests"
            echo ""
            echo "  nix build               - Build package"
            echo "  nix run                 - Run MCP server"
            echo "  nix run .#dev           - Run development version"
            echo ""
            echo "Test MCP server:"
            echo "  echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}' | node build/src/index.js"
            echo ""
            echo "Environment:"
            echo "  PROJECT_ROOT: ''${PROJECT_ROOT:-/etc/nixos}"
            echo "  KNOWLEDGE_DB: ''${KNOWLEDGE_DB_PATH:-/var/lib/mcp-knowledge/knowledge.db}"
          '';

          # Development environment variables
          PROJECT_ROOT = builtins.getEnv "PWD";
          KNOWLEDGE_DB_PATH = "/var/lib/mcp-knowledge/knowledge.db";
          ENABLE_KNOWLEDGE = "true";
        };

        checks = {
          build = mcpServer;
        };
      }
    );
}
