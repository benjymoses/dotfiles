#!/bin/sh
# PostToolUse hook: format + lint edited files with biome
# Receives tool JSON on stdin, extracts file_path, runs biome from the project root

FILE=$(jq -r '.tool_input.file_path' < /dev/stdin)
[ -z "$FILE" ] || [ "$FILE" = "null" ] && exit 0

# Walk up from the file to find biome.json (works in worktrees)
DIR=$(dirname "$FILE")
while [ "$DIR" != "/" ]; do
  [ -f "$DIR/biome.json" ] || [ -f "$DIR/biome.jsonc" ] && break
  DIR=$(dirname "$DIR")
done

[ "$DIR" = "/" ] && exit 0

# Format silently — formatting failures shouldn't block
biome format --write --config-path "$DIR" "$FILE" 2>/dev/null

# Lint with auto-fix — pass through exit code so agents see unfixable errors
exec biome lint --write --unsafe --config-path "$DIR" "$FILE"
