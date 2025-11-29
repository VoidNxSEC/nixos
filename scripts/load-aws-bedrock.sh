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
echo "  - AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:0:15}..."
echo "  - AWS_REGION: $AWS_REGION"
echo "  - BEDROCK_MODEL_ID: $BEDROCK_MODEL_ID"
