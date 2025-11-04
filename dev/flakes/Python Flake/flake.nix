{
  description = "Ultimate Dev Environment - Python, LLM, Low-Level, Hacking & ML";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Python poetry2nix para gerenciamento avançado
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      poetry2nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ poetry2nix.overlays.default ];
        };

        # Python customizado com todas as libs necessárias
        pythonEnv = pkgs.python311.withPackages (
          ps: with ps; [
            # === CORE ===
            pip
            virtualenv
            setuptools
            wheel

            # === DATA SCIENCE & ML ===
            numpy
            pandas
            scipy
            scikit-learn
            matplotlib
            seaborn
            plotly
            jupyter
            ipython
            notebook

            # === DEEP LEARNING ===
            torch
            torchvision
            torchaudio
            tensorflow
            keras
            jax
            jaxlib

            # === LLM & NLP ===
            transformers
            tokenizers
            datasets
            accelerate
            sentencepiece
            tiktoken
            langchain
            openai
            anthropic

            # === VECTOR DBs & RAG ===
            chromadb
            faiss
            pinecone-client
            weaviate-client

            # === HACKING & SECURITY ===
            pwntools
            pycryptodome
            scapy
            requests
            beautifulsoup4
            scrapy
            selenium

            # === LOW-LEVEL & PERFORMANCE ===
            cython
            numba
            cffi
            pybind11

            # === NETWORKING & ASYNC ===
            aiohttp
            httpx
            asyncio
            websockets

            # === UTILS ===
            rich
            click
            typer
            pydantic
            fastapi
            flask
            pytest
            black
            ruff
            mypy
            pylint
          ]
        );

        # Ferramentas de LLM e AI
        llmTools = with pkgs; [
          ollama
          llama-cpp
          koboldcpp
          # localai  # Se disponível
        ];

        # Ferramentas de low-level development
        lowLevelTools = with pkgs; [
          gcc
          clang
          llvm
          gdb
          lldb
          valgrind
          strace
          ltrace
          radare2
          ghidra
          binutils
          nasm
          yasm
          cmake
          ninja
          meson
          pkg-config
          bear
          ccls
          clang-tools
        ];

        # Ferramentas de hacking e pentesting
        hackingTools = with pkgs; [
          nmap
          masscan
          rustscan
          wireshark
          tcpdump
          burpsuite
          metasploit
          sqlmap
          nikto
          dirb
          gobuster
          ffuf
          hydra
          john
          hashcat
          aircrack-ng
          netcat
          socat
          proxychains
          tor
          exploitdb
          searchsploit
        ];

        # Ferramentas de análise e debugging
        analysisTools = with pkgs; [
          htop
          btop
          iotop
          nethogs
          iftop
          bandwhich
          hyperfine
          perf-tools
          flamegraph
          heaptrack
        ];

        # Ferramentas de desenvolvimento
        devTools = with pkgs; [
          git
          gh
          neovim
          tmux
          fzf
          ripgrep
          fd
          bat
          eza
          zoxide
          starship
          direnv
          jq
          yq
          httpie
          curl
          wget
          docker
          docker-compose
          kubernetes
          kubectl
          k9s
        ];

        # Scripts úteis customizados
        customScripts = pkgs.writeScriptBin "devenv-info" ''
          #!${pkgs.bash}/bin/bash
          echo "🚀 Ultimate Dev Environment"
          echo "=========================="
          echo ""
          echo "📦 Available Commands:"
          echo "  python-ml     - Python ML environment"
          echo "  llm-chat      - Start Ollama for local LLM"
          echo "  hack-recon    - Quick recon toolkit"
          echo "  low-level     - GDB, Radare2, Ghidra shortcuts"
          echo ""
          echo "🐍 Python: $(python --version)"
          echo "🔧 GCC: $(gcc --version | head -n1)"
          echo "🦀 Rust: $(rustc --version 2>/dev/null || echo 'Not in PATH')"
          echo ""
          echo "💡 Tip: Use 'nix develop .#<shell>' for specialized environments"
        '';

        mlScript = pkgs.writeScriptBin "python-ml" ''
          #!${pkgs.bash}/bin/bash
          echo "🤖 Starting ML Python Environment..."
          exec ${pythonEnv}/bin/python "$@"
        '';

        llmScript = pkgs.writeScriptBin "llm-chat" ''
          #!${pkgs.bash}/bin/bash
          echo "🧠 Starting Ollama for local LLM..."
          ${pkgs.ollama}/bin/ollama serve &
          sleep 2
          echo "Ready! Try: ollama run llama2"
          exec ${pkgs.bash}/bin/bash
        '';

      in
      {
        # Shell padrão com tudo
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
          ]
          ++ llmTools
          ++ lowLevelTools
          ++ hackingTools
          ++ analysisTools
          ++ devTools
          ++ [
            customScripts
            mlScript
            llmScript
          ];

          shellHook = ''
            export PYTHONPATH="${pythonEnv}/${pythonEnv.sitePackages}:$PYTHONPATH"
            export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
            export EXTRA_LDFLAGS="-L${pkgs.linuxPackages.nvidia_x11}/lib"
            export EXTRA_CCFLAGS="-I${pkgs.cudaPackages.cudatoolkit}/include"

            # Banner épico
            ${pkgs.figlet}/bin/figlet -f slant "Dev Ultimate" 2>/dev/null || echo "=== DEV ULTIMATE ==="
            ${customScripts}/bin/devenv-info

            # Aliases úteis
            alias py="${pythonEnv}/bin/python"
            alias ipy="${pythonEnv}/bin/ipython"
            alias jup="${pythonEnv}/bin/jupyter"
            alias gdb-pwndbg="gdb -q"
            alias r2="radare2"
            alias ghidra="${pkgs.ghidra}/bin/ghidra"

            # Configurações de segurança para hacking ético
            export HISTFILE=~/.bash_history_dev

            echo ""
            echo "✅ Environment ready! Happy hacking! 🎯"
          '';
        };

        # Shell focado em ML/AI
        devShells.ml = pkgs.mkShell {
          buildInputs = [
            pythonEnv
          ]
          ++ llmTools
          ++ [
            pkgs.tensorboard
            pkgs.graphviz
          ];

          shellHook = ''
            export PYTHONPATH="${pythonEnv}/${pythonEnv.sitePackages}:$PYTHONPATH"
            echo "🤖 ML/AI Environment Activated"
            echo "Available: PyTorch, TensorFlow, JAX, Transformers, LangChain"
          '';
        };

        # Shell focado em hacking
        devShells.hacking = pkgs.mkShell {
          buildInputs = hackingTools ++ [
            pythonEnv
            pkgs.exploitdb
          ];

          shellHook = ''
            echo "🎯 Hacking Environment Activated"
            echo "⚠️  Use apenas para fins éticos e autorizados!"
            echo ""
            echo "Tools: nmap, metasploit, burpsuite, sqlmap, hydra, john, hashcat"

            alias scan="nmap -sV -sC -oN scan.txt"
            alias dirscan="gobuster dir -u"
            alias vulnscan="nikto -h"
          '';
        };

        # Shell focado em low-level
        devShells.lowlevel = pkgs.mkShell {
          buildInputs = lowLevelTools ++ [
            pythonEnv
            pkgs.rust
            pkgs.cargo
          ];

          shellHook = ''
            echo "⚙️  Low-Level Development Environment"
            echo "Tools: GCC, Clang, LLVM, GDB, Radare2, Ghidra, Valgrind"

            alias compile-debug="gcc -g -O0 -Wall -Wextra"
            alias compile-release="gcc -O3 -march=native"
            alias check-mem="valgrind --leak-check=full"
            alias disasm="objdump -d -M intel"
          '';
        };

        # Shell focado em LLM
        devShells.llm = pkgs.mkShell {
          buildInputs = [
            pythonEnv
          ]
          ++ llmTools;

          shellHook = ''
            echo "🧠 LLM Development Environment"
            echo "Starting Ollama service..."

            # Auto-start ollama
            ${pkgs.ollama}/bin/ollama serve > /tmp/ollama.log 2>&1 &

            echo "Tools: Ollama, llama.cpp, Transformers, LangChain"
            echo ""
            echo "Quick start:"
            echo "  ollama pull llama2"
            echo "  ollama run llama2"
          '';
        };

        # App exemplo para build
        packages.default = pkgs.stdenv.mkDerivation {
          name = "dev-ultimate-env";
          src = ./.;
          buildInputs = [ pythonEnv ];

          installPhase = ''
            mkdir -p $out/bin
            echo "Dev environment tools" > $out/README
          '';
        };
      }
    );
}
