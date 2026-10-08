# Copies the shareable parts of the Hermes setup into this repo, commits, and pushes.
# Secrets (.env, auth.json) and runtime state (databases, logs, caches, sessions) are never copied.
param([string]$Message = "")

$ErrorActionPreference = "Stop"
$Hermes = Join-Path $env:LOCALAPPDATA "hermes"
$Repo   = $PSScriptRoot
$Dest   = Join-Path $Repo "hermes"

if (-not (Test-Path $Hermes)) { throw "Hermes directory not found: $Hermes" }
New-Item -ItemType Directory -Force $Dest | Out-Null

foreach ($f in @("config.yaml", "SOUL.md")) {
    $src = Join-Path $Hermes $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $Dest $f) -Force }
}

# /MIR mirrors deletions too; /NJH /NJS /NFL /NDL /NP keep output quiet.
foreach ($d in @("skills", "hooks", "memories", "plugins")) {
    $src = Join-Path $Hermes $d
    if (Test-Path $src) {
        robocopy $src (Join-Path $Dest $d) /MIR /XF *.lock *.db *.db-* /NJH /NJS /NFL /NDL /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $d (exit $LASTEXITCODE)" }
    }
}
$global:LASTEXITCODE = 0

Set-Location $Repo
git add -A

# Abort if anything staged looks like a credential.
$secretPattern = '((?<![A-Za-z0-9_])sk-(?!x{8})[A-Za-z0-9_\-]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[abp]-[A-Za-z0-9\-]{10,}|AKIA[0-9A-Z]{16}|\d{8,10}:[A-Za-z0-9_\-]{35})'
$hits = git diff --cached -U0 | Select-String -Pattern $secretPattern
if ($hits) {
    git reset -q
    Write-Host "Possible secret detected - nothing committed:" -ForegroundColor Red
    $hits | ForEach-Object { Write-Host "  $($_.Line.Substring(0, [Math]::Min(60, $_.Line.Length)))..." }
    exit 1
}

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "No changes."; exit 0 }

if (-not $Message) { $Message = "Sync Hermes config $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
git commit -q -m $Message
Write-Host "Committed: $Message"

if (git remote) {
    git push -q -u origin HEAD
    Write-Host "Pushed."
} else {
    Write-Host "No remote set - run: git remote add origin <url>" -ForegroundColor Yellow
}
