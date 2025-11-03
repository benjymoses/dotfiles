export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export HOMEBREW_NO_ENV_HINTS=1

plugins=(git)

if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
  fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)
fi

# Functions (load immediately as they might be used)
function mkcode() {
  mkdir -p $HOME/Documents/code/$1; code $HOME/Documents/code/$1;
}

function mkkiro() {
  mkdir -p $HOME/Documents/code/$1; kiro $HOME/Documents/code/$1;
}

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

source $ZSH/oh-my-zsh.sh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# fzf
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--preview 'bat --color=always {}'"

# Starship
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh --cmd cd)"

# eza
alias ls="eza --icons --color=always --group-directories-first"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Allows local environment overrides or additions
source ~/.zshrc-local