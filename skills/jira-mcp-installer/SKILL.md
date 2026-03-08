---
name: jira-mcp-installer
description: >
  Installs and registers the jira-mcp servers from scratch for Claude Code and/or Codex.
  Use this skill whenever someone wants to set up this repo as an MCP server, bootstrap a
  fresh jira-mcp install, wire the full server plus minimal servers into Claude Code or
  Codex, repair a broken jira-mcp registration, or re-run setup after pulling new changes.
  Also trigger for: "install jira mcp", "set up jira-mcp for claude", "set up jira-mcp for
  codex", "register jira mcp", "repair jira mcp config", or "make this repo available as
  an MCP server".
---

# Jira MCP Installer

This skill installs the repo dependencies, collects Jira credentials if needed, optionally
persists them to `~/.jira-mcp.env`, registers the MCP entries for Claude Code and/or Codex,
and runs offline smoke checks.

By default, this skill performs a global MCP installation:

- Claude Code: user scope
- Codex: user-level MCP registration

That makes the servers available across projects on the same machine.

This skill is not for project-local MCP installation. If the user wants a local/project-only
setup, explain the difference and switch to manual project-scoped MCP config instead of
running this installer.

## Agent Rules

- If the user points you at this skill on GitHub, open these exact files first:
  - `skills/jira-mcp-installer/SKILL.md`
  - `skills/jira-mcp-installer/scripts/setup.sh`
- Before running the installer, inspect the current folder. If it is not the `jira-mcp`
  repo, clone or open the repo first, then run the local installer script from that checkout.
- This matters when the user points to `skills/jira-mcp-installer/SKILL.md` on GitHub: you
  may be able to read the skill remotely before the repo exists locally, but you still must
  create or open a local `jira-mcp` checkout before running `scripts/setup.sh`.
- Always run `scripts/setup.sh`. Do not hand-edit Claude or Codex MCP config files.
- Be explicit about installation scope before running the script:
  - "global install" means user-level MCP registration shared across projects
  - "local install" means project-scoped MCP config for one repo only
- Check whether `JIRA_BASE_URL`, `JIRA_EMAIL`, and `JIRA_API_TOKEN` are already set before
  asking the user for credentials. Only ask for values that are actually missing.
- Prefer `--client both` when both `claude` and `codex` are installed.
- Surface the script's exact failure message instead of improvising fallback commands.
- If the script fails, stop and report the exact failure. Do not improvise manual MCP
  registration commands.
- Do not write raw tokens directly into `.zshrc` or `.bashrc`. If the user wants persistence,
  use `~/.jira-mcp.env` and optionally source that file from the shell rc.

## Required Inputs

The setup script accepts these environment variables:

- `JIRA_BASE_URL`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

Optional:

- `CONFLUENCE_BASE_URL`
  Defaults to `JIRA_BASE_URL/wiki`.

If they are missing and the script is running interactively, it prompts for them and shows
the Atlassian token page URL:

- `https://id.atlassian.com/manage-profile/security/api-tokens`

The script mirrors Jira credentials to the Confluence/report servers automatically, so the
user does not need separate `ATLASSIAN_*` variables for installation.

## Step 1

First, inspect the current working folder.

If you are already inside the `jira-mcp` repo, confirm it with these checks:

- `package.json` exists and contains `"name": "jira-mcp"`
- `scripts/minimal-server.mjs` exists
- `src/index.ts` exists

If you are not inside the repo, stop and get the repo onto disk first by cloning it or by
switching to an existing local checkout. Only after that should you run the installer script.

Then run the setup script from the skill directory:

```bash
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client both
```

If you are reading this skill remotely from GitHub, clone or open the repo locally first,
then run the same local script path from that checkout.

Useful variants:

```bash
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client claude
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client codex
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client both --dry-run
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client both --persist-env
bash /path/to/skills/jira-mcp-installer/scripts/setup.sh --client both --source-shell-rc
```

What the script does:

1. Validates `node`, `npm`, and the selected client CLIs
2. Collects Jira credentials if they are missing
3. Runs `npm install`
4. Runs `npm run build`
5. Re-registers these MCP servers in user/global scope:
   - `jira-mcp`
   - `jira-min`
   - `confluence-min`
   - `reports-min`
6. Verifies the built server and the three minimal servers by listing tools over stdio
7. Optionally stores credentials in `~/.jira-mcp.env` and optionally adds a source line to
   the user's shell rc

## Step 2

After the script succeeds, tell the user to restart Claude Code or Codex if the new MCPs do
not appear immediately.

## Expected Outcome

- `jira-mcp` exposes the full read-only server from `dist/index.js`
- `jira-min` exposes the 12-tool minimal Jira/Confluence server
- `confluence-min` exposes `confluence_search_pages`
- `reports-min` exposes the 3 reporting tools
- The registrations are user-level, not project-local

## Scope

Use this skill when the user wants the MCP servers available across projects on their
machine.

Do not use this skill when the user explicitly wants:

- project-local MCP config
- repo-scoped registration only
- a config file committed inside another repository

In those cases, explain that this installer is global/user-level and use manual local MCP
configuration instead.

## Troubleshooting

### Missing CLI

- If `claude` is missing, install Claude Code first.
- If `codex` is missing, install Codex CLI first.
- If the user only wants one client, rerun with `--client claude` or `--client codex`.

### Missing credentials

If the script is running in a real terminal, it prompts for `JIRA_BASE_URL`, `JIRA_EMAIL`,
and `JIRA_API_TOKEN`. If it is running non-interactively, provide those env vars up front.

The Atlassian API token page is:

- `https://id.atlassian.com/manage-profile/security/api-tokens`

### MCP registered but not visible

Restart the client. Registration is done by CLI, but some sessions cache the MCP list.

### Update after pulling new repo changes

Rerun the same script. It is idempotent and replaces the existing `jira-mcp` entries.
