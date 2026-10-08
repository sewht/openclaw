import { describe, expect, it } from "vitest";
import { explicitlyRequestedExternalAccess, isExternalTool, isLikelyNetworkCommand } from "./learning-policy.js";

describe("learning-stage external access policy", () => {
  it("requires a direct external-access request", () => {
    expect(explicitlyRequestedExternalAccess("Tell me what you remember about my workflow")).toBe(false);
    expect(explicitlyRequestedExternalAccess("I am building a web app; fix the TypeScript error")).toBe(false);
    expect(explicitlyRequestedExternalAccess("Search the web for OpenClaw current docs")).toBe(true);
    expect(explicitlyRequestedExternalAccess("Open https://example.com")).toBe(true);
  });

  it("respects a direct prohibition", () => {
    expect(explicitlyRequestedExternalAccess("Do not browse the web; work only from the repository")).toBe(false);
    expect(explicitlyRequestedExternalAccess("Never go online or search for this")).toBe(false);
  });

  it("recognizes dedicated external tools", () => {
    expect(isExternalTool("web_search")).toBe(true);
    expect(isExternalTool("browser")).toBe(true);
    expect(isExternalTool("exec")).toBe(false);
  });

  it("detects common network-capable shell commands", () => {
    expect(isLikelyNetworkCommand("exec", { command: "curl https://example.com" })).toBe(true);
    expect(isLikelyNetworkCommand("process", { command: "pnpm install" })).toBe(true);
    expect(isLikelyNetworkCommand("exec", { command: "git status" })).toBe(false);
  });
});
