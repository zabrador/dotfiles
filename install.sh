echo "Installing dotfiles..."

if type "brew" > /dev/null; then
  echo "Using brew for installation..."

  if ! type "stow" > /dev/null; then
    echo "Installing stow..."
    brew install stow
    echo "...stow installation complete!"
  fi
elif type "apt" > /dev/null; then
  echo "Using apt for installation..."

  if ! type "stow" > /dev/null; then
    echo "Installing stow..."
    sudo apt install stow
    echo "...stow installation complete!"
  fi
fi

cd ~/.dotfiles
stow shell
echo "...dotfiles installation complete!"
