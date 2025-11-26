#!/bin/bash
# Basic usage examples for SecureLLM Bridge

# Set your API key
export SECURELLM_API_KEY="sk-9160578845714c0f88ba9ef0bfefbaa6"

# Simple chat request
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  "Explain quantum computing in simple terms"

# Chat with system prompt
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  --system "You are a helpful coding assistant" \
  "Write a function to calculate fibonacci numbers"

# Custom parameters
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  --max-tokens 2000 \
  --temperature 0.9 \
  "Write a creative short story about AI"

# Check provider health
securellm health deepseek

# List available models
securellm models deepseek

# Get provider information
securellm info deepseek
