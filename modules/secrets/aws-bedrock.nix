{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.secrets.aws-bedrock;
in
{
  options.kernelcore.secrets.aws-bedrock = {
    enable = mkEnableOption "Enable AWS Bedrock credentials from SOPS";
  };

  config = mkIf cfg.enable {
    # Decrypt AWS secrets from encrypted YAML file
    sops.secrets = {
      # AWS Access Key ID
      "aws_access_key_id" = {
        sopsFile = ../../secrets/aws.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # AWS Secret Access Key
      "aws_secret_access_key" = {
        sopsFile = ../../secrets/aws.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };

      # AWS Region
      "aws_region" = {
        sopsFile = ../../secrets/aws.yaml;
        mode = "0440";
        owner = config.users.users.kernelcore.name;
        group = "users";
      };
    };

    # Helper script to load AWS credentials into environment
    environment.etc."load-aws-bedrock.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Load decrypted AWS Bedrock credentials from /run/secrets into environment
        # Usage: source /etc/load-aws-bedrock.sh

        export AWS_ACCESS_KEY_ID="$(cat /run/secrets/aws_access_key_id 2>/dev/null || echo "")"
        export AWS_SECRET_ACCESS_KEY="$(cat /run/secrets/aws_secret_access_key 2>/dev/null || echo "")"
        export AWS_REGION="$(cat /run/secrets/aws_region 2>/dev/null || echo "")"
        export AWS_DEFAULT_REGION="$AWS_REGION"

        # Bedrock specific (hardcoded from secrets/aws.yaml)
        export BEDROCK_MODEL_ID="anthropic.claude-3-sonnet-20240229-v1:0"
        export BEDROCK_ENDPOINT="https://bedrock-runtime.us-east-1.amazonaws.com"

        # Claude Code specific environment variables
        export ANTHROPIC_BEDROCK_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
        export ANTHROPIC_BEDROCK_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
        export ANTHROPIC_BEDROCK_AWS_REGION="$AWS_REGION"

        echo "✓ AWS Bedrock credentials loaded into environment"
        echo "  - AWS_ACCESS_KEY_ID: ''${AWS_ACCESS_KEY_ID:0:15}..."
        echo "  - AWS_REGION: $AWS_REGION"
        echo "  - BEDROCK_MODEL_ID: $BEDROCK_MODEL_ID"
      '';
      mode = "0755";
    };

    # Create AWS credentials file for applications that need it
    environment.etc."aws-credentials" = {
      text = ''
        [default]
        aws_access_key_id = $(cat /run/secrets/aws_access_key_id)
        aws_secret_access_key = $(cat /run/secrets/aws_secret_access_key)
        region = $(cat /run/secrets/aws_region)
      '';
      mode = "0600";
      user = config.users.users.kernelcore.name;
    };

    # Create AWS config file
    environment.etc."aws-config" = {
      text = ''
        [default]
        region = $(cat /run/secrets/aws_region)
        output = json
      '';
      mode = "0644";
      user = config.users.users.kernelcore.name;
    };

    # NOTE: awscli2 package not included due to nixpkgs hash mismatch
    # Install manually if needed: nix-env -iA nixpkgs.awscli2

    # Add to user shell profile
    programs.bash.interactiveShellInit = mkDefault ''
      # AWS Bedrock credentials available via: source /etc/load-aws-bedrock.sh
      # Uncomment to automatically load on shell start:
      # source /etc/load-aws-bedrock.sh 2>/dev/null
    '';
  };
}
