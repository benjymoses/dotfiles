# Service Wiring Matrix

Per-service wiring for step 2b. Columns map to the four mechanisms in
SKILL.md (plugins by reference, MCP via committed `.mcp.json`, skills
vendored as raw files, sandbox/permission additions merged into project
`.claude/settings.json`).

Verify exact plugin names against the marketplace and MCP server
commands/URLs against the provider's current docs before writing config —
do not trust this table blindly; correct it here when it drifts.

| Service | Detection signal | Plugin (enable by reference) | MCP server (`.mcp.json`) | Skills to vendor | Sandbox domains |
|---|---|---|---|---|---|
| Vercel | `vercel.json`, `.vercel/`, `next` in deps | `vercel@claude-plugins-official` | — (plugin provides tooling) | — | `api.vercel.com`, `vercel.com` |
| Supabase | `@supabase/*` in deps, `supabase/` dir | `supabase@claude-plugins-official` | — (plugin bundles MCP) | — | project API host (`*.supabase.co`), `api.supabase.com` |
| AWS (general) | `aws-sdk`/`@aws-sdk/*` in deps, `template.yaml`, `cdk.json`, `amplify/` | — (none official; CLI via Bash) | `awslabs.aws-documentation-mcp-server` (uvx) — confirm current name in awslabs/mcp repo | — | the service endpoints actually used (e.g. `*.amazonaws.com` region hosts) — keep narrow |
| AWS AgentCore | `bedrock-agentcore` in deps, AgentCore config | — | `awslabs.amazon-bedrock-agentcore-mcp-server` (uvx) — confirm current name in awslabs/mcp repo | — | Bedrock/AgentCore regional endpoints |
| Swift | `Package.swift`, `*.xcodeproj` | `swift-lsp@claude-plugins-official` | — | — | — |

## Notes

- **Empty cell = nothing to do** for that artifact type; a service rarely
  needs all four.
- **Plugins deliberately disabled globally** (vercel, supabase, swift-lsp)
  are the main reason this step exists — per-project enablement is the
  designed pattern.
- **MCP `.mcp.json` shape** (project root, committed):

  ```json
  {
    "mcpServers": {
      "<name>": {
        "command": "uvx",
        "args": ["<package>@latest"]
      }
    }
  }
  ```

  Merge with any existing file. Env-dependent values (API keys) go via
  `env` referencing variables, never literals committed to the repo.
- **Vendored skill provenance**: add `metadata: { vendoredFrom: <source>,
  vendoredVersion: <version-or-sha>, vendoredDate: <date> }` to the
  vendored SKILL.md frontmatter.
- **Adding a service**: one row here + whatever notes it needs. No
  SKILL.md or description change required.
