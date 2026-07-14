# Global Working Agreement

My cross-tool working agreement (communication, autonomy, scope, problem-solving,
code, decisions) lives in the shared core, imported here:

@~/.claude/global-core.md

Claude-only additions on top of the core:

- When asking me multiple-choice questions, use the `AskUserQuestion` tool.

# Project Context Store

Each project keeps agent-facing context under `.claude/`:

- **`.claude/CONTEXT.md`** — the index: current project state plus a one-line entry per reference file (`- [topic](references/topic.md) — when to read it`). A SessionStart hook injects it automatically, so whatever it lists is discoverable every session. Keep it current: update it when project state changes materially or when adding/removing reference files.
- **`.claude/references/{topic}.md`** — in-depth docs (domain models, integration guides, gotchas). Not auto-loaded; read the relevant file when CONTEXT.md's index says it applies to the task at hand.
- **`.claude/diagrams/`** — architecture diagrams (Mermaid format). Keep them updated when making structural changes.
- **`openspec/`** — change proposals, specs, and decisions (see Workflow Tiering).

When a project lacks `.claude/CONTEXT.md` and you learn something future sessions need, offer to create it.

# Code Rules

Core code and tooling rules are in the shared core. Claude-only additions:

- Prefer running single tests, not the whole suite, for performance.
- If a `package-lock.json` exists, ask whether to run `pnpm import` and delete it.

# Shell Command Style

Commands run in a sandbox with auto-allow — simple commands matching the permission allowlist run without prompting. To stay hands-off:

- Prefer simple, single-purpose commands over chained compounds (`cd X && foo && bar`) — every segment of a compound is permission-checked independently, and one unmatched segment forces a prompt
- Avoid command substitution (`$(...)`) and pipes into mutating commands when a plain invocation works
- Never prepend `cd <cwd>` to commands; the shell already runs in the working directory
- If a command fails due to sandboxing (network/system writes), it retries unsandboxed with a prompt — that prompt is expected and correct for genuinely escaping operations

# Workflow Tiering

Match process weight to work size. The **`openspec-flow` skill** (§0 Intake)
holds the authoritative tier table (0/1/2) and routing, and loads whenever work
is classified. In short: Tier 0/1 = direct edit / small scoped change; Tier 2 =
multi-file / architectural / feature → spec-driven via **OpenSpec** (`openspec`
CLI; project schema if present, else the user-level default). Do not restate the
full tier definitions here — defer to the skill.

# Sub Agents & Parallelism

Default: **parallel where safe, sequential only when required.** A single message with multiple tool calls runs them in parallel.

- **`Agent(subagent_type=Explore)`** — broad codebase questions, "how does X work", anything spanning >2 files. Always prefer this over manual `Read`/`Grep` chains. Multiple Explore calls in one message → parallel research.
- **`Agent(subagent_type=Plan)`** — Tier 2 implementation strategy before starting work.
- **Agent teams** — for genuinely parallel, disjoint-file work, multiple agents can run in parallel, share a task list, and message each other. The **team-spawn mechanism** (how teams form, the enabling env var, teammate prompt shape) lives in full in the `openspec-flow` skill and the `spec-driven-plus` apply block — defer to them; don't restate it here.
- **Independent review, always** — the main thread NEVER reviews its own writes. For non-parallel work, orchestrate a warm **implementer subagent** (prefer background → returns an `agentId`; resume via `SendMessage` to rework, never re-spawn fresh) plus independent **spec-validator** and **code-reviewer** subagents in parallel. Objectivity without team overhead.
- **`model: "sonnet"` (shorthand) on every spawn** — EU Bedrock needs region-prefixed IDs set via env vars; only the shorthand resolves correctly. Project-specific dispatch detail (e.g. an OpenSpec apply loop) belongs in that project's schema/skill, not here.
- **Kill teammates when done** — every spawned teammate MUST be explicitly terminated (`TaskStop`) once its work is accepted and no longer needed. Never leave idle teammates running: without an active handle they accumulate, and the only recovery is manual cleanup or killing and re-launching the Claude process. Before ending a turn that spawned a team, confirm no orphaned teammates remain. (Background implementer/review subagents from the non-team path should likewise be stopped once their output is consumed.)

**Parallel implementation OK** when plan tasks touch disjoint files (no shared edits, no ordering constraint). **Stay sequential** when tasks edit the same file, depend on each other's outputs, or where ordering is part of the design (e.g., add the type before the consumer).

**Worktrees:** managed by the OpenSpec flow — the `openspec-flow` skill and the `spec-driven-plus` apply block are the single source of truth for when and how to use them. Don't restate worktree mechanics here.

# Memory

System prompt covers the rules in detail. Quick reminders:

- **Save proactively** to the project memory directory — don't wait to be asked. Always update `MEMORY.md` index with a one-line entry.
- **Save:** user info, feedback corrections AND validated non-obvious choices (with `**Why:**` and `**How to apply:**`), project decisions/deadlines (absolute dates), references to external systems
- **Don't save:** code patterns, file paths, git history, debugging recipes, anything in CLAUDE.md, ephemeral state
- **Verify before recommending** — memories can go stale; check the current state of the code or system before acting on a remembered fact

# Validation & Hooks Awareness

Validation runs in layers — rely on them rather than running checks manually:

1. **LSP (live):** typescript-lsp surfaces diagnostics as you edit — consult them after each edit instead of running `tsc` ad hoc
2. **`PostToolUse` → `biome.sh`:** auto-formats and lint-fixes edited files; unfixable lint errors come back as hook feedback — fix them before moving on. Include imports in the same edit as their usage (unused imports are auto-removed). When an import must temporarily exist before its consumer, add `// biome-ignore lint/correctness/noUnusedImports: <reason>` and remove the comment in the same edit that introduces the consumer.
3. **`Stop` → `stop-typecheck.sh`:** project-wide `tsc --noEmit` runs once at end of turn; failures block completion until types are clean. Don't end a turn expecting type errors to slide.

All hooks no-op for projects/file types they don't apply to. Don't run formatters/linters/type-checkers manually — the hooks handle them.
