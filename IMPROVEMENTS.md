# Improvements Backlog

This file tracks technical debt, automation opportunities, and process improvements for the billing-dashboard-project.

**Review cadence:** Weekly (during DORA metrics review)  
**Owner:** orchestrator-agent

---

## How to Add Items

Each improvement should include:
- **ID:** `IMP-###` format (sequential)
- **Title:** Brief description
- **Priority:** P0 (critical), P1 (high), P2 (medium), P3 (low)
- **Effort:** S (<1h), M (1-4h), L (1-2 days), XL (>2 days)
- **Source:** Link to evidence (test failure, incident, review note, metric)
- **Status:** `backlog`, `ready`, `in_progress`, `done`

---

## Backlog

<!-- Add new items here, highest priority first -->

### IMP-001: Migrate tests to pytest
- **Priority:** P3
- **Effort:** M
- **Source:** Code review 2026-03-10 (non-standard test runner limits CI integration)
- **Status:** backlog
- **Description:** Current test runner in `tests/test_tasks_generator.py` is custom. Migrate to pytest for better CI integration, fixtures, and reporting.

### IMP-002: Add file locking for venv creation
- **Priority:** P2
- **Effort:** S
- **Source:** Code review 2026-03-10 (race condition in parallel CI)
- **Status:** backlog
- **Description:** Both `scripts/generate_tasks.py` and `analysis/run.sh` create venvs without locking. Add `fcntl` file locking to prevent corruption in parallel CI jobs.

### IMP-003: SQL file integrity checks
- **Priority:** P2
- **Effort:** M
- **Source:** Code review 2026-03-10 (SQL injection pattern risk)
- **Status:** backlog
- **Description:** Add checksum validation for SQL files in `analysis/run.sh` to detect tampering or corruption. Consider signing for production deployments.

### IMP-004: Add dashboard screenshot tests
- **Priority:** P3
- **Effort:** L
- **Source:** Visual regression risk
- **Status:** backlog
- **Description:** Add Playwright screenshot tests to detect unintended UI changes. Store baseline images and compare on PR.

### IMP-005: Automate DORA data collection
- **Priority:** P1
- **Effort:** L
- **Source:** `OUTCOMES.md` - currently manual data collection
- **Status:** backlog
- **Description:** Create GitHub Actions workflow to automatically collect DORA metrics from GitHub API and update `OUTCOMES.md` weekly.

### IMP-006: Add CHANGELOG.md generation
- **Priority:** P3
- **Effort:** M
- **Source:** PR template references non-existent CHANGELOG.md
- **Status:** backlog
- **Description:** Create `CHANGELOG.md` with Keep a Changelog format. Automate updates from PR titles/labels on merge.

---

## Completed

<!-- Move completed items here with completion date -->

### IMP-007: Schema drift guardrails
- **Priority:** P1
- **Effort:** M
- **Completed:** 2026-03-10
- **Description:** Added pre-run schema validation in `analysis/run.sh` with actionable error messages.

### IMP-008: Task generator with validation
- **Priority:** P1
- **Effort:** M
- **Completed:** 2026-03-10
- **Description:** Created `scripts/generate_tasks.py` with YAML error handling, schema validation, and CI sync check.

### IMP-009: Dashboard glossary and PR template
- **Priority:** P1
- **Effort:** M
- **Completed:** 2026-03-10
- **Description:** Created `docs/DASHBOARD_GLOSSARY.md` and `.github/PULL_REQUEST_TEMPLATE.md` with strategic alignment checklist.

---

## Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Backlog size | <10 items | TBD |
| Avg time to resolve (P1) | <2 weeks | TBD |
| Automation coverage | >80% repetitive tasks | TBD |

---

## Weekly Review Template

```md
## Week of YYYY-MM-DD

### Reviewed
- IMP-###: status update

### Added
- IMP-###: new item

### Completed
- IMP-###: moved to completed

### Metrics
- Backlog: X items
- Completed this week: X
```
