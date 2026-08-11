#!/bin/sh
# PreToolUse hook (matcher: Bash): deny agent-issued `git commit` while the
# target repo is on main/master. Non-bypassable by design — sanctioned commits
# to main (Tier 0/1 user-chosen main, archive close-out) are run by the human
# (`! git commit ...` in-session, or another terminal).
# Exempt: ~/dotfiles (main-only repo, no PR flow).

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# Match `git commit` as the subcommand, including `git -C <path> commit` and
# `git -c key=val commit`, in any segment of a compound command.
printf '%s' "$CMD" | grep -qE '(^|[;&|(])[[:space:]]*git[[:space:]]+((-C|-c)[[:space:]]+[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$)' || exit 0

# Branch is checked in the repo the commit targets: -C path if given, else cwd
DIR=$(printf '%s' "$CMD" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p')
[ -z "$DIR" ] && DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
case "$DIR" in "~"*) DIR="$HOME${DIR#\~}" ;; esac
[ -z "$DIR" ] && exit 0

TOP=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
[ "$TOP" = "$HOME/dotfiles" ] && exit 0

BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Agent commits on main are blocked (non-bypassable, by design). If this commit is sanctioned (Tier 0/1 where the user chose main, or the archive close-out commit), stage everything, present the exact commit command with its message, and ask the user to run it themselves (they can type `! git commit ...` in-session or use another terminal). Otherwise switch to a feature branch."}}
EOF
  exit 0
fi

exit 0
