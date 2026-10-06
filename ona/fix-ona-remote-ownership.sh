#!/bin/bash
# Ona can create root-owned files during instance startup and resume.
# Repair existing ownership synchronously, then watch for replacements.

[ "$IS_ON_ONA" = "true" ] || exit 0

vscode_home="$(getent passwd vscode 2>/dev/null | cut -d: -f6)"
[ -n "$vscode_home" ] || exit 0

# A trailing slash includes a directory's descendants; other entries match one file.
ownership_paths=(
  "$vscode_home/.claude/"
  "$vscode_home/.zshenv"
)

for entry in "${ownership_paths[@]}"; do
  target="${entry%/}"
  if [[ "$entry" == */ ]]; then
    [ -L "$target" ] && continue
    mkdir -p "$target" 2>/dev/null
  fi
  # -h and -P keep ownership repairs from following symlinks.
  sudo -n chown -hRP vscode:vscode "$target" 2>/dev/null
done

if ! command -v inotifywait > /dev/null 2>&1; then
  # Never prompt for a password during shell startup.
  sudo -n apt-get install -y inotify-tools > /dev/null 2>&1
  command -v inotifywait > /dev/null 2>&1 || exit 0
fi

for entry in "${ownership_paths[@]}"; do
  target="${entry%/}"
  [[ "$entry" == */ && -L "$target" ]] && continue
  if ps -eo args= | (
    while IFS= read -r process; do
      [[ "$process" == *" ona-ownership-watcher $entry" ]] && exit 0
    done
    exit 1
  ); then
    continue
  fi
  nohup sudo -n bash -c '
    entry=$1
    target=${entry%/}
    if [[ "$entry" == */ ]]; then
      watch_args=(-r "$target")
    else
      watch_args=("$(dirname "$target")")
    fi
    inotifywait -mq -e create -e moved_to --format "%w%f" "${watch_args[@]}" \
    | while IFS= read -r path; do
        if [[ "$path" == "$target" || ( "$entry" == */ && "$path" == "$target/"* ) ]]; then
          chown -hRP vscode:vscode "$path" 2>/dev/null
        fi
      done
  ' ona-ownership-watcher "$entry" > /dev/null 2>&1 &
done
