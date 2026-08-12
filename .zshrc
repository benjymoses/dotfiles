# ~/.zshrc — interactive shells only.
# Environment and PATH live in ~/.zshenv and ~/.zprofile.

# Completions for Homebrew. HOMEBREW_PREFIX is exported by
# `brew shellenv` in .zprofile. Skip silently if this is 
# not a login shell or brew is absent.
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
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

# Project helpers
function mkcode() {
  mkdir -p $HOME/Documents/code/$1; code $HOME/Documents/code/$1;
}

function mkkiro() {
  mkdir -p $HOME/Documents/code/$1; kiro $HOME/Documents/code/$1;
}

# Node & Python (managed by mise)
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# Worktrunk: shell wrapper so `wt switch` can change the shell's directory
(( $+commands[wt] )) && eval "$(wt config shell init zsh)"

# History setup
HISTFILE=$HOME/.zhistory
SAVEHIST=50000
HISTSIZE=50000
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
export _ZO_DOCTOR=0
eval "$(zoxide init zsh --cmd cd)"

# eza
alias ls="eza --icons --color=always --group-directories-first"

# Kiro shell integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Machine-local interactive overrides (real file in $HOME, never in dotfiles)
[[ -f ~/.zshrc-local ]] && source ~/.zshrc-local

# Plugins (zsh-syntax-highlighting MUST be sourced last)
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
