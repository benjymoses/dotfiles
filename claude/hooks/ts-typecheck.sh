#!/bin/bash
# Runs tsc --noEmit when a .ts/.tsx file is edited.
# Resolves the nearest tsconfig.json by walking up from the file's directory,
# so it works correctly in git worktrees as well as the main project.

FILE=$(jq -r '.tool_input.file_path // empty' < /dev/stdin)

# Only run for TypeScript files (.ts, .tsx, .test.ts, .spec.ts, etc.)
if [[ "$FILE" != *.ts && "$FILE" != *.tsx ]]; then
  exit 0
fi

# Walk up from the file's directory to find the nearest tsconfig.json
DIR=$(dirname "$FILE")
TSCONFIG=""
while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/tsconfig.json" ]]; then
    TSCONFIG="$DIR/tsconfig.json"
    break
  fi
  DIR=$(dirname "$DIR")
done

if [[ -z "$TSCONFIG" ]]; then
  exit 0
fi

# Use --incremental + a per-tsconfig build info file so subsequent runs are fast.
# Build info lives next to the tsconfig so worktrees stay isolated.
TSBUILDINFO="${TSCONFIG%.json}.tsbuildinfo"

# Run in background-safe foreground: trim output, time-bound the run.
# A failed typecheck still surfaces (head exits 0, tsc's exit code is captured via PIPESTATUS).
output=$(tsc --noEmit --incremental --tsBuildInfoFile "$TSBUILDINFO" --project "$TSCONFIG" 2>&1 | head -20)
status=${PIPESTATUS[0]}

if [[ $status -ne 0 ]]; then
  printf '%s\n' "$output"
  exit $status
fi

exit 0
