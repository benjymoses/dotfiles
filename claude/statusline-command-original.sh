#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
if [ -n "$cwd" ]; then
  cwd="${cwd/#$HOME/\~}"
fi

# Get git branch (skip optional locks)
branch=""
if [ -n "$cwd" ]; then
  expanded_cwd="${cwd/#\~/$HOME}"
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$expanded_cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

# Context usage bar (10 segments)
ctx_bar=""
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")
  filled=$((pct * 10 / 100))
  empty=$((10 - filled))
  bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty); do bar="${bar}░"; done
  ctx_bar="${bar} ${pct}%"
fi

# Build the status line with separators
out=""

[ -n "$cwd" ] && out="${out}  \uf07b ${cwd}"
[ -n "$branch" ] && out="${out}  \ue0a0 ${branch}"
[ -n "$model" ] && out="${out}  \u2728 ${model}"
[ -n "$ctx_bar" ] && out="${out}  \ue285 ${ctx_bar}"

printf '%b' "$out"
