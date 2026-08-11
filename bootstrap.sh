#!/bin/bash
#
# Bootstrap this machine.
#
# This script only handles preparation: confirming with you, backing up whatever
# it is about to replace, and then calling the stages in order. The actual work
# lives in scripts/, so each stage can be re-run on its own:
#
#   scripts/packages.sh   Homebrew + packages          (slow, network)
#   scripts/link.sh       stow + agent config          (fast, idempotent)
#   scripts/plugins.sh    mise tools + herdr plugins   (needs config in place)
#
# Order matters: packages installs the binaries link needs, and link puts the
# config files plugins reads.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

# ── Pre-flight ────────────────────────────────────────────────────────────────
preflight_check() {
  echo -e "${GREEN}Bootstrap Script - Pre-flight Check${NC}"
  echo "=================================="
  echo ""
  echo "This script will perform the following activities:"
  echo "• Install Homebrew (if not present)"
  echo "• Install development packages via Homebrew"
  echo "• Configure dotfiles using GNU stow"
  echo "• Install agent config for Claude Code and Kiro"
  echo "• Install mise tool versions and herdr plugins"
  echo ""

  local conflicts=()

  # Root-level dotfiles
  for file in "$DOTFILES_DIR"/.*; do
    [ -f "$file" ] || continue
    local basename
    basename=$(basename "$file")
    [ "$basename" = "." ] || [ "$basename" = ".." ] && continue
    [ -e "$HOME/$basename" ] && conflicts+=("$basename")
  done

  # .config files
  if [ -d "$DOTFILES_DIR/.config" ]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$DOTFILES_DIR/.config/}"
      local target="$HOME/.config/$rel_path"
      [ -e "$target" ] && conflicts+=("~/.config/$rel_path")
    done < <(find "$DOTFILES_DIR/.config" -type f -print0)
  fi

  if [ ${#conflicts[@]} -gt 0 ]; then
    warn "Existing configuration files will be backed up:"
    printf "  %s\n" "${conflicts[@]}"
    echo ""
  fi

  echo -e "${YELLOW}Warning:${NC} If existing configs exist, they'll be backed up to:"
  echo "  ~/.config/backups/$(date -u +%Y-%m-%d-%H%M%S)/"
  echo ""
  echo "NVIM plugins will be purged (you can re-install them afterwards)"
  echo ""

  read -p "Do you want to proceed? (y/N): " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
}

# ── Backup ────────────────────────────────────────────────────────────────────
backup_configs() {
  local backup_dir="$HOME/.config/backups/$(date -u +%Y-%m-%d-%H%M%S)"
  local needs_backup=false

  mkdir -p "$backup_dir"

  # Root-level dotfiles
  cd "$DOTFILES_DIR"
  for file in .*; do
    [ "$file" = "." ] || [ "$file" = ".." ] && continue
    [ -f "$file" ] || continue

    local target="$HOME/$file"
    if [ -e "$target" ]; then
      log "Backing up $file"
      cp -r "$target" "$backup_dir/"
      rm -rf "$target"
      needs_backup=true
    fi
  done

  # .config files
  if [ -d "$DOTFILES_DIR/.config" ]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$DOTFILES_DIR/.config/}"
      local target="$HOME/.config/$rel_path"
      if [ -e "$target" ]; then
        log "Backing up ~/.config/$rel_path"
        mkdir -p "$backup_dir/.config/$(dirname "$rel_path")"
        cp -r "$target" "$backup_dir/.config/$rel_path"
        rm -rf "$target"
        needs_backup=true
      fi
    done < <(find "$DOTFILES_DIR/.config" -type f -print0)
  fi

  if [ -e "$HOME/.zprofile" ]; then
    log "Backing up ~/.zprofile"
    cp "$HOME/.zprofile" "$backup_dir/"
    needs_backup=true
  fi

  # Agent config that the installer will replace
  for agent_file in \
    "$HOME/.claude/settings.json" \
    "$HOME/.claude/CLAUDE.md" \
    "$HOME/.claude/global-core.md" \
    "$HOME/.claude/statusline-command.sh" \
    "$HOME/.claude/hooks/biome.sh" \
    "$HOME/.claude/hooks/stop-typecheck.sh"; do
    if [ -e "$agent_file" ]; then
      log "Backing up ${agent_file/#$HOME/~}"
      mkdir -p "$backup_dir/.claude/hooks"
      cp "$agent_file" "$backup_dir/.claude/$(basename "$agent_file")"
      needs_backup=true
    fi
  done

  # NVIM local data, state, and cache
  for nvim_pair in \
    "$HOME/.local/share/nvim:nvim_local_share" \
    "$HOME/.local/state/nvim:nvim_local_state" \
    "$HOME/.cache/nvim:nvim_cache"; do
    local src="${nvim_pair%%:*}"
    local dest_name="${nvim_pair##*:}"
    if [ -d "$src" ]; then
      log "Backing up $src"
      mkdir -p "$backup_dir/$dest_name"
      mv "$src" "$backup_dir/$dest_name/"
      needs_backup=true
    fi
  done

  # Clean plugin directories
  for plugin_dir in "$HOME/.config/nvim/plugins"; do
    if [ -d "$plugin_dir" ]; then
      log "Cleaning $plugin_dir"
      rm -rf "$plugin_dir"/*
      mkdir -p "$plugin_dir"
    fi
  done

  if [ "$needs_backup" = true ]; then
    log "Configs backed up to: $backup_dir"
  else
    rmdir "$backup_dir" 2>/dev/null || true
  fi
}

# ── Run ───────────────────────────────────────────────────────────────────────
git -C "$DOTFILES_DIR" config core.hooksPath .githooks

preflight_check
backup_configs

bash "$SCRIPT_DIR/scripts/packages.sh"
bash "$SCRIPT_DIR/scripts/link.sh"
bash "$SCRIPT_DIR/scripts/plugins.sh"

log "Bootstrap complete!"
echo ""
echo -e "${GREEN}🎉 Setup finished! Please close this terminal with ${YELLOW}CMD + Q${GREEN} and open WezTerm.${NC}"
