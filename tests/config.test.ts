import { afterEach, describe, expect, it, vi } from "vitest";
import { loadConfig } from "../src/config.js";

describe("loadConfig", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("derives the Confluence URL and returns the trimmed config shape", () => {
    vi.stubEnv("JIRA_BASE_URL", "https://example.atlassian.net");
    vi.stubEnv("JIRA_EMAIL", "user@example.com");
    vi.stubEnv("JIRA_API_TOKEN", "token");
    vi.stubEnv("CONFLUENCE_BASE_URL", "");

    expect(loadConfig()).toEqual({
      baseUrl: "https://example.atlassian.net",
      confluenceBaseUrl: "https://example.atlassian.net/wiki",
      email: "user@example.com",
      apiToken: "token",
    });
  });
});
