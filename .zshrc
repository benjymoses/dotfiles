export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# Homebrew (loaded via .zprofile for login shells; not duplicated here)
export HOMEBREW_NO_ENV_HINTS=1

# Paths 
export PATH="$HOME/.local/bin:$PATH"

# Completions
if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
  fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)
fi

autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Git aliases
alias ga="git add"
alias gc="git commit --verbose"
alias gp="git push"
alias gl="git pull"
alias gb="git branch"
alias gst="git status"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias glog="git log --oneline --decorate --graph"

function mkcode() {
  mkdir -p $HOME/Documents/code/$1; code $HOME/Documents/code/$1;
}

function mkkiro() {
  mkdir -p $HOME/Documents/code/$1; kiro $HOME/Documents/code/$1;
}

# Pyenv (lazy - only init on first use)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if (( $+commands[pyenv] )); then
  _lazy_pyenv_init() {
    unfunction python python3 pyenv 2>/dev/null
    eval "$(pyenv init -)"
  }
  function python3() { _lazy_pyenv_init; python3 "$@" }
  function python() { _lazy_pyenv_init; python "$@" }
  function pyenv() { _lazy_pyenv_init; pyenv "$@" }
fi

## NVM (lazy - only init on first use)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  local _nvm_default="$NVM_DIR/alias/default"
  if [ -r "$_nvm_default" ]; then
    local _nvm_ver="v$(cat "$_nvm_default")"
    local _nvm_bin="$NVM_DIR/versions/node/$_nvm_ver/bin"
    [[ -d "$_nvm_bin" && ":PATH:" != *":$_nvm_bin:"* ]] && PATH="$_nvm_bin:$PATH"
  fi
  _lazy_nvm_init() {
    unfunction nvm node npm npx 2>/dev/null
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }
  function nvm() { _lazy_nvm_init; nvm "$@" }
  function node() { _lazy_nvm_init; node "$@" }
  function npm() { _lazy_nvm_init; npm "$@" }
  function npx() { _lazy_nvm_init; npx "$@" }
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

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
