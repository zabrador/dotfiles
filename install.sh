echo "Installing dotfiles..."

# --- Package manager / Stow -------------------------------------------------

if type "brew" > /dev/null; then
  echo "Using brew for installation..."
  brew update

  if ! type "stow" > /dev/null; then
    echo "Installing stow..."
    brew install stow
    echo "...stow installation complete!"
  fi
elif type "apt" > /dev/null; then
  echo "Using apt for installation..."
  sudo apt update

  if ! type "stow" > /dev/null; then
    echo "Installing stow..."
    sudo apt install stow
    echo "...stow installation complete!"
  fi
fi

# --- Antigen ----------------------------------------------------------------

if [ ! -d ~/.antigen ]; then
  echo "Installing antigen..."
  git clone https://github.com/zsh-users/antigen.git ~/.antigen
  echo "...antigen installation complete!"
else
  echo "Antigen already present at ~/.antigen; skipping clone."
fi

# --- Stow home config -------------------------------------------------------

# Move to the directory containing this install script
cd "$(dirname "$0")"

echo "Removing existing configuration files..."
for file in $(find shell -type f -exec basename {} \;); do
  rm -f ~/$file
done

stow shell --target ~/

# --- Claude skills -----------------------------------------------------------

echo "Linking Claude skills..."
mkdir -p ~/.claude/skills

# Remove anything that would collide with the skills Stow package; skills not
# in the package are left alone.
for skill in claude/skills/*/; do
  rm -rf ~/.claude/skills/"$(basename "$skill")"
done

stow skills --dir claude --target ~/.claude/skills
echo "...Claude skills linked!"

# --- Environment-specific credentials / Codespaces --------------------------

if [ "$CODESPACES" = "true" ]; then
  echo "Simplifying git config in codespaces..."
  git config --global --remove-section commit
  git config --global --remove-section gpg
  git config --global --remove-section user
  echo "...git config simplification complete!"
elif [ -n "$SSH_PRIVATE_KEY_ED25519" ]; then
  echo "Importing SSH key from environment..."

  mkdir -p ~/.ssh
  echo "$SSH_PRIVATE_KEY_ED25519" > ~/.ssh/id_ed25519

  # `ssh` requires the private key to only be readable by the current user
  chmod 600 ~/.ssh/id_ed25519

  # Derive the public key from the private key
  ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub

  echo "...SSH key import complete!"
fi

# --- Ona: Claude remote ownership watcher -----------------------------------

if [ "$IS_ON_ONA" = "true" ]; then
  echo "Starting Claude-remote ownership watcher..."
  sh ona/fix-claude-remote-ownership.sh
  echo "...starting Claude-remote ownership watcher complete!"
fi

# --- Login shell ------------------------------------------------------------

echo "Configuring login shell to zsh..."
zsh_path=""
if type "brew" > /dev/null 2>&1; then
  brew_zsh="$(brew --prefix 2>/dev/null)/bin/zsh"
  if [ -x "$brew_zsh" ]; then
    zsh_path="$brew_zsh"
  fi
fi
if [ -z "$zsh_path" ] && [ -x /usr/bin/zsh ]; then
  zsh_path="/usr/bin/zsh"
fi
if [ -z "$zsh_path" ]; then
  zsh_path="$(command -v zsh 2>/dev/null || true)"
fi

if [ -n "$zsh_path" ] && [ -x "$zsh_path" ]; then
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    echo "Adding $zsh_path to /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
  fi

  if ! sudo chsh -s "$zsh_path" "$(id -un)"; then
    echo "...failed to set login shell to $zsh_path!" >&2
    exit 1
  fi
  echo "...login shell set to $zsh_path!"
else
  echo "...login shell configuration failed: no usable zsh found!" >&2
  exit 1
fi

echo "...dotfiles installation complete!"
