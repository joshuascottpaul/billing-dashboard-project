# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dashboard glossary with complete KPI, chart, and table definitions (`docs/DASHBOARD_GLOSSARY.md`)
- Strategic alignment checklist in PR template
- GitHub Actions CI workflow with tasks sync check, unit tests, analytics pipeline, and E2E tests
- `IMPROVEMENTS.md` for tracking technical debt and automation opportunities
- Schema validation with actionable error messages in analytics pipeline
- Task generator with YAML error handling and schema validation

### Changed
- Task generator now uses dynamic Python version detection (was hardcoded to 3.14)
- Task generator includes subprocess timeouts (120s for venv, 300s for pip)
- Analytics pipeline validates source Excel file is not empty
- Analytics pipeline shows pip install errors (removed `--quiet` flag)

### Fixed
- Task generator handles malformed YAML with clear error messages
- Task generator validates required task fields before generating
- Test coverage expanded for edge cases (unicode, long fields, null values)

## [0.1.0] - 2026-03-10

### Added
- Initial release of billing analytics dashboard
- Analytics pipeline with 4 SQL stages and 23 output files
- Executive dashboard with KPIs, charts, and tables
- Playwright E2E test suite (12 tests)
- Multi-agent orchestration framework (`tasks.yaml`, `TASKS.md`)
- DORA metrics instrumentation (`OUTCOMES.md`)
- Strategic intent documentation (`STRATEGIC_INTENT.md`)

### Analytics Outputs
- Yearly and monthly summaries
- Top customers and concentration analysis
- Customer lifecycle and retention cohorts
- A/R aging and DSO metrics
- Payment behavior scorecard
- Invoice drift analysis
- Currency and country exposure
- Anomaly detection
- Forecast baseline
- Reconciliation reports

### Dashboard Features
- Global filter bar with preset views
- Bookmarkable URL state
- Customer drill-down drawer
- Resizable and sortable tables
- Per-chart CSV/PNG exports
- Download bundle (.zip) for all tables
- Hover help tooltips
- Persistent help and definitions panel
