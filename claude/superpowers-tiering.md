# Workflow Tiering (SuperPowers)

Match the SuperPowers chain to the size of the work. Trying to brainstorm a typo fix wastes everybody's time; jumping into a 6-file refactor without a plan ends in tears.

## Tier 0 — One-shot (no chain)

- Typo fixes, formatting tweaks, single-line config changes, single-file edits under ~20 LOC
- Direct edit. No brainstorm, no plan, no worktree. Verify after.

## Tier 1 — Task (lightweight)

- 1–3 files, scope is clear, no architectural decisions
- Quick clarification with the user (1-2 questions if anything is ambiguous), implement directly, verify
- No worktree, no formal plan document, no subagent dispatch
- Use `verification-before-completion` skill before claiming done

## Tier 2 — Feature (full chain)

- Multi-file changes, architectural decisions, anything touching shared infra, or work the user explicitly framed as a feature/project
- Full chain: `brainstorming` → `writing-plans` → `using-git-worktrees` → `subagent-driven-development` → `finishing-a-development-branch`
- Plans MUST include explicit TDD steps (RED → GREEN → REFACTOR) and verification commands
- Implementer subagent prompts MUST include "Follow TDD for all implementation"

## Self-classification

When uncertain between tiers, ask the user once with `AskUserQuestion`. If the user says "go" or "looks good" partway through, that means proceed to the next step in the active tier — never skip steps within a tier.
