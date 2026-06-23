#!/usr/bin/env bash
# Launcher referenced by .mcp.json. Execs the built gitnexus MCP (stdio) server.
# gitnexus is installed from source by /destrier-setup into $DESTRIER_HOME/vendor.
set -uo pipefail
DESTRIER_HOME="${DESTRIER_HOME:-$HOME/.destrier}"
GN_DIR="${DESTRIER_GITNEXUS_DIR:-$DESTRIER_HOME/vendor/gitnexus}"
ENTRY="$GN_DIR/dist/cli/index.js"

if [ ! -f "$ENTRY" ]; then
  echo "gitnexus is not installed at $GN_DIR. Run /destrier-setup first." >&2
  exit 1
fi

# `gitnexus mcp` starts the stdio MCP server (serves all indexed repos).
MCP_SUBCMD="${DESTRIER_GITNEXUS_MCP_SUBCMD:-mcp}"
exec node "$ENTRY" "$MCP_SUBCMD"
