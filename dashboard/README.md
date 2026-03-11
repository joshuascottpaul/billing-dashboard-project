# Dashboard

## Open the dashboard

From project root:

```bash
open dashboard/index.html
```

If browser security blocks CSV loading from `file://`, run a local server on port `8000`:

```bash
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000/dashboard/
```

## Refresh data before opening

```bash
bash analysis/run.sh
```

## Single global filter area

One filter block controls the whole page:
- `Year from` / `Year to`: time window for charts and year-scoped tables
- `Focus year`: KPI year + exposure charts + YoY cross-tab base year
- `Customer selector`: global customer filter (applies across relevant tables)
- `Top N`: controls Top-N cross-tab and exposure charts
- `Include forecast`: toggles forecast series on monthly chart
- `Compare vs prior year`: adds KPI comparison deltas
- `Saved view` + `Apply view`: one-click presets (`Default overview`, `Collections review`, `Growth review`, `Concentration risk`)
- Active filters chip row always shows effective global scope

## Help and definitions

The dashboard includes:
- Hover help on KPI cards, chart titles, and table section titles.
- A persistent **Help and Definitions** panel at the top of the page (mobile-friendly).

### Glossary reference

Full KPI, chart, and table definitions are in `docs/DASHBOARD_GLOSSARY.md`:
- Formula and data source for each metric
- Risk thresholds (🟢🟡🔴) where applicable
- Anomaly type definitions
- Strategic alignment checklist

### Strategic alignment

Dashboard changes should align with `STRATEGIC_INTENT.md`:
- **Purpose:** Billing, collections, and concentration risk decisions
- **Success signals:** Understandable without analyst support, reproducible outputs
- **Decision principles:** Determinism, text artifacts, SQL-first, explicit assumptions

## Interaction features

- Sortable table headers (click any column heading to sort ascending/descending).
- Resizable table columns (drag the vertical grip on the right edge of each header cell).
- Preferences persist across reloads (`localStorage`):
  - global filters
  - table sorts
  - table column widths
- `Reset all preferences` clears saved state and restores defaults.
- Global master filters are now the only filtering controls (table-local filter inputs were removed).

## Added analytics UX features

1. Conditional color bands:
- KPI risk colors for Top-1 Share, Latest DSO, High-Risk A/R
- Threshold highlighting in YoY, 90+ share, and late-payment cells

2. Bookmarkable URL state:
- Current filter state is reflected in query params and shareable

3. Data freshness badge:
- Header badge uses CSV response `Last-Modified` (when available)

4. Customer drill-down drawer:
- Click customer names in tables (or Top-N chart bars) to open a side drawer with customer metrics, yearly sales trend, and recent anomalies

5. Download bundle:
- `Download bundle (.zip)` exports all currently visible table views as CSV files in one ZIP

6. Active filter visibility:
- Filter chips show current year window, focus year, customer, Top-N, forecast toggle, compare mode, and preset

7. Data coverage card:
- Displays month coverage and key row-count signals (years, customers, unmatched, anomalies)

8. Per-chart exports:
- Every chart supports `Chart CSV` and `PNG` export buttons in the chart header

## Automated testing (headless browser)

From project root:

```bash
npm install
npx playwright install --with-deps chromium
npm run test:e2e
```

Local notes:
- The Playwright config starts a local server automatically on `http://127.0.0.1:4173`.
- Tests live in `dashboard/tests/e2e/dashboard.spec.js`.
- URL query-argument coverage lives in `dashboard/tests/e2e/query-args.spec.js`.
- Headed mode is available with:

```bash
npm run test:e2e:headed
```

Run only URL query-argument tests:

```bash
npm run test:e2e:query
```
