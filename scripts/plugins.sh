#!/bin/bash
# Install everything that needs config to already be in place.
#
# Runs LAST: mise reads .config/mise/config.toml and herdr reads
# .config/herdr/config.toml, both of which link.sh has just stowed.
#
# Safe to re-run: mise and herdr both skip what is already installed.

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Language toolchains ───────────────────────────────────────────────────────
# Versions come from .config/mise/config.toml (node, python, rust).
if command_exists mise; then
  log "Installing mise-managed tool versions..."
  mise install
else
  warn "mise not found — skipping tool versions"
fi

# ── herdr plugins ─────────────────────────────────────────────────────────────
# Installed from GitHub by <owner>/<repo>. herdr records the resolved commit, so
# re-running is a no-op for anything already present.
#
# Per-plugin configuration lives in ~/.config/herdr/plugins/config/<id>/ and is
# deliberately NOT in this repo: it can contain host-specific details. Configure
# those by hand after a rebuild.
herdr_plugins=(
  "0x5c0f/herdr-insight"                  # session/agent timeline
  "rohankewal/herdr-nerd-font-tab-name"   # nerd font tab labels
  "den-tanui/herdr-zoxide"                # zoxide directory jumping
  "JanTvrdik/herdr-command-palette"       # fzf command palette
  "nikok6/herdr-mirror"                   # mirror remote herdr workspaces locally
  "paulbkim-dev/vim-herdr-navigation"     # ctrl+hjkl across nvim splits and panes
  "devashish2203/herdr-worktrunk"         # worktree picker driving worktrunk
)

if command_exists herdr; then
  installed="$(herdr plugin list 2>/dev/null || true)"
  for plugin in "${herdr_plugins[@]}"; do
    plugin_id="${plugin##*/}"
    if echo "$installed" | grep -q "$plugin"; then
      log "herdr plugin $plugin_id already installed"
    else
      log "Installing herdr plugin $plugin_id..."
      herdr plugin install "$plugin" --yes || warn "Failed to install $plugin"
    fi
  done
else
  warn "herdr not found — skipping plugins"
fi

log "Plugins complete."
