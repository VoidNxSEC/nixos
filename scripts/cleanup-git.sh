#!/usr/bin/env bash
set -e

echo "Removing large files from git history..."

# Remove storage directories and build artifacts
git filter-branch --force --index-filter \
  'git rm -rf --cached --ignore-unmatch \
    modules/packages/_archive/tar-packages/storage/ \
    modules/packages/gemini/storage/ \
    modules/ml/orchestration/api-temp/target/ \
    modules/ml/Security-Architect/target/ \
    projects/securellm-mcp/node_modules/ \
    projects/cognitive-vault/core/target/' \
  --prune-empty --tag-name-filter cat -- --all

echo "Cleaning up refs..."
rm -rf .git/refs/original/

echo "Running git gc..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Done! Repository cleaned."
du -sh .git
