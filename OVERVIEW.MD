# Multi-Agent Orchestration Overview

Use a docs-as-control-plane model:
- Agents execute work.
- Markdown files define architecture, policy, and quality gates.
- The orchestrator reads these docs before planning and updates them after merges.

## Core Documentation

1. `SDD.md`
- Scope, architecture, components, interfaces, constraints, non-goals.
- Design decisions / ADR-style section for major choices.

2. `CONTRIBUTING.md`
- Coding standards, PR rules, branching strategy, review checklist.
- Commit format and commit hygiene.
- Agent delivery contract.

3. `AGENTS.md`
- Agent roles, ownership boundaries, escalation paths, conflict resolution.
- Handoff schema and status vocabulary.

4. `tasks.yaml` (source of truth)
- Machine-readable DAG/task board with task IDs, owners, dependencies, status, and required fields.
- Schema-validated in CI.
- **Generate `TASKS.md`:** `python3 scripts/generate_tasks.py`
- **CI sync check:** `./scripts/check_tasks_sync.sh`

5. `TASKS.md` (generated)
- Human-readable view generated from `tasks.yaml`.
- Should not be manually edited except in emergencies.

6. `TESTING.md`
- Test pyramid: unit, integration, e2e/smoke.
- Required commands by change type.
- Coverage thresholds and flaky-test policy.

7. `RELEASE.md`
- Release/versioning workflow.
- GitHub release/tag process.
- Homebrew formula update process and validation.

8. `IMPROVEMENTS.md`
- Backlog for weaknesses, tech debt, automation opportunities.
- Each item links to evidence (test failure, incident, review note, metric).

9. `CHANGELOG.md` (optional but recommended)
- Human-readable merged outcomes.

10. `OUTCOMES.md`
- DORA metric definitions, formulas, targets, owners, and reporting cadence.
- Baseline values and trend tracking.

11. `STRATEGIC_INTENT.md`
- Purpose, scope boundaries, decision principles, and success signals.

## Agent Roles to Add

- `orchestrator-agent`: decomposes work, schedules DAG, replans.
- `backend-agent` / `frontend-agent` / domain specialists: implement tasks.
- `qa-agent`: enforces `TESTING.md` and validates evidence.
- `review-agent`: policy + architecture compliance checks.
- `release-agent`: GitHub tags/releases and release notes.
- `homebrew-agent`: updates formula in tap repo and runs brew smoke validation.

## Task Contract (`TASKS.md`)

Each task should include:
- Task ID
- Owner
- Depends on
- Inputs (doc sections)
- Output expectations
- Test Plan
- Commit Plan
- Release Impact: `none | app | homebrew`
- Status: `todo | in_progress | blocked | done`
- Reviewer

Canonical storage is `tasks.yaml`; this markdown representation is generated for readability.

Example:

```md
## T-042: Add caching layer
- Owner: backend-agent
- Depends on: T-039
- Inputs: SDD §3.2, CONTRIBUTING test policy
- Output: PR + tests + migration note
- Test Plan: unit + integration for cache invalidation
- Commit Plan: feat(cache): add redis-backed query cache
- Release Impact: app
- Status: in_progress
- Reviewer: review-agent
```

## Agent Delivery Contract (`CONTRIBUTING.md`)

```md
### Agent Delivery Contract
- Summary: 3-5 lines
- Files changed: list
- Tests: added/updated + exact results
- Risks: known tradeoffs
- Status: done | blocked
```

## Merge and Release Gates

### Merge Gate (Required)
- [ ] Unit/integration tests pass
- [ ] CI is green
- [ ] Commit messages follow convention
- [ ] PR includes test evidence and rollback note
- [ ] CHANGELOG entry added (if user-visible)
- [ ] `TASKS.md` in sync with `tasks.yaml` (if tasks changed)

### Homebrew Release Gate (When applicable)
- [ ] GitHub release/tag created
- [ ] Formula version/url/sha256 updated in tap repo
- [ ] `brew install --build-from-source <formula>` passes
- [ ] Smoke test command succeeds
- [ ] If formula already installed locally: `brew upgrade <formula>` and local smoke test pass

## DORA Outcomes (`OUTCOMES.md`)

Track and review at least weekly:
- Deployment Frequency
- Lead Time for Changes
- Change Failure Rate
- MTTR (Mean Time To Restore)

Each metric should include:
- Definition and calculation query
- Data source
- Owner
- Target/SLO
- Current value and trend

## Orchestration Loop

1. Read `SDD.md`, `CONTRIBUTING.md`, `AGENTS.md`, `TESTING.md`, `RELEASE.md`, `OUTCOMES.md`.
2. Build/refresh DAG in `tasks.yaml` and generate `TASKS.md`.
3. Dispatch ready tasks in parallel.
4. Collect outputs with test evidence and commit proposals.
5. Run reviewer + QA gates.
6. Merge via GitHub PR checks.
7. If `Release Impact` includes Homebrew:
   - Create GitHub release/tag.
   - Automatically open/update tap PR with formula (`version`, `url`, `sha256`).
   - Run `brew audit`, clean-environment install, and smoke test in CI.
   - If app is already installed on the local machine, run local `brew upgrade <formula>` plus smoke test.
8. Record outcomes in `CHANGELOG.md`, DORA metrics in `OUTCOMES.md`, and follow-ups in `IMPROVEMENTS.md`.
9. Strategic alignment check against `STRATEGIC_INTENT.md` before major scope changes.

## Plan vs Overview

This document is an overview and operating model.
A full execution plan would add:
- Milestones with dates and owners
- Exact command sequence per phase
- Go/no-go criteria
- Rollback checkpoints

## Implemented Example (Billing Analysis)

The operating model is now implemented for a reproducible billing history workflow under `analysis/`:
- Docs and controls: `analysis/README.md`, SQL stages, deterministic `run.sh`
- Source: `nc-2002-2026.xlsx`
- Execution: `bash analysis/run.sh`
- Output artifacts: version-controlled CSV/Markdown in `analysis/out/`

Delivered analysis coverage includes:
- Core summaries and concentration metrics
- Customer lifecycle and drift metrics
- A/R aging, DSO, payment behavior scorecards
- Revenue quality and retention/churn cohorts
- Mix shift, exposure, anomaly detection
- Forecast baseline and reconciliation outputs
