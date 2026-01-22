{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Import sops secrets for blockchain/web3
  sops.secrets = {
    # Ethereum wallet private key
    "ethereum/private_key" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400"; # Read-only for owner
    };

    # RPC endpoints
    "rpc/sepolia_url" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };

    "rpc/mainnet_url" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };

    "rpc/alchemy_key" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };

    # Etherscan API key (currently empty, but ready for future use)
    "etherscan/api_key" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };

    # IPFS credentials
    "ipfs/project_id" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };

    "ipfs/project_secret" = {
      sopsFile = /etc/nixos/secrets/blockchain.yaml;
      owner = config.users.users.kernelcore.name;
      group = config.users.users.kernelcore.group;
      mode = "0400";
    };
  };

  # Environment variables for blockchain development
  # These will be available in the user's shell
  environment.sessionVariables = {
    # Point to sops-managed secrets
    BLOCKCHAIN_SECRETS_DIR = "/run/secrets";
  };

  # Create wrapper script for foundry that loads secrets
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "forge-with-secrets" ''
      # Load secrets as environment variables
      export PRIVATE_KEY=$(cat /run/secrets/ethereum/private_key)
      export SEPOLIA_RPC_URL=$(cat /run/secrets/rpc/sepolia_url)
      export MAINNET_RPC_URL=$(cat /run/secrets/rpc/mainnet_url)
      export ETHERSCAN_API_KEY=$(cat /run/secrets/etherscan/api_key 2>/dev/null || echo "")

      # Run forge with secrets loaded
      exec ${pkgs.foundry}/bin/forge "$@"
    '')

    (pkgs.writeShellScriptBin "cast-with-secrets" ''
      # Load secrets as environment variables
      export PRIVATE_KEY=$(cat /run/secrets/ethereum/private_key)
      export SEPOLIA_RPC_URL=$(cat /run/secrets/rpc/sepolia_url)
      export MAINNET_RPC_URL=$(cat /run/secrets/rpc/mainnet_url)

      # Run cast with secrets loaded
      exec ${pkgs.foundry}/bin/cast "$@"
    '')

    # Script to safely export secrets to .env for development
    (pkgs.writeShellScriptBin "blockchain-export-env" ''
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
      echo "IPFS_PROJECT_ID=$(cat /run/secrets/ipfs/project_id)" >> "$ENV_FILE"
      echo "IPFS_PROJECT_SECRET=$(cat /run/secrets/ipfs/project_secret)" >> "$ENV_FILE"

      chmod 600 "$ENV_FILE"
      echo "✅ Secrets exported to $ENV_FILE"
      echo "⚠️  Remember to add .env to .gitignore!"
    '')
  ];

  # Note for deployment info (not sensitive)
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
}
