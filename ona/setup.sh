#!/bin/sh
# Ona-specific installation steps, aggregated here so install.sh stays
# readable.

ona_dir="$(dirname "$0")"

# --- Ona remote ownership watchers ------------------------------------------

echo "Starting Ona remote ownership watchers..."
bash "$ona_dir/fix-ona-remote-ownership.sh"
echo "...Ona remote ownership watchers running!"

# Agent shells skip .zshrc; append Ona secrets loading to .zshenv once, preserving existing contents.
if [ -f /etc/profile.d/ona-secrets.sh ]; then
  ona_secrets_line='. /etc/profile.d/ona-secrets.sh'
  if ! grep -Fqx "$ona_secrets_line" "$HOME/.zshenv" 2>/dev/null; then
    printf '\n%s\n' "$ona_secrets_line" >> "$HOME/.zshenv" || exit 1
  fi
fi

# --- Claude plugin opt-outs ---------------------------------------------------

# Project settings can force-enable plugins for everyone; `--scope local`
# records the opt-out in the project's gitignored .claude/settings.local.json,
# which takes precedence over project settings. The disable only lands in
# repos whose settings already enable the plugin — rerun after a project
# newly force-enables one.
if type "claude" > /dev/null 2>&1; then
  echo "Applying Claude plugin opt-outs..."
  for repo in /workspaces/*/; do
    [ -d "$repo/.git" ] || continue
    (cd "$repo" && claude plugin disable superpowers --scope local > /dev/null 2>&1) || true
  done
  echo "...Claude plugin opt-outs applied!"
else
  echo "Claude not installed, skipping plugin opt-outs."
fi
