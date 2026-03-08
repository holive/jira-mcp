# jira + confluence mcp servers (cloud)

Simple, stdio-based MCP servers for Atlassian Jira and Confluence (cloud, API token auth). No webhooks. Focus on issue search, boards, and Confluence search, plus a minimal "reports" server for daily briefs.

---

## quick setup

### prerequisites
- Node.js 18+
- Atlassian Cloud email + API token ([create one here](https://id.atlassian.com/manage-profile/security/api-tokens))

### install

```bash
git clone https://github.com/your-org/jira-mcp.git
cd jira-mcp
npm install
npm run build
```

### recommended: install with your llm

Point your agent to `skills/jira-mcp-installer/SKILL.md`.

The installer skill collects your Jira credentials, builds the project, configures the MCP servers, and runs offline verification.

This is a global MCP installation: the script registers the servers in your user-level Claude/Codex config so they are available across projects.

If you want a local MCP installation instead, do not use the installer skill. Add the server entries manually in a project-scoped MCP config.

### manual mcp client configuration (fallback)

If not using Gemini CLI, add to your MCP client config (Claude Desktop, Cline, etc.):

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

**Important:** Use absolute paths, not relative paths.

---

## example: ai-powered dependency analysis

Turn complex Jira tickets into actionable implementation plans in 3 simple steps:

![95wlim95wlim95wl](https://github.com/user-attachments/assets/4c6bf137-ac3b-4558-9430-f906f9c4a1cd)

### step 1: analyze jira dependencies

In Gemini CLI, paste:
```
run dependency analysis on DMD-11937 with:
- depth: 3
- include confluence docs updated in last 12 months
- save to jira_analysis.json
```

**What you get:** Jira ticket context, dependency graph, blocker analysis, Confluence docs, and a ready-to-use prompt for code analysis

### step 2: analyze related code

Copy the `suggested_prompt` from `jira_analysis.json` (replace `{{YOUR_GITHUB_ORG}}` and `{{YOUR_GITHUB_REPO}}`), then paste it into Claude or Gemini in your repository.

**Note:** Tell the AI to wait if it hits GitHub rate limits - accuracy over speed for this report.

**What you get:** Related PRs, commits, implementation patterns, cross-repo dependencies with confidence scores - saved to `code_analysis.json`

### step 3: synthesize implementation plan

In Claude or Gemini, run the synthesis prompt:
```
use the SYNTHESIS_PROMPT.md template with @jira_analysis.json and @code_analysis.json
```

**What you get:**
- **Tech lead context**: executive summary, effort estimate, risk assessment
- **Developer guide**: step-by-step implementation plan with code examples, testing strategy, deployment plan
- **Correlation analysis**: confidence-scored matches between Jira context and code findings

**Output:** `synthesis_analysis.json` - ready to paste into ticket descriptions or hand to developers

---
