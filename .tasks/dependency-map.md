# `scripts/` Dependency Map

Built from the current `scripts/` directory after a successful `npm run build`.

## Dist Imports By Script

| Script | `dist/` imports | Notes |
| --- | --- | --- |
| `scripts/minimal-server.mjs` | `../dist/jira/client.js`, `../dist/jira/issues.js`, `../dist/jira/adf-parser.js` | Depends on `JiraClient`, `normalizeIssue`, `adfToPlainText`, and `extractConfluenceLinks`. |
| `scripts/report-minimal-server.mjs` | `../dist/jira/client.js`, `../dist/jira/issues.js` | Depends on `JiraClient` and `normalizeIssue`. |
| `scripts/confluence-minimal-server.mjs` | none | Self-contained Confluence server. |
| `scripts/ping.mjs` | none | Starts `dist/index.js` via stdio and calls listed tools. |
| `scripts/setup-gemini.js` | none | Uses `npm run ping`; no direct `dist/` import. |
| `scripts/gemini-config-generator.js` | none | Writes client config only. |

## `JiraClient` Method Usage In Scripts

| Method/member | Used by | Keep? |
| --- | --- | --- |
| `searchIssues()` | `scripts/minimal-server.mjs`, `scripts/report-minimal-server.mjs` | yes |
| `getIssue()` | `scripts/minimal-server.mjs` | yes |
| `listProjects()` | `scripts/minimal-server.mjs` | yes |
| `listBoards()` | `scripts/minimal-server.mjs` | yes |
| `getBoardFilter()` | `scripts/minimal-server.mjs` | yes |
| `listBoardIssues()` | `scripts/minimal-server.mjs` | yes |
| `getConfluencePage()` | `scripts/minimal-server.mjs` | yes |
| `searchConfluencePages()` | none in `scripts/` | keep for full server only |
| `getIssueChangelog()` | `scripts/minimal-server.mjs` | yes |
| `createIssue()` | none in `scripts/` | no |
| `updateIssue()` | none in `scripts/` | no |
| `addComment()` | none in `scripts/` | no |
| `listTransitions()` | none in `scripts/` | no |
| `transitionIssue()` | none in `scripts/` | no |
| `listComponents()` | none in `scripts/` | no |
| `getFilter()` | none in `scripts/` | no script dependency |

## Other Export Usage In Scripts

| Export | Used by | Keep? |
| --- | --- | --- |
| `normalizeIssue` from `dist/jira/issues.js` | `scripts/minimal-server.mjs`, `scripts/report-minimal-server.mjs` | yes |
| `adfToPlainText` from `dist/jira/issues.js` | `scripts/minimal-server.mjs` | yes |
| `extractConfluenceLinks` from `dist/jira/adf-parser.js` | `scripts/minimal-server.mjs` | yes |

## `ping` / Entry Point Dependencies

- `scripts/ping.mjs` launches `dist/index.js`, so `src/index.ts` must keep building to the `main` entrypoint.
- `scripts/ping.mjs` calls `jira_list_projects`, so the full server must continue to register that tool.
- `scripts/ping.mjs` currently forwards `DEFAULT_PROJECT_KEY` and `DEFAULT_ISSUE_TYPE`, but no preserved runtime path in `src/` or `scripts/` consumes them after the planned cleanup.

## Validation Against Built Exports

- Built exports present:
  - `dist/jira/client.js` exports `JiraClient`
  - `dist/mcp/tools.js` exports `registerTools`, `registerResources`, `registerPrompts`
- No script imports `dist/mcp/tools.js`.
- No script usage was found for the write-side Jira client methods targeted by the task:
  - `createIssue()`
  - `updateIssue()`
  - `addComment()`
  - `listTransitions()`
  - `transitionIssue()`
  - `listComponents()`

## Pruning Decision

Protected by script usage or full-server contract:

- `JiraClient.searchIssues`
- `JiraClient.getIssue`
- `JiraClient.listProjects`
- `JiraClient.listBoards`
- `JiraClient.getBoardFilter`
- `JiraClient.listBoardIssues`
- `JiraClient.getConfluencePage`
- `JiraClient.searchConfluencePages`
- `JiraClient.getIssueChangelog`
- `normalizeIssue`
- `adfToPlainText`
- `extractConfluenceLinks`
- `src/index.ts` / `dist/index.js`

Safe to remove for this task if no non-script source still needs them:

- `JiraClient.createIssue`
- `JiraClient.updateIssue`
- `JiraClient.addComment`
- `JiraClient.listTransitions`
- `JiraClient.transitionIssue`
- `JiraClient.listComponents`
- `registerResources`
- `registerPrompts`
