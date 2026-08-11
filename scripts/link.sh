#!/bin/bash
# Symlink configs into $HOME with GNU stow, then install agent config.
#
# Runs AFTER packages.sh (needs stow) and BEFORE plugins.sh (which needs the
# configs this puts in place).
#
# Safe to re-run: stow is idempotent and the agent installer guards its targets.

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Pre-stow directory guards ─────────────────────────────────────────────────
# stow "folds" a directory when the target does not exist: instead of linking the
# individual file, it symlinks the whole directory into the repo. That is wrong
# for any tool that WRITES into its own config directory, because its runtime
# state would land inside this git repo. Creating these as real directories
# first forces stow to descend and link only the files.
#
#   herdr     writes logs, session.json, a socket, and installed plugins
#   worktrunk writes approvals.toml and cached state
#   mise      may write local state
for real_dir in \
  "$HOME/.config/herdr" \
  "$HOME/.config/worktrunk" \
  "$HOME/.config/mise"; do
  if [ ! -d "$real_dir" ]; then
    log "Creating ${real_dir/#$HOME/~} as a real directory (stow fold guard)"
  fi
  mkdir -p "$real_dir"
done

# ── Stow ──────────────────────────────────────────────────────────────────────
# Ignores are listed in .stowrc: anything that is not a $HOME dotfile
# (bootstrap.sh, scripts/, agent-config/, repo meta) must be listed there.
log "Configuring dotfiles with stow..."
cd "$DOTFILES_DIR"
stow .

# ── Agent config ──────────────────────────────────────────────────────────────
# Claude Code + Kiro: settings merge, hooks, statusline, steering, and the
# shared skills in agent-config/skills/ linked into both agents.
log "Installing agent config..."
source "$DOTFILES_DIR/agent-config/claude/claude.sh"

log "Linking complete."
