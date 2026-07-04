#!/bin/sh
# PreToolUse hook (matcher: Bash): deny busy-wait sleep patterns with guidance.
# Blocks only (a) bare `sleep N` where N >= 15, or (b) `sleep` inside a shell
# loop construct. Short sleeps (server boot, backoff) pass through untouched.
# Receives tool JSON on stdin; deny is returned as permissionDecision JSON.

CMD=$(jq -r '.tool_input.command // empty' </dev/stdin)
[ -z "$CMD" ] && exit 0

deny() {
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Busy-waiting is never needed: teammate/subagent messages and task notifications arrive automatically - end your turn and wait for them instead of sleeping/polling."}}
EOF
  exit 0
}

# sleep inside a loop construct → busy-wait polling
if printf '%s' "$CMD" | grep -qE '\b(while|for|until)\b.*\bsleep\b'; then
  deny
fi

# long sleeps (>= 15s), including compound segments like `foo && sleep 30`
for N in $(printf '%s' "$CMD" | grep -oE '(^|[;&|(])[[:space:]]*sleep[[:space:]]+[0-9]+' | grep -oE '[0-9]+$'); do
  [ "$N" -ge 15 ] && deny
done

exit 0
