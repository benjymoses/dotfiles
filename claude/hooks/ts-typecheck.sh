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
  echo "typecheck-on-ts-edit: no tsconfig.json found for $FILE" >&2
  exit 0
fi

tsc --noEmit --project "$TSCONFIG" 2>&1 | head -20
