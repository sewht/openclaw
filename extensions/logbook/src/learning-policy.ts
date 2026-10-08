const EXTERNAL_TARGET_PATTERN =
  /\b(web|internet|online|website|site|google|bing|duckduckgo|twitter|x\.com|x\s+search)\b/i;
const EXTERNAL_VERB_PATTERN =
  /\b(search|look\s+up|browse|visit|open|fetch|check|access|go\s+to)\b/i;
const DIRECT_URL_PATTERN = /https?:\/\//i;

function removeNegatedExternalPhrases(input: string): string {
  return input.replace(
    /\b(?:do\s+not|don't|never|without|no)\s+(?:search|look\s+up|browse|use\s+(?:the\s+)?(?:web|internet)|go\s+online|access\s+(?:the\s+)?internet|visit|open|fetch)\b/gi,
    " ",
  );
}

export function explicitlyRequestedExternalAccess(input: string): boolean {
  const normalized = input.trim();
  if (!normalized) return false;
  const cleaned = removeNegatedExternalPhrases(normalized);
  if (DIRECT_URL_PATTERN.test(cleaned) && /\b(open|visit|fetch|check|read|go\s+to)\b/i.test(cleaned)) {
    return true;
  }
  return EXTERNAL_VERB_PATTERN.test(cleaned) && EXTERNAL_TARGET_PATTERN.test(cleaned);
}

export function isExternalTool(toolName: string): boolean {
  const name = toolName.trim().toLowerCase();
  return name === "web_search" || name === "x_search" || name === "web_fetch" || name === "browser";
}

export function isLikelyNetworkCommand(toolName: string, params: unknown): boolean {
  const name = toolName.trim().toLowerCase();
  if (name !== "exec" && name !== "process") return false;
  let serialized = "";
  try {
    serialized = JSON.stringify(params ?? "");
  } catch {
    serialized = String(params ?? "");
  }
  return /\b(?:curl|wget|invoke-webrequest|invoke-restmethod|start-bitstransfer|webclient|certutil|bitsadmin|npm\s+(?:install|ci|update)|pnpm\s+(?:install|add|update)|yarn\s+(?:add|install)|bun\s+(?:add|install)|npx\s+|pip\s+install|uv\s+pip\s+install|git\s+(?:clone|fetch|pull|push))\b|https?:\/\//i.test(
    serialized,
  );
}
