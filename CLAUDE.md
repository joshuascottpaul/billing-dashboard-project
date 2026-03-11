# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Run the analytics pipeline
```bash
bash analysis/run.sh
```
Requires `nc-2002-2026.xlsx` in the repo root. Creates `.venv-analysis` automatically, installs `duckdb`, `pandas`, `openpyxl`, converts the workbook to CSV, runs all SQL stages, and writes outputs to `analysis/out/`.

### Open the dashboard
```bash
open dashboard/index.html
# or if browser blocks file:// CSV loading:
python3 -m http.server 8000
# then visit http://localhost:8000/dashboard/
```

### Run E2E tests (headless)
```bash
npm install
npx playwright install --with-deps chromium
npm run test:e2e                  # all tests
npm run test:e2e:query            # URL query-arg tests only
npm run test:e2e:headed           # headed mode
npm run test:e2e:ui               # Playwright UI mode
```
Playwright auto-starts a server on `http://127.0.0.1:4173`. Tests live in `dashboard/tests/e2e/`.

## Architecture

### Two-stage system

**Stage 1 — Analytics pipeline** (`analysis/`)
- Source: `nc-2002-2026.xlsx` (first sheet only)
- `run.sh` orchestrates everything: Python converts Excel → CSV, then DuckDB executes 4 SQL files in sequence and exports ~23 CSVs + a quality report to `analysis/out/`
- SQL files are the authoritative logic layer; `run.sh` is just a runner
- SQL stage order matters: `01_ingest.sql` → `02_quality_checks.sql` → `03_metrics.sql` → `04_advanced_analysis.sql`
- Intermediate state lives in `analysis/tmp/` (gitignored); outputs in `analysis/out/` are version-controlled

**Stage 2 — Dashboard** (`dashboard/index.html`)
- Single-file vanilla JS dashboard that reads CSVs from `analysis/out/` via fetch
- No build step; all state is in `localStorage` and URL query params
- Global filter bar controls the entire page (year window, focus year, top-N, customer, presets)
- URL query params: `yf`, `yt`, `fy`, `n`, `fc`, `cm` (bookmarkable/shareable state)

### Key data flow
```
nc-2002-2026.xlsx
  → analysis/tmp/nc-2002-2026.csv    (Python/pandas)
  → analysis/tmp/billing.duckdb      (DuckDB, ephemeral)
  → analysis/out/*.csv               (version-controlled outputs)
  → dashboard/index.html             (reads CSVs, renders UI)
```

### Schema / normalization assumptions
- Customer identity: `Billing Company` → `Billing Contact` → email (fallback chain)
- `customer_name_norm`: uppercased, trimmed, whitespace-collapsed
- `statement_type_norm`: `invoice`, `payment`, `credit`, `other` (maps `InvoiceRmvd` → `invoice`)
- Currency normalized to `CAD`, `USD`, or `OTHER`
- If source columns are renamed, update mappings in `analysis/01_ingest.sql`

### Tasks and planning
- `tasks.yaml` is the source of truth for the task backlog (machine-readable DAG)
- `TASKS.md` is generated from `tasks.yaml` — do not manually edit it
- `STRATEGIC_INTENT.md` defines scope boundaries and decision principles; consult before major changes
