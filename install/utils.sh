# Sourced by install.sh. Not meant to be executed.

# $1 command to look for; $2 brew formula and $3 apt package default to $1.
# Uses pkg_manager from the caller: brew, apt, or empty.
ensure_package() {
  command="$1"
  brew_formula="${2:-$1}"
  apt_package="${3:-$1}"
  if type "$command" > /dev/null 2>&1; then
    return 0
  fi
  if [ -z "$pkg_manager" ]; then
    return 0
  fi
  echo "Installing $command..."
  if [ "$pkg_manager" = brew ]; then
    brew install "$brew_formula"
  else
    sudo apt install "$apt_package"
  fi
  echo "...$command installation complete!"
}
