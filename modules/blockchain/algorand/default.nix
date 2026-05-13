# ============================================
# Algorand Development Environment Module
# ============================================
# Provides AlgoKit SDK, PyTeal, and development tools
# for Algorand smart contract development
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.blockchain.algorand;

  # Python environment with Algorand development tools
  algorandPython = pkgs.python313.withPackages (
    ps: with ps; [
      # Core Algorand SDK
      py-algorand-sdk

      # Smart contract development
      pyteal

      # Testing and utilities
      pytest
      pytest-cov
      black
      mypy

      # Web3 utilities
      pycryptodome
      msgpack
      requests

      # Data handling
      pydantic
      httpx
    ]
  );

in
{
  options.kernelcore.blockchain.algorand = {
    enable = mkEnableOption "Algorand development environment";

    network = mkOption {
      type = types.enum [
        "testnet"
        "mainnet"
        "localnet"
      ];
      default = "testnet";
      description = "Algorand network to connect to";
    };

    enableNode = mkOption {
      type = types.bool;
      default = false;
      description = "Run a local Algorand node (requires significant resources)";
    };

    enableIndexer = mkOption {
      type = types.bool;
      default = false;
      description = "Run a local Algorand indexer (requires enableNode)";
    };

    algoKitVersion = mkOption {
      type = types.str;
      default = "2.3.1";
      description = "AlgoKit CLI version";
    };
  };

  config = mkIf cfg.enable {
    # ============================================
    # DEVELOPMENT PACKAGES
    # ============================================
    environment.systemPackages = with pkgs; [
      # Python environment with Algorand tools
      algorandPython

      # Node.js for AlgoKit and frontend development
      nodejs_24
      nodePackages.npm

      # Docker for local sandbox
      docker
      docker-compose

      # Development utilities
      jq
      curl
      git

      # Editor support
      nodePackages.typescript-language-server
      python313Packages.python-lsp-server
    ];

    # ============================================
    # ALGOKIT CLI WRAPPER
    # ============================================
    environment.etc."algorand/install-algokit.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Install AlgoKit via pipx (user-level installation)

        set -euo pipefail

        echo "=== Algorand Development Environment Setup ==="

        # Check if pipx is available
        if ! command -v pipx &> /dev/null; then
          echo "Installing pipx..."
          pip install --user pipx
          pipx ensurepath
        fi

        # Install AlgoKit
        echo "Installing AlgoKit ${cfg.algoKitVersion}..."
        pipx install algokit==${cfg.algoKitVersion} || pipx upgrade algokit

        # Verify installation
        algokit --version

        echo ""
        echo "=== Setup Complete ==="
        echo "Available commands:"
        echo "  algokit init      - Create new Algorand project"
        echo "  algokit localnet  - Manage local sandbox"
        echo "  algokit compile   - Compile TEAL contracts"
        echo "  algokit deploy    - Deploy to network"
        echo ""
        echo "Network: ${cfg.network}"
      '';
    };

    # ============================================
    # ENVIRONMENT VARIABLES
    # ============================================
    environment.sessionVariables = {
      ALGORAND_NETWORK = cfg.network;
      ALGORAND_DATA = "/var/lib/algorand";

      # API endpoints per network
      ALGOD_SERVER =
        if cfg.network == "mainnet" then
          "https://mainnet-api.algonode.cloud"
        else if cfg.network == "testnet" then
          "https://testnet-api.algonode.cloud"
        else
          "http://localhost:4001";

      INDEXER_SERVER =
        if cfg.network == "mainnet" then
          "https://mainnet-idx.algonode.cloud"
        else if cfg.network == "testnet" then
          "https://testnet-idx.algonode.cloud"
        else
          "http://localhost:8980";
    };

    # ============================================
    # SHELL ALIASES
    # ============================================
    environment.shellAliases = {
      algo-init = "algokit init";
      algo-sandbox = "algokit localnet start";
      algo-stop = "algokit localnet stop";
      algo-status = "algokit localnet status";
      algo-compile = "algokit compile";

      # Quick PyTeal development
      pyteal-shell = "python -c \"from pyteal import *; import code; code.interact(local=locals())\"";
    };

    # ============================================
    # DOCKER (required for AlgoKit sandbox)
    # ============================================
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # ============================================
    # LOCAL NODE (optional)
    # ============================================
    # Note: Full Algorand node requires significant resources
    # Recommended: Use AlgoKit sandbox for development instead
  };
}
