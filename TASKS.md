# TASKS (Generated)

Source of truth: `tasks.yaml`
Last generated: 2026-03-11

## T-001: Define baseline DORA instrumentation
- Owner: orchestrator-agent
- Reviewer: qa-agent
- Priority: P1
- Status: done
- Depends on: none
- Release Impact: none
- Inputs: OUTCOMES.md, RELEASE.md, TESTING.md
- Output: Metric pipeline spec with data source mappings
- Acceptance Criteria:
  - All four DORA metrics have explicit data sources
  - Calculation query exists for each metric
  - Weekly reporting owner and cadence confirmed
- Test Plan:
  - Validate sample week computes all metrics without null errors
- Commit Plan: docs(outcomes): define baseline DORA instrumentation
- Rollback Plan: Revert metrics section to prior baseline if calculations are invalid
- Evidence Links: OUTCOMES.md
- Telemetry: dora.pipeline.health, dora.snapshot.generated

## T-002: Implement tasks.yaml to TASKS.md generator
- Owner: backend-agent
- Reviewer: review-agent
- Priority: P1
- Status: done
- Depends on: T-001
- Release Impact: app
- Inputs: tasks.yaml, CONTRIBUTING.md
- Output: Script that renders markdown task board from tasks.yaml
- Acceptance Criteria:
  - Generator produces deterministic TASKS.md ordering
  - Generated file includes owner, deps, status, reviewer
  - CI fails if TASKS.md is out of sync
- Test Plan:
  - Unit tests for schema parsing and markdown rendering
  - Golden file test for stable output
- Commit Plan: feat(orchestration): add tasks board generator
- Rollback Plan: Disable sync check and keep manual TASKS.md editing temporarily
- Evidence Links: none
- Telemetry: tasks.generator.run, tasks.generator.drift_detected

## T-003: Automate Homebrew tap update on release
- Owner: homebrew-agent
- Reviewer: release-agent
- Priority: P0
- Status: done
- Depends on: T-002
- Release Impact: homebrew
- Inputs: RELEASE.md, Formula/<formula>.rb
- Output: Release automation that opens/updates tap PR and validates brew install
- Acceptance Criteria:
  - On tag, formula version/url/sha256 update PR is created automatically
  - CI runs brew audit + clean build-from-source install + smoke test
  - If local install exists, local upgrade + smoke test is executed
- Test Plan:
  - Dry run release in staging tag
  - Verify failure path blocks merge on audit/install errors
- Commit Plan: ci(release): automate homebrew tap updates on release
- Rollback Plan: Disable auto-merge, switch to manual tap PR approval
- Evidence Links: none
- Telemetry: release.tag.detected, homebrew.pr.opened, homebrew.validation.passed
- Homebrew:
  - Formula: <formula>
  - Tap Repo: <org>/<homebrew-tap-repo>
  - Smoke Command: <formula> --version
  - Local Upgrade When Installed: true

## T-004: Harden billing schema drift checks
- Owner: qa-agent
- Reviewer: review-agent
- Priority: P1
- Status: todo
- Depends on: T-002
- Release Impact: none
- Inputs: analysis/01_ingest.sql, analysis/README.md
- Output: Pre-run schema validation with actionable error messages
- Acceptance Criteria:
  - Run fails fast when required columns are missing
  - Error output lists missing columns and expected names
  - README includes schema drift remediation steps
- Test Plan:
  - Simulate missing/renamed columns and verify deterministic failure
- Commit Plan: feat(qa): add schema drift guardrails for billing pipeline
- Rollback Plan: Disable strict schema gate and run with warning-only mode
- Evidence Links: none
- Telemetry: schema.validation.run, schema.validation.failed

## T-005: Automate docs refresh after pipeline changes
- Owner: orchestrator-agent
- Reviewer: review-agent
- Priority: P2
- Status: done
- Depends on: T-002
- Release Impact: none
- Inputs: OVERVIEW.MD, OUTCOMES.md, analysis/README.md
- Output: Documentation update checklist and CI reminder for stale docs
- Acceptance Criteria:
  - Pipeline PR template includes docs impact section
  - README and OVERVIEW are reviewed in every analysis logic change
  - OUTCOMES metric-change log updated when instrumentation changes
- Test Plan:
  - Open a sample change and verify docs checklist appears in review flow
- Commit Plan: docs(governance): enforce documentation refresh workflow
- Rollback Plan: Temporarily remove CI reminder if it blocks urgent hotfixes
- Evidence Links: none
- Telemetry: docs.checklist.present, docs.update.completed

## T-006: Maintain dashboard glossary and strategic alignment checks
- Owner: orchestrator-agent
- Reviewer: qa-agent
- Priority: P1
- Status: done
- Depends on: T-005
- Release Impact: none
- Inputs: dashboard/index.html, dashboard/README.md, STRATEGIC_INTENT.md, OUTCOMES.md
- Output: Versioned glossary governance and strategic-fit review step for dashboard changes
- Acceptance Criteria:
  - Every new KPI/chart/table has tooltip help text and glossary entry
  - Dashboard README reflects active help model
  - Major metric additions include strategic intent and outcomes impact note
- Test Plan:
  - Review one dashboard change PR and verify glossary + strategic sections are updated
- Commit Plan: docs(strategy): enforce dashboard help and strategic alignment workflow
- Rollback Plan: Temporarily relax mandatory glossary checks for urgent fixes
- Evidence Links: none
- Telemetry: dashboard.glossary.updated, strategy.alignment.checked

