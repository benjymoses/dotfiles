---
name: openspec-flow
description: End-to-end spec-driven delivery loop. Takes a GitHub issue number, issue URL, or feature/bug description; classifies the work (Tier 0/1/2); for Tier 2 drives OpenSpec (ben-flow schema) through proposal → specs → design → tasks → team-dispatched TDD apply; verifies, reviews, and closes the loop with a well-formed PR. Use when asked to "pick up issue #N", "start work on", "implement feature X", or any task that smells like a feature or non-trivial bug fix.
---

# OpenSpec Flow

Drive a piece of work from intake to merged-ready PR using OpenSpec for the
spec-driven middle. Relevant depth at every step, zero ceremony where it isn't
earning anything.

## 0. Intake

- If given an issue number/URL: `gh issue view <n>` — read title, body, labels,
  linked discussions. The issue is the "why"; distil it, don't restate it.
- If given a description: that's the brief.
- Restate the goal in one sentence and classify the tier (see CLAUDE.md
  Workflow Tiering). If genuinely uncertain, ask once with `AskUserQuestion`.

| Tier | Route |
|---|---|
| 0 — typo / one-liner | Skip OpenSpec entirely. Edit, verify, done (step 6 only if asked to PR) |
| 1 — 1–3 files, clear scope | Skip OpenSpec. Branch, implement directly with TDD where tests make sense, then steps 5–7 |
| 2 — multi-file / architectural / feature | Full flow below |

## 1. Setup (Tier 2)

- Ensure OpenSpec is initialised (`openspec/` exists); if not, run
  `openspec init` and set `schema: ben-flow` in `openspec/config.yaml`.
- For work on an existing repo with in-flight changes, prefer a worktree:
  `EnterWorktree` (never manual `git worktree add` to sibling paths).
- Create the change: `openspec new change <kebab-name>`.

## 2. Proposal

- Run `openspec instructions proposal --change <name>` and follow it.
- Research before writing: existing specs (`openspec list --specs`), the
  affected code (dispatch `Agent(subagent_type=Explore)` for anything
  spanning >2 files), and `.claude/CONTEXT.md` references.
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
- **Dispatch (schema `apply` block is authoritative; this restates it):**
  - Non-trivial context-gathering → read-only `Agent(subagent_type=Explore)`.
  - Per task group, the main thread NEVER reviews its own writes: spawn a
    warm **implementer** subagent (prefer background → resume via `SendMessage`
    to its `agentId`, never re-spawn fresh) following TDD, then dispatch an
    independent **spec validator** and **code reviewer** in parallel; iterate
    until both pass; main arbitrates, escalates to the human if it can't.
  - Groups sharing a `[batch:]` tag → an **agent team**, one implementer
    teammate per group (teams auto-form; no `TeamCreate`). Verify task status
    is truly updated before unblocking dependents.
  - `model: "sonnet"` (shorthand) on every spawn. One conventional commit per
    task group. Mark checkboxes as you go.
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
- If review surfaces a spec-level problem, go back to step 3 — don't patch
  around a wrong spec.

## 7. GitOps — close the loop

- Use the `commit-commands:commit-push-pr` skill. PR body must include:
  - `Closes #<issue>` when the work came from an issue
  - One-paragraph summary lifted from the proposal's Why
  - Link to the OpenSpec change directory for reviewers
  - Test plan: the Verify commands and what they prove
- After the PR merges (or when the user says so): `openspec archive <name>`
  to fold delta specs into `openspec/specs/`.

## Rules

- Never skip the proposal pause in Tier 2 — user approval gates implementation.
- Never improvise around a spec that turns out wrong; surface it.
- Keep every artifact at the depth the schema instruction demands and no more.
