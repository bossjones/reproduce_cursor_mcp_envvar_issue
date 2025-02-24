#!/usr/bin/env zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
REPO_ROOT="$(cd "$(dirname "${(%):-%N}")" && cd ../.. && pwd)"

# Load and export environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Export all variables from the .env file, excluding comments
    set -a  # Automatically export all variables
    source "$SCRIPT_DIR/.env"
    set +a  # Turn off automatic exports
fi

# Run the uvx command
uvx --directory $REPO_ROOT mcp-server-perplexity
