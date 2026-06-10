---
name: bootstrap-project
description: Bootstrap or audit a project's harness conventions, service wiring, and stack tooling. Lays down .claude/CONTEXT.md, OpenSpec (ben-flow), diagrams dir; wires selected/detected services (Vercel, Supabase, AWS…) via per-project plugins, .mcp.json, vendored skills; applies stack tooling from references (TypeScript — tsc strict, Biome, pnpm scripts). Use for "bootstrap this", "set up / initialise / audit this project", "add Biome", "make sure TypeScript and linting are configured", or retrofitting conventions onto an existing repo.
---

# Bootstrap Project

Bring a project — greenfield or existing — up to the standard harness
conventions plus stack-appropriate tooling. Idempotent: assess first,
report the gaps, then fix only what's missing. Never overwrite intentional
existing config.

Track every file created or modified — the commit at the end adds exactly
those files, never `git add .`.

## 1. Assess

Build a gap report before acting:

| Item | How to check |
|---|---|
| Stack | Lockfiles/manifests (`package.json` + tsconfig → TypeScript; `pyproject.toml` → Python; etc.). If ambiguous or greenfield, ask once with `AskUserQuestion` |
| Git repo | `.git/` exists |
| `.claude/CONTEXT.md` | Exists and indexes any `references/` files |
| `.claude/diagrams/` | Exists (only expected where architecture warrants it) |
| OpenSpec | `openspec/` exists; `openspec/config.yaml` has `schema: ben-flow` |
| Services | Detected in deps/config (Vercel, Supabase, AWS…) but missing their per-project wiring per `references/services.md` |
| `.worktreeinclude` | Present when the project needs untracked files (`.env`-style) inside worktrees |
| Stack tooling | Per the matching reference file below |

Print the report (present / missing / not applicable), then act on the
missing items. In an existing repo, treat anything deliberate-looking as
intentional and flag rather than change it.

## 2. Harness conventions (stack-agnostic)

- **Git**: `git init` if absent.
- **`.claude/CONTEXT.md`**: create with current project state (one short
  paragraph) and an index section for reference files. The SessionStart
  hook injects it every session — keep it lean. Diagrams get an index line
  (`- [architecture](diagrams/architecture.mmd) — read before structural
  changes`), read on demand; only inline a small diagram directly when the
  topology matters every session.
- **`.claude/diagrams/`**: create only if the project has (or will have)
  architecture worth diagramming — Mermaid format.
- **OpenSpec**: `openspec init` if missing; ensure `schema: ben-flow` in
  `openspec/config.yaml`.
- **`.worktreeinclude`**: offer when untracked env files exist.

## 2b. Services

Read `references/services.md` for the service → wiring matrix, then:

- **Existing repos**: detection is primary — wire up what the deps/config
  show. Ask only about ambiguous or planned-but-not-yet-added services.
- **Greenfield**: ask once with `AskUserQuestion` (multiSelect) which
  services the project will use, options drawn from the matrix.

For each selected/detected service apply its row from the matrix. The
mechanism differs by artifact type — never mix them up:

| Artifact | Mechanism |
|---|---|
| Plugins | Enable by reference in project `.claude/settings.json` `enabledPlugins` (merge). Never vendor plugin content into the repo |
| MCP servers | Committed `.mcp.json` at project root (merge with existing) |
| Skills | Vendor as raw files committed in `.claude/skills/<name>/` — never symlinks (break for collaborators/CI). Note source + version in the vendored SKILL.md frontmatter so a later re-run can diff against upstream and offer a refresh |
| Sandbox/permissions | Add the service's domains/paths to project `.claude/settings.json` (merge) to pre-empt first-run friction prompts |

## 3. Stack tooling

Read the matching reference and apply it in full:

| Stack | Reference |
|---|---|
| TypeScript / Node | `references/typescript.md` |
| (others) | No reference yet — say so, set up harness conventions only, and suggest adding a reference file for the stack |

## 4. Commit + summary

Commit only the tracked file list:
`chore(bootstrap): harness conventions + <stack> tooling` (adjust to what
was actually done). Then print a concise summary: present/skipped,
created/patched, and any flagged-but-untouched items.
