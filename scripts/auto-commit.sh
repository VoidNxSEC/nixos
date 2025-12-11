#!/usr/bin/env bash
set -e

# Configuration
API_URL="http://127.0.0.1:11434/v1/chat/completions"
MODEL_NAME="qwen2.5-coder:7b-instruct"

# Check dependencies
if ! command -v jq &> /dev/null;
then
    echo "Error: jq is required but not installed."
    exit 1
fi

if ! command -v curl &> /dev/null;
then
    echo "Error: curl is required but not installed."
    exit 1
fi

# Check if inside git repo
if ! git rev-parse --is-inside-work-tree &> /dev/null;
then
    echo "Error: Not inside a git repository."
    exit 1
fi

# Stage all changes
echo "Staging all changes..."
git add -A

# Check if there are staged changes
if git diff --cached --quiet;
then
    echo "No changes to commit."
    exit 0
fi

# Get diff (limit size to avoid context overflow)
DIFF_CONTENT=$(git diff --cached | head -c 8000)

SYSTEM_PROMPT="You are a helpful assistant that writes semantic git commit messages."
USER_PROMPT_TEXT="You are a senior software engineer. Write a concise, conventional git commit message (max 72 chars title, blank line, then body) that accurately describes the changes shown below. Include a short “Why” explanation if the diff is non-trivial. Keep the tone professional and avoid jargon. Use the Conventional Commits format when applicable."

# Construct JSON payload using jq for safe escaping
PAYLOAD=$(jq -n \
                  --arg model "$MODEL_NAME" \
                  --arg system_content "$SYSTEM_PROMPT" \
                  --arg user_text "$USER_PROMPT_TEXT" \
                  --arg diff "$DIFF_CONTENT" \
                  '{
                    model: $model,
                    messages: [
                      { role: "system", content: $system_content },
                      { role: "user", content: ($user_text + "\n\nDiff:\n" + $diff) }
                    ],
                    temperature: 0.2,
                    max_tokens: 1000
                  }')

echo "Generating commit message..."
RESPONSE=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d "$PAYLOAD")

# Extract message
COMMIT_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed 's/^"//;s/"$//')

if [ -z "$COMMIT_MSG" ] || [ "$COMMIT_MSG" == "null" ];
then
    echo "Error: Failed to generate commit message."
    echo "Response: $RESPONSE"
    exit 1
fi

echo "Commit Message: $COMMIT_MSG"

# Commit
git commit -m "$COMMIT_MSG"
echo "Committed successfully."
