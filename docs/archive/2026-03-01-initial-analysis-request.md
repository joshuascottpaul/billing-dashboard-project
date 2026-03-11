2026-03-01 2-40 PM

1. You are my data analysis agent. Goal: create a reproducible, text-file-only analysis of billing/invoices history.

Inputs:
- Source file: nc-2002-2026.xlsx (assume it exists in the repo root)
- Treat outputs as version-controlled text artifacts.

Deliverables (create these files):
1) analysis/README.md
   - exact commands to run everything end-to-end
   - brief data dictionary (columns used and assumptions)
2) analysis/01_ingest.sql
   - load the Excel-derived data (if Excel is hard, generate a one-time conversion step to CSV and document it)
   - normalize key fields: dates, currency, customer names
3) analysis/02_quality_checks.sql
   - missingness table
   - constant-column detection (flag columns that are constant across all rows)
   - bad categorical values (currency/country anomalies)
4) analysis/03_metrics.sql
   - yearly and monthly invoices, payments, credits
   - top customers overall and by year
   - concentration metrics: top 1/5/10 share by year + 2025 Pareto table
   - lifecycle metrics per customer: first_date, last_date, active_years, max_gap_days, reactivations (gap>=365d)
   - distribution drift by year: median, p75, p90, p95, negative share
5) analysis/run.sh
   - runs all SQL and writes outputs to analysis/out/*.csv and analysis/out/*.md
6) analysis/out/
   - generate: yearly_summary.csv, monthly_summary.csv, top_customers_2025.csv, delta_2024_2025.csv,
     concentration_by_year.csv, lifecycle_customers.csv, lifecycle_cohorts.csv, invoice_drift.csv,
     data_quality_report.md

Rules:
- Prefer DuckDB CLI + SQL. Use Python only if needed for Excel-to-CSV conversion.
- Make the workflow deterministic and non-interactive.
- Verify your work: after generating outputs, sanity-check totals (invoice sum vs known totals), date range, row counts.
- Keep everything in plain text files and CSV outputs.
Proceed now: inspect the repo, create the folder structure, implement, and show me the key output tables in Markdown summaries.

2. Why it fits the analysis we just did
	•	All our outputs are aggregates: monthly and yearly totals, top customers, deltas, Pareto shares, negative-rate, distribution percentiles. These are native SQL patterns (GROUP BY, ORDER BY, window functions).
	•	Lifecycle metrics are SQL-friendly: first/last invoice, days since last, gap detection, reactivation counts - all doable with MIN/MAX, LAG(), date diffs, and conditional sums.
	•	Concentration and Pareto are trivial in SQL: rank customers, cumulative sum, divide by total - window functions do this cleanly and transparently.
	•	Data quality scans map cleanly to SQL: missingness counts, constant-column checks, category anomaly lists - fast to compute and easy to re-run.

Why it’s best for me (and for text-file workflows)
	1.	Deterministic, reviewable artifacts
	•	SQL files and CSV/MD outputs diff cleanly in git.
	•	No hidden notebook state, no “it worked on my machine” variables.
	2.	Less glue code
	•	The “analysis logic” is mostly query logic, not Python plumbing.
	•	Fewer moving parts means fewer errors when you rerun later.
	3.	Fast iteration on big-ish files
	•	DuckDB scans files directly (CSV/Parquet) and is optimized for analytics workloads.
	•	Great for the kind of repeated slicing we were doing.
	4.	Clear separation of concerns
	•	One-time ingest/cleanup step, then pure analytic queries.
	•	Makes it easy to swap source format later without rewriting analysis logic.

Options (pros/cons) in this context
	1.	DuckDB + SQL (Option 1)
	•	Pros: best fit for aggregations, Pareto, deltas, lifecycle gaps, drift tables; clean text artifacts; easy to audit
	•	Cons: SQL learning curve if the team is Python-only; Excel ingest might need a one-time CSV conversion step

3. Here’s why DuckDB is usually the better pick than SQLite for the exact work we’ve been doing - file-based analytics, heavy GROUP BYs, window functions, Pareto, deltas, percentiles, and reruns from text scripts.

Core reason
	•	DuckDB is built for analytics (OLAP) - columnar + vectorized execution, optimized for scans and aggregations.  ￼
	•	SQLite is built for transactions (OLTP) - great for many small point lookups and updates, less ideal for repeated full-table scans and big aggregations.  ￼

Practical reasons that matter for your workflow

1) Query data in-place - no ETL tax
	•	DuckDB can query Parquet directly via read_parquet() and even create views over files, staying “text artifacts only”.  ￼
	•	SQLite generally wants you to import CSV into tables first - more steps, more schema pain, more drift risk.  ￼

2) Speed and “scan economics”
	•	DuckDB’s columnar/vectorized engine is specifically designed to reduce CPU per value for analytic scans.  ￼
	•	SQLite can do window functions and aggregates, but its architecture is not primarily tuned for big analytic scans.  ￼

3) The exact analysis we ran maps better
	•	Pareto and concentration: heavy window functions + cumulative sums - DuckDB is in its comfort zone.  ￼
	•	Percentiles and distribution drift: DuckDB has strong analytic function support and is commonly used for this kind of local OLAP.  ￼

Options (pros/cons)
	1.	DuckDB

	•	Pros: best for local analytics; file-native on Parquet/CSV; fast aggregations; great for scripted SQL pipelines.  ￼
	•	Cons: younger than SQLite; if you need heavy concurrent writes or strict transactional patterns, it’s not the focus.  ￼