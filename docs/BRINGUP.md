# fnCast-dotNet — Bring-Up Package

> **Audience:** Engineers onboarding to or restarting the fnCast-dotNet project.  
> **Goal:** Deterministic, step-by-step path from a clean checkout to a validated running system.

---

## 1. Repository Layout (Expected)

```
fnCast-dotNet/
├── FnCast.sln
├── Directory.Build.props          ← SDK analyzers, build globals
├── .editorconfig                  ← C# + Python code style
├── .gitignore
├── Makefile                       ← init / build / test / run-sanity targets
├── pipelines/
│   └── hello-world.yaml           ← minimal pipeline definition
├── src/
│   ├── Domain/                    ← InferenceEvent, InferenceResult, ValidationResult
│   ├── Application/               ← IPipelineOrchestrator + abstractions
│   ├── Infrastructure/            ← Validator, MetadataExtractor, Executor, Router
│   │   └── Steps/EchoStep.cs      ← sample custom step
│   ├── Api/                       ← Minimal API  (POST /ingest, GET /health)
│   ├── Functions/                 ← Azure Functions v4 isolated worker
│   └── Cli/                       ← fncast CLI  (run / check / doctor)
├── tests/
│   └── FnCast.Tests/
├── docs/
│   ├── BRINGUP.md                 ← this file
│   ├── BRANCHING_MODEL.md
│   ├── diagrams.md
│   └── scripts/
│       ├── bootstrap.ps1          ← Windows bring-up (6 stages)
│       ├── bootstrap.sh           ← Linux/macOS/WSL bring-up
│       ├── fncast-doctor.ps1      ← 25-check diagnostic (Windows)
│       └── fncast-doctor.sh       ← 25-check diagnostic (Linux/macOS)
└── infra/
	└── azure/                     ← Bicep IaC
```

---

## 2. Prerequisites

| Tool | Required Version | Install |
|---|---|---|
| .NET SDK | **8.x** | https://dot.net |
| Git | Any modern | https://git-scm.com |
| Azure Functions Core Tools | v4 (for Functions project only) | `npm install -g azure-functions-core-tools@4` |
| Azurite | Latest (for Functions storage emulation) | `npm install -g azurite` |
| curl | Any (sanity check) | Ships with Windows 10+, `apt install curl` on Linux |

---

## 3. Environment Setup

### 3a. Clone

```bash
git clone https://github.com/drewbai/fnCast-dotNet
cd fnCast-dotNet
```

### 3b. Copy secrets template

```powershell
# PowerShell
Copy-Item .env.example .env
# Edit .env — set ASPNETCORE_URLS if needed (default: http://localhost:5097)
```

```bash
# Bash
cp .env.example .env
```

### 3c. local.settings.json (Functions only)

`src/Functions/local.settings.json` is git-ignored. It already exists with safe defaults:

```json
{
  "IsEncrypted": false,
  "Values": {
	"AzureWebJobsStorage": "UseDevelopmentStorage=true",
	"FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```

For real Azure storage, replace `UseDevelopmentStorage=true` with a connection string.  
**Never commit this file.**

---

## 4. Bring-Up — Deterministic Execution Path

Run the bootstrap script. It executes all stages in order and exits non-zero on any failure.

### Windows (PowerShell)

```powershell
.\docs\scripts\bootstrap.ps1
```

### Linux / macOS / WSL

```bash
chmod +x docs/scripts/bootstrap.sh
./docs/scripts/bootstrap.sh
```

### CI / headless (skip live HTTP check)

```powershell
.\docs\scripts\bootstrap.ps1 -SkipSanity
```

```bash
./docs/scripts/bootstrap.sh --skip-sanity
```

### Bootstrap stages

| Stage | Command | Expected output |
|---|---|---|
| 1 Prerequisites | `dotnet --version` | `8.x.x` |
| 2 Restore | `dotnet restore FnCast.sln` | 0 errors |
| 3 Build | `dotnet build --configuration Release` | `Build succeeded. 0 Warning(s) 0 Error(s)` |
| 4 Test | `dotnet test` | `3 Passed, 0 Failed` |
| 5 Format check | `dotnet format --verify-no-changes` | no output (clean) |
| 6 Sanity POST | `POST /ingest {"payload":"hello fncast"}` | `{"success":true,"output":"HELLO FNCAST"}` |

---

## 5. Manual Execution Commands

### Run Minimal API

```powershell
# PowerShell
$env:ASPNETCORE_URLS = 'http://localhost:5097'
dotnet run --project src\Api\FnCast.Api.csproj
```

```bash
# Bash
ASPNETCORE_URLS=http://localhost:5097 dotnet run --project src/Api/FnCast.Api.csproj
```

**Expected log output:**

```
info: Microsoft.Hosting.Lifetime[14]
	  Now listening on: http://localhost:5097
info: Microsoft.Hosting.Lifetime[0]
	  Application started.
```

### Run Azure Functions

> Precondition: `func` CLI installed, Azurite running (`azurite --silent`).

```bash
cd src/Functions
func start
```

**Expected log output:**

```
Functions:
	HttpIngest: [POST] http://localhost:7071/api/HttpIngest
	QueueIngest: queueTrigger
	EventGridIngest: eventGridTrigger
```

### Run CLI

```powershell
dotnet run --project src\Cli\FnCast.Cli.csproj -- run pipelines\hello-world.yaml --payload "hello fncast"
```

**Expected output:**

```
[fncast] pipeline : pipelines\hello-world.yaml
[fncast] payload  : hello fncast
[fncast] type     : text/plain

success : True
output  : HELLO FNCAST
metadata:
  eventId: <guid>
  timestamp: <unix-ms>
```

### Health check

```powershell
Invoke-RestMethod http://localhost:5097/health
```

```bash
curl -s http://localhost:5097/health
```

**Expected:** `{"status":"ok"}`

### Ingest POST

```powershell
Invoke-RestMethod -Method POST http://localhost:5097/ingest `
  -ContentType "application/json" `
  -Body '{"payload":"hello fncast","contentType":"text/plain"}'
```

```bash
curl -s -X POST http://localhost:5097/ingest \
  -H "Content-Type: application/json" \
  -d '{"payload":"hello fncast","contentType":"text/plain"}'
```

**Expected:**

```json
{
  "success": true,
  "output": "HELLO FNCAST",
  "metadata": { "eventId": "...", "timestamp": "..." },
  "errors": []
}
```

---

## 6. Makefile Targets

```bash
make init          # prerequisite check + restore
make build         # Release build
make test          # full test suite → TestResults/make-results.trx
make run-sanity    # POST sanity check (API must be running)
make format        # apply dotnet format
make format-check  # verify no drift
make clean         # delete bin/ and obj/
make doctor        # run fncast-doctor.sh
```

---

## 7. Pipeline Configuration

`Inference:Mode` controls how the placeholder executor transforms payloads:

| Mode | Behaviour | Config value |
|---|---|---|
| `Uppercase` | `hello` → `HELLO` | `"Mode": "Uppercase"` |
| `Lowercase` | `HELLO` → `hello` | `"Mode": "Lowercase"` |
| `Echo` | unchanged | `"Mode": "Echo"` |

Set in `src/Api/appsettings.json` or via environment variable:

```bash
Inference__Mode=Lowercase dotnet run --project src/Api/FnCast.Api.csproj
```

---

## 8. Validation Checklist

Run before every PR merge to `develop` or `main`.

### Automated (CI enforced)

- [ ] `dotnet build FnCast.sln --configuration Release` → **0 errors, 0 warnings**
- [ ] `dotnet test FnCast.sln` → **all tests pass**
- [ ] `dotnet format FnCast.sln --verify-no-changes` → **no drift**
- [ ] `dotnet list package --vulnerable` → **no vulnerable packages**

### Manual (local)

- [ ] `.\docs\scripts\fncast-doctor.ps1` → **all 25 checks pass**
- [ ] `GET /health` → `{"status":"ok"}`
- [ ] `POST /ingest` with `text/plain` → `success: true`, `output: "HELLO FNCAST"`
- [ ] `POST /ingest` with invalid JSON body + `application/json` → `success: false`, `errors` non-empty
- [ ] `fncast run pipelines/hello-world.yaml` → exits 0

---

## 9. Error-Path Reference

| Symptom | Root Cause | Resolution |
|---|---|---|
| `gRPC channel URI 'http://:7071' could not be parsed` | Running Functions worker directly via `dotnet run` | Use `func start` or the VS launch profile (`func start` via `Executable`) |
| `NU1603: package X was not found` | Package version pinned to a version no longer on the feed | Bump version in `.csproj` to the next available |
| `CS8604: Possible null reference` | `ReadAsStringAsync()` returns `string?` | Null-coalesce: `?? string.Empty` |
| Port 5097 in use | Previous run not terminated | `Stop-Process -Name dotnet -Force` |
| Port 7071 in use | Previous `func start` not terminated | `Stop-Process -Name func -Force` |
| Build DLL locked (`CS2012`) | Previous dotnet process still running | `Stop-Process -Name dotnet -Force` |
| `local.settings.json` missing | Git-ignored, not restored on clone | Copy from `.env.example` pattern above |
| `AzureWebJobsStorage` connection error | Azurite not running | `azurite --silent &` before `func start` |

---

## 10. Future-Proofing — Recommended Next Steps

### Immediate (before first release)

1. **Delete `UnitTest1.cs`** — scaffolding placeholder, adds noise.
2. **Wire `EchoStep`** — replace `PlaceholderInferenceExecutor` in DI when real inference logic is ready.
3. **Add integration test project** — `tests/FnCast.Integration.Tests` covering `/health` and `/ingest` via `WebApplicationFactory<Program>`.
4. **Enable `TreatWarningsAsErrors`** in `Directory.Build.props` — enforces zero-warning builds in CI.

### Short-term

5. **Implement `IPipelineLoader`** — load `pipelines/*.yaml` at startup; enable `fncast check` schema validation.
6. **Add OpenTelemetry** — wire `AddOpenTelemetry()` in both `Api/Program.cs` and `Functions/Program.cs` with OTLP exporter.
7. **Add health checks** — replace the hand-rolled `/health` endpoint with `services.AddHealthChecks()`.
8. **Structured logging** — switch from `Console` to `Serilog` or `OpenTelemetry` log provider.

### Medium-term

9. **Publish CLI as dotnet tool** — add `<PackAsTool>true</PackAsTool>` to `FnCast.Cli.csproj`; distribute via `dotnet tool install`.
10. **Multi-environment config** — add `appsettings.Staging.json` and `appsettings.Production.json`; inject via CI secrets.
11. **Contract tests** — add Pact or similar for the `/ingest` API surface.
12. **Branching model automation** — enforce `feature/*` → `develop` → `release/*` → `main` via GitHub branch protection rules (see `docs/BRANCHING_MODEL.md`).
