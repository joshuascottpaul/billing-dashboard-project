#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYSIS_DIR="$ROOT_DIR/analysis"
TMP_DIR="$ANALYSIS_DIR/tmp"
OUT_DIR="$ANALYSIS_DIR/out"
VENV_DIR="$ROOT_DIR/.venv-analysis"
SOURCE_XLSX="$ROOT_DIR/nc-2002-2026.xlsx"
SOURCE_CSV="$TMP_DIR/nc-2002-2026.csv"
DB_PATH="$TMP_DIR/billing.duckdb"

mkdir -p "$TMP_DIR" "$OUT_DIR"

if [[ ! -f "$SOURCE_XLSX" ]]; then
  echo "Missing source file: $SOURCE_XLSX" >&2
  exit 1
fi

# Validate source file is not empty
if [[ ! -s "$SOURCE_XLSX" ]]; then
  echo "Error: Source file is empty: $SOURCE_XLSX" >&2
  exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi

PYTHON_BIN="$VENV_DIR/bin/python3"
if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "Missing python in virtualenv: $PYTHON_BIN" >&2
  exit 1
fi

"$PYTHON_BIN" -m pip install --no-warn-script-location duckdb pandas openpyxl || {
  echo "Error: Failed to install Python dependencies" >&2
  exit 1
}

PROJECT_ROOT="$ROOT_DIR" "$PYTHON_BIN" - <<'PY'
from pathlib import Path
import os
import sys
import pandas as pd

root = Path(os.environ["PROJECT_ROOT"])
source_xlsx = root / "nc-2002-2026.xlsx"
out_csv = root / "analysis" / "tmp" / "nc-2002-2026.csv"

# Deterministic one-shot conversion: first sheet, stable encoding, no index.
df = pd.read_excel(source_xlsx, sheet_name=0)
out_csv.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(out_csv, index=False)
print(f"Wrote CSV: {out_csv} rows={len(df)} cols={len(df.columns)}")

# Schema validation: check required columns before proceeding
REQUIRED_COLUMNS = [
    "Invoice Date",
    "Statement Item Type",
    "Invoice Grand Total",
    "Amount of Payment",
    "Billing Company",
    "Billing Contact",
    "Billing Contact Address Email",
    "Currency",
    "Billing Country",
]

OPTIONAL_COLUMNS = [
    "Payment Method",
    "Work Order Number",
    "Tax GST",
    "Sub Total",
    "Total Invoice",
    "Total of Payments",
    "Total Outstanding",
]

actual_columns = set(df.columns)
missing_required = [col for col in REQUIRED_COLUMNS if col not in actual_columns]
missing_optional = [col for col in OPTIONAL_COLUMNS if col not in actual_columns]

if missing_required:
    print("\n" + "=" * 70, file=sys.stderr)
    print("SCHEMA VALIDATION FAILED: Missing required columns", file=sys.stderr)
    print("=" * 70, file=sys.stderr)
    print(f"\nSource file: {source_xlsx}", file=sys.stderr)
    print(f"Missing columns ({len(missing_required)}):", file=sys.stderr)
    for col in missing_required:
        print(f"  - {col}", file=sys.stderr)
    print(f"\nAvailable columns ({len(actual_columns)}):", file=sys.stderr)
    for col in sorted(actual_columns):
        print(f"  - {col}", file=sys.stderr)
    print("\n" + "=" * 70, file=sys.stderr)
    print("REMEDIATION:", file=sys.stderr)
    print("  1. Check if column names changed in the source Excel file", file=sys.stderr)
    print("  2. Update REQUIRED_COLUMNS in analysis/run.sh to match new schema", file=sys.stderr)
    print("  3. Or update column mappings in analysis/01_ingest.sql", file=sys.stderr)
    print("=" * 70 + "\n", file=sys.stderr)
    sys.exit(1)

if missing_optional:
    print(f"\nWarning: {len(missing_optional)} optional column(s) not found: {', '.join(missing_optional)}", file=sys.stderr)

print("Schema validation passed: all required columns present")
PY

PROJECT_ROOT="$ROOT_DIR" "$PYTHON_BIN" - <<'PY'
from pathlib import Path
import os
import duckdb

root = Path(os.environ["PROJECT_ROOT"])
analysis = root / "analysis"
out_dir = analysis / "out"
out_dir.mkdir(parents=True, exist_ok=True)

db_path = analysis / "tmp" / "billing.duckdb"
con = duckdb.connect(str(db_path))
con.execute("PRAGMA disable_progress_bar;")

for sql_name in ["01_ingest.sql", "02_quality_checks.sql", "03_metrics.sql", "04_advanced_analysis.sql"]:
    sql_text = (analysis / sql_name).read_text(encoding="utf-8")
    con.execute(sql_text)

exports = {
    "yearly_summary.csv": "SELECT * FROM yearly_summary ORDER BY year",
    "monthly_summary.csv": "SELECT * FROM monthly_summary ORDER BY invoice_month",
    "top_customers_2025.csv": "SELECT * FROM top_customers_2025 ORDER BY rank_2025",
    "delta_2024_2025.csv": "SELECT * FROM delta_2024_2025 ORDER BY delta_2025_minus_2024 DESC, customer_name_norm",
    "concentration_by_year.csv": "SELECT * FROM concentration_by_year ORDER BY year",
    "lifecycle_customers.csv": "SELECT * FROM lifecycle_customers ORDER BY customer_name_norm",
    "lifecycle_cohorts.csv": "SELECT * FROM lifecycle_cohorts ORDER BY cohort_year",
    "invoice_drift.csv": "SELECT * FROM invoice_drift ORDER BY year",
    "ar_aging_monthly.csv": "SELECT * FROM ar_aging_monthly ORDER BY month_end, customer_name_norm",
    "collections_risk_latest.csv": "SELECT * FROM collections_risk_latest ORDER BY bucket_90_plus DESC, open_balance DESC, customer_name_norm",
    "dso_monthly_overall.csv": "SELECT * FROM dso_monthly_overall ORDER BY month_start",
    "dso_monthly_top_customers.csv": "SELECT * FROM dso_monthly_top_customers ORDER BY customer_name_norm, month_start",
    "payment_behavior_scorecard.csv": "SELECT * FROM payment_behavior_scorecard ORDER BY matched_amount DESC, customer_name_norm",
    "revenue_quality_yearly.csv": "SELECT * FROM revenue_quality_yearly ORDER BY year",
    "retention_cohorts.csv": "SELECT * FROM retention_cohorts ORDER BY year",
    "invoice_size_mix_by_year.csv": "SELECT * FROM invoice_size_mix_by_year ORDER BY year, invoice_band",
    "currency_exposure_by_year.csv": "SELECT * FROM currency_exposure_by_year ORDER BY year, invoice_total DESC, currency",
    "country_exposure_by_year.csv": "SELECT * FROM country_exposure_by_year ORDER BY year, invoice_total DESC, country",
    "anomalies_detected.csv": "SELECT * FROM anomalies_detected ORDER BY event_date DESC, anomaly_type, amount DESC",
    "forecast_monthly_baseline.csv": "SELECT * FROM forecast_monthly_baseline ORDER BY month_start",
    "reconciliation_customer_year.csv": "SELECT * FROM reconciliation_customer_year ORDER BY customer_name_norm, year",
    "reconciliation_unmatched_invoices.csv": "SELECT * FROM reconciliation_unmatched_invoices ORDER BY unmatched_amount DESC, customer_name_norm, debit_date",
}

for filename, query in exports.items():
    con.execute(f"COPY ({query}) TO '{(out_dir / filename).as_posix()}' (HEADER, DELIMITER ',');")


def to_markdown(headers, rows, max_rows=None):
    if max_rows is not None:
        rows = rows[:max_rows]
    widths = [len(h) for h in headers]
    for row in rows:
        for i, v in enumerate(row):
            widths[i] = max(widths[i], len("" if v is None else str(v)))
    def fmt(row):
        return "| " + " | ".join(("" if v is None else str(v)).ljust(widths[i]) for i, v in enumerate(row)) + " |"
    out = [fmt(headers), "| " + " | ".join("-" * widths[i] for i in range(len(headers))) + " |"]
    out.extend(fmt(row) for row in rows)
    return "\n".join(out)

row_count = con.execute("SELECT COUNT(*) FROM billing_facts").fetchone()[0]
min_date, max_date = con.execute("SELECT MIN(invoice_date), MAX(invoice_date) FROM billing_facts").fetchone()
sum_invoices = con.execute("SELECT ROUND(SUM(invoice_value), 2) FROM billing_facts").fetchone()[0]
sum_yearly = con.execute("SELECT ROUND(SUM(invoices_total), 2) FROM yearly_summary").fetchone()[0]
invoice_rows = con.execute("SELECT COUNT(*) FROM billing_facts WHERE statement_type_norm='invoice'").fetchone()[0]
payment_rows = con.execute("SELECT COUNT(*) FROM billing_facts WHERE statement_type_norm='payment'").fetchone()[0]
credit_rows = con.execute("SELECT COUNT(*) FROM billing_facts WHERE statement_type_norm='credit'").fetchone()[0]

missing_headers = [d[0] for d in con.execute("SELECT * FROM qc_missingness LIMIT 0").description]
missing_rows = con.execute("SELECT * FROM qc_missingness ORDER BY missing_pct DESC, column_name LIMIT 15").fetchall()

constant_headers = [d[0] for d in con.execute("SELECT * FROM qc_constant_columns LIMIT 0").description]
constant_rows = con.execute("SELECT * FROM qc_constant_columns ORDER BY column_name").fetchall()

bad_headers = [d[0] for d in con.execute("SELECT * FROM qc_bad_categorical_values LIMIT 0").description]
bad_rows = con.execute("SELECT * FROM qc_bad_categorical_values ORDER BY field_name, row_count DESC, bad_value LIMIT 25").fetchall()

yearly_headers = [d[0] for d in con.execute("SELECT * FROM yearly_summary LIMIT 0").description]
yearly_rows = con.execute("SELECT * FROM yearly_summary ORDER BY year").fetchall()

top_headers = [d[0] for d in con.execute("SELECT * FROM top_customers_2025 LIMIT 0").description]
top_rows = con.execute("SELECT * FROM top_customers_2025 ORDER BY rank_2025 LIMIT 15").fetchall()

drift_headers = [d[0] for d in con.execute("SELECT * FROM invoice_drift LIMIT 0").description]
drift_rows = con.execute("SELECT * FROM invoice_drift ORDER BY year DESC LIMIT 10").fetchall()

report = []
report.append("# Data Quality Report")
report.append("")
report.append("## Sanity Checks")
report.append("")
report.append(f"- Row count (`billing_facts`): **{row_count}**")
report.append(f"- Date range: **{min_date}** to **{max_date}**")
report.append(f"- Statement rows: invoice={invoice_rows}, payment={payment_rows}, credit={credit_rows}")
report.append(f"- Invoice sum from facts: **{sum_invoices}**")
report.append(f"- Invoice sum from yearly summary: **{sum_yearly}**")
report.append(f"- Sum difference (facts - yearly): **{round((sum_invoices or 0) - (sum_yearly or 0), 2)}**")
report.append("")
report.append("## Missingness (Top 15)")
report.append("")
report.append(to_markdown(missing_headers, missing_rows))
report.append("")
report.append("## Constant Columns")
report.append("")
report.append(to_markdown(constant_headers, constant_rows))
report.append("")
report.append("## Bad Categorical Values (Top 25)")
report.append("")
report.append(to_markdown(bad_headers, bad_rows))
report.append("")
report.append("## Yearly Summary")
report.append("")
report.append(to_markdown(yearly_headers, yearly_rows))
report.append("")
report.append("## Top Customers 2025 (Top 15)")
report.append("")
report.append(to_markdown(top_headers, top_rows))
report.append("")
report.append("## Invoice Drift (Most Recent 10 Years)")
report.append("")
report.append(to_markdown(drift_headers, drift_rows))

(out_dir / "data_quality_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

print("Wrote outputs:")
for filename in [
    "yearly_summary.csv",
    "monthly_summary.csv",
    "top_customers_2025.csv",
    "delta_2024_2025.csv",
    "concentration_by_year.csv",
    "lifecycle_customers.csv",
    "lifecycle_cohorts.csv",
    "invoice_drift.csv",
    "ar_aging_monthly.csv",
    "collections_risk_latest.csv",
    "dso_monthly_overall.csv",
    "dso_monthly_top_customers.csv",
    "payment_behavior_scorecard.csv",
    "revenue_quality_yearly.csv",
    "retention_cohorts.csv",
    "invoice_size_mix_by_year.csv",
    "currency_exposure_by_year.csv",
    "country_exposure_by_year.csv",
    "anomalies_detected.csv",
    "forecast_monthly_baseline.csv",
    "reconciliation_customer_year.csv",
    "reconciliation_unmatched_invoices.csv",
    "data_quality_report.md",
]:
    print(f"- {out_dir / filename}")

con.close()
PY
