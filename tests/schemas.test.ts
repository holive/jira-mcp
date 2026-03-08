import { describe, it, expect } from "vitest";
import {
  SearchIssuesInput,
  ConfluenceSearchPagesInput,
  EnvConfig,
} from "../src/schemas.js";

describe("Schemas", () => {
  it("SearchIssuesInput applies defaults", () => {
    const parsed = SearchIssuesInput.parse({ jql: "project = ABC" });
    expect(parsed.limit).toBe(25);
    expect(parsed.startAt).toBe(0);
  });

  it("ConfluenceSearchPagesInput applies defaults", () => {
    const parsed = ConfluenceSearchPagesInput.parse({ cql: "type = page" });
    expect(parsed.limit).toBe(25);
    expect(parsed.start).toBe(0);
  });

  it("EnvConfig validates required vars", () => {
    const res = EnvConfig.safeParse({});
    expect(res.success).toBe(false);
  });
});
