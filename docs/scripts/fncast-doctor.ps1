<#
.SYNOPSIS
	fncast-doctor — local environment diagnostic checklist for fnCast-dotNet.

.DESCRIPTION
	Runs a deterministic set of checks against the local environment and
	repository state. Prints a pass/fail result for each item.
	Exits with code 0 if all checks pass; 1 if any check fails.

.EXAMPLE
	.\docs\scripts\fncast-doctor.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'   # don't abort on non-fatal checks

$pass = 0
$fail = 0

function Check([string]$label, [scriptblock]$test, [string]$hint = "") {
	try {
		$result = & $test
		if ($result) {
			Write-Host ("  {0,-6} {1}" -f "[OK]", $label) -ForegroundColor Green
			$script:pass++
		} else {
			Write-Host ("  {0,-6} {1}" -f "[FAIL]", $label) -ForegroundColor Red
			if ($hint) { Write-Host ("         hint: {0}" -f $hint) -ForegroundColor Yellow }
			$script:fail++
		}
	} catch {
		Write-Host ("  {0,-6} {1} — exception: {2}" -f "[FAIL]", $label, $_.Exception.Message) -ForegroundColor Red
		$script:fail++
	}
}

$repoRoot = (Resolve-Path "$PSScriptRoot\..\.." -ErrorAction SilentlyContinue)?.Path
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

Write-Host ""
Write-Host "fncast-doctor  —  $repoRoot" -ForegroundColor Cyan
Write-Host ("─" * 60) -ForegroundColor DarkGray
Write-Host ""

# ── Section 1: SDK & Tooling ─────────────────────────────────────────────────

Write-Host "SDK & Tooling" -ForegroundColor White

Check ".NET 8 SDK installed" {
	$v = dotnet --version 2>$null
	$v -match '^8\.'
} "Install from https://dot.net"

Check "dotnet format available" {
	dotnet format --version 2>$null | Out-Null
	$LASTEXITCODE -eq 0
} "Included with .NET 8 SDK — update SDK if missing"

Check "git installed" {
	$null -ne (Get-Command git -ErrorAction SilentlyContinue)
} "Install from https://git-scm.com"

Check "Azure Functions Core Tools (func) installed" {
	$null -ne (Get-Command func -ErrorAction SilentlyContinue)
} "npm install -g azure-functions-core-tools@4"

Check "curl or Invoke-RestMethod available" {
	($null -ne (Get-Command curl.exe -ErrorAction SilentlyContinue)) -or $true
} "curl.exe ships with Windows 10+; use Invoke-RestMethod as fallback"

# ── Section 2: Repository structure ─────────────────────────────────────────

Write-Host ""
Write-Host "Repository Structure" -ForegroundColor White

Check "FnCast.sln present" {
	Test-Path "$repoRoot\FnCast.sln"
} "Re-clone the repository"

Check "src\Api\FnCast.Api.csproj" {
	Test-Path "$repoRoot\src\Api\FnCast.Api.csproj"
} "Project missing — check git status"

Check "src\Functions\FnCast.Functions.csproj" {
	Test-Path "$repoRoot\src\Functions\FnCast.Functions.csproj"
} "Project missing — check git status"

Check "src\Application\FnCast.Application.csproj" {
	Test-Path "$repoRoot\src\Application\FnCast.Application.csproj"
} "Project missing — check git status"

Check "src\Infrastructure\FnCast.Infrastructure.csproj" {
	Test-Path "$repoRoot\src\Infrastructure\FnCast.Infrastructure.csproj"
} "Project missing — check git status"

Check "src\Domain\FnCast.Domain.csproj" {
	Test-Path "$repoRoot\src\Domain\FnCast.Domain.csproj"
} "Project missing — check git status"

Check "Directory.Build.props present" {
	Test-Path "$repoRoot\Directory.Build.props"
} "Recreate from docs/BRINGUP.md"

Check ".editorconfig present" {
	Test-Path "$repoRoot\.editorconfig"
} "Recreate from docs/BRINGUP.md"

# ── Section 3: Configuration ─────────────────────────────────────────────────

Write-Host ""
Write-Host "Configuration" -ForegroundColor White

Check "src\Api\appsettings.json" {
	Test-Path "$repoRoot\src\Api\appsettings.json"
} "Restore from git: git checkout src/Api/appsettings.json"

Check "src\Functions\appsettings.json" {
	Test-Path "$repoRoot\src\Functions\appsettings.json"
} "Restore from git"

Check "src\Functions\local.settings.json exists" {
	Test-Path "$repoRoot\src\Functions\local.settings.json"
} "Copy .env.example and set AzureWebJobsStorage=UseDevelopmentStorage=true"

Check "local.settings.json has AzureWebJobsStorage key" {
	if (-not (Test-Path "$repoRoot\src\Functions\local.settings.json")) { return $false }
	$json = Get-Content "$repoRoot\src\Functions\local.settings.json" -Raw | ConvertFrom-Json
	$null -ne $json.Values.AzureWebJobsStorage
} "Add 'AzureWebJobsStorage': 'UseDevelopmentStorage=true' to local.settings.json"

Check "local.settings.json has FUNCTIONS_WORKER_RUNTIME=dotnet-isolated" {
	if (-not (Test-Path "$repoRoot\src\Functions\local.settings.json")) { return $false }
	$json = Get-Content "$repoRoot\src\Functions\local.settings.json" -Raw | ConvertFrom-Json
	$json.Values.FUNCTIONS_WORKER_RUNTIME -eq 'dotnet-isolated'
} "Set FUNCTIONS_WORKER_RUNTIME to 'dotnet-isolated'"

Check "Inference.Mode set in Api appsettings" {
	$json = Get-Content "$repoRoot\src\Api\appsettings.json" -Raw | ConvertFrom-Json
	$null -ne $json.Inference.Mode
} "Add { 'Inference': { 'Mode': 'Uppercase' } } to src/Api/appsettings.json"

# ── Section 4: Build & Tests ─────────────────────────────────────────────────

Write-Host ""
Write-Host "Build & Tests" -ForegroundColor White

Check "dotnet restore succeeds" {
	dotnet restore "$repoRoot\FnCast.sln" --verbosity quiet 2>&1 | Out-Null
	$LASTEXITCODE -eq 0
} "Check network / NuGet source config"

Check "dotnet build succeeds (Release)" {
	dotnet build "$repoRoot\FnCast.sln" --configuration Release --no-restore --verbosity quiet 2>&1 | Out-Null
	$LASTEXITCODE -eq 0
} "Run: dotnet build FnCast.sln and inspect errors"

Check "dotnet test passes" {
	dotnet test "$repoRoot\FnCast.sln" --configuration Release --no-build --verbosity quiet 2>&1 | Out-Null
	$LASTEXITCODE -eq 0
} "Run: dotnet test FnCast.sln --verbosity normal to see failures"

Check "No build warnings (0 warnings)" {
	$output = dotnet build "$repoRoot\FnCast.sln" --configuration Release --no-restore 2>&1
	$warnCount = ($output | Select-String " Warning\(s\)" | ForEach-Object {
		[int]($_ -replace '.*?\s(\d+)\s+Warning.*', '$1')
	} | Measure-Object -Sum).Sum
	$warnCount -eq 0
} "Run: dotnet build FnCast.sln and address reported warnings"

# ── Section 5: Git hygiene ────────────────────────────────────────────────────

Write-Host ""
Write-Host "Git Hygiene" -ForegroundColor White

Check "On a valid branch (not detached HEAD)" {
	$branch = git symbolic-ref --short HEAD 2>$null
	-not [string]::IsNullOrWhiteSpace($branch)
} "Run: git checkout -b <branch-name>"

Check "No uncommitted changes" {
	$status = git status --porcelain 2>$null
	[string]::IsNullOrWhiteSpace($status)
} "Run: git status — commit or stash pending changes"

Check ".gitignore covers local.settings.json" {
	$content = Get-Content "$repoRoot\.gitignore" -Raw -ErrorAction SilentlyContinue
	$content -match 'local\.settings\.json'
} "Add 'local.settings.json' to .gitignore"

Check ".gitignore covers .vscode/" {
	$content = Get-Content "$repoRoot\.gitignore" -Raw -ErrorAction SilentlyContinue
	$content -match '\.vscode'
} "Add '.vscode/' to .gitignore"

# ── Section 6: Ports (quick) ──────────────────────────────────────────────────

Write-Host ""
Write-Host "Ports" -ForegroundColor White

Check "Port 5097 is available (API)" {
	$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 5097)
	try { $listener.Start(); $listener.Stop(); $true }
	catch { $false }
} "Port 5097 is in use. Stop the conflicting process or change API_PORT"

Check "Port 7071 is available (Functions)" {
	$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 7071)
	try { $listener.Start(); $listener.Stop(); $true }
	catch { $false }
} "Port 7071 is in use. Stop the conflicting process or pass --port to func start"

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host ("─" * 60) -ForegroundColor DarkGray
$total = $pass + $fail
Write-Host ("Checks: {0}/{1} passed" -f $pass, $total)

if ($fail -eq 0) {
	Write-Host "Environment is ready." -ForegroundColor Green
	exit 0
} else {
	Write-Host ("$fail check(s) failed. Address hints above, then re-run fncast-doctor.") -ForegroundColor Red
	exit 1
}
