# Loading completions
if type brew &>/dev/null; then
  # Completions from zsh-completions installed using homebrew
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"

  # Completions downloaded using homebrew
  FPATH="/opt/homebrew/share/zsh/site-functions:$FPATH"
fi

# Sourcing zsh-autocomplete. Has to be done at the top
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# history setup
HISFILE=$HOME/.zsh_history
HISTSIZE=100000
export SAVEHIST=$HISTSIZE
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_verify

# Pyenv

# Eza (better ls)
alias ls="eza --icons=always"

# Zoxide
eval "$(zoxide init zsh)"
alias cd="z"

# Sourcing Zsh Syntax Highlighting. Has to be done last
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship setup
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
eval "$(starship init zsh)"
