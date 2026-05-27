#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# fnCast-dotNet deterministic bring-up script (Linux / macOS / WSL)
#
# Usage:
#   ./docs/scripts/bootstrap.sh               # full bring-up + sanity check
#   ./docs/scripts/bootstrap.sh --skip-sanity # skip live HTTP check
#   API_PORT=5097 ./docs/scripts/bootstrap.sh
#
# Preconditions:
#   - .NET 8 SDK installed  (https://dot.net)
#   - git installed
#   - curl installed (sanity step only)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────

API_PORT="${API_PORT:-5097}"
SKIP_SANITY=0
for arg in "$@"; do [[ "$arg" == "--skip-sanity" ]] && SKIP_SANITY=1; done

# ─── Helpers ─────────────────────────────────────────────────────────────────

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

step()  { echo -e "\n${CYAN}==> $*${NC}"; }
ok()    { echo -e "    ${GREEN}[OK]${NC}  $*"; }
warn()  { echo -e "    ${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "    ${RED}[FAIL]${NC} $*"; exit 1; }

require_cmd() {
	local cmd="$1" hint="$2"
	command -v "$cmd" >/dev/null 2>&1 || fail "'$cmd' not found. $hint"
	ok "$cmd → $(command -v "$cmd")"
}

# ─── Resolve repo root ────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
ok "Repo root: $REPO_ROOT"

# ─── Step 1: Prerequisites ────────────────────────────────────────────────────

step "1/6  Checking prerequisites"

require_cmd dotnet "Install .NET 8 SDK: https://dot.net"

SDK_VERSION="$(dotnet --version)"
[[ "$SDK_VERSION" =~ ^8\. ]] || fail ".NET 8 SDK required. Found: $SDK_VERSION"
ok ".NET SDK $SDK_VERSION"

require_cmd git "Install Git: https://git-scm.com"
ok "Git: $(git --version)"

if command -v func >/dev/null 2>&1; then
	ok "Azure Functions Core Tools: $(func --version)"
else
	warn "'func' not found — Functions project will not run locally."
	warn "Install: npm install -g azure-functions-core-tools@4"
fi

# ─── Step 2: Restore ──────────────────────────────────────────────────────────

step "2/6  Restoring NuGet packages"
dotnet restore FnCast.sln --verbosity quiet
ok "Restore complete"

# ─── Step 3: Build ────────────────────────────────────────────────────────────

step "3/6  Building solution (Release)"
dotnet build FnCast.sln --configuration Release --no-restore --verbosity quiet
ok "Build succeeded — 0 errors"

# ─── Step 4: Test ─────────────────────────────────────────────────────────────

step "4/6  Running test suite"
dotnet test FnCast.sln \
	--configuration Release \
	--no-build \
	--verbosity normal \
	--results-directory TestResults \
	--logger "trx;LogFileName=bootstrap-results.trx"
ok "All tests passed"

# ─── Step 5: Format check ─────────────────────────────────────────────────────

step "5/6  Checking code format"
if dotnet format FnCast.sln --verify-no-changes --verbosity quiet 2>/dev/null; then
	ok "No format drift"
else
	warn "Format drift detected. Run: dotnet format FnCast.sln"
fi

# ─── Step 6: Sanity POST ──────────────────────────────────────────────────────

if [[ "$SKIP_SANITY" -eq 1 ]]; then
	echo -e "\n${YELLOW}==> 6/6  Sanity check skipped (--skip-sanity)${NC}"
else
	step "6/6  Running live sanity check against API (port $API_PORT)"

	require_cmd curl "Install curl via your package manager"

	export ASPNETCORE_URLS="http://localhost:$API_PORT"
	dotnet run --project src/Api/FnCast.Api.csproj \
		--configuration Release --no-build &
	API_PID=$!

	echo "    Waiting for API to start (pid $API_PID)..."
	READY=0
	for i in $(seq 1 20); do
		sleep 0.5
		if curl -sf "http://localhost:$API_PORT/health" >/dev/null 2>&1; then
			READY=1; break
		fi
	done

	if [[ "$READY" -eq 0 ]]; then
		kill "$API_PID" 2>/dev/null || true
		fail "API did not start within 10 seconds on port $API_PORT"
	fi
	ok "API healthy on port $API_PORT"

	RESPONSE=$(curl -sf -X POST \
		"http://localhost:$API_PORT/ingest" \
		-H "Content-Type: application/json" \
		-d '{"payload":"hello fncast","contentType":"text/plain"}')

	kill "$API_PID" 2>/dev/null || true

	SUCCESS=$(echo "$RESPONSE" | grep -o '"success":true' || true)
	OUTPUT=$(echo "$RESPONSE"  | grep -o '"output":"[^"]*"' | cut -d'"' -f4 || true)

	[[ -n "$SUCCESS" ]]             || fail "Sanity POST returned success=false. Response: $RESPONSE"
	[[ "$OUTPUT" == "HELLO FNCAST" ]] || fail "Unexpected output. Expected 'HELLO FNCAST', got '$OUTPUT'"
	ok "Sanity POST passed. output='$OUTPUT'"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  fnCast-dotNet bring-up: SUCCESS       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  API  :  dotnet run --project src/Api/FnCast.Api.csproj"
echo "  Func :  cd src/Functions && func start"
echo "  Tests:  dotnet test FnCast.sln"
