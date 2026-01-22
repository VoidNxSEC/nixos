# ============================================
# Blockchain/Web3 Module - reads from blockchain.yaml
# ============================================
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.blockchain;
in
{
  options.kernelcore.secrets.blockchain = {
    enable = mkEnableOption "Enable Blockchain/Web3 secrets from SOPS (blockchain.yaml)";
  };

  config = mkIf cfg.enable {
    # Decrypt blockchain secrets from /etc/nixos/secrets/blockchain.yaml
    sops.secrets = {
      # Ethereum wallet private key
      "ethereum/private_key" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0400";  # Read-only for owner
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Ethereum deployer address (not sensitive, but kept with secrets)
      "ethereum/deployer_address" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0444";  # Readable by all
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # RPC endpoints
      "rpc/sepolia_url" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "rpc/mainnet_url" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "rpc/alchemy_key" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0400";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Etherscan API key
      "etherscan/api_key" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # IPFS credentials
      "ipfs/api_url" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0444";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "ipfs/project_id" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      "ipfs/project_secret" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0400";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # Arweave wallet path (not the actual wallet, just the path)
      "arweave/wallet_path" = {
        sopsFile = ../../secrets/blockchain.yaml;
        mode = "0444";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Environment variables for blockchain development
    environment.sessionVariables = {
      BLOCKCHAIN_SECRETS_DIR = "/run/secrets";
    };

    # Create wrapper scripts for foundry with secrets
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "forge-with-secrets" ''
        #!/usr/bin/env bash
        # Load secrets as environment variables
        export PRIVATE_KEY=$(cat /run/secrets/ethereum/private_key)
        export SEPOLIA_RPC_URL=$(cat /run/secrets/rpc/sepolia_url)
        export MAINNET_RPC_URL=$(cat /run/secrets/rpc/mainnet_url)
        export ETHERSCAN_API_KEY=$(cat /run/secrets/etherscan/api_key 2>/dev/null || echo "")

        # Run forge with secrets loaded
        exec ${foundry}/bin/forge "$@"
      '')

      (writeShellScriptBin "cast-with-secrets" ''
        #!/usr/bin/env bash
        # Load secrets as environment variables
        export PRIVATE_KEY=$(cat /run/secrets/ethereum/private_key)
        export SEPOLIA_RPC_URL=$(cat /run/secrets/rpc/sepolia_url)
        export MAINNET_RPC_URL=$(cat /run/secrets/rpc/mainnet_url)

        # Run cast with secrets loaded
        exec ${foundry}/bin/cast "$@"
      '')

      (writeShellScriptBin "blockchain-export-env" ''
        #!/usr/bin/env bash
        # Export blockchain secrets to .env file (use with caution!)

        TARGET_DIR="''${1:-.}"
        ENV_FILE="$TARGET_DIR/.env"

        if [ -f "$ENV_FILE" ]; then
          echo "⚠️  .env already exists at $ENV_FILE"
          read -p "Overwrite? (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
          fi
        fi

        echo "# NEXUS BASTION-SC Deployment Configuration" > "$ENV_FILE"
        echo "# Generated from sops-encrypted secrets" >> "$ENV_FILE"
        echo "# $(date)" >> "$ENV_FILE"
        echo "" >> "$ENV_FILE"

        echo "PRIVATE_KEY=$(cat /run/secrets/ethereum/private_key)" >> "$ENV_FILE"
        echo "SEPOLIA_RPC_URL=$(cat /run/secrets/rpc/sepolia_url)" >> "$ENV_FILE"
        echo "MAINNET_RPC_URL=$(cat /run/secrets/rpc/mainnet_url)" >> "$ENV_FILE"
        echo "ETHERSCAN_API_KEY=$(cat /run/secrets/etherscan/api_key 2>/dev/null || echo "")" >> "$ENV_FILE"
        echo "IPFS_API_URL=$(cat /run/secrets/ipfs/api_url)" >> "$ENV_FILE"
        echo "IPFS_PROJECT_ID=$(cat /run/secrets/ipfs/project_id)" >> "$ENV_FILE"
        echo "IPFS_PROJECT_SECRET=$(cat /run/secrets/ipfs/project_secret)" >> "$ENV_FILE"
        echo "LOCALHOST_RPC_URL=http://localhost:8545" >> "$ENV_FILE"

        chmod 600 "$ENV_FILE"
        echo "✅ Secrets exported to $ENV_FILE"
        echo "⚠️  Remember: NEVER commit .env to git!"
      '')
    ];

    # Non-sensitive deployment info
    environment.etc."blockchain/deployment-info.json" = {
      text = builtins.toJSON {
        network = "sepolia";
        chainId = 11155111;
        contracts = {
          lendingProtocol = "0x35fF603BD286E287f932356316271D59a4ADa779";
        };
        deployed = "2026-01-22";
        etherscan = "https://sepolia.etherscan.io/address/0x35fF603BD286E287f932356316271D59a4ADa779";
      };
      mode = "0644";
    };
  };
}
