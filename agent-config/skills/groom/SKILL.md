---
name: groom
description: Fallow-based grooming sweep for JS/TS repos — full static analysis, triage into tiered work, land safe mechanical fixes, route structural refactors into openspec-flow. Use for "groom the codebase", tech-debt sweeps, dead-code cleanup, or a pre-release hygiene pass.
---

# Groom

A grooming pass turns fallow's raw findings into tiered, actionable work.
Mechanical fixes land immediately; opinionated refactors are held for the
user and routed through openspec-flow. Defer to the `fallow` skill for all
command mechanics (JSON flags, exit codes, trace tools, gotchas).

## 0. Preconditions

- JS/TS project (skip otherwise — say so and stop).
- Clean working tree, or at least no unstaged changes in files fallow might
  touch — grooming commits must not entangle in-flight work.
- fallow available (`which fallow` or fall back to `pnpx fallow`).

## 1. Sweep

Run the full analysis (cleanup + duplication + health):

```bash
fallow --format json --quiet 2>/dev/null || true
```

For monorepos, sweep whole by default; scope with `--workspace` only if the
user named one.

## 2. Triage

Sort every finding into exactly one bucket:

| Bucket | Findings | Route |
|---|---|---|
| **Mechanical** | unused exports/types/enum-and-class members, unused deps, stale suppressions | Land now (step 3) |
| **Surgical** | unused files, circular deps with an obvious break point, test-only deps → devDependencies | Land per-item after trace verification (step 3) |
| **Structural** | duplication clusters, complexity hotspots (rank by CRAP/cognitive), boundary violations, re-export cycles | Hold — present shortlist (step 4) |

Findings that look like false positives (framework magic, dynamic loading)
get a suggested inline suppression or config rule, not a fix.

## 3. Land mechanical + surgical

- **Verify first**: anything being deleted gets a trace
  (`--trace`, `--trace-file`, `--trace-dependency`) before removal.
  `used_in_workspaces` non-empty means placement issue, not removal.
- **Preview**: `fallow fix --dry-run`, show the user the summary, then
  `fix --yes`. Manual deletions (files) shown as a list before acting.
- **Prove**: re-run fallow to confirm findings cleared, then run the test
  suite once. Ambient hooks handle lint/types.
- **Commit separately**: grooming changes go in their own commit(s), never
  mixed with feature work. Suggested shape: `chore: groom — remove N unused
  exports, M dead files`.

## 4. Present structural shortlist

For the held bucket, present a ranked shortlist (top 5 max) via
`AskUserQuestion` (multiSelect): each entry names the finding, the evidence
(clone group size / complexity score), and a one-line refactor sketch
(use `trace_clone` suggestions for dupes). For each item the user accepts:

- Estimate tier per CLAUDE.md Workflow Tiering.
- Tier 1 → implement directly in this session (TDD where tests make sense).
- Tier 2 → hand to the `openspec-flow` skill as a fresh brief (the finding
  + evidence is the intake description), or `gh issue create` if the user
  prefers batching for later.

## 5. Report

Close with a short summary: counts per bucket, what landed (commits), what
was proposed and where it went (openspec change / issue / declined), and
any suppressions suggested. A clean sweep ("nothing worth doing") is a
valid outcome — do not invent work.

## Rules

- Never delete or fix without trace verification and a dry-run preview.
- Never auto-apply structural refactors — they are opinionated; the user
  decides.
- Respect the fallow skill's Agent Rules (JSON output, `|| true`, no
  `watch`, telemetry stays untouched).
- One grooming pass per invocation; don't loop on the residue.
