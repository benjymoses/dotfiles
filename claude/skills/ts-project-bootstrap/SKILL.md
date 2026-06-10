---
name: ts-project-bootstrap
description: Bootstrap or audit a TypeScript project's tooling setup. Use this skill whenever the user asks to set up, initialise, or audit a TypeScript project — even if they just say "bootstrap this", "get this project set up", "make sure TypeScript and linting are configured", or "add Biome to this project". This skill sets up TypeScript, Biome (linter/formatter), the correct npm scripts, and a Claude stop hook that blocks when there are TypeScript errors. Trigger this whenever the user mentions TypeScript project setup, Biome configuration, missing tsconfig, or wants to ensure a project is properly tooled.
---

# TypeScript Project Bootstrap

Audit the current project directory and bring it up to a standard TypeScript + Biome setup. Work through each section in order — assess first, then act on what's missing.

Keep track of every file you create or modify throughout the process — you'll need this list for the git commit at the end.

## 1. Assess the project

Read `package.json` (if it exists) and check the filesystem for config files. Build a picture of what's present vs missing:

| Item | How to check |
|------|-------------|
| `package.json` | File exists in cwd |
| `"type": "module"` | `type` field in package.json is `"module"` |
| TypeScript installed | `devDependencies.typescript` in package.json |
| `tsconfig.json` | File exists in cwd |
| Biome installed | `devDependencies["@biomejs/biome"]` in package.json |
| `biome.json` / `biome.jsonc` | Either file exists in cwd |
| Required scripts | `typecheck`, `format`, `lint`, `lint:fix` in package.json `scripts` |
| Claude stop hook | `.claude/settings.json` exists with a `Stop` hook containing `typecheck` |

Print a clear summary of what's present and what's missing before taking any action.

## 2. Set up package.json

If `package.json` is missing, create it:
```bash
pnpm init
```

Ensure `package.json` has `"type": "module"`. If the field is missing or set to `"commonjs"`, patch it to `"module"`. Read the file and merge — don't overwrite unrelated config.

## 3. Set up TypeScript

If `typescript` is not in devDependencies:
```bash
pnpm add -D typescript
```

If `tsconfig.json` doesn't exist, generate the default and then patch it:
```bash
tsc --init
```

After generating `tsconfig.json`, read it and patch the following compiler options (preserve any other options already set):

| Option | Value | Notes |
|--------|-------|-------|
| `strict` | `true` | Enable all strict type-checking options |
| `outDir` | `"./dist"` | Compiled output directory |
| `module` | `"nodenext"` | ESM-compatible module resolution |
| `moduleResolution` | `"nodenext"` | Pairs with `module: "nodenext"` |

If `tsconfig.json` already existed before this skill ran, do NOT overwrite these options — the project may have intentional settings. Only patch a pre-existing tsconfig if the user explicitly asks.

## 4. Set up Biome

If `@biomejs/biome` is not in devDependencies:
```bash
pnpm add -D @biomejs/biome
```

If no `biome.json` or `biome.jsonc` exists:
```bash
biome init
```

After ensuring `biome.json` exists, patch the `files` section to lint/format everything except build output. Read the current file and merge — don't overwrite unrelated config:

```json
{
  "files": {
    "include": ["**", "!dist/**", "!build/**"]
  }
}
```

If `files.include` already exists, patch it with the array above.

## 5. Add package scripts

Read `package.json` and add any missing scripts. Don't touch existing scripts.

| Script | Command |
|--------|---------|
| `typecheck` | `tsc --noEmit` |
| `format` | `biome format --write .` |
| `lint` | `biome check .` |
| `lint:fix` | `biome check . --write --unsafe` |

## 6. Set up the Claude stop hook

This hook prevents Claude from finishing a task when TypeScript errors are present — keeping the project in a valid state at the end of every session.

Create or update `.claude/settings.json` in the **project directory** (not `~/.claude/settings.json`).

If the file doesn't exist, create `.claude/` and write:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pnpm run typecheck 2>&1; if [ $? -ne 0 ]; then exit 2; fi",
            "timeout": 60,
            "statusMessage": "Checking for TypeScript errors..."
          }
        ]
      }
    ]
  }
}
```

Hook behaviour:
- `matcher: ""` — fires on every stop, regardless of reason
- Exit code `0` — typecheck passed, stop is allowed
- Exit code `2` — typecheck failed, stop is **blocked** and Claude must fix the errors before finishing
- `timeout: 60` — allows up to 60 seconds for large projects
- `statusMessage` — shows a spinner message while the hook runs

If `.claude/settings.json` already exists, read it and merge the Stop hook in — preserving all existing configuration. Only add the hook if no existing Stop hook command contains `typecheck`.

## 7. Git repository

If no `.gitignore` exists:
```bash
touch .gitignore
```

After ensuring `.gitignore` exists, patch it to include the following without duplicating entries. Read the current file and merge in the changes — don't overwrite existing values:

```text
# dependencies
node_modules
/.pnp
.pnp.*
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/versions

# testing
/coverage

# build output
/dist
/build

# misc
.DS_Store
*.pem

# env files (can opt-in for committing if needed)
.env*

# typescript
*.tsbuildinfo

# skills
.superpowers/
```

If there is no `.git` folder and no Git repository, initialise it with:
```bash
git init
```

Commit only the files that were created or modified during this process. Build the `git add` command from the list of files you tracked:

```bash
git add <files created or modified during this process>
git commit -m "chore(ts-bootstrap): add TypeScript and Biome tooling"
```

Do NOT use `git add .` or `git add -A` — only add files this skill touched.

## 8. Summary

After all steps, print a concise summary of:
- What was already present (skipped)
- What was installed, created, or patched
