param(
  [string]$Root = "D:\OpenClaw",
  [string]$RepoUrl = "https://github.com/sewht/openclaw.git",
  [string]$Branch = "learning-stage-observer",
  [switch]$SkipWindowsHub,
  [switch]$SkipOnboarding,
  [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host ("==> " + $Message) -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' is not available on PATH."
  }
}

function Set-UserEnv([string]$Name, [string]$Value) {
  [Environment]::SetEnvironmentVariable($Name, $Value, "User")
  Set-Item -Path ("Env:" + $Name) -Value $Value
}

function Invoke-OpenClaw([Parameter(Mandatory)][string[]]$Args) {
  & openclaw @Args
  if ($LASTEXITCODE -ne 0) {
    throw "OpenClaw command failed ($LASTEXITCODE): openclaw $($Args -join ' ')"
  }
}

if ($env:OS -ne "Windows_NT") {
  throw "This installer is for Windows."
}

$Root = [System.IO.Path]::GetFullPath($Root)
$RootDrive = [System.IO.Path]::GetPathRoot($Root)
if (-not (Test-Path -LiteralPath $RootDrive)) {
  throw "Required drive/root does not exist: $RootDrive. Default is D:\OpenClaw."
}

Write-Step "Prepare D:\OpenClaw storage"
$directories = @(
  "state",
  "workspace",
  "worktrees",
  "logs",
  "cache",
  "cache\node-compile",
  "backups",
  "temp"
)
foreach ($relative in $directories) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Root $relative) | Out-Null
}

Set-UserEnv "OPENCLAW_STATE_DIR" (Join-Path $Root "state")
Set-UserEnv "OPENCLAW_WORKSPACE_DIR" (Join-Path $Root "workspace")
Set-UserEnv "OPENCLAW_CONFIG_PATH" (Join-Path $Root "state\openclaw.json")
Set-UserEnv "NODE_COMPILE_CACHE" (Join-Path $Root "cache\node-compile")

Write-Step "Check Node.js"
$nodeOk = $false
if (Get-Command node -ErrorAction SilentlyContinue) {
  $nodeVersionText = (& node --version).Trim()
  if ($nodeVersionText -match '^v(\d+)\.(\d+)\.(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $nodeOk = (($major -eq 26 -and $minor -ge 1) -or ($major -eq 24 -and $minor -ge 16))
  }
}
if (-not $nodeOk) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Supported Node 24.16+ or 26.1+ not found. Installing Node.js LTS with winget..."
    winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "winget could not install Node.js LTS. Install Node 24.16+ or 26.1+ and rerun."
    }
    $candidate = "C:\Program Files\nodejs\node.exe"
    if (Test-Path $candidate) {
      $env:Path = "C:\Program Files\nodejs;" + $env:Path
    }
  } else {
    throw "Node 24.16+ or 26.1+ is required, and winget is unavailable. Install Node manually, then rerun."
  }
}
Require-Command "node"
Write-Host ("Node: " + (& node --version).Trim())

Write-Step "Check Git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Git not found. Installing Git for Windows..."
    winget install --id Git.Git --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "winget could not install Git for Windows. Install Git and rerun."
    }
    $gitCandidates = @(
      "C:\Program Files\Git\cmd",
      (Join-Path $env:LOCALAPPDATA "Programs\Git\cmd")
    )
    foreach ($candidate in $gitCandidates) {
      if (Test-Path $candidate) {
        $env:Path = $candidate + ";" + $env:Path
        break
      }
    }
  } else {
    throw "Git for Windows is required, and winget is unavailable. Install Git and rerun."
  }
}
Require-Command "git"

Write-Step "Obtain the exact personal-AI source branch"
$Source = Join-Path $Root "source"
if (-not (Test-Path (Join-Path $Source ".git"))) {
  if (Test-Path $Source) {
    $children = Get-ChildItem -LiteralPath $Source -Force
    if ($children.Count -gt 0) {
      throw "$Source exists and is not a Git checkout. Move/remove it and rerun."
    }
  }
  git clone --branch $Branch --single-branch $RepoUrl $Source
  if ($LASTEXITCODE -ne 0) {
    throw "Could not clone $RepoUrl branch $Branch."
  }
} else {
  Push-Location $Source
  try {
    $dirty = git status --porcelain
    if ($dirty) {
      throw "$Source has local changes. Refusing to overwrite them."
    }
    git fetch origin $Branch
    if ($LASTEXITCODE -ne 0) {
      throw "Could not fetch branch $Branch."
    }
    git checkout $Branch
    if ($LASTEXITCODE -ne 0) {
      throw "Could not checkout branch $Branch."
    }
    git reset --hard ("origin/" + $Branch)
    if ($LASTEXITCODE -ne 0) {
      throw "Could not align local source to origin/$Branch."
    }
  } finally {
    Pop-Location
  }
}

Push-Location $Source
try {
  $head = (git rev-parse HEAD).Trim()
  Write-Host ("Source branch: " + $Branch)
  Write-Host ("Source commit: " + $head)
} finally {
  Pop-Location
}

Write-Step "Install the exact repo toolchain"
Require-Command "corepack"
corepack enable
if ($LASTEXITCODE -ne 0) {
  throw "corepack enable failed."
}

Push-Location $Source
try {
  pnpm install --frozen-lockfile
  if ($LASTEXITCODE -ne 0) {
    throw "pnpm install failed."
  }

  if (-not $NoBuild) {
    pnpm build
    if ($LASTEXITCODE -ne 0) {
      throw "pnpm build failed. The source checkout is not ready to run."
    }

    pnpm ui:build
    if ($LASTEXITCODE -ne 0) {
      throw "pnpm ui:build failed."
    }
  }

  # Official OpenClaw source-install pattern: link this exact checkout into the CLI.
  pnpm add --global ("openclaw@link:" + $Source)
  if ($LASTEXITCODE -ne 0) {
    throw "Could not link the personal OpenClaw checkout into the global CLI."
  }
} finally {
  Pop-Location
}

Require-Command "openclaw"

Write-Step "Configure the personal learning environment"
$ConfigPath = Join-Path $Root "state\openclaw.json"
if (-not $SkipOnboarding -and -not (Test-Path -LiteralPath $ConfigPath)) {
  Write-Host "OpenClaw onboarding is interactive. Complete provider/model setup in the wizard."
  Write-Host "This installer does not create or guess API keys."
  Invoke-OpenClaw @("onboard", "--install-daemon")
} elseif (Test-Path -LiteralPath $ConfigPath) {
  Write-Host "Existing OpenClaw config found at $ConfigPath; onboarding will not overwrite it."
}

# These writes use OpenClaw's own validated config writer; they do not replace openclaw.json.
Invoke-OpenClaw @("config", "set", "agents.defaults.heartbeat.every", "0m")

# Use OpenClaw's own memory/session indexing so the actual agent can recall
# earlier conversations in addition to the curated Logbook learning context.
Invoke-OpenClaw @("config", "set", "agents.defaults.memorySearch.experimental.sessionMemory", "true")
Invoke-OpenClaw @("config", "set", "agents.defaults.memorySearch.sources", '["memory","sessions"]', "--strict-json", "--merge")
Invoke-OpenClaw @("config", "set", "tools.sessions.visibility", "agent")

Invoke-OpenClaw @("plugins", "enable", "codex")
Invoke-OpenClaw @("plugins", "enable", "logbook")

Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.enabled", "true")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.captureEnabled", "true")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.captureIntervalSeconds", "30")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.analysisIntervalMinutes", "15")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.learningEnabled", "true")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.learningIntervalMinutes", "60")
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.learningRawEvidenceRetentionDays", "7")

# The branch's Logbook integration uses the bundled Codex structured image path.
Invoke-OpenClaw @("config", "set", "plugins.entries.logbook.config.visionModel", "codex/gpt-6-astra")

Write-Step "Verify configuration and Gateway"
Invoke-OpenClaw @("config", "validate")
Invoke-OpenClaw @("doctor")
Invoke-OpenClaw @("gateway", "status", "--json")

Write-Step "Check the Logbook runtime"
Invoke-OpenClaw @("plugins", "inspect", "logbook", "--runtime", "--json")

if (-not $SkipWindowsHub) {
  Write-Step "Install the Windows Hub companion"
  $arch = $env:PROCESSOR_ARCHITECTURE
  if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
  $asset = if ($arch -eq "ARM64") { "OpenClawCompanion-Setup-arm64.exe" } else { "OpenClawCompanion-Setup-x64.exe" }
  $hubUrl = "https://github.com/openclaw/openclaw/releases/latest/download/" + $asset
  $hubInstaller = Join-Path $Root "temp\$asset"
  Write-Host "Downloading official Windows Hub asset: $asset"
  Invoke-WebRequest -Uri $hubUrl -OutFile $hubInstaller
  Start-Process -FilePath $hubInstaller -Wait
  Remove-Item -LiteralPath $hubInstaller -Force -ErrorAction SilentlyContinue
}

Write-Step "Open your direct OpenClaw chat"
Invoke-OpenClaw @("dashboard")

Write-Host ""
Write-Host "INSTALLATION COMPLETE FOR THE SOURCE CHECKOUT." -ForegroundColor Green
Write-Host ""
Write-Host "NEXT ONE-TIME WINDOWS STEP:" -ForegroundColor Yellow
Write-Host "In OpenClaw Companion, choose Connections and connect to the EXISTING local Gateway created by this installer. Do not create another Gateway."
Write-Host "Then enable Windows Node mode. When the Gateway shows a pending node request, approve it with:"
Write-Host "  openclaw nodes pending"
Write-Host "  openclaw nodes approve <requestId>"
Write-Host "After that, the Logbook learning service can receive screen.snapshot evidence from this laptop."
Write-Host ""
Write-Host "Chat is already available at the OpenClaw Control UI opened above. Responses there come directly from OpenClaw's configured model, not through ChatGPT."
Write-Host ""
Write-Host "The agent you chat with in the dashboard is OpenClaw itself. The learning layer only supplies accumulated personal context."
