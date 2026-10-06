source ~/.antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle git
antigen bundle asdf
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle sindresorhus/pure@main

antigen apply

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code-insiders --wait'
fi

# Dotfiles repo root, derived from the stowed ~/.zshrc symlink
export DOTFILES_ROOT="${${:-$HOME/.zshrc}:A:h:h}"

# Ensure Ona ownership watcher is running
[ "$IS_ON_ONA" = "true" ] && bash "$DOTFILES_ROOT/ona/fix-ona-remote-ownership.sh"
