<#
.SYNOPSIS
	fnCast-dotNet deterministic bring-up script (Windows / PowerShell).

.DESCRIPTION
	Verifies all prerequisites, restores packages, builds the solution,
	runs the test suite, and performs a live sanity POST against the API.

.PARAMETER SkipSanity
	Skip the live HTTP sanity check (use when running headless / CI).

.PARAMETER ApiPort
	Port the Minimal API will listen on. Default: 5097.

.EXAMPLE
	.\docs\scripts\bootstrap.ps1
	.\docs\scripts\bootstrap.ps1 -SkipSanity
#>

[CmdletBinding()]
param(
	[switch]$SkipSanity,
	[int]$ApiPort = 5097
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Helpers ────────────────────────────────────────────────────────────────

function Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function OK([string]$msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Fail([string]$msg) { Write-Host "    [FAIL] $msg" -ForegroundColor Red; exit 1 }

function Require-Command([string]$cmd, [string]$installHint) {
	if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
		Fail "$cmd not found. $installHint"
	}
	OK "$cmd found: $((Get-Command $cmd).Source)"
}

# ─── Resolve repo root ───────────────────────────────────────────────────────

$repoRoot = (Resolve-Path "$PSScriptRoot\..\.." -ErrorAction Stop).Path
Set-Location $repoRoot
OK "Repo root: $repoRoot"

# ─── Step 1: Prerequisites ──────────────────────────────────────────────────

Step "1/6  Checking prerequisites"

Require-Command "dotnet" "Install .NET 8 SDK from https://dot.net"

$sdkVersion = dotnet --version
if ($sdkVersion -notmatch '^8\.') {
	Fail ".NET 8 SDK required. Found: $sdkVersion. Install from https://dot.net"
}
OK ".NET SDK $sdkVersion"

Require-Command "git" "Install Git from https://git-scm.com"
OK "Git: $(git --version)"

# func is optional — only required to run the Functions project
$funcAvailable = $null -ne (Get-Command func -ErrorAction SilentlyContinue)
if ($funcAvailable) {
	OK "Azure Functions Core Tools: $(func --version)"
} else {
	Write-Host "    [WARN] 'func' not found. Functions project will not run locally." -ForegroundColor Yellow
	Write-Host "           Install: npm install -g azure-functions-core-tools@4" -ForegroundColor Yellow
}

# ─── Step 2: Restore ────────────────────────────────────────────────────────

Step "2/6  Restoring NuGet packages"
dotnet restore FnCast.sln --verbosity quiet
if ($LASTEXITCODE -ne 0) { Fail "dotnet restore failed (exit $LASTEXITCODE)" }
OK "Restore complete"

# ─── Step 3: Build ──────────────────────────────────────────────────────────

Step "3/6  Building solution (Release)"
dotnet build FnCast.sln --configuration Release --no-restore --verbosity quiet
if ($LASTEXITCODE -ne 0) { Fail "dotnet build failed (exit $LASTEXITCODE)" }
OK "Build succeeded — 0 errors"

# ─── Step 4: Test ───────────────────────────────────────────────────────────

Step "4/6  Running test suite"
dotnet test FnCast.sln --configuration Release --no-build --verbosity normal `
	--results-directory TestResults --logger "trx;LogFileName=bootstrap-results.trx"
if ($LASTEXITCODE -ne 0) { Fail "One or more tests failed (exit $LASTEXITCODE)" }
OK "All tests passed"

# ─── Step 5: Format check ───────────────────────────────────────────────────

Step "5/6  Checking code format"
dotnet format FnCast.sln --verify-no-changes --verbosity quiet 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
	Write-Host "    [WARN] Format drift detected. Run: dotnet format FnCast.sln" -ForegroundColor Yellow
} else {
	OK "No format drift"
}

# ─── Step 6: Sanity POST ────────────────────────────────────────────────────

if ($SkipSanity) {
	Write-Host "`n==> 6/6  Sanity check skipped (-SkipSanity)" -ForegroundColor Yellow
} else {
	Step "6/6  Running live sanity check against API (port $ApiPort)"

	$env:ASPNETCORE_URLS = "http://localhost:$ApiPort"
	$apiProcess = Start-Process -FilePath "dotnet" `
		-ArgumentList "run --project src\Api\FnCast.Api.csproj --configuration Release --no-build" `
		-PassThru -WindowStyle Hidden

	Write-Host "    Waiting for API to start (pid $($apiProcess.Id))..." -ForegroundColor Gray
	$ready = $false
	for ($i = 0; $i -lt 20; $i++) {
		Start-Sleep -Milliseconds 500
		try {
			$null = Invoke-RestMethod "http://localhost:$ApiPort/health" -TimeoutSec 2
			$ready = $true; break
		} catch { }
	}

	if (-not $ready) {
		Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
		Fail "API did not start within 10 seconds on port $ApiPort"
	}
	OK "API healthy on port $ApiPort"

	$body = '{"payload":"hello fncast","contentType":"text/plain"}'
	$response = Invoke-RestMethod -Method POST `
		-Uri "http://localhost:$ApiPort/ingest" `
		-ContentType "application/json" `
		-Body $body

	Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue

	if ($response.success -ne $true) {
		Fail "Sanity POST returned success=false. Response: $($response | ConvertTo-Json)"
	}
	if ($response.output -ne "HELLO FNCAST") {
		Fail "Unexpected output. Expected 'HELLO FNCAST', got '$($response.output)'"
	}
	OK "Sanity POST passed. output='$($response.output)'"
}

# ─── Summary ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  fnCast-dotNet bring-up: SUCCESS       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  API  :  dotnet run --project src\Api\FnCast.Api.csproj" -ForegroundColor Gray
Write-Host "  Func :  cd src\Functions && func start" -ForegroundColor Gray
Write-Host "  Tests:  dotnet test FnCast.sln" -ForegroundColor Gray
