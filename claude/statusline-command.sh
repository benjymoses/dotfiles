#!/usr/bin/env bash
input=$(cat)

# Single jq pass — statusline runs frequently, keep subprocesses down.
# Unit separator (\x1f) as delimiter: tabs are IFS whitespace in bash, so
# empty TSV fields would collapse and shift every later field left.
IFS=$'\x1f' read -r cwd model used size in_tok cc_tok cr_tok cost wt_name transcript <<<"$(
  jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.context_window.used_percentage // ""),
    (.context_window.context_window_size // ""),
    (.context_window.current_usage.input_tokens // ""),
    (.context_window.current_usage.cache_creation_input_tokens // ""),
    (.context_window.current_usage.cache_read_input_tokens // ""),
    (.cost.total_cost_usd // ""),
    (.worktree.name // ""),
    (.transcript_path // "")
  ] | map(tostring) | join("")' <<<"$input"
)"

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

# Context usage: bar + percentage + actual token numbers
ctx=""
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")
  filled=$((pct * 10 / 100))
  empty=$((10 - filled))
  # C-style loops: BSD `seq 1 0` counts down (1, 0) so it'd add 2 phantom segments
  bar=""
  for ((i = 0; i < filled; i++)); do bar="${bar}█"; done
  for ((i = 0; i < empty; i++)); do bar="${bar}░"; done
  ctx="${bar} ${pct}%"

  # Actual numbers: used = input + cache creation + cache read (output excluded,
  # matching how used_percentage is calculated). current_usage is null before
  # the first API call and right after /compact — fall back to % only.
  if [ -n "$in_tok" ] && [ -n "$size" ]; then
    tok=$((in_tok + ${cc_tok:-0} + ${cr_tok:-0}))
    tok_k=$(((tok + 500) / 1000))
    size_k=$(((size + 500) / 1000))
    ctx="${ctx} ${tok_k}k/${size_k}k"
  fi
fi

# Session cost (Bedrock estimate)
cost_disp=""
if [ -n "$cost" ]; then
  cost_disp=$(printf '$%.2f' "$cost")
fi

# Prompt cache countdown (Bedrock TTL ≈ 5 min, refreshed on every API hit).
# The transcript's mtime is a proxy for the last API call. NOTE: the statusline
# only re-renders on conversation activity, so this is "remaining as of last
# render", not a live ticking clock — it goes stale while you idle.
cache_disp=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  last_api=$(stat -f %m "$transcript" 2>/dev/null)
  if [ -n "$last_api" ]; then
    remaining=$((300 - ($(date +%s) - last_api)))
    if ((remaining > 0)); then
      cache_disp=$(printf '%d:%02d' $((remaining / 60)) $((remaining % 60)))
    else
      cache_disp="expired"
    fi
  fi
fi

# Build the status line with separators (\u escapes expanded by printf %b)
out=""

[ -n "$cwd" ] && out="${out}   ${cwd}"
[ -n "$branch" ] && out="${out}   ${branch}"
[ -n "$wt_name" ] && out="${out}   ${wt_name}"
[ -n "$model" ] && out="${out}  ✨ ${model}"
[ -n "$ctx" ] && out="${out}   ${ctx}"
[ -n "$cost_disp" ] && out="${out}  ${cost_disp}"

[ -n "$cache_disp" ] && out="${out}  ⚡ ${cache_disp}"

printf '%b' "$out"
