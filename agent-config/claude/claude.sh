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
AGENT_CONFIG_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"
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
# CLAUDE.md is the Claude-specific global instructions file.
# global-core.md is the shared cross-tool working agreement (imported by CLAUDE.md and
# referenced by Kiro's AGENTS.md steering file — see below).
for md_file in CLAUDE.md global-core.md; do
  if [ -e "$HOME/.claude/$md_file" ]; then
    log "Removing existing $md_file before linking (original backed up to ~/.config/backups/)"
    rm -f "$HOME/.claude/$md_file"
  fi
  log "Linking $md_file to ~/.claude/..."
  ln -sf "$CLAUDE_DIR/$md_file" "$HOME/.claude/$md_file"
done

# Link the shared working agreement into Kiro global steering.
# Kiro loads every .md in ~/.kiro/steering, so global-core.md is picked up directly.
# (Kiro won't follow #[[file:]] references outside the current project, so we can't use
# a wrapper that points at the shared core — the file itself must live in steering.)
KIRO_STEERING="$HOME/.kiro/steering"
if [ -d "$KIRO_STEERING" ]; then
  # Remove legacy steering files now superseded by the shared core.
  for legacy in global-tech-preferences.md AGENTS.md; do
    if [ -e "$KIRO_STEERING/$legacy" ]; then
      log "Removing legacy Kiro steering file $legacy (superseded by shared core)"
      rm -f "$KIRO_STEERING/$legacy"
    fi
  done
  log "Linking global-core.md to $KIRO_STEERING/global-core.md..."
  ln -sf "$CLAUDE_DIR/global-core.md" "$KIRO_STEERING/global-core.md"
else
  warn "$KIRO_STEERING not found — skipping Kiro steering link"
fi

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

# Link agent persona definitions into ~/.claude/agents/
# Unlike hooks, an existing NON-symlink target is left alone: that directory also
# holds locally-managed agents which are not tracked in this repo.
if [ -d "$CLAUDE_DIR/agents" ]; then
  mkdir -p "$HOME/.claude/agents"
  for agent_file in "$CLAUDE_DIR/agents/"*.md; do
    [ -e "$agent_file" ] || continue
    local_name=$(basename "$agent_file")
    if [ -e "$HOME/.claude/agents/$local_name" ] && [ ! -L "$HOME/.claude/agents/$local_name" ]; then
      warn "~/.claude/agents/$local_name exists and is not a symlink — skipping"
      continue
    fi
    log "Linking agent '$local_name' to ~/.claude/agents/..."
    ln -sf "$agent_file" "$HOME/.claude/agents/$local_name"
  done
fi

# Link dotfiles-managed skills into ~/.claude/skills/
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$AGENT_CONFIG_DIR/skills/"*/; do
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
  # A literal "~" or "$HOME" is NOT written into the JSON: Claude Code is not
   # documented to expand either inside statusLine.command.
   CLAUDE_FRAGMENT_RESOLVED="$(mktemp "${TMPDIR:-/tmp}/claude-fragment.XXXXXX")"
   if ! jq --arg home "$HOME" '
         if has("statusLine")
         then .statusLine.command = $home + "/.claude/statusline-command.sh"
         else . end
       ' "$CLAUDE_FRAGMENT" > "$CLAUDE_FRAGMENT_RESOLVED"; then
     warn "Could not normalise statusLine path - using the fragment as-is"
     cp "$CLAUDE_FRAGMENT" "$CLAUDE_FRAGMENT_RESOLVED"
   fi

  if [ ! -f "$CLAUDE_REAL" ]; then
    # No existing settings — just copy the fragment
    log "No existing Claude settings found. Installing fragment as ~/.claude/settings.json"
    cp "$CLAUDE_FRAGMENT_RESOLVED" "$CLAUDE_REAL"
  else
    # Merge program, used for both the preview and the apply so they cannot drift.
    #
    # jq's `*` merges objects recursively but REPLACES arrays outright. That is
    # wrong here: ~/.claude/settings.json accumulates machine-local entries that
    # are deliberately not in this repo, and a plain merge silently drops them.
    # Measured against the real files, `*` would have discarded 157 entries,
    # including 123 permissions.deny rules (the ~/.midway credential guards).
    #
    # So this merge is additive for arrays of STRINGS: real first, then any
    # fragment entries not already present, order preserved and deduped.
    # Arrays containing anything else (hook definitions) keep replace semantics,
    # because unioning those would register duplicate hooks. Objects merge
    # recursively and scalars are overridden by the fragment, both as before.
    MERGE_PROGRAM='
      def dedupe: reduce .[] as $x ([]; if index($x) then . else . + [$x] end);
      def allstrings: (length == 0) or all(type == "string");
      def dmerge($a; $b):
        if   ($a|type) == "object" and ($b|type) == "object" then
          reduce ($b|keys_unsorted[]) as $k ($a;
            .[$k] = (if ($a|has($k)) then dmerge($a[$k]; $b[$k]) else $b[$k] end))
        elif ($a|type) == "array" and ($b|type) == "array"
             and ($a|allstrings) and ($b|allstrings) then
          ($a + $b) | dedupe
        else $b end;
      dmerge(.[0]; .[1])
    '
    MERGED=$(jq -s "$MERGE_PROGRAM" "$CLAUDE_REAL" "$CLAUDE_FRAGMENT_RESOLVED" 2>/dev/null)

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
          jq -s "$MERGE_PROGRAM" "$CLAUDE_REAL" "$CLAUDE_FRAGMENT_RESOLVED" > "${CLAUDE_REAL}.tmp" && mv "${CLAUDE_REAL}.tmp" "$CLAUDE_REAL"
          log "Claude settings updated"
        else
          log "Skipped Claude settings merge"
        fi
      fi
    fi
  fi
  rm -f "$CLAUDE_FRAGMENT_RESOLVED"
else
  log "No settings-fragment.json found — skipping Claude settings merge"
fi

log "Claude Code setup complete!"
