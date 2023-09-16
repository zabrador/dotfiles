echo "Installing dotfiles..."

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

echo "Installing antigen..."
git clone https://github.com/zsh-users/antigen.git ~/.antigen
echo "...antigen installation complete!"

stow shell --target ~/
echo "...dotfiles installation complete!"
