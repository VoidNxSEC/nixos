{
  description = "ML Offload API - Unified ML model orchestration with VRAM monitoring";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true; # For CUDA
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        # Python environment with FastAPI
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          fastapi
          uvicorn
          pydantic
          # Standard library modules are included by default
        ]);

        # Feature flag for GPU support
        enableGpu = true;

        gpuBuildInputs = pkgs.lib.optionals enableGpu (
          if system == "x86_64-linux" then [
            pkgs.cudaPackages.cuda_nvml
          ] else []
        );

        # Rust API server
        rustApi = pkgs.rustPlatform.buildRustPackage {
          pname = "ml-offload-api";
          version = "0.1.0";
          src = ./api;

          cargoLock = {
            lockFile = ./api/Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            rustToolchain
          ];

          buildInputs = with pkgs; [
            openssl
            sqlite
          ] ++ gpuBuildInputs;

          buildPhase = ''
            ${if enableGpu then
              "cargo build --release --features gpu-support"
            else
              "cargo build --release --no-default-features"
            }
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp target/release/ml-offload-api $out/bin/
          '';

          meta = with pkgs.lib; {
            description = "ML model orchestration API server";
            license = licenses.mit;
            maintainers = [ "kernelcore" ];
          };
        };

        # Python scripts wrapper
        pythonScripts = pkgs.stdenv.mkDerivation {
          pname = "ml-offload-python-scripts";
          version = "0.1.0";
          src = ./api;

          buildInputs = [ pythonEnv ];

          installPhase = ''
            mkdir -p $out/bin $out/lib/ml-offload

            # Copy Python scripts
            cp *.py $out/lib/ml-offload/ || true

            # Create wrapper for main API script
            if [ -f ml-offload-api.py ]; then
              cat > $out/bin/ml-offload-api-python <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pythonEnv}/bin/python $out/lib/ml-offload/ml-offload-api.py "\$@"
            EOF
              chmod +x $out/bin/ml-offload-api-python
            fi

            # Create wrapper for registry script
            if [ -f registry.py ]; then
              cat > $out/bin/ml-offload-registry <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pythonEnv}/bin/python $out/lib/ml-offload/registry.py "\$@"
            EOF
              chmod +x $out/bin/ml-offload-registry
            fi

            # Create wrapper for VRAM monitor
            if [ -f vram_monitor.py ]; then
              cat > $out/bin/ml-offload-vram-monitor <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pythonEnv}/bin/python $out/lib/ml-offload/vram_monitor.py "\$@"
            EOF
              chmod +x $out/bin/ml-offload-vram-monitor
            fi
          '';
        };

        # Combined package (Rust + Python)
        mlOffloadAll = pkgs.symlinkJoin {
          name = "ml-offload-all";
          paths = [ rustApi pythonScripts ];
        };

      in {
        packages = {
          default = mlOffloadAll;
          rust = rustApi;
          python = pythonScripts;
          all = mlOffloadAll;
        };

        apps = {
          default = {
            type = "app";
            program = "${rustApi}/bin/ml-offload-api";
          };

          rust-api = {
            type = "app";
            program = "${rustApi}/bin/ml-offload-api";
          };

          python-api = {
            type = "app";
            program = "${pythonScripts}/bin/ml-offload-api-python";
          };

          registry = {
            type = "app";
            program = "${pythonScripts}/bin/ml-offload-registry";
          };

          vram-monitor = {
            type = "app";
            program = "${pythonScripts}/bin/ml-offload-vram-monitor";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain
            rustToolchain
            cargo-watch
            cargo-edit

            # Python environment
            pythonEnv
            python3Packages.pip
            python3Packages.ipython

            # Build dependencies
            pkg-config
            openssl
            sqlite

            # GPU support
          ] ++ gpuBuildInputs ++ [

            # Development tools
            git
            ripgrep
            fd
            jq
            curl
          ];

          shellHook = ''
            echo "🚀 ML Offload API Development Environment"
            echo "  Rust: $(rustc --version)"
            echo "  Python: $(python --version)"
            echo "  GPU Support: ${if enableGpu then "✅ Enabled" else "❌ Disabled"}"
            echo ""
            echo "Commands:"
            echo "  Rust API:"
            echo "    cargo build --release         - Build Rust API"
            echo "    cargo run                     - Run Rust API server"
            echo ""
            echo "  Python Scripts:"
            echo "    python api/ml-offload-api.py  - Run Python API"
            echo "    python api/vram_monitor.py    - Run VRAM monitor"
            echo ""
            echo "  Nix builds:"
            echo "    nix build .#rust              - Build Rust API"
            echo "    nix build .#python            - Build Python scripts"
            echo "    nix build .#all               - Build both"
            ${if enableGpu then ''
              echo ""
              echo "GPU Info:"
              nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "  nvidia-smi not available"
            '' else ""}
          '';

          # Environment variables for development
          ML_OFFLOAD_DATA_DIR = "./data";
          ML_OFFLOAD_MODELS_PATH = "./models";
          ML_OFFLOAD_LOG_DIR = "./logs";
        };

        checks = {
          rust-build = rustApi;
          python-build = pythonScripts;
        };
      }
    );
}
