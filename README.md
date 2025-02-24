# reproduce_cursor_mcp_envvar_issue

> NOTE: This repo will only focus on `.cursor/mcp-server-shims/mcp-server-perplexity.sh`

Repository to reproduce an issue with loading environment variables in Cursor's Model Context Protocol (MCP) implementation.

## Disclaimer

This repository was created to reproduce an issue encountered while working with Cursor's MCP functionality. The goal is to demonstrate a specific problem where environment variables loaded from a `.env` file through a shell script are not properly passed to MCP servers. This repository contains the minimal setup required to reproduce the issue consistently.

## Introduction

The issue occurs when attempting to set up a secure MCP configuration that doesn't require hardcoding sensitive API keys directly in the `mcp.json` configuration file. When loading environment variables from a `.env` file using a shell script, the variables are not properly passed to the MCP server process, despite working correctly when the script is run directly from the terminal.

## Requirements

- Cursor IDE (latest version)
- Node.js environment with `uvx` command available
- Perplexity API key for testing

```bash
$ cursor --version
# Output should show your Cursor version

$ node --version
# Should be v16+ or later

$ npm list -g uvx
# Should show uvx is installed globally
```

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/bossjones/reproduce_cursor_mcp_envvar_issue.git
cd reproduce_cursor_mcp_envvar_issue
```

### 2. Create a `.env` file in the `.cursor/mcp-server-shims` directory

```bash
mkdir -p .cursor/mcp-server-shims
```

You can either create a new `.env` file:
```bash
touch .cursor/mcp-server-shims/.env
```

Or copy and modify the provided `.env.sample` file:
```bash
cp .cursor/mcp-server-shims/.env.sample .cursor/mcp-server-shims/.env
```

### 3. Add your API keys to the `.env` file

If you created a new `.env` file, add at minimum your Perplexity API key:

```bash
echo "PERPLEXITY_API_KEY=your_api_key_here" > .cursor/mcp-server-shims/.env
```

If you copied `.env.sample`, edit the `.env` file and replace the "REDACTED" values with your actual API keys:

```bash
# Example of what your .env file should look like
PERPLEXITY_API_KEY="your_perplexity_api_key_here"
# ... other optional API keys as needed ...
```

### 4. Create the shell script to load environment variables

Create a file at `.cursor/mcp-server-shims/mcp-server-perplexity.sh` with the following content:

```bash
#!/usr/bin/env zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
REPO_ROOT="$(cd "$(dirname "${(%):-%N}")" && cd ../.. && pwd)"

# Load environment variables from .env file in the same directory as the script
if [ -f "$SCRIPT_DIR/.env" ]; then
  . "$SCRIPT_DIR/.env"
  export PERPLEXITY_API_KEY
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Run the uvx command
uvx mcp-server-perplexity
```

### 5. Make the script executable

```bash
chmod +x .cursor/mcp-server-shims/mcp-server-perplexity.sh
```

### 6. Create the `mcp.json` configuration file

Create a file at `.cursor/mcp.json` with the following content:

```json
{
  "Perplexity": {
    "command": ".cursor/mcp-server-shims/mcp-server-perplexity.sh"
  }
}
```

## How to Reproduce the Issue

### 1. Verify the shell script works directly in the terminal

```bash
cd /path/to/reproduce_cursor_mcp_envvar_issue
.cursor/mcp-server-shims/mcp-server-perplexity.sh
```

The script should run without errors when executed directly from the terminal, correctly loading the environment variables.

### 2. Test using the MCP Inspector

```bash
npx @modelcontextprotocol/inspector .cursor/mcp-server-shims/mcp-server-perplexity.sh
```

You should see an error indicating that the `PERPLEXITY_API_KEY` environment variable is not available to the MCP server, even though it's being exported in the shell script.

### 3. Reproduce the issue in Cursor

1. Open the project in Cursor
2. Try to use the Perplexity MCP function in Cursor
3. Check the Dev Tools console for errors related to missing API keys

## Workarounds

There are two workarounds for this issue:

### Workaround 1: Include Environment Variables in `mcp.json`

Modify `.cursor/mcp.json` to directly include environment variables:

```json
{
  "mcp-server-perplexity.sh": {
    "command": "/absolute/path/to/reproduce_cursor_mcp_envvar_issue/.cursor/mcp-server-shims/mcp-server-perplexity.sh",
    "env": {
      "PERPLEXITY_API_KEY": "your_api_key_here"
    }
  }
}
```

**Important**: This approach requires storing sensitive information in the `mcp.json` file, which is not ideal for security.

### Workaround 2: Pass Directory Parameter and Include Environment Variables

1. Modify the script to include a directory parameter:

```bash
#!/usr/bin/env zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
REPO_ROOT="$(cd "$(dirname "${(%):-%N}")" && cd ../.. && pwd)"

# Load environment variables from .env file in the same directory as the script
if [ -f "$SCRIPT_DIR/.env" ]; then
  . "$SCRIPT_DIR/.env"
  export PERPLEXITY_API_KEY
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Run the uvx command with directory parameter
uvx --directory $REPO_ROOT mcp-server-perplexity
```

2. Still include environment variables in `mcp.json`:

```json
{
  "mcp-server-perplexity.sh": {
    "command": "/absolute/path/to/reproduce_cursor_mcp_envvar_issue/.cursor/mcp-server-shims/mcp-server-perplexity.sh",
    "env": {
      "PERPLEXITY_API_KEY": "your_api_key_here"
    }
  }
}
```

## Additional Testing Notes

### 1. Testing with Different Shell Script Loading Methods

Several approaches to loading environment variables in the shell script were tested, all with the same result:

```bash
# Approach 1: Direct export
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Approach 2: Source and explicit export
if [ -f "$SCRIPT_DIR/.env" ]; then
  . "$SCRIPT_DIR/.env"
  export PERPLEXITY_API_KEY
fi

# Approach 3: Using set -a
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi
```

None of these approaches successfully passed the environment variables to the MCP server when launched via Cursor.

### 2. Important Considerations

- The key name in `mcp.json` needs to match the script file name for proper execution
- Remove any console output in the script (like `echo` statements) as they break the JSON communication channel
- MCP appears to only accept environment variables that are defined directly in the `mcp.json` file
- The MCP server receives a limited set of environment variables by default, as documented in the [MCP debugging documentation](https://modelcontextprotocol.io/docs/tools/debugging#environment-variables)

## Conclusion

This issue makes it difficult to use environment variables securely with Cursor MCP without committing sensitive information to the repository. The current workarounds all involve storing sensitive information in the `mcp.json` file, which is not ideal for security-conscious applications.
