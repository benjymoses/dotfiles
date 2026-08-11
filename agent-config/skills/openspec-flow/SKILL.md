---
name: openspec-flow
description: End-to-end spec-driven delivery loop. Takes a GitHub issue number, issue URL, or feature/bug description; classifies the work (Tier 0/1/2); for Tier 2 drives OpenSpec (spec-driven-plus schema) through proposal → specs → design → tasks → subagent/team-dispatched TDD apply; verifies, reviews, and closes the loop with a well-formed PR. Use when asked to "pick up issue #N", "start work on", "implement feature X", or any task that smells like a feature or non-trivial bug fix.
---

# OpenSpec Flow

Drive a piece of work from intake to merged-ready PR using OpenSpec for the
spec-driven middle. Relevant depth at every step, zero ceremony where it isn't
earning anything.

## 0. Intake

- If given an issue number/URL: `gh issue view <n>` — read title, body, labels,
  linked discussions. The issue is the "why"; distil it, don't restate it.
- If given a description: that's the brief.
- Restate the goal in one sentence and classify the tier. This table is the
  authoritative tier definition — match process weight to work size. If
  genuinely uncertain between tiers, ask once with `AskUserQuestion`; "go" /
  "looks good" means continue to the next step in the active tier, never skip
  steps.

| Tier | Scope | Route |
|---|---|---|
| 0 — typo / one-liner / <20 LOC | trivial, no decisions | Skip OpenSpec entirely. Ask branch-or-main (below), edit, verify, done (§7a only if on a branch and asked to PR). No worktree. |
| 1 — 1–3 files, clear scope | no architectural decisions | Skip OpenSpec. Ask branch-or-main (below), clarify anything ambiguous (1–2 questions max), implement directly with TDD where tests make sense, then §§5–7 (skip §7 if on main). No worktree. |
| 2 — multi-file / architectural / shared infra | anything framed as a feature | Full flow below. Always a feature branch + PR — never main. |

**Branch-or-main (Tier 0/1 only):** before touching any file, ask via
`AskUserQuestion`: work on a feature branch (then PR as usual) or directly on
the current branch/main? This is the sanctioned carve-out from the project's
never-push-to-main rule — it applies only when the user explicitly chooses
main here, and never to Tier 2. **On main, the commit itself is the user's:**
a non-bypassable main-guard hook denies agent `git commit` on main. Stage
everything, present the exact commit command with its conventional message,
and ask the user to run it (they can type `! git commit ...` in-session).

## 1. Setup (Tier 2)

- **Planning model:** planning artefacts (proposal, specs, design, tasks,
  ADRs) deserve the strongest model. Prompt the user to run `/model opus`
  before planning starts (the agent cannot switch models itself); suggest
  switching back to their usual model at the §4 approval gate, where
  implementation is delegated to subagents anyway. If they decline, continue
  on the session model.
- Ensure OpenSpec is initialised (`openspec/` exists); if not, run
  `openspec init` and set `schema: spec-driven-plus` in `openspec/config.yaml`.
- Create a plain feature branch (`feat/<n>-<slug>` or `fix/<n>-<slug>`).
  Planning (proposal → specs → design → tasks) happens here; the worktree is
  entered later, at apply (§4), only after the approval gate.
- Create the change: `openspec new change <kebab-name>`.

## 2. Proposal

- Run `openspec instructions proposal --change <name>` and follow it.
- Research before writing: existing specs (`openspec list --specs`), the
  affected code (dispatch `Agent(subagent_type=Explore)` for anything
  spanning >2 files), and `.claude/CONTEXT.md` references. For platform or
  library specifics (framework APIs, database features, hosting behaviour),
  consult the relevant docs MCP (Context7, Supabase, Vercel, …) rather than
  recalling from training — get implementation facts right at planning time.
- **Front-load the questions.** Collect every open decision the research
  surfaced — scope boundaries, UX choices, data-model options, naming,
  trade-offs — and ask them via `AskUserQuestion` in batched calls (max 4
  questions per call) BEFORE locking the artefact. The goal is a high-quality
  plan agreed up front, not a stream of mid-implementation clarifications.
  Repeat at each artefact (§2 proposal, §3 specs/design) as new decisions
  appear; by the §4 approval gate there should be nothing left to ask.
- JS/TS repos: check whether the affected area is already a known hotspot —
  `fallow health --format json --quiet 2>/dev/null || true` (see `fallow`
  skill for mechanics). High-complexity or heavily-duplicated targets are a
  scope signal: flag in the proposal's Impact section whether the change
  rides on top or should absorb a cleanup task.
- **Pause: present the proposal to the user for approval before continuing.**
  This is the cheap moment to be wrong.

## 3. Specs + Design

- `openspec instructions specs --change <name>` — every scenario must be
  concrete enough to become a test verbatim.
- Design doc only if the schema's criteria apply (cross-cutting, new
  dependency, security/perf/migration complexity, genuine ambiguity).
  For architectural decisions worth a diagram, update `.claude/diagrams/`.
- **ADRs:** any decision with genuine trade-offs (chosen X over Y for
  reasons that matter later) gets an ADR in `docs/adr/`, following the
  project's existing ADR format/numbering. Write it during design, commit it
  with the planning artefacts — don't defer it to close-out.
- Validate: `openspec validate <name>`. Fix what it flags.
- For substantial designs, offer the user a review pause; for routine ones,
  proceed.

## 4. Tasks + Apply

- `openspec instructions tasks --change <name>` — TDD groups
  (RED → GREEN → REFACTOR) with per-group **Verify** commands. Tag groups
  that are safe to run concurrently with `[batch: <id>]` — same id only for
  groups touching disjoint files with no dependency edge; default sequential.
- **Approval gate:** apply does not begin automatically. Summarise the task
  plan and get explicit human approval before any implementation.
- **Isolation:** after approval, move into a native worktree (`EnterWorktree`,
  `.claude/worktrees/`) for the apply work.
- **Worktree bootstrap (immediately after EnterWorktree):** confirm the
  project's `.env*` files arrived (a repo-root `.worktreeinclude` file copies
  them into native worktrees automatically — check file *names* only, never
  read contents; if missing, tell the user to add a `.worktreeinclude` rather
  than copying secrets by hand), then run the project's install command
  (`pnpm install` — fast, hardlinked from the store) so tests and builds work
  from the first task.
- **Dispatch (schema `apply` block is authoritative; this restates it):**
  - Non-trivial context-gathering → read-only `Agent(subagent_type=Explore)`.
  - Per task group, the main thread NEVER reviews its own writes: spawn a
    warm **implementer** subagent (`subagent_type=implementer` — the persona
    carries TDD method, incremental checkbox ticking, and `model: sonnet`;
    prefer background → resume via `SendMessage` to its `agentId`, never
    re-spawn fresh). When it reports done, dispatch
    `subagent_type=spec-validator` (haiku) and `subagent_type=code-reviewer`
    (sonnet) in parallel; iterate until both pass; main arbitrates, escalates
    to the human if it can't. Reviewers gate the commit — review first, then
    one conventional commit per group.
  - Groups sharing a `[batch:]` tag → an **agent team**, one implementer
    teammate per group (same `implementer` persona as teammate type).
    **Team mechanism (current):** there is no `TeamCreate` tool (removed in
    Claude Code v2.1.178) — a team auto-forms when the first teammate is
    spawned, gated by `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Each teammate
    prompt is self-contained (task text, context, success criteria, expected
    output — teammates don't inherit the lead's history). Verify each task's
    status is truly updated before unblocking dependents (teammate status can
    lag).
  - **Idle discipline:** teammate/subagent messages and completion
    notifications arrive automatically — after dispatching, end the turn and
    wait. NEVER poll, loop, or issue `sleep` commands to pass time (a
    sleep-guard hook denies busy-wait sleeps anyway).
  - **Models:** personas carry their own `model:` frontmatter. Generic spawns
    (Explore, Plan, ad-hoc agents) still pass `model: "sonnet"` (shorthand) —
    EU Bedrock needs region-prefixed model IDs (set via env vars); only the
    shorthand resolves correctly.
  - **Teardown:** after each group's commit, `TaskStop` every agent spawned
    for it (implementer + both reviewers; whole team for a batch). Never leave
    idle teammates running.
- Real-time validation is ambient (LSP, biome hook, Stop typecheck gate) —
  don't run formatters/linters manually.

## 5. Verify

- Run each group's Verify command, then the full test suite once.
- Use the `verify` skill (or playwright for UI) to confirm behaviour — the
  golden path of each spec scenario, not just unit tests.
- Check conformity: every spec scenario maps to a passing test; every task
  checkbox done; `openspec status --change <name>` shows complete.

## 6. Review

- Run the `code-review` skill on the diff (correctness + simplification).
  Apply fixes worth taking (`--fix` or manual judgement).
- JS/TS repos: audit the changed code —
  `fallow audit --format json --quiet --base <base-branch> 2>/dev/null || true`.
  Fix what the change itself introduced (new dead exports, new duplication,
  complexity spikes). Pre-existing findings in touched files are out of
  scope here — note them for a later `groom` pass, don't expand the diff.
- If review surfaces a spec-level problem, go back to §3 — don't patch
  around a wrong spec.

## 7. Close the loop — two segments across the merge boundary

The close-out spans local git, a PR, then a merge that happens on GitHub
(outside the agent's turn). Run it as two segments with a hard pause at the
PR.

### 7a. Push + PR (agent), then STOP

- Use the `commit-commands:commit-push-pr` skill. PR body must include:
  - `Closes #<issue>` when the work came from an issue
  - One-paragraph summary lifted from the proposal's Why
  - Link to the OpenSpec change directory for reviewers
  - Test plan: the Verify commands and what they prove
- **STOP here.** Merging is the human's action on GitHub. Do not `gh pr merge`
  unless the user explicitly asks. Tell the user the PR is up and you'll
  resume the close-out once it's merged.

### 7b. Merge-back + archive (resumed after merge)

When the user confirms the PR is merged:

- Exit the apply worktree first (`ExitWorktree`, remove) so you're back in
  the primary checkout — Tier 2 apply always runs in one.
- `git checkout main` → `git pull` → confirm the change is present in `main`
  (e.g. the merge commit / `Closes #N` shows, key files match).
- Delete the feature branch (local; the remote branch is usually auto-deleted
  on merge — delete it too if not).
- **Knowledge-capture pass (before archiving):** sweep for what the change
  taught us — memories to save or update, CLAUDE.md recommendations (propose,
  don't silently edit), ADRs still owed from §3, and updates to
  `docs/agents/*` (domain, issue-tracker) and `docs/diagrams/`. Make the doc
  edits now so they ride the archive commit.
- Run `/opsx:archive <name>`. **Archive handles sync itself** — it detects
  delta specs, shows a combined summary, and prompts to sync into
  `openspec/specs/` before moving the change to `changes/archive/`. Do NOT run
  `/opsx:sync` separately first; it's redundant in the close-out (sync alone
  is only for updating main specs *without* archiving). Let archive's built-in
  prompts gate sync and any incomplete-artifact/task warnings.
- The archived change + knowledge-capture edits land directly on `main` as
  one conventional commit (e.g. `docs(openspec): archive <name>`) — the
  second sanctioned carve-out, covering only the archive/doc-capture commit,
  never implementation code. **The commit is the user's:** the non-bypassable
  main-guard hook denies agent `git commit` on main. Stage everything, present
  the exact commit + push commands, and ask the user to run them
  (`! git commit ...` in-session works).

## Rules

- Never skip the proposal pause in Tier 2 — user approval gates implementation.
- Never improvise around a spec that turns out wrong; surface it.
- Keep every artifact at the depth the schema instruction demands and no more.
- **`openspec ... --json` output is consumed directly — never pipe it.** The
  `--json` flag is deliberate: these commands return structured fields
  (`contextFiles`, `resolvedOutputPath`, progress, `actionContext`) that must
  be parsed reliably, so always keep it. But read the JSON yourself — do NOT
  pipe it through `python`/`python3 -c`/`jq`/`node`/any interpreter to
  reformat it. Inline interpreter invocations are arbitrary code execution
  that trip the permission gate on every call and add nothing: you parse JSON
  natively and summarise in prose without a helper. Run openspec commands
  bare, as single (non-compound) invocations.

## References

The `openspec` CLI ships single-purpose skills for each step of the change
lifecycle. This flow is the orchestration layer over them; reach for a
reference file when you need the mechanics of one specific step. They live in
`references/` alongside this skill (mirrors of the upstream `openspec` skills,
vendored so the flow is self-contained).

- [references/new-change.md](references/new-change.md) — starting a new change step-by-step; read when creating a change and stepping through artifacts one at a time.
- [references/propose.md](references/propose.md) — generate a full proposal (proposal + design + specs + tasks) in one shot; read when the user wants everything scaffolded at once rather than stepwise.
- [references/continue-change.md](references/continue-change.md) — create the next artifact in an in-progress change; read when resuming a change and unsure which artifact comes next.
- [references/ff-change.md](references/ff-change.md) — fast-forward through all remaining artifacts to reach implementation quickly; read when the user wants to skip the per-artifact pauses.
- [references/explore.md](references/explore.md) — explore-mode thinking partner for investigating ideas/requirements before or during a change; read when clarifying scope before committing to specs.
- [references/apply-change.md](references/apply-change.md) — implement the tasks of a change; read for the mechanics of working through the task list (the spec-driven-plus `apply` block is authoritative for dispatch).
- [references/verify-change.md](references/verify-change.md) — validate implementation matches the artifacts before archiving; read during §5 Verify to check completeness and coherence.
- [references/sync-specs.md](references/sync-specs.md) — sync delta specs into main specs WITHOUT archiving; read only when updating main specs standalone (in close-out, archive handles sync — don't call this).
- [references/archive-change.md](references/archive-change.md) — finalise and archive a completed change; read during §7b close-out (archive prompts for sync itself).
- [references/bulk-archive-change.md](references/bulk-archive-change.md) — archive several completed changes at once; read when clearing multiple parallel changes together.
- [references/onboard.md](references/onboard.md) — guided walk through a full OpenSpec cycle with narration; read when onboarding a repo or learning the workflow end-to-end.
