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

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
(( $+commands[pyenv] )) && eval "$(pyenv init -)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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

# eza
alias ls="eza --icons --color=always --group-directories-first"

# Claude Code launchers
alias cdi='claude --append-system-prompt "$(cat .claude/diagrams/*.md(N) < /dev/null 2>/dev/null)"'

alias claude-pro="claude --settings '{\"env\":{\"CLAUDE_CODE_USE_BEDROCK\":\"0\",\"ANTHROPIC_DEFAULT_SONNET_MODEL\":\"\",\"ANTHROPIC_DEFAULT_OPUS_MODEL\":\"\",\"ANTHROPIC_DEFAULT_HAIKU_MODEL\":\"\",\"ANTHROPIC_DEFAULT_OPUS_MODEL_NAME\":\"Opus 4.6 (Claude Pro)\",\"ANTHROPIC_DEFAULT_SONNET_MODEL_NAME\":\"Sonnet 4.6 (Claude Pro)\",\"ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME\":\"Haiku 4.5 (Claude Pro)\"}}'"


[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Allows local environment overrides or additions
source ~/.zshrc-local

# Zoxide
eval "$(zoxide init zsh --cmd cd)"
export _ZO_DOCTOR=0
