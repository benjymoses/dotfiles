#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

# Resolve the directory this script lives in
CLAUDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$CLAUDE_DIR")"

CLAUDE_FRAGMENT="$CLAUDE_DIR/settings-fragment.json"
CLAUDE_REAL="$HOME/.claude/settings.json"

# ── Claude Code setup ──────────────────────────────────────────────
log "Setting up Claude Code..."
mkdir -p "$HOME/.claude"

# Backup existing Claude files before replacing them
BACKUP_DIR="$HOME/.config/backups/$(date -u +%Y-%m-%d-%H%M%S)"
CLAUDE_BACKUP_NEEDED=false
for claude_file in "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/statusline-command.sh" "$HOME/.claude/hooks/biome.sh" "$HOME/.claude/hooks/stop-typecheck.sh"; do
  if [ -e "$claude_file" ] && [ ! -L "$claude_file" ]; then
    if [ "$CLAUDE_BACKUP_NEEDED" = false ]; then
      mkdir -p "$BACKUP_DIR/.claude"
      CLAUDE_BACKUP_NEEDED=true
    fi
    log "Backing up $claude_file"
    cp "$claude_file" "$BACKUP_DIR/.claude/"
  fi
done
if [ "$CLAUDE_BACKUP_NEEDED" = true ]; then
  log "Claude files backed up to: $BACKUP_DIR/.claude/"
fi

# Link top-level markdown files manually (stow ignores the claude dir via .stowrc and can't override per-file)
# CLAUDE.md is the global instructions file.
for md_file in CLAUDE.md; do
  if [ -e "$HOME/.claude/$md_file" ]; then
    log "Removing existing $md_file before linking (original backed up to ~/.config/backups/)"
    rm -f "$HOME/.claude/$md_file"
  fi
  log "Linking $md_file to ~/.claude/..."
  ln -sf "$CLAUDE_DIR/$md_file" "$HOME/.claude/$md_file"
done

# Link DesktopNotification.app (used by Claude Code notification hook)
if [ -e "$HOME/.claude/DesktopNotification.app" ]; then
  rm -rf "$HOME/.claude/DesktopNotification.app"
fi
log "Linking DesktopNotification.app to ~/.claude/..."
ln -sf "$CLAUDE_DIR/DesktopNotification.app" "$HOME/.claude/DesktopNotification.app"

# Link statusline-command.sh (used by Claude Code status line)
if [ -e "$HOME/.claude/statusline-command.sh" ]; then
  log "Removing existing statusline-command.sh before linking (original backed up to ~/.config/backups/)"
  rm -f "$HOME/.claude/statusline-command.sh"
fi
log "Linking statusline-command.sh to ~/.claude/..."
ln -sf "$CLAUDE_DIR/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# Link hook scripts
mkdir -p "$HOME/.claude/hooks"
for hook_file in "$CLAUDE_DIR/hooks/"*.sh; do
  local_name=$(basename "$hook_file")
  if [ -e "$HOME/.claude/hooks/$local_name" ]; then
    log "Removing existing $local_name before linking (original backed up to ~/.config/backups/)"
    rm -f "$HOME/.claude/hooks/$local_name"
  fi
  log "Linking $local_name to ~/.claude/hooks/..."
  ln -sf "$hook_file" "$HOME/.claude/hooks/$local_name"
done

# Link dotfiles-managed skills into ~/.claude/skills/
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$CLAUDE_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  if [ -e "$HOME/.claude/skills/$skill_name" ] && [ ! -L "$HOME/.claude/skills/$skill_name" ]; then
    warn "~/.claude/skills/$skill_name exists and is not a symlink — skipping"
    continue
  fi
  log "Linking skill '$skill_name'..."
  ln -sfn "${skill_dir%/}" "$HOME/.claude/skills/$skill_name"
done

# Link OpenSpec user-level schemas (resolution: project → user → package).
# OpenSpec's user dir is ${XDG_DATA_HOME:-~/.local/share}/openspec/schemas.
OPENSPEC_USER_SCHEMAS="${XDG_DATA_HOME:-$HOME/.local/share}/openspec/schemas"
mkdir -p "$OPENSPEC_USER_SCHEMAS"
for schema_dir in "$CLAUDE_DIR/openspec/schemas/"*/; do
  [ -d "$schema_dir" ] || continue
  schema_name=$(basename "$schema_dir")
  if [ -e "$OPENSPEC_USER_SCHEMAS/$schema_name" ] && [ ! -L "$OPENSPEC_USER_SCHEMAS/$schema_name" ]; then
    warn "$OPENSPEC_USER_SCHEMAS/$schema_name exists and is not a symlink — skipping"
    continue
  fi
  log "Linking OpenSpec schema '$schema_name'..."
  ln -sfn "${schema_dir%/}" "$OPENSPEC_USER_SCHEMAS/$schema_name"
done

# Ensure global gitignore entries Claude Code relies on (idempotent append).
# ~/.config/git/ignore is git's XDG default — no core.excludesFile config needed.
GIT_IGNORE_GLOBAL="$HOME/.config/git/ignore"
mkdir -p "$(dirname "$GIT_IGNORE_GLOBAL")"
touch "$GIT_IGNORE_GLOBAL"
for ignore_entry in "**/.claude/settings.local.json" ".claude/worktrees/"; do
  if ! grep -qxF "$ignore_entry" "$GIT_IGNORE_GLOBAL"; then
    log "Adding '$ignore_entry' to global gitignore"
    echo "$ignore_entry" >> "$GIT_IGNORE_GLOBAL"
  fi
done

# Merge Claude settings fragment into real settings
if [ -f "$CLAUDE_FRAGMENT" ]; then
  if [ ! -f "$CLAUDE_REAL" ]; then
    # No existing settings — just copy the fragment
    log "No existing Claude settings found. Installing fragment as ~/.claude/settings.json"
    cp "$CLAUDE_FRAGMENT" "$CLAUDE_REAL"
  else
    # Merge: fragment keys override real settings
    MERGED=$(jq -s '.[0] * .[1]' "$CLAUDE_REAL" "$CLAUDE_FRAGMENT" 2>/dev/null)

    if [ $? -ne 0 ]; then
      warn "Failed to merge Claude settings (invalid JSON?) — skipping"
    else
      CURRENT=$(jq -S '.' "$CLAUDE_REAL")
      MERGED_SORTED=$(echo "$MERGED" | jq -S '.')

      if [ "$CURRENT" = "$MERGED_SORTED" ]; then
        log "Claude settings already up to date"
      else
        echo ""
        echo -e "${YELLOW}Claude settings merge preview:${NC}"
        echo ""
        diff <(echo "$CURRENT") <(echo "$MERGED_SORTED") || true
        echo ""
        read -p "Apply these changes to ~/.claude/settings.json? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
          jq -s '.[0] * .[1]' "$CLAUDE_REAL" "$CLAUDE_FRAGMENT" > "${CLAUDE_REAL}.tmp" && mv "${CLAUDE_REAL}.tmp" "$CLAUDE_REAL"
          log "Claude settings updated"
        else
          log "Skipped Claude settings merge"
        fi
      fi
    fi
  fi
else
  log "No settings-fragment.json found — skipping Claude settings merge"
fi

log "Claude Code setup complete!"
