#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# fncast-doctor — local environment diagnostic checklist (Linux / macOS / WSL)
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
WHITE='\033[1;37m'; GRAY='\033[0;37m'; NC='\033[0m'

PASS=0; FAIL=0

check() {
	local label="$1" hint="${3:-}"
	if eval "$2" >/dev/null 2>&1; then
		printf "  ${GREEN}%-6s${NC} %s\n" "[OK]" "$label"
		((PASS++)) || true
	else
		printf "  ${RED}%-6s${NC} %s\n" "[FAIL]" "$label"
		[[ -n "$hint" ]] && printf "  ${YELLOW}       hint: %s${NC}\n" "$hint"
		((FAIL++)) || true
	fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo ""
printf "${CYAN}fncast-doctor  —  %s${NC}\n" "$REPO_ROOT"
printf "${GRAY}%s${NC}\n" "$(printf '─%.0s' {1..60})"
echo ""

# ── SDK & Tooling ─────────────────────────────────────────────────────────────

printf "${WHITE}SDK & Tooling${NC}\n"
check ".NET 8 SDK"              "dotnet --version | grep -qE '^8\.'"  "https://dot.net"
check "dotnet format"           "dotnet format --version"             "Included with .NET 8 SDK"
check "git"                     "command -v git"                      "https://git-scm.com"
check "func (Core Tools)"       "command -v func"                     "npm install -g azure-functions-core-tools@4"
check "curl"                    "command -v curl"                     "Install via package manager"

# ── Repository Structure ──────────────────────────────────────────────────────

echo ""
printf "${WHITE}Repository Structure${NC}\n"
check "FnCast.sln"                              "test -f FnCast.sln"
check "src/Api/FnCast.Api.csproj"               "test -f src/Api/FnCast.Api.csproj"
check "src/Functions/FnCast.Functions.csproj"   "test -f src/Functions/FnCast.Functions.csproj"
check "src/Application/FnCast.Application.csproj" "test -f src/Application/FnCast.Application.csproj"
check "src/Infrastructure/FnCast.Infrastructure.csproj" "test -f src/Infrastructure/FnCast.Infrastructure.csproj"
check "src/Domain/FnCast.Domain.csproj"         "test -f src/Domain/FnCast.Domain.csproj"
check "Directory.Build.props"                   "test -f Directory.Build.props"
check ".editorconfig"                           "test -f .editorconfig"

# ── Configuration ─────────────────────────────────────────────────────────────

echo ""
printf "${WHITE}Configuration${NC}\n"
check "src/Api/appsettings.json"                "test -f src/Api/appsettings.json"
check "src/Functions/appsettings.json"          "test -f src/Functions/appsettings.json"
check "src/Functions/local.settings.json"       "test -f src/Functions/local.settings.json" \
	"Copy .env.example → local.settings.json and set AzureWebJobsStorage"
check "local.settings.json has AzureWebJobsStorage" \
	"test -f src/Functions/local.settings.json && grep -q 'AzureWebJobsStorage' src/Functions/local.settings.json"
check "local.settings.json has FUNCTIONS_WORKER_RUNTIME=dotnet-isolated" \
	"test -f src/Functions/local.settings.json && grep -q 'dotnet-isolated' src/Functions/local.settings.json"
check "Inference.Mode in Api appsettings" \
	"grep -q '\"Mode\"' src/Api/appsettings.json"

# ── Build & Tests ─────────────────────────────────────────────────────────────

echo ""
printf "${WHITE}Build & Tests${NC}\n"
check "dotnet restore" \
	"dotnet restore FnCast.sln --verbosity quiet" \
	"Check network / NuGet source"
check "dotnet build (Release)" \
	"dotnet build FnCast.sln --configuration Release --no-restore --verbosity quiet" \
	"Run: dotnet build FnCast.sln"
check "dotnet test" \
	"dotnet test FnCast.sln --configuration Release --no-build --verbosity quiet" \
	"Run: dotnet test FnCast.sln --verbosity normal"

# ── Git Hygiene ───────────────────────────────────────────────────────────────

echo ""
printf "${WHITE}Git Hygiene${NC}\n"
check "On named branch (not detached HEAD)" \
	"git symbolic-ref --short HEAD"                      "git checkout -b <branch>"
check "No uncommitted changes" \
	'test -z "$(git status --porcelain)"'               "Commit or stash pending changes"
check ".gitignore covers local.settings.json" \
	"grep -q 'local.settings.json' .gitignore"
check ".gitignore covers .vscode/" \
	"grep -q '.vscode' .gitignore"

# ── Ports ─────────────────────────────────────────────────────────────────────

echo ""
printf "${WHITE}Ports${NC}\n"
check "Port 5097 available (API)" \
	"! (ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep -q ':5097'" \
	"Stop the process using port 5097"
check "Port 7071 available (Functions)" \
	"! (ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep -q ':7071'" \
	"Stop the process using port 7071"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
printf "${GRAY}%s${NC}\n" "$(printf '─%.0s' {1..60})"
TOTAL=$((PASS + FAIL))
echo "Checks: $PASS/$TOTAL passed"
if [[ "$FAIL" -eq 0 ]]; then
	printf "${GREEN}Environment is ready.${NC}\n\n"
	exit 0
else
	printf "${RED}$FAIL check(s) failed. Address hints above, then re-run fncast-doctor.${NC}\n\n"
	exit 1
fi
