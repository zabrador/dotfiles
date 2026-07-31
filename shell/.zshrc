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

# Ona injects secrets into bash only; load them in zsh too.
[ -f /etc/profile.d/ona-secrets.sh ] && . /etc/profile.d/ona-secrets.sh

# Ensure Ona ownership watcher is running
[ "$IS_ON_ONA" = "true" ] && sh "$DOTFILES_ROOT/ona/fix-claude-remote-ownership.sh"
