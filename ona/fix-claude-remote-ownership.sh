#!/bin/sh
# Ona-only: Ona's Claude integration writes files into ~vscode/.claude/remote
# as root, leaving them unreadable for the vscode user. Start a background
# watcher that hands ownership back as files appear.
#
# Idempotent: called from install.sh (instance creation) and .zshrc (instance
# resume); at most one watcher runs per instance.

# Only on Ona hosts
[ "$IS_ON_ONA" = "true" ] || exit 0

vscode_home="$(getent passwd vscode 2>/dev/null | cut -d: -f6)"
[ -n "$vscode_home" ] || exit 0
watch_dir="$vscode_home/.claude"

if ! command -v inotifywait > /dev/null 2>&1; then
  # -n: never prompt for a password; a shell must not hang on startup
  sudo -n apt-get install -y inotify-tools > /dev/null 2>&1
  command -v inotifywait > /dev/null 2>&1 || exit 0
fi

# Already watching? Then this instance is covered.
pgrep -f "inotifywait -mrq .*\.claude" > /dev/null 2>&1 && exit 0

# inotifywait -r fails if the directory doesn't exist yet
mkdir -p "$watch_dir" 2> /dev/null
sudo -n chown vscode:vscode "$watch_dir" 2> /dev/null

# chown -h: never follow symlinks — a link planted in the watched tree must
# not redirect a root chown to an arbitrary file
nohup sudo -n sh -c '
  inotifywait -mrq -e create -e moved_to --format "%w%f" "$1" \
  | while read -r f; do
      chown -h vscode:vscode "$f" 2>/dev/null
    done
' watcher "$watch_dir" > /dev/null 2>&1 &
