# TypeScript Stack Tooling

Bring the project up to the standard TypeScript + Biome setup. Assess each
section first, then act on what's missing.

## 1. Assess

| Item | How to check |
|------|-------------|
| `package.json` | File exists in cwd |
| `"type": "module"` | `type` field in package.json is `"module"` |
| TypeScript installed | `devDependencies.typescript` in package.json |
| `tsconfig.json` | File exists in cwd |
| Biome installed | `devDependencies["@biomejs/biome"]` in package.json |
| `biome.json` / `biome.jsonc` | Either file exists in cwd |
| Required scripts | `typecheck`, `format`, `lint`, `lint:fix` in package.json `scripts` |
| Claude stop hook | Project `.claude/settings.json` has a `Stop` hook containing `typecheck` |

## 2. package.json

If missing, create it:
```bash
pnpm init
```

Ensure `"type": "module"`. If the field is missing or set to `"commonjs"`,
patch it to `"module"`. Read the file and merge — don't overwrite
unrelated config.

## 3. TypeScript

If `typescript` is not in devDependencies:
```bash
pnpm add -D typescript
```

If `tsconfig.json` doesn't exist, generate the default and then patch it:
```bash
tsc --init
```

After generating, patch these compiler options (preserve any others):

| Option | Value | Notes |
|--------|-------|-------|
| `strict` | `true` | Enable all strict type-checking options |
| `outDir` | `"./dist"` | Compiled output directory |
| `module` | `"nodenext"` | ESM-compatible module resolution |
| `moduleResolution` | `"nodenext"` | Pairs with `module: "nodenext"` |

If `tsconfig.json` already existed before this run, do NOT overwrite these
options — the project may have intentional settings. Only patch a
pre-existing tsconfig if the user explicitly asks.

## 4. Biome

If `@biomejs/biome` is not in devDependencies:
```bash
pnpm add -D @biomejs/biome
```

If no `biome.json` or `biome.jsonc` exists:
```bash
biome init
```

Then patch the `files` section to lint/format everything except build
output. Read the current file and merge — don't overwrite unrelated config:

```json
{
  "files": {
    "include": ["**", "!dist/**", "!build/**"]
  }
}
```

If `files.include` already exists, patch it with the array above.

## 5. Package scripts

Read `package.json` and add any missing scripts. Don't touch existing ones.

| Script | Command |
|--------|---------|
| `typecheck` | `tsc --noEmit` |
| `format` | `biome format --write .` |
| `lint` | `biome check .` |
| `lint:fix` | `biome check . --write --unsafe` |

## 6. Claude stop hook

Prevents a session ending with TypeScript errors. Create or update
`.claude/settings.json` in the **project directory** (not
`~/.claude/settings.json`).

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
- Exit code `2` — typecheck failed, stop is **blocked** until errors are fixed
- `timeout: 60` — allows up to 60 seconds for large projects
- `statusMessage` — spinner message while the hook runs

If `.claude/settings.json` already exists, merge the Stop hook in,
preserving all existing configuration. Only add it if no existing Stop
hook command contains `typecheck`. Note: the global harness already runs
`stop-typecheck.sh` — if the project relies on the global hook, this
per-project hook is redundant; skip it and say so.

## 7. .gitignore

If no `.gitignore` exists, create it. Patch to include the following
without duplicating entries (read and merge, don't overwrite):

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
```
