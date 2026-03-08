import { afterEach, describe, expect, it, vi } from "vitest";

describe("full server entrypoint", () => {
  afterEach(() => {
    vi.resetModules();
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it("initializes without resource or prompt registration helpers", async () => {
    const connectSpy = vi.fn().mockResolvedValue(undefined);
    const sendToolListChangedSpy = vi.fn();
    const toolSpy = vi.fn();

    vi.doMock("@modelcontextprotocol/sdk/server/mcp.js", () => ({
      McpServer: class {
        public server = {};

        constructor(_info: unknown, _capabilities: unknown) {}

        tool = toolSpy;
        connect = connectSpy;
        sendToolListChanged = sendToolListChangedSpy;
      },
    }));

    vi.doMock("@modelcontextprotocol/sdk/server/stdio.js", () => ({
      StdioServerTransport: class {},
    }));

    vi.doMock("../src/config.js", () => ({
      loadConfig: () => ({
        baseUrl: "https://example.atlassian.net",
        confluenceBaseUrl: "https://example.atlassian.net/wiki",
        email: "user@example.com",
        apiToken: "token",
      }),
    }));

    const exitSpy = vi.spyOn(process, "exit").mockImplementation(((code?: number) => {
      throw new Error(`process.exit(${code})`);
    }) as any);

    await import("../src/index.ts");
    await Promise.resolve();

    expect(connectSpy).toHaveBeenCalledTimes(1);
    expect(sendToolListChangedSpy).toHaveBeenCalledTimes(1);
    expect(toolSpy).toHaveBeenCalledTimes(11);
    expect(exitSpy).not.toHaveBeenCalled();
  });
});
