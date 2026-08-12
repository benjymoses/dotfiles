# ~/.zprofile — login shells. Home for PATH and login-time environment.
# Runs after macOS /etc/zprofile (path_helper), so PATH set here is not reordered.

# Homebrew. Prefix differs by platform (Apple Silicon, Intel macOS, Linux),
# so probe rather than hardcode. `brew shellenv` exports HOMEBREW_PREFIX, 
# which .zshrc then uses to find completions and plugins.

for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew
export HOMEBREW_NO_ENV_HINTS=1

# User-local bins
export PATH="$HOME/.local/bin:$PATH"

# Mise Shims for Path
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Machine-local PATH / env (real file in $HOME, never in dotfiles)
[[ -f ~/.zprofile-local ]] && source ~/.zprofile-local
