# ~/.zshenv — sourced for ALL shells (login, interactive, scripts).
# Keep lean: no PATH mutations (login path_helper reorders these), no subshell evals.

# Keep PATH entries unique automatically (prevents duplicates across nested/login shells).
typeset -U path PATH

export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
