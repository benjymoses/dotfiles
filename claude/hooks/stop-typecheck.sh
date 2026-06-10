#!/bin/bash
# Stop hook: project-wide TypeScript check once per turn.
# Exit 2 + stderr blocks the stop and keeps Claude working until types are clean.
# Live per-edit diagnostics come from the typescript-lsp plugin; this is the final gate.

INPUT=$(cat)

# Loop guard: if we already blocked this turn-chain once, report but don't block
# again — prevents an infinite loop when Claude can't fix the errors.
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && CWD=$PWD

TSCONFIG="$CWD/tsconfig.json"
[[ -f "$TSCONFIG" ]] || exit 0

# Skip when nothing TypeScript-related changed (fast path for non-TS turns)
if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CHANGED=$(
    {
      git -C "$CWD" diff --name-only HEAD 2>/dev/null
      git -C "$CWD" ls-files --others --exclude-standard 2>/dev/null
    } | grep -cE '\.(tsx|ts|mts|cts)$'
  )
  [[ "$CHANGED" -eq 0 ]] && exit 0
fi

# Prefer the project's pinned tsc; skip if the project has none
TSC="$CWD/node_modules/.bin/tsc"
[[ -x "$TSC" ]] || exit 0

TSBUILDINFO="${TSCONFIG%.json}.tsbuildinfo"

OUTPUT=$("$TSC" --noEmit --incremental --tsBuildInfoFile "$TSBUILDINFO" --project "$TSCONFIG" 2>&1 | head -30)
STATUS=${PIPESTATUS[0]}

[[ $STATUS -eq 0 ]] && exit 0

if [[ "$STOP_ACTIVE" == "true" ]]; then
  # Already blocked once this chain — surface the failure without looping.
  printf 'tsc still failing (not blocking again):\n%s\n' "$OUTPUT" >&2
  exit 0
fi

printf 'TypeScript errors — fix before finishing:\n%s\n' "$OUTPUT" >&2
exit 2
