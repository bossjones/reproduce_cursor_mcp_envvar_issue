.PHONY: help
help:
	@uv run python -c "import re; \
	[[print(f'\033[36m{m[0]:<20}\033[0m {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(makefile).read(), re.M)] for makefile in ('$(MAKEFILE_LIST)').strip().split()]"

.PHONY: start-mcp-perplexity
start-mcp-perplexity: ## Start Perplexity MCP server
	@.cursor/mcp-server-shims/mcp-server-perplexity.sh

.PHONY: start-mcp-servers
start-mcp-servers: start-mcp-perplexity ## Start all MCP servers (Perplexity)
	@echo "✅ All MCP servers started in background"

.DEFAULT_GOAL := help
