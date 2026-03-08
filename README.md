# jira + confluence mcp servers (cloud)

simple, stdio-based mcp servers for atlassian jira and confluence (cloud, api token auth). no webhooks. focus on issue search, boards, and confluence search, plus a minimal "reports" server for daily briefs.

---

## example: ai-powered dependency analysis

turn complex jira tickets into actionable implementation plans in 3 simple steps:

![95wlim95wlim95wl](https://github.com/user-attachments/assets/4c6bf137-ac3b-4558-9430-f906f9c4a1cd)

### step 1: analyze jira dependencies

in gemini cli, paste:
```
run dependency analysis on DMD-11937 with:
- depth: 3
- include confluence docs updated in last 12 months
- save to jira_analysis.json
```

**what you get:** jira ticket context, dependency graph, blocker analysis, confluence docs, and a ready-to-use prompt for code analysis

### step 2: analyze related code

copy the `suggested_prompt` from `jira_analysis.json` (replace `{{YOUR_GITHUB_ORG}}` and `{{YOUR_GITHUB_REPO}}`), then paste it into claude or gemini in your repository.

**note:** tell the ai to wait if it hits github rate limits - accuracy over speed for this report.

**what you get:** related prs, commits, implementation patterns, cross-repo dependencies with confidence scores - saved to `code_analysis.json`

### step 3: synthesize implementation plan

in claude or gemini, run the synthesis prompt:
```
use the SYNTHESIS_PROMPT.md template with @jira_analysis.json and @code_analysis.json
```

**what you get:**
- **tech lead context**: executive summary, effort estimate, risk assessment
- **developer guide**: step-by-step implementation plan with code examples, testing strategy, deployment plan
- **correlation analysis**: confidence-scored matches between jira context and code findings

**output:** `synthesis_analysis.json` - ready to paste into ticket descriptions or hand to developers

---

## quick setup

### prerequisites
- node.js 18+
- atlassian cloud email + api token ([create one here](https://id.atlassian.com/manage-profile/security/api-tokens))

### install

```bash
git clone https://github.com/your-org/jira-mcp.git
cd jira-mcp
npm install
npm run build
```

### recommended: install with your llm

point your agent to `skills/jira-mcp-installer/SKILL.md`.

the installer skill collects your jira credentials, builds the project, configures the mcp servers, and runs offline verification.

this is a global mcp installation: the script registers the servers in your user-level claude/codex config so they are available across projects.

if you want a local mcp installation instead, do not use the installer skill. add the server entries manually in a project-scoped mcp config.

### manual mcp client configuration (fallback)

if not using gemini cli, add to your mcp client config (claude desktop, cline, etc.):

```json
"mcpServers": {
  "jira-min": {
    "command": "node",
    "args": ["/absolute/path/to/jira-mcp/scripts/minimal-server.mjs"],
    "cwd": "/absolute/path/to/jira-mcp",
    "transport": "stdio",
    "env": {
      "JIRA_BASE_URL": "https://your-site.atlassian.net",
      "JIRA_EMAIL": "you@example.com",
      "JIRA_API_TOKEN": "your-api-token"
    }
  }
}
```

**important:** use absolute paths, not relative paths.

---
