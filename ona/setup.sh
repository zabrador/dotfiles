#!/bin/sh
# Ona-specific installation steps, aggregated here so install.sh stays
# readable.

ona_dir="$(dirname "$0")"

# --- Claude remote ownership watcher ------------------------------------------

echo "Starting Claude-remote ownership watcher..."
sh "$ona_dir/fix-claude-remote-ownership.sh"
echo "...Claude-remote ownership watcher running!"
