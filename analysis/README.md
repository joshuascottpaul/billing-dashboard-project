# Billing History Analysis (DuckDB + SQL)

This directory contains a deterministic, text-file-only workflow for analyzing invoice/payment history from `nc-2002-2026.xlsx`.

## Quick start

Run from repo root:

```bash
bash analysis/run.sh
```

The script will:
1. Create/use `.venv-analysis`
2. Install `duckdb`, `pandas`, `openpyxl`
3. Convert `nc-2002-2026.xlsx` -> `analysis/tmp/nc-2002-2026.csv`
4. Execute SQL files:
- `analysis/01_ingest.sql`
- `analysis/02_quality_checks.sql`
- `analysis/03_metrics.sql`
- `analysis/04_advanced_analysis.sql`
5. Export outputs to `analysis/out/`


## Dashboard launch

Open directly:

```bash
open dashboard/index.html
```

If local `file://` fetch is blocked, host on port `8000`:

```bash
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000/dashboard/
```


## Dashboard help model

The dashboard has two layers of help:
- Hover tooltips on KPI cards, charts, and table section titles.
- A persistent **Help and Definitions** panel near the top of the page for mobile/touch use.

See also: `dashboard/README.md` for usage details.

## Re-running with new Excel files

Yes, this workflow is designed for drop-in refreshes:
- Replace `nc-2002-2026.xlsx` in repo root (same schema expected).
- Re-run `bash analysis/run.sh`.
- Review diffs in `analysis/out/*.csv` and `analysis/out/data_quality_report.md`.

If sheet name or column names change, update mappings in `analysis/01_ingest.sql`.

## Schema Drift Remediation

The pipeline validates source schema before execution. If column names change in a new Excel file, the run fails fast with actionable errors.

### Required columns

| Column | Purpose |
|--------|---------|
| `Invoice Date` | Event date for all transactions |
| `Statement Item Type` | Transaction class (Invoice, Payment, Credit) |
| `Invoice Grand Total` | Invoice/credit amount source |
| `Amount of Payment` | Payment amount source |
| `Billing Company` | Primary customer identity |
| `Billing Contact` | Fallback customer identity |
| `Billing Contact Address Email` | Final fallback customer identity |
| `Currency` | Currency code (normalized to CAD/USD/OTHER) |
| `Billing Country` | Country code (normalized to CA/US/GB/etc.) |

### Optional columns (warnings only)

`Payment Method`, `Work Order Number`, `Tax GST`, `Sub Total`, `Total Invoice`, `Total of Payments`, `Total Outstanding`

### If validation fails

**Error message includes:**
- List of missing required columns
- List of available columns in source
- Three remediation steps

**To fix:**

1. **Quick fix** - Update `REQUIRED_COLUMNS` in `analysis/run.sh` to match new column names

2. **Update normalization** - Edit `analysis/01_ingest.sql` to map new column names:
   ```sql
   -- Example: if "Invoice Date" became "Inv_Date"
   NULLIF(TRIM("Inv_Date"), '') AS invoice_date_raw,
   ```

3. **Verify** - Re-run `bash analysis/run.sh` and check `analysis/out/data_quality_report.md`

## Files

- `01_ingest.sql`: CSV ingest + normalization (dates, currency, customer names)
- `02_quality_checks.sql`: missingness, constant columns, categorical anomalies
- `03_metrics.sql`: summaries, top customers, concentration, lifecycle, drift
- `04_advanced_analysis.sql`: A/R aging, DSO, payment behavior, revenue quality, retention/churn, mix shift, exposure, anomalies, forecast baseline, reconciliation
- `run.sh`: non-interactive runner that writes required CSV/MD artifacts

## Data dictionary (columns used + assumptions)

### Source columns used
- `Invoice Date`: event date for all row types
- `Statement Item Type`: transaction class (`Invoice`, `Payment`, `Credit`, etc.)
- `Invoice Grand Total`: invoice/credit amount candidate
- `Amount of Payment`: payment amount candidate
- `Billing Company`, `Billing Contact`, `Billing Contact Address Email`: customer identity fallback chain
- `Currency`: normalized to `CAD`, `USD`, or `OTHER`
- `Billing Country`: normalized to ISO-like short codes (`CA`, `US`, `GB`, etc.) or `OTHER`

### Derived fields
- `invoice_date`: parsed date from `Invoice Date`
- `statement_type_norm`: `invoice`, `payment`, `credit`, `other`
- `customer_name_norm`: uppercase, trimmed, whitespace-collapsed
- `invoice_value`: `invoice_amount` when `statement_type_norm='invoice'`, else 0
- `payment_value`: `payment_amount` when `statement_type_norm='payment'`, else 0
- `credit_value`: `invoice_amount` when `statement_type_norm='credit'`, else 0

### Assumptions
- Excel import is one-time per run and deterministic (first worksheet only).
- Amount parsing strips non-numeric symbols (`$`, commas, text) before cast.
- `InvoiceRmvd` is treated as `invoice` in normalization.
- Unknown/dirty categorical values are retained in raw fields and flagged in quality checks.
- All outputs are reproducible from source + SQL files.

## Output catalog

### Baseline outputs
- `analysis/out/yearly_summary.csv`: yearly invoices/payments/credits/net
- `analysis/out/monthly_summary.csv`: monthly invoices/payments/credits/net
- `analysis/out/top_customers_2025.csv`: top customers + Pareto cumulative share for 2025
- `analysis/out/delta_2024_2025.csv`: customer-level deltas from 2024 to 2025
- `analysis/out/concentration_by_year.csv`: top 1/5/10 concentration shares by year
- `analysis/out/lifecycle_customers.csv`: first/last date, active years, max gap, reactivations
- `analysis/out/lifecycle_cohorts.csv`: cohort rollups of lifecycle behavior
- `analysis/out/invoice_drift.csv`: yearly median/p75/p90/p95 and negative share
- `analysis/out/data_quality_report.md`: quality + sanity checks report

### Advanced outputs (10 added analyses)
- `analysis/out/ar_aging_monthly.csv`: customer-month A/R buckets
- `analysis/out/collections_risk_latest.csv`: latest-month high-risk collections accounts
- `analysis/out/dso_monthly_overall.csv`: overall monthly DSO (3-month denominator)
- `analysis/out/dso_monthly_top_customers.csv`: DSO for top customers
- `analysis/out/payment_behavior_scorecard.csv`: days-to-pay and lateness profile
- `analysis/out/revenue_quality_yearly.csv`: gross/credits/net/payments/collection ratio by year
- `analysis/out/retention_cohorts.csv`: new/retained/reactivated/churned customers + revenue
- `analysis/out/invoice_size_mix_by_year.csv`: invoice band mix shift by year
- `analysis/out/currency_exposure_by_year.csv`: yearly currency concentration
- `analysis/out/country_exposure_by_year.csv`: yearly country concentration
- `analysis/out/anomalies_detected.csv`: invoice outliers, spikes, credit bursts
- `analysis/out/forecast_monthly_baseline.csv`: simple 12-month baseline forecast
- `analysis/out/reconciliation_customer_year.csv`: customer-year net reconciliation
- `analysis/out/reconciliation_unmatched_invoices.csv`: unresolved invoice balances

## Validation performed each run

- Row count and date-range sanity checks.
- Statement row counts by normalized type.
- Invoice totals reconciliation (`facts` vs `yearly_summary`).
- Missingness top table and constant-column detection.
- Category anomaly listing for currency/country/type.

## Method notes

- Core analytics are SQL-first in DuckDB; only Excel-to-CSV conversion uses Python.
- Aging/DSO/reconciliation use deterministic customer-level FIFO settlement proxy.
- For exact invoice-to-payment accounting match, source data needs explicit invoice linkage keys.

## Why DuckDB + SQL for this project

- Native fit for outputs: monthly/yearly aggregates, Pareto concentration, deltas, percentiles, and lifecycle gaps are all SQL-native (`GROUP BY`, window functions, `LAG`, quantiles).
- Deterministic text workflow: SQL + shell + CSV/MD outputs are reviewable in git with clean diffs and no hidden notebook state.
- Low glue overhead: analysis logic stays in SQL files instead of Python orchestration code.
- Better local OLAP behavior than SQLite for this use case:
  - DuckDB is optimized for analytic scans/aggregations and window-heavy workloads.
  - SQLite is strong for transactional/point-query patterns, but less ideal for repeated full-scan analytics.
- Easy reruns with new source files: replace workbook and rerun one command (`bash analysis/run.sh`).
