import { describe, expect, it } from "vitest";
import { registerTools } from "../src/mcp/tools.js";
import type { Config } from "../src/config.js";

class FakeServer {
  public readonly tools = new Map<string, { description: string; schema: any; handler: Function }>();

  tool(name: string, description: string, schema: any, handler: Function) {
    this.tools.set(name, { description, schema, handler });
  }
}

const config: Config = {
  baseUrl: "https://example.atlassian.net",
  confluenceBaseUrl: "https://example.atlassian.net/wiki",
  email: "user@example.com",
  apiToken: "token",
};

const expectedTools = [
  "jira_list_issues",
  "jira_list_projects",
  "jira_get_issue",
  "jira_issue_relationships",
  "jira_get_changelog",
  "confluence_get_page",
  "jira_issue_confluence_links",
  "confluence_page_jira_links",
  "confluence_search_pages",
  "jira_dependency_analysis",
  "jira_find_similar_tickets",
];

describe("registerTools", () => {
  it("returns and registers the preserved read-only tool set", () => {
    const server = new FakeServer();

    const toolNames = registerTools(server as any, config);

    expect(toolNames).toEqual(expectedTools);
    expect(Array.from(server.tools.keys())).toEqual(expectedTools);
    expect((server as any)._registeredToolNames).toEqual(expectedTools);
  });

  it("does not register removed write tools", () => {
    const server = new FakeServer();

    registerTools(server as any, config);

    expect(server.tools.has("jira_create_issue")).toBe(false);
    expect(server.tools.has("jira_update_issue")).toBe(false);
    expect(server.tools.has("jira_add_comment")).toBe(false);
    expect(server.tools.has("jira_list_transitions")).toBe(false);
    expect(server.tools.has("jira_transition_issue")).toBe(false);
  });
});
