#!/usr/bin/env bash
set -e

# Get directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for python3
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required."
    exit 1
fi

# Run the V2 implementation with chain-of-thought reasoning
python3 "$DIR/smart-commit-v2.py" "$@"
