Build a production-quality, single-page HTML dashboard using Tailwind CSS + Chart.js, with optional HTMX for dynamic filtering (no React, no backend required).

Context:
- Data files are in `analysis/out/` as CSV:
  - yearly_summary.csv
  - monthly_summary.csv
  - top_customers_2025.csv
  - delta_2024_2025.csv
  - concentration_by_year.csv
  - lifecycle_customers.csv
  - lifecycle_cohorts.csv
  - invoice_drift.csv
  - collections_risk_latest.csv
  - dso_monthly_overall.csv
  - payment_behavior_scorecard.csv
  - revenue_quality_yearly.csv
  - retention_cohorts.csv
  - invoice_size_mix_by_year.csv
  - currency_exposure_by_year.csv
  - country_exposure_by_year.csv
  - anomalies_detected.csv
  - forecast_monthly_baseline.csv
  - reconciliation_unmatched_invoices.csv

Goal:
Create `dashboard/index.html` (and `dashboard/styles.css` only if needed) that visualizes billing health, concentration risk, collections, retention, and forecast in a clear executive layout.

Technical requirements:
1. Stack:
   - Tailwind CSS (CDN version is fine)
   - Chart.js for charts
   - PapaParse (or native parsing) for CSV ingestion
   - Optional HTMX for filter interactions
2. No build step required; dashboard should open directly in browser.
3. Responsive for desktop + mobile.
4. Deterministic loading from local relative paths (`../analysis/out/*.csv`).
5. Graceful error handling if CSV missing/empty (show user-friendly cards).

Dashboard requirements:
1. Header:
   - Title, “last loaded” timestamp, quick KPI chips
2. KPI row:
   - Latest year invoices total
   - Latest year payments total
   - Net total
   - Top-1 concentration share (latest year)
   - Latest DSO
   - High-risk A/R customers count
3. Charts:
   - Yearly invoices/payments/credits (multi-line or grouped bar)
   - Monthly trend + forecast overlay
   - Concentration by year (top1/top5/top10 lines)
   - Invoice drift percentiles by year (median/p75/p90/p95)
   - Retention cohort stacked bars (new/retained/reactivated/churned)
   - Invoice size mix by year (stacked % bars)
   - Currency and country exposure (latest year donuts)
4. Tables:
   - Top customers 2025 (rank, invoice_total, cumulative_share)
   - 2024 vs 2025 delta (top movers up/down)
   - Collections risk latest (90+ bucket first)
   - Payment behavior scorecard (median days to pay, late share)
   - Reconciliation unmatched invoices (largest unmatched first)
   - Recent anomalies
5. Filters:
   - Year selector
   - Customer search (applies to relevant tables)
   - Reset filters button
6. UX:
   - Consistent visual theme with Tailwind tokens
   - Sticky table headers
   - Number formatting (currency, %, decimals)
   - Export visible table to CSV button per table

Code quality:
- Keep JS modular and readable in `<script type="module">`.
- Create reusable helpers for:
  - CSV loading
  - numeric/date parsing
  - metric formatting
  - chart creation/destruction
- Add comments only where logic is non-obvious.
- Avoid external dependencies beyond CDN scripts.

Deliverables:
1. `dashboard/index.html`
2. Brief “How to run” section at top of HTML comments:
   - `bash analysis/run.sh`
   - open `dashboard/index.html`
3. Include a short assumptions section in comments.

Design direction:
- Clean analytics aesthetic, high information density, not generic template look.
- Emphasize risk and trend changes visually (color coding for warning states).


Run notes:
- Open directly: `open dashboard/index.html`
- If browser blocks local CSV fetch, host on port 8000:
  - `python3 -m http.server 8000`
  - open `http://localhost:8000/dashboard/`
