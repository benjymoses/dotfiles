#!/bin/sh
# PostToolUse hook: format + check (lint + import organisation) edited files with biome
# Receives tool JSON on stdin, extracts file_path, runs biome from the project root

FILE=$(jq -r '.tool_input.file_path' </dev/stdin)
[ -z "$FILE" ] || [ "$FILE" = "null" ] && exit 0

# Only run for file types Biome supports (avoids spurious failures on .md, .py, .sh, etc.)
case "$FILE" in
*.ts | *.tsx | *.js | *.jsx | *.cjs | *.mjs | *.cts | *.mts | *.json | *.jsonc | *.css) ;;
*) exit 0 ;;
esac

# Walk up from the file to find biome.json (works in worktrees)
DIR=$(dirname "$FILE")
while [ "$DIR" != "/" ]; do
  [ -f "$DIR/biome.json" ] || [ -f "$DIR/biome.jsonc" ] && break
  DIR=$(dirname "$DIR")
done

[ "$DIR" = "/" ] && exit 0

CONFIG="$DIR/biome.json"
[ -f "$CONFIG" ] || CONFIG="$DIR/biome.jsonc"

# Skip files outside files.includes — Biome would reject them as "protected"
# and return non-zero, surfacing a spurious non-blocking hook failure.
REL=${FILE#"$DIR"/}
PATTERNS=$(jq -r '.files.includes[]? // empty' "$CONFIG" 2>/dev/null)
if [ -n "$PATTERNS" ]; then
  MATCHED=0
  # set -f so `**` in patterns isn't filename-expanded during word splitting.
  # In POSIX case, `*` already matches slashes, so `src/**` works as expected.
  set -f
  OLD_IFS=$IFS
  IFS='
'
  for pattern in $PATTERNS; do
    # shellcheck disable=SC2254
    case "$REL" in $pattern)
      MATCHED=1
      break
      ;;
    esac
  done
  IFS=$OLD_IFS
  set +f
  [ "$MATCHED" = 0 ] && exit 0
fi

# Prefer the project-local biome so hook results match the project's pinned version
BIOME="$DIR/node_modules/.bin/biome"
[ -x "$BIOME" ] || BIOME="biome"
command -v "$BIOME" >/dev/null 2>&1 || exit 0

# Format silently — formatting failures shouldn't block
"$BIOME" format --write --config-path "$DIR" "$FILE" 2>/dev/null

# Check (lint + organise imports) with auto-fix.
# PostToolUse hooks only feed errors back to Claude on exit 2 + stderr —
# any other non-zero exit is silently logged, so map failures explicitly.
if ! OUTPUT=$("$BIOME" check --write --config-path "$DIR" "$FILE" 2>&1); then
  printf '%s\n' "$OUTPUT" >&2
  exit 2
fi

exit 0
