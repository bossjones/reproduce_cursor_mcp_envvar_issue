# reproduce_cursor_mcp_envvar_issue

> NOTE: This repo focuses on demonstrating the issue with environment variable loading in Cursor's Model Context Protocol (MCP) implementation, particularly with `.cursor/mcp-server-shims/mcp-server-perplexity.sh`.

Repository to reproduce an issue with loading environment variables in Cursor's Model Context Protocol (MCP) implementation.

## Disclaimer

This repository was created to reproduce an issue encountered while working with Cursor's MCP functionality. The goal is to demonstrate a specific problem where environment variables loaded from a `.env` file through a shell script are not properly passed to MCP servers. This repository contains the minimal setup required to reproduce the issue consistently.

## Introduction

The issue occurs when attempting to set up a secure MCP configuration that doesn't require hardcoding sensitive API keys directly in the `mcp.json` configuration file. When loading environment variables from a `.env` file using a shell script, the variables are not properly passed to the MCP server process, despite working correctly when the script is run directly from the terminal.

## Repository Structure

```
.
├── README.md               # This documentation file
├── Makefile                # Contains commands to help test and reproduce the issue
├── .cursor/                # Cursor IDE configuration directory
│   ├── mcp.json            # Current MCP configuration (may not work with env vars)
│   ├── mcp-broken.json     # Example of broken configuration (for reference)
│   ├── mcp-working.json    # Example of working configuration (with env vars hardcoded)
│   └── mcp-server-shims/   # Directory containing shell scripts for MCP servers
│       ├── mcp-server-perplexity.sh  # Main script demonstrating the issue
│       ├── mcp-server-github.sh      # GitHub MCP server script
│       ├── mcp-server-brave-search.sh # Brave Search MCP server script
│       ├── mcp-server-firecrawl.sh   # Firecrawl MCP server script
│       ├── .env                      # Your actual environment variables (gitignored)
│       └── .env.sample               # Template for environment variables
└── .gitignore              # Standard gitignore file
```

## Requirements

- Cursor IDE (latest version)
- Node.js environment with `uv`/`uvx` command available
- Perplexity API key for testing

```bash
$ cursor --version
# Output should show your Cursor version

$ node --version
# Should be v16+ or later

$ uv --version
# Should show uv is installed globally

$ which uvx
# Should show path to uvx command
```

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/bossjones/reproduce_cursor_mcp_envvar_issue.git
cd reproduce_cursor_mcp_envvar_issue
```

### 2. Create a `.env` file in the `.cursor/mcp-server-shims` directory

The repository already contains a `.cursor/mcp-server-shims` directory with:
- `.env.sample` file showing expected environment variables
- Shell scripts for various MCP servers including `mcp-server-perplexity.sh`

You'll need to create or modify the `.env` file to include your API keys:

```bash
cp .cursor/mcp-server-shims/.env.sample .cursor/mcp-server-shims/.env
```

### 3. Add your API keys to the `.env` file

Edit the `.env` file and replace the "REDACTED" values with your actual API keys:

```bash
# Example of what your .env file should look like
PERPLEXITY_API_KEY="your_perplexity_api_key_here"
# ... other optional API keys as needed ...
```

### 4. Review the shell script used to load environment variables

The repository includes a shell script at `.cursor/mcp-server-shims/mcp-server-perplexity.sh` with the following content:

```bash
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
```

### 5. Make sure the script is executable

```bash
chmod +x .cursor/mcp-server-shims/mcp-server-perplexity.sh
```

### 6. Review the MCP configuration

The repository includes three MCP configuration files:
- `.cursor/mcp.json` - Current configuration
- `.cursor/mcp-broken.json` - Example of a configuration that doesn't work
- `.cursor/mcp-working.json` - Example of a configuration that works (with env vars in the config)

## How to Reproduce the Issue

### 1. Test the shell script directly

Run the following to verify the shell script works when executed directly:

```bash
make start-mcp-perplexity
```

Or directly with:

```bash
.cursor/mcp-server-shims/mcp-server-perplexity.sh
```

This should run without errors, correctly loading the environment variables.

### 2. Test using the MCP Inspector

```bash
npx @modelcontextprotocol/inspector .cursor/mcp-server-shims/mcp-server-perplexity.sh
```

You'll likely see an error indicating that the `PERPLEXITY_API_KEY` environment variable is not available to the MCP server, even though it's being exported in the shell script.

### 3. Reproduce the issue in Cursor

1. Open the project in Cursor
2. Try to use the Perplexity MCP function in Cursor
3. Check the Dev Tools console for errors related to missing API keys

## Differences Between Working and Broken Configurations

The key difference between the working and broken configurations:

### Broken Configuration (mcp-broken.json)
```json
{
  "Perplexity": {
    "command": ".cursor/mcp-server-shims/mcp-server-perplexity.sh"
  }
}
```

### Working Configuration (mcp-working.json)
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

The working configuration includes:
1. The server name matching the script filename (`mcp-server-perplexity.sh`)
2. An absolute path to the script
3. Explicitly defining environment variables in the config

## Workarounds

There are two main workarounds for this issue:

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

1. Modify the script to include a directory parameter (already implemented in the provided script):

```bash
#!/usr/bin/env zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
REPO_ROOT="$(cd "$(dirname "${(%):-%N}")" && cd ../.. && pwd)"

# Load environment variables from .env file in the same directory as the script
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
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

## Testing Resources

The repository includes a Makefile with helpful commands:

```bash
# Show available commands
make help

# Start the Perplexity MCP server directly (useful for testing)
make start-mcp-perplexity
```

## Additional Testing Notes

### 1. Different Shell Script Loading Methods Tested

The repository includes implementation of the following approaches for loading environment variables, all with the same result:

```bash
# Approach 1: Set -a method (used in current script)
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

# Approach 2: Direct export
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Approach 3: Source and explicit export
if [ -f "$SCRIPT_DIR/.env" ]; then
  . "$SCRIPT_DIR/.env"
  export PERPLEXITY_API_KEY
fi
```

None of these approaches successfully passed the environment variables to the MCP server when launched via Cursor.

### 2. Important Considerations

- The key name in `mcp.json` needs to match the script file name for proper execution
- Remove any console output in the script (like `echo` statements) as they break the JSON communication channel
- MCP appears to only accept environment variables that are defined directly in the `mcp.json` file
- The MCP server receives a limited set of environment variables by default, as documented in the [MCP debugging documentation](https://modelcontextprotocol.io/docs/tools/debugging#environment-variables)

## Conclusion

This issue makes it difficult to use environment variables securely with Cursor MCP without committing sensitive information to the repository. The current workarounds all involve storing sensitive information in the `mcp.json` file, which is not ideal for security-conscious applications. We hope this repository helps demonstrate the issue and contributes to its resolution in future Cursor updates.
