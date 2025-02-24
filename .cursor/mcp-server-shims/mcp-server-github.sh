#!/usr/bin/env zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"

# Load environment variables from .env file in the same directory as the script
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

npx -y @modelcontextprotocol/server-github
