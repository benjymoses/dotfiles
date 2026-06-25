# ~/.zprofile — login shells. Home for PATH and login-time environment.
# Runs after macOS /etc/zprofile (path_helper), so PATH set here is not reordered.

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1

# User-local bins
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Machine-local PATH / env (real file in $HOME, never in dotfiles)
[[ -f ~/.zprofile-local ]] && source ~/.zprofile-local
