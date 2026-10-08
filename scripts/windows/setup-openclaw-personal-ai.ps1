param(
  [string]$Root = "D:\OpenClaw"
)

$ErrorActionPreference = "Stop"

$Root = [System.IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath ([System.IO.Path]::GetPathRoot($Root)))) {
  throw "Drive/root does not exist: $Root"
}

$directories = @(
  "state",
  "workspace",
  "worktrees",
  "logs",
  "cache",
  "cache\node-compile",
  "backups",
  "temp",
  "state\learning",
  "state\logbook"
)

foreach ($relative in $directories) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Root $relative) | Out-Null
}

$envValues = @{
  OPENCLAW_STATE_DIR = (Join-Path $Root "state")
  OPENCLAW_WORKSPACE_DIR = (Join-Path $Root "workspace")
  OPENCLAW_CONFIG_PATH = (Join-Path $Root "state\openclaw.json")
  NODE_COMPILE_CACHE = (Join-Path $Root "cache\node-compile")
}

foreach ($pair in $envValues.GetEnumerator()) {
  [Environment]::SetEnvironmentVariable($pair.Key, $pair.Value, "User")
  Set-Item -Path ("Env:" + $pair.Key) -Value $pair.Value
}

Write-Host ""
Write-Host "OpenClaw personal-AI storage root prepared: $Root"
Write-Host "State:     $($envValues.OPENCLAW_STATE_DIR)"
Write-Host "Workspace: $($envValues.OPENCLAW_WORKSPACE_DIR)"
Write-Host "Config:    $($envValues.OPENCLAW_CONFIG_PATH)"
Write-Host "Cache:     $($envValues.NODE_COMPILE_CACHE)"
Write-Host ""
Write-Host "This script does not install OpenClaw, enable learning, or overwrite openclaw.json."
Write-Host "Apply the reviewed learning-stage config only after validating the machine and safety policy."
