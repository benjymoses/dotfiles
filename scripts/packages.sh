#!/bin/bash
# Install Homebrew and all packages.
#
# Runs BEFORE linking, because later stages need the binaries this installs
# (stow, herdr, mise). Tool versions pinned in .config/mise/config.toml are
# installed later by plugins.sh, once stow has put that config in place.
#
# Safe to re-run: every step checks before acting.

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Homebrew ──────────────────────────────────────────────────────────────────
# The installer is the same on macOS and Linux.
if ! command_exists brew; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "Homebrew already installed"
fi

# Probe for Brew to get shellenv
BREW=""
for candidate in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  [ -x "$candidate/bin/brew" ] && BREW="$candidate/bin/brew" && break
done
[ -n "$BREW" ] || { error "brew not found after install"; exit 1; }

eval "$("$BREW" shellenv)"

# ── Packages ──────────────────────────────────────────────────────────────────
# NOTE: worktrunk installs a `wt` binary and conflicts with the `wiredtiger`
# formula, which installs its own `wt`. Do not install both.
log "Installing Homebrew packages..."
packages=(
  "starship"
  "neovim"
  "ripgrep"
  "herdr"                  # terminal workspace manager for AI agents
  "worktrunk"              # git worktree manager with lifecycle hooks
  "eza"
  "zoxide"
  "fzf"                    # required by the herdr command-palette + worktrunk plugins
  "bat"
  "luarocks"
  "wget"
  "fd"
  "jq"                     # required by herdr plugins and the claude settings merge
  "stow"
  "uv"
  "mise"
  "zsh-autosuggestions"
  "zsh-syntax-highlighting"
  "font-fira-code-nerd-font"
  "font-meslo-lg-nerd-font"
)

# macOS-only: a GUI terminal, and a shim around NSUserNotification
if [ "$(uname -s)" = "Darwin" ]; then
  packages+=(
    "wezterm"
    "terminal-notifier"
  )
fi

for package in "${packages[@]}"; do
  if brew list "$package" &>/dev/null; then
    log "$package already installed"
  else
    log "Installing $package..."
    brew install "$package" || warn "Failed to install $package - continuing"
  fi
done

log "Packages complete."

# ── herdr agent integrations ──────────────────────────────────────────────────
# The integration writes a hook script into ~/.claude/hooks/ that reports
# authoritative agent state back to herdr, so the sidebar shows working/blocked/
# done rather than guessing from screen output.
#
# The hook FILE is managed by herdr and deliberately NOT tracked in this repo.
# Only the wiring that references it is, in
# agent-config/claude/settings-fragment.json.
#
# Installed here rather than in plugins.sh so the hook exists before link.sh
# merges the settings that point at it.
if command_exists herdr; then
  if herdr integration status 2>/dev/null | grep -q '^claude: current'; then
    log "herdr claude integration already current"
  else
    log "Installing herdr claude integration..."
    herdr integration install claude || warn "herdr integration install claude failed"
  fi
fi
