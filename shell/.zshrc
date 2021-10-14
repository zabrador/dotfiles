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

# java home
. ~/.asdf/plugins/java/set-java-home.zsh
