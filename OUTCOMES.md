# Outcomes and Metrics (DORA)

This file defines the measurable outcomes for the multi-agent workflow.
Review cadence: weekly (with monthly trend review).
Last updated: 2026-03-10

## Scope

- Service/Repo: `billing-dashboard-project`
- Environment: production (dashboard + analytics pipeline)
- Timezone for reporting: America/Vancouver (Pacific Time)

## DORA Metrics

### Data Sources

All DORA metrics are derived from:
- **GitHub Actions**: Workflow run logs for deployments
- **GitHub API**: PR merge timestamps, release events
- **Playwright reports**: Test pass/fail evidence
- **Dashboard server logs**: Deployment confirmation

### 1. Deployment Frequency

- **Definition**: Number of successful dashboard/analytics deployments per week.
- **What counts**: Any merge to `main` that triggers dashboard redeploy or analytics refresh.
- **Calculation query**:
  ```sql
  SELECT 
    DATE_TRUNC('week', deployed_at) AS week,
    COUNT(*) AS deployment_count
  FROM github_deployments
  WHERE status = 'success'
  GROUP BY 1
  ORDER BY 1 DESC;
  ```
- **Data source**: GitHub Actions workflow runs (`dashboard-deploy.yml`), GitHub Releases API.
- **Owner**: release-agent
- **Target/SLO**: `>= 1 per week` (continuous delivery cadence).
- **Current value**: Baseline pending (first measurement after instrumentation).
- **Trend**: N/A

### 2. Lead Time for Changes

- **Definition**: Median elapsed time from PR merge to production deployment.
- **Calculation query**:
  ```sql
  SELECT 
    DATE_TRUNC('week', deployed_at) AS week,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (deployed_at - merged_at))/60) AS median_minutes
  FROM github_deployments
  WHERE status = 'success'
  GROUP BY 1
  ORDER BY 1 DESC;
  ```
- **Data source**: GitHub API (PR `merged_at` timestamp) + GitHub Actions (workflow completion timestamp).
- **Owner**: orchestrator-agent
- **Target/SLO**: `<= 30 minutes median` (automated deploy on merge).
- **Current value**: Baseline pending.
- **Trend**: N/A

### 3. Change Failure Rate

- **Definition**: Percentage of deployments that result in rollback, hotfix, or incident within 24 hours.
- **Calculation query**:
  ```sql
  SELECT 
    DATE_TRUNC('week', deployed_at) AS week,
    COUNT(*) FILTER (WHERE failed_within_24h = true) * 100.0 / COUNT(*) AS failure_rate_pct
  FROM github_deployments
  GROUP BY 1
  ORDER BY 1 DESC;
  ```
- **Data source**: 
  - Deployment logs (GitHub Actions)
  - Rollback detection: subsequent deploy within 24h with `rollback: true` flag
  - Hotfix detection: PRs labeled `hotfix` merged within 24h of deploy
  - Incident tracker: GitHub Issues labeled `incident` linked to deployment
- **Owner**: qa-agent
- **Target/SLO**: `<= 10%`.
- **Current value**: Baseline pending.
- **Trend**: N/A

### 4. MTTR (Mean Time To Restore)

- **Definition**: Average time from incident detection to service restoration.
- **Calculation query**:
  ```sql
  SELECT 
    DATE_TRUNC('week', incident_start) AS week,
    AVG(EXTRACT(EPOCH FROM (resolved_at - incident_start))/60) AS mean_minutes
  FROM incidents
  WHERE status = 'resolved'
  GROUP BY 1
  ORDER BY 1 DESC;
  ```
- **Data source**: GitHub Issues labeled `incident` with `created_at` and `closed_at` timestamps, or manual incident log.
- **Owner**: qa-agent
- **Target/SLO**: `<= 60 minutes`.
- **Current value**: Baseline pending.
- **Trend**: N/A

## Reporting Protocol

- **Weekly update owner**: orchestrator-agent
- **Publish cadence**: Every Monday by 10:00 AM PT for the prior week
- **Snapshot location**: This file (`OUTCOMES.md`) under "Weekly Snapshot" section
- **Raw evidence**: Linked in `IMPROVEMENTS.md` or GitHub Actions run summaries

### Data Collection (Manual until automated)

Until GitHub Actions integration is implemented, collect metrics manually:

```bash
# Deployment count (from GitHub Actions)
# Go to: Actions > Dashboard Deploy > filter by week > count successful runs

# Lead time (from GitHub PRs + Actions)
# For each merged PR: note merge time and deploy completion time

# Failure rate (from deploys + incidents)
# Count deploys with rollback/hotfix within 24h

# MTTR (from GitHub Issues)
# Filter: label:incident is:closed, calculate time to close
```

### Breach Response

If any metric breaches target 2 weeks in a row:
1. Open a remediation task in `tasks.yaml` with priority P1
2. Assign owner and due date (within 1 week)
3. Add rollback/risk controls if production stability is affected
4. Escalate to weekly review if unresolved after 2 weeks

## Weekly Snapshot Template

```md
## Week of YYYY-MM-DD
- Deployment Frequency: X/week (target >= 1)
- Lead Time for Changes: Xm median (target <= 30)
- Change Failure Rate: X% (target <= 10%)
- MTTR: Xm (target <= 60)
- Notes: key drivers, anomalies, and follow-up task IDs
- Data collection method: manual | automated
```

## Weekly Snapshots

<!-- Add weekly snapshots here, newest first -->

### Week of 2026-03-10
- Deployment Frequency: N/A (baseline not yet established)
- Lead Time for Changes: N/A
- Change Failure Rate: N/A
- MTTR: N/A
- Notes: DORA instrumentation defined (T-001 complete). Manual data collection until GitHub Actions integration.
- Data collection method: manual

## Metric Change Log

- 2026-03-10: GitHub Actions CI workflow added with tasks sync check, unit tests, analytics pipeline, and E2E tests. `IMPROVEMENTS.md` created for tech debt tracking. `CHANGELOG.md` added for user-visible changes.
- 2026-03-10: Dashboard glossary and strategic alignment checklist defined (T-006 complete). PR template includes help text and glossary requirements.
- 2026-03-10: DORA instrumentation baseline defined (T-001 complete). All 4 metrics have explicit data sources, calculation queries, owners, and targets. Manual data collection until GitHub Actions integration.
- 2026-03-02: Added strategic intent and dashboard help model documentation (`STRATEGIC_INTENT.md`, `dashboard/README.md`).
- 2026-03-01: Added reproducible billing analytics pipeline documentation (`analysis/README.md`) with deterministic SQL outputs and run-level validation checks.

## Applied Analytics Outcomes (Billing Pipeline)

For the billing history workflow, track these operational outcomes in addition to DORA:
- Reproducibility: successful non-interactive runs / attempted runs.
- Data freshness latency: source file update to regenerated outputs.
- Validation pass rate: run-level sanity checks passed.
- Schema drift incidents: runs requiring ingest mapping changes.
- Decision latency: time from data refresh to stakeholder-ready summary tables.

## Additional strategic indicators

- Dashboard comprehension rate: % of stakeholders who can interpret KPI definitions without analyst assistance.
- Time-to-insight: elapsed time from data refresh to first management-ready summary.
