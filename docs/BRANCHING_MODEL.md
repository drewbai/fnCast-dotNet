# fnCast-dotNet — Git Branching Model

> **Version:** 1.0.0  
> **Last Updated:** 2025  
> **Applies To:** `fnCast-dotNet` (.NET 8 · Azure Functions · Event-Driven · Cloud-Native)

---

## Rationale

This branching model is based on **Gitflow** with pragmatic simplifications to support:

- A cloud-native, event-driven Azure Functions architecture
- Continuous integration on every branch
- Controlled, versioned releases to staging and production
- Hotfix capability without disrupting in-flight feature work
- Optional trunk-based development compatibility (see §6)

The model balances **team velocity** (short-lived feature branches, fast PRs) with
**production stability** (protected `main`, mandatory PR checks, tagged releases).

---

## 1. Branch Definitions

### `main`

| Property | Value |
|---|---|
| **Purpose** | Represents the latest **production-ready** code. Every commit here is deployable. |
| **Created by** | Repository initialization (exists permanently) |
| **Created when** | Repository bootstrap |
| **Merges accepted from** | `release/*`, `hotfix/*` only — **never** direct commits |
| **Protected** | ✅ Yes — branch protection rules enforced |
| **Deleted** | Never |

**Rules:**
- No direct pushes. All changes arrive via Pull Request.
- Merging a PR to `main` automatically triggers a production deployment pipeline.
- Every merge to `main` **must** be tagged with a SemVer version (automated via CI).
- Requires a minimum of **2 approving reviewers**.

---

### `develop`

| Property | Value |
|---|---|
| **Purpose** | Integration branch. Represents the latest **development state** — what will become the next release. |
| **Created by** | Repository initialization (exists permanently) |
| **Created when** | Repository bootstrap, branched from `main` |
| **Merges accepted from** | `feature/*`, `bugfix/*` |
| **Protected** | ✅ Yes — no direct pushes |
| **Deleted** | Never |

**Rules:**
- All feature and bugfix work is merged here first.
- CI pipeline runs on every push: build, unit tests, integration tests, linting.
- Deployment to a **dev/integration environment** is triggered automatically on merge.
- `develop` is never directly deployed to production.

---

### `feature/*`

| Property | Value |
|---|---|
| **Purpose** | Isolated development of a single feature, capability, or user story. |
| **Created by** | Any developer |
| **Created when** | Work on a new feature begins |
| **Branched from** | `develop` |
| **Merges into** | `develop` via Pull Request |
| **Deleted** | After PR is merged and branch is no longer needed |

**Naming Convention:**
```
feature/<issue-id>-<short-description>
```

**Examples:**
```
feature/42-podcast-ingestion-pipeline
feature/87-cast-scheduling-api
feature/103-azure-servicebus-consumer
```

**Rules:**
- Branch lifespan should be **≤ 5 business days**. Long-running branches must be rebased onto `develop` daily.
- One feature per branch. No bundling unrelated work.
- PR requires: ✅ build passing · ✅ all tests passing · ✅ 1 approving reviewer · ✅ no merge conflicts.
- Squash-merge preferred to keep `develop` history clean.
- Delete branch after merge (enforced by GitHub branch auto-delete setting).

---

### `bugfix/*`

| Property | Value |
|---|---|
| **Purpose** | Fix a non-critical defect found during development or QA (not in production). |
| **Created by** | Any developer |
| **Created when** | A bug is identified in `develop` or a `release/*` branch |
| **Branched from** | `develop` (or `release/*` if fixing a pre-release regression) |
| **Merges into** | `develop` (or back into the originating `release/*` branch) |
| **Deleted** | After PR is merged |

**Naming Convention:**
```
bugfix/<issue-id>-<short-description>
```

**Examples:**
```
bugfix/55-null-reference-cast-metadata
bugfix/61-servicebus-retry-policy
bugfix/78-episode-duration-parsing
```

**Rules:**
- Same PR checks as `feature/*`.
- If the fix targets a `release/*` branch, it must also be back-merged into `develop`.
- Squash-merge preferred.

---

### `hotfix/*`

| Property | Value |
|---|---|
| **Purpose** | Emergency fix for a **critical production defect**. Bypasses the normal release cycle. |
| **Created by** | Senior developer or release manager |
| **Created when** | A critical bug is confirmed in production (`main`) |
| **Branched from** | `main` (at the exact production tag) |
| **Merges into** | `main` **and** `develop` (and any active `release/*` branch) |
| **Deleted** | After all merges are complete |

**Naming Convention:**
```
hotfix/<semver-patch>-<short-description>
```

**Examples:**
```
hotfix/1.2.1-fix-broken-feed-parser
hotfix/2.0.1-servicebus-connection-leak
hotfix/3.1.1-auth-token-expiry
```

**Rules:**
- Must be reviewed by at least **2 approvers**, including the lead engineer.
- Merging to `main` triggers an immediate production deployment.
- A new patch tag is applied to `main` after merge (e.g., `v1.2.1`).
- **Must** be merged back into `develop` (and any open `release/*`) within 24 hours.
- All standard PR checks apply — no exceptions, even in emergencies.

---

### `release/*`

| Property | Value |
|---|---|
| **Purpose** | Stabilization branch for a specific release. Only bug fixes, docs, and release prep are allowed — no new features. |
| **Created by** | Release manager or senior developer |
| **Created when** | `develop` is feature-complete for the upcoming release |
| **Branched from** | `develop` |
| **Merges into** | `main` (triggers production deploy) **and** back into `develop` |
| **Deleted** | After merging into `main` and tagging |

**Naming Convention:**
```
release/<major.minor.0>
```

**Examples:**
```
release/1.0.0
release/1.3.0
release/2.0.0
```

**Rules:**
- Creating a `release/*` branch **freezes** feature intake for that version into `develop`.
- Deployment to a **staging/pre-production** environment is triggered automatically.
- Only `bugfix/*` PRs targeting this branch are accepted.
- Release notes and CHANGELOG must be updated before merging to `main`.
- After merging to `main`, the branch is tagged and deleted.

---

### `support/*` _(optional — long-term support)_

| Property | Value |
|---|---|
| **Purpose** | Maintain a **legacy major version** while `main` continues on a newer major. |
| **Created by** | Release manager |
| **Created when** | A prior major version requires long-term support after a new major is released |
| **Branched from** | The tag of the last patch of the previous major (e.g., `v1.x.x`) |
| **Merges into** | Receives `hotfix/*` branches only — does **not** merge into `main` |
| **Deleted** | When the LTS version is officially end-of-life |

**Naming Convention:**
```
support/<major.x>
```

**Examples:**
```
support/1.x
support/2.x
```

**Rules:**
- Only security patches and critical fixes are accepted.
- Receives its own versioned tags (e.g., `v1.9.1`, `v1.9.2`).
- CI/CD deploys to a dedicated LTS environment if one exists.

---

## 2. Branch Lifecycle Summary

```
main ──────────────────────────────────────────────────────► (production)
  │                                          ▲          ▲
  │ (bootstrap)                   release/* ─┘  hotfix/*┘
  ▼
develop ──────────────────────────────────────────────────► (dev env)
  ▲   ▲
  │   └── bugfix/*
  └────── feature/*
```

---

## 3. Versioning & Tagging Strategy

### Semantic Versioning (SemVer)

All releases follow [SemVer 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH`

| Version Component | When to Increment |
|---|---|
| **MAJOR** | Breaking API changes, major architectural shifts |
| **MINOR** | New backward-compatible features or capabilities |
| **PATCH** | Backward-compatible bug fixes, hotfixes |

### Tagging Rules

- Tags are applied to `main` only, immediately after a successful merge from `release/*` or `hotfix/*`.
- Tag format: `v<MAJOR>.<MINOR>.<PATCH>` (e.g., `v1.3.0`, `v2.0.1`)
- Tags are **annotated** (not lightweight) and include a short release summary message.
- Tagging is automated via GitHub Actions on merge to `main`.

```bash
# Example annotated tag (applied by CI)
git tag -a v1.3.0 -m "Release 1.3.0: podcast scheduling API, ServiceBus consumer improvements"
git push origin v1.3.0
```

### Pre-release Tags

| Stage | Format | Example |
|---|---|---|
| Alpha | `v<version>-alpha.<n>` | `v2.0.0-alpha.1` |
| Beta | `v<version>-beta.<n>` | `v2.0.0-beta.3` |
| Release Candidate | `v<version>-rc.<n>` | `v2.0.0-rc.1` |

Pre-release tags are applied manually to `release/*` branches during stabilization.

### Release Cadence

- **Minor releases:** Every 2–4 weeks (sprint-aligned)
- **Patch/hotfix releases:** As needed, within 24 hours of production incident confirmation
- **Major releases:** Planned, with a dedicated `release/*` stabilization period of ≥ 1 week

---

## 4. CI/CD Behavior Per Branch

### GitHub Actions Trigger Matrix

| Branch Pattern | Build | Unit Tests | Integration Tests | Deploy Target | Tag |
|---|---|---|---|---|---|
| `feature/*` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `bugfix/*` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `develop` | ✅ | ✅ | ✅ | Dev environment | ❌ |
| `release/*` | ✅ | ✅ | ✅ | Staging environment | ❌ |
| `hotfix/*` | ✅ | ✅ | ✅ | ❌ (fast-tracked) | ❌ |
| `main` | ✅ | ✅ | ✅ | Production | ✅ SemVer |
| `support/*` | ✅ | ✅ | ✅ | LTS environment | ✅ Patch |

### Workflow Files (Recommended Structure)

```
.github/
  workflows/
	ci.yml              # Runs on feature/*, bugfix/* — build + unit tests
	ci-integration.yml  # Runs on develop, release/*, hotfix/* — full test suite
	deploy-dev.yml      # Triggered on push to develop
	deploy-staging.yml  # Triggered on push to release/*
	deploy-prod.yml     # Triggered on merge to main
	tag-release.yml     # Creates annotated SemVer tag on main after deploy
```

### Azure Functions Deployment Notes

- Each environment (dev, staging, prod) maps to a separate **Azure Function App** resource.
- Deployment uses `azure/functions-action` with slot swapping for zero-downtime production releases.
- Infrastructure changes (Bicep/Terraform) are gated behind a manual approval step in the staging → prod pipeline.
- Application settings and secrets are injected via **Azure Key Vault references** — never stored in code or pipeline YAML.

---

## 5. Pull Request Requirements

### Required Checks (All Branches → `develop` or `main`)

- [ ] **Build succeeds** — `dotnet build` passes with zero errors and zero warnings (WarningsAsErrors enabled)
- [ ] **Unit tests pass** — All tests in `FnCast.Tests` pass
- [ ] **Code coverage** — Minimum 80% line coverage on `FnCast.Domain` and `FnCast.Application`
- [ ] **Linting / style** — `dotnet format` produces no diffs (enforced in CI)
- [ ] **No vulnerable packages** — `dotnet list package --vulnerable` returns clean
- [ ] **PR description** — Linked issue, summary of changes, testing notes
- [ ] **Reviewer approval** — 1 reviewer for `feature/*`/`bugfix/*` → `develop`; 2 reviewers for anything → `main`

### Branch Protection Settings (GitHub)

```yaml
# main
- Require pull request before merging: true
- Required approving reviews: 2
- Dismiss stale reviews on new commits: true
- Require status checks: build, test, lint
- Require branches to be up to date: true
- Restrict pushes: admins only
- Allow force pushes: false
- Allow deletions: false

# develop
- Require pull request before merging: true
- Required approving reviews: 1
- Require status checks: build, test
- Allow force pushes: false
- Allow deletions: false
```

---

## 6. Trunk-Based Development Compatibility

This model is **compatible with trunk-based development (TBD)** when teams need to move faster:

| Gitflow Mode | Trunk-Based Mode |
|---|---|
| `feature/*` branches (multi-day) | Short-lived branches (≤ 1 day) or direct commits with feature flags |
| `develop` as integration branch | `main` is the trunk; `develop` may be dropped |
| `release/*` for stabilization | Release branches still used for hotfix isolation |
| Explicit merge gates | Automated gating via required CI checks on `main` |

**To operate in trunk-based mode:**
1. Keep all feature branches under 24 hours.
2. Use **feature flags** (e.g., Azure App Configuration feature toggles) to hide incomplete work.
3. Merge directly to `develop` (or `main` if TBD is fully adopted) multiple times per day.
4. `release/*` and `hotfix/*` branches are retained as safety valves.

This hybrid approach is recommended for the fnCast-dotNet team as it grows, allowing a gradual shift from Gitflow toward trunk-based development without a disruptive flag day.

---

## 7. Quick Reference — Branch Cheat Sheet

```
New feature          →  git checkout -b feature/123-my-feature develop
Dev bug fix          →  git checkout -b bugfix/456-fix-something develop
Pre-release fix      →  git checkout -b bugfix/456-fix-something release/1.3.0
Production hotfix    →  git checkout -b hotfix/1.2.1-critical-fix main
Start a release      →  git checkout -b release/1.3.0 develop
LTS maintenance      →  git checkout -b support/1.x v1.9.0
```

---

## 8. CHANGELOG & Release Notes

- Maintain a `CHANGELOG.md` at the repository root following [Keep a Changelog](https://keepachangelog.com/) format.
- Each `release/*` branch must include a CHANGELOG entry before merging to `main`.
- Sections per release: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- GitHub Releases are created automatically by `tag-release.yml`, using the CHANGELOG entry as the release body.

---

*This document should be reviewed and updated at the start of each major version cycle.*
