# ─────────────────────────────────────────────────────────────────────────────
# fnCast-dotNet Makefile
#
# Targets:
#   init         Verify prerequisites and restore packages
#   build        Compile solution (Release)
#   test         Run full test suite with TRX output
#   run-api      Start the Minimal API on port 5097
#   run-sanity   Fire a single POST and assert output == "HELLO FNCAST"
#   format       Apply dotnet format
#   format-check Verify no format drift (non-destructive)
#   clean        Remove all bin/ and obj/ directories
#   doctor       Run the fncast-doctor diagnostic script
#
# Variables (override via command line):
#   API_PORT     Port for Minimal API (default: 5097)
#   CONFIG       Build configuration (default: Release)
# ─────────────────────────────────────────────────────────────────────────────

API_PORT  ?= 5097
CONFIG    ?= Release
SLN       := FnCast.sln
API_PROJ  := src/Api/FnCast.Api.csproj
TEST_PROJ := tests/FnCast.Tests/FnCast.Tests.csproj

.PHONY: init build test run-api run-sanity format format-check clean doctor

# ── init ─────────────────────────────────────────────────────────────────────
init:
	@echo "==> Checking prerequisites"
	@dotnet --version | grep -qE '^8\.' || (echo "[FAIL] .NET 8 SDK required" && exit 1)
	@echo "    [OK] .NET SDK $$(dotnet --version)"
	@echo "==> Restoring packages"
	dotnet restore $(SLN) --verbosity quiet
	@echo "    [OK] Restore complete"

# ── build ────────────────────────────────────────────────────────────────────
build: init
	@echo "==> Building solution ($(CONFIG))"
	dotnet build $(SLN) --configuration $(CONFIG) --no-restore --verbosity quiet
	@echo "    [OK] Build succeeded"

# ── test ─────────────────────────────────────────────────────────────────────
test: build
	@echo "==> Running test suite"
	dotnet test $(SLN) \
		--configuration $(CONFIG) \
		--no-build \
		--verbosity normal \
		--results-directory TestResults \
		--logger "trx;LogFileName=make-results.trx"
	@echo "    [OK] Tests complete — results in TestResults/"

# ── run-api ──────────────────────────────────────────────────────────────────
run-api:
	@echo "==> Starting API on port $(API_PORT)"
	ASPNETCORE_URLS=http://localhost:$(API_PORT) \
	dotnet run --project $(API_PROJ) --configuration $(CONFIG)

# ── run-sanity ───────────────────────────────────────────────────────────────
run-sanity:
	@echo "==> Sanity POST → http://localhost:$(API_PORT)/ingest"
	@RESPONSE=$$(curl -sf -X POST http://localhost:$(API_PORT)/ingest \
		-H "Content-Type: application/json" \
		-d '{"payload":"hello fncast","contentType":"text/plain"}') && \
	echo "    Response: $$RESPONSE" && \
	echo "$$RESPONSE" | grep -q '"success":true'  || (echo "[FAIL] success != true"  && exit 1) && \
	echo "$$RESPONSE" | grep -q '"output":"HELLO FNCAST"' || (echo "[FAIL] output mismatch" && exit 1) && \
	echo "    [OK] Sanity passed"

# ── format ───────────────────────────────────────────────────────────────────
format:
	dotnet format $(SLN)

format-check:
	dotnet format $(SLN) --verify-no-changes --verbosity quiet
	@echo "    [OK] No format drift"

# ── clean ────────────────────────────────────────────────────────────────────
clean:
	@echo "==> Cleaning build artifacts"
	find . -type d \( -name bin -o -name obj \) \
		-not -path '*/.git/*' \
		-exec rm -rf {} + 2>/dev/null || true
	@echo "    [OK] Clean complete"

# ── doctor ───────────────────────────────────────────────────────────────────
doctor:
	@echo "==> Running fncast-doctor"
	@bash docs/scripts/fncast-doctor.sh
