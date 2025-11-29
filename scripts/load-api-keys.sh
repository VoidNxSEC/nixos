#!/usr/bin/env bash
# Load decrypted API keys from /run/secrets into environment
# Usage: source /etc/load-api-keys.sh

export ANTHROPIC_API_KEY="$(cat /run/secrets/anthropic_api_key 2>/dev/null || echo "")"
export OPENAI_API_KEY="$(cat /run/secrets/openai_api_key 2>/dev/null || echo "")"
export OPENAI_PROJECT_ID="$(cat /run/secrets/openai_project_id 2>/dev/null || echo "")"
export DEEPSEEK_API_KEY="$(cat /run/secrets/deepseek_api_key 2>/dev/null || echo "")"
export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key 2>/dev/null || echo "")"
export GOOGLE_CLOUD_PROJECT="$(cat /run/secrets/google_cloud_project 2>/dev/null || echo "")"
export GOOGLE_CLOUD_LOCATION="$(cat /run/secrets/google_cloud_location 2>/dev/null || echo "")"
export OPENROUTER_API_KEY="$(cat /run/secrets/openrouter_api_key 2>/dev/null || echo "")"
export REPLICATE_API_TOKEN="$(cat /run/secrets/replicate_api_key 2>/dev/null || echo "")"
export MISTRAL_API_KEY="$(cat /run/secrets/mistral_api_key 2>/dev/null || echo "")"
export GROQ_API_KEY="$(cat /run/secrets/groq_api_key 2>/dev/null || echo "")"
export GROQ_PROJECT_ID="$(cat /run/secrets/groq_project_id 2>/dev/null || echo "")"
export NVIDIA_API_KEY="$(cat /run/secrets/nvidia_api_key 2>/dev/null || echo "")"
export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || echo "")"

echo "✓ API keys loaded into environment"
echo "  - ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:15}..."
echo "  - OPENAI_API_KEY: ${OPENAI_API_KEY:0:15}..."
echo "  - GEMINI_API_KEY: ${GEMINI_API_KEY:0:15}..."
echo "  - GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT}"
echo "  - GROQ_API_KEY: ${GROQ_API_KEY:0:15}..."
echo "  - GITHUB_TOKEN: ${GITHUB_TOKEN:0:10}..."
