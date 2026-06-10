#!/usr/bin/env bash
# PreToolUse hook: nudge towards TeamCreate when dispatching coordinated implementation subagents.
# This warns rather than blocks — single-shot Explore/research Agent() calls are fine.
#
# Trigger: Agent tool calls whose prompt looks like coordinated implementation work
# (mentions implementer, fixes, plan execution, multiple tasks, TDD, etc).
# Skip: Explore subagent_type, single research questions, plugin agents.

set -u

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
[ "$tool_name" = "Agent" ] || exit 0

subagent_type=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty')
prompt=$(printf '%s' "$input" | jq -r '.tool_input.prompt // empty')

# Allow Explore — research is the right use case for plain Agent().
[ "$subagent_type" = "Explore" ] && exit 0

# Allow Plan — same rationale.
[ "$subagent_type" = "Plan" ] && exit 0

# Allow plugin agents (namespaced like "plugin-name:agent-name").
case "$subagent_type" in
  *:*) exit 0 ;;
esac

# Heuristic: prompt indicates coordinated implementation work
# (implementer/reviewer roles, plan execution, multi-task TDD runs).
if printf '%s' "$prompt" | grep -qiE 'implementer|spec[- ]review|code[- ]quality[- ]review|TDD|RED/GREEN|task [0-9]+ of|execute the plan|implementation plan|apply the change'; then
  cat <<'EOF' >&2
⚠️  Agent() call looks like coordinated implementation work.
Prefer TeamCreate so multiple subagents share team context and you can run them in parallel.
For one-shot research, use Agent(subagent_type=Explore) — that path is silent.
EOF
  # Non-zero exit on stderr would block; we want a warning only, so exit 0.
fi

exit 0
