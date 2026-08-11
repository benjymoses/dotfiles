---
name: fallow
description: Run the fallow CLI for JS/TS codebase intelligence — dead code, duplication, complexity, circular deps, boundary violations, PR risk audits, auto-fixes. Prefer the groom skill for full grooming sweeps; use this for direct/ad-hoc fallow runs.
---

# Fallow (shim)

This is a dotfiles-managed shim that keeps the always-loaded description
small. The full, upstream-maintained command reference lives at
`~/.agents/skills/fallow/SKILL.md`.

**Before running any fallow command:** Read `~/.agents/skills/fallow/SKILL.md`
in full and follow its Agent Rules, command tables, and gotchas exactly
(JSON output flags, `|| true` exit-code handling, trace-before-delete,
never `watch`, telemetry untouched). Consult its `references/` directory
(cli-reference.md, gotchas.md, patterns.md) when the task needs depth.

If that upstream file is missing, the fallow skill install has moved or
been removed — tell the user rather than improvising commands.
