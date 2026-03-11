-- 03_metrics.sql
-- Produces analysis output views consumed by analysis/run.sh.

CREATE OR REPLACE VIEW yearly_summary AS
SELECT
  invoice_year AS year,
  COUNT(*) FILTER (WHERE statement_type_norm = 'invoice') AS invoice_rows,
  COUNT(*) FILTER (WHERE statement_type_norm = 'payment') AS payment_rows,
  COUNT(*) FILTER (WHERE statement_type_norm = 'credit') AS credit_rows,
  ROUND(SUM(invoice_value), 2) AS invoices_total,
  ROUND(SUM(payment_value), 2) AS payments_total,
  ROUND(SUM(credit_value), 2) AS credits_total,
  ROUND(SUM(invoice_value + credit_value - payment_value), 2) AS net_total
FROM billing_facts
WHERE invoice_year IS NOT NULL
GROUP BY invoice_year
ORDER BY invoice_year;

CREATE OR REPLACE VIEW monthly_summary AS
SELECT
  invoice_month,
  invoice_year AS year,
  EXTRACT(MONTH FROM invoice_date) AS month,
  COUNT(*) FILTER (WHERE statement_type_norm = 'invoice') AS invoice_rows,
  COUNT(*) FILTER (WHERE statement_type_norm = 'payment') AS payment_rows,
  COUNT(*) FILTER (WHERE statement_type_norm = 'credit') AS credit_rows,
  ROUND(SUM(invoice_value), 2) AS invoices_total,
  ROUND(SUM(payment_value), 2) AS payments_total,
  ROUND(SUM(credit_value), 2) AS credits_total,
  ROUND(SUM(invoice_value + credit_value - payment_value), 2) AS net_total
FROM billing_facts
WHERE invoice_date IS NOT NULL
GROUP BY invoice_month, invoice_year, EXTRACT(MONTH FROM invoice_date)
ORDER BY invoice_month;

CREATE OR REPLACE VIEW top_customers_overall AS
WITH customer_invoice AS (
  SELECT
    customer_name_norm,
    COUNT(*) AS invoice_rows,
    SUM(invoice_value) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_value > 0
  GROUP BY customer_name_norm
), ranked AS (
  SELECT
    customer_name_norm,
    invoice_rows,
    invoice_total,
    ROW_NUMBER() OVER (ORDER BY invoice_total DESC, customer_name_norm) AS rank_overall,
    SUM(invoice_total) OVER () AS total_invoices,
    SUM(invoice_total) OVER (ORDER BY invoice_total DESC, customer_name_norm) AS running_invoices
  FROM customer_invoice
)
SELECT
  rank_overall,
  customer_name_norm,
  invoice_rows,
  ROUND(invoice_total, 2) AS invoice_total,
  ROUND(invoice_total / NULLIF(total_invoices, 0), 6) AS share_of_total,
  ROUND(running_invoices / NULLIF(total_invoices, 0), 6) AS cumulative_share
FROM ranked
ORDER BY rank_overall;

CREATE OR REPLACE VIEW top_customers_2025 AS
WITH customer_invoice AS (
  SELECT
    customer_name_norm,
    COUNT(*) AS invoice_rows,
    SUM(invoice_value) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year = 2025 AND invoice_value > 0
  GROUP BY customer_name_norm
), ranked AS (
  SELECT
    customer_name_norm,
    invoice_rows,
    invoice_total,
    ROW_NUMBER() OVER (ORDER BY invoice_total DESC, customer_name_norm) AS rank_2025,
    SUM(invoice_total) OVER () AS total_invoices_2025,
    SUM(invoice_total) OVER (ORDER BY invoice_total DESC, customer_name_norm) AS running_invoices_2025
  FROM customer_invoice
)
SELECT
  rank_2025,
  customer_name_norm,
  invoice_rows,
  ROUND(invoice_total, 2) AS invoice_total,
  ROUND(invoice_total / NULLIF(total_invoices_2025, 0), 6) AS share_of_2025,
  ROUND(running_invoices_2025 / NULLIF(total_invoices_2025, 0), 6) AS cumulative_share_2025,
  CASE WHEN running_invoices_2025 / NULLIF(total_invoices_2025, 0) <= 0.80 THEN 1 ELSE 0 END AS in_2025_pareto_80
FROM ranked
ORDER BY rank_2025;

CREATE OR REPLACE VIEW delta_2024_2025 AS
WITH y2024 AS (
  SELECT customer_name_norm, SUM(invoice_value) AS invoice_2024
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year = 2024
  GROUP BY customer_name_norm
),
y2025 AS (
  SELECT customer_name_norm, SUM(invoice_value) AS invoice_2025
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year = 2025
  GROUP BY customer_name_norm
)
SELECT
  COALESCE(y2025.customer_name_norm, y2024.customer_name_norm) AS customer_name_norm,
  ROUND(COALESCE(y2024.invoice_2024, 0), 2) AS invoice_2024,
  ROUND(COALESCE(y2025.invoice_2025, 0), 2) AS invoice_2025,
  ROUND(COALESCE(y2025.invoice_2025, 0) - COALESCE(y2024.invoice_2024, 0), 2) AS delta_2025_minus_2024,
  ROUND(
    CASE
      WHEN COALESCE(y2024.invoice_2024, 0) = 0 THEN NULL
      ELSE (COALESCE(y2025.invoice_2025, 0) - COALESCE(y2024.invoice_2024, 0)) / y2024.invoice_2024
    END,
    6
  ) AS pct_change_2025_vs_2024
FROM y2024
FULL OUTER JOIN y2025
  ON y2024.customer_name_norm = y2025.customer_name_norm
ORDER BY delta_2025_minus_2024 DESC, customer_name_norm;

CREATE OR REPLACE VIEW concentration_by_year AS
WITH customer_year AS (
  SELECT
    invoice_year,
    customer_name_norm,
    SUM(invoice_value) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL AND invoice_value > 0
  GROUP BY invoice_year, customer_name_norm
), ranked AS (
  SELECT
    invoice_year,
    customer_name_norm,
    invoice_total,
    ROW_NUMBER() OVER (PARTITION BY invoice_year ORDER BY invoice_total DESC, customer_name_norm) AS rn,
    SUM(invoice_total) OVER (PARTITION BY invoice_year) AS year_total
  FROM customer_year
)
SELECT
  invoice_year AS year,
  ROUND(MAX(year_total), 2) AS invoices_total,
  ROUND(SUM(CASE WHEN rn <= 1 THEN invoice_total ELSE 0 END) / NULLIF(MAX(year_total), 0), 6) AS top_1_share,
  ROUND(SUM(CASE WHEN rn <= 5 THEN invoice_total ELSE 0 END) / NULLIF(MAX(year_total), 0), 6) AS top_5_share,
  ROUND(SUM(CASE WHEN rn <= 10 THEN invoice_total ELSE 0 END) / NULLIF(MAX(year_total), 0), 6) AS top_10_share,
  COUNT(*) AS customers_with_invoices
FROM ranked
GROUP BY invoice_year
ORDER BY invoice_year;

CREATE OR REPLACE VIEW lifecycle_customers AS
WITH activity AS (
  SELECT customer_name_norm, invoice_date
  FROM billing_facts
  WHERE invoice_date IS NOT NULL
), gaps AS (
  SELECT
    customer_name_norm,
    invoice_date,
    date_diff('day', LAG(invoice_date) OVER (PARTITION BY customer_name_norm ORDER BY invoice_date), invoice_date) AS gap_days
  FROM activity
), aggregated AS (
  SELECT
    customer_name_norm,
    MIN(invoice_date) AS first_date,
    MAX(invoice_date) AS last_date,
    COUNT(DISTINCT EXTRACT(YEAR FROM invoice_date)) AS active_years,
    COALESCE(MAX(gap_days), 0) AS max_gap_days,
    SUM(CASE WHEN gap_days >= 365 THEN 1 ELSE 0 END) AS reactivations,
    COUNT(*) AS activity_rows
  FROM gaps
  GROUP BY customer_name_norm
)
SELECT
  customer_name_norm,
  first_date,
  last_date,
  active_years,
  max_gap_days,
  reactivations,
  activity_rows
FROM aggregated
ORDER BY customer_name_norm;

CREATE OR REPLACE VIEW lifecycle_cohorts AS
SELECT
  EXTRACT(YEAR FROM first_date) AS cohort_year,
  COUNT(*) AS customers,
  ROUND(AVG(active_years), 2) AS avg_active_years,
  ROUND(AVG(max_gap_days), 2) AS avg_max_gap_days,
  ROUND(AVG(reactivations), 2) AS avg_reactivations,
  ROUND(SUM(CASE WHEN reactivations > 0 THEN 1 ELSE 0 END)::DOUBLE / COUNT(*), 6) AS reactivation_customer_share
FROM lifecycle_customers
GROUP BY EXTRACT(YEAR FROM first_date)
ORDER BY cohort_year;

CREATE OR REPLACE VIEW invoice_drift AS
SELECT
  invoice_year AS year,
  COUNT(*) AS invoice_rows,
  ROUND(SUM(invoice_value), 2) AS invoices_total,
  ROUND(quantile_cont(invoice_value, 0.50), 2) AS median_invoice,
  ROUND(quantile_cont(invoice_value, 0.75), 2) AS p75_invoice,
  ROUND(quantile_cont(invoice_value, 0.90), 2) AS p90_invoice,
  ROUND(quantile_cont(invoice_value, 0.95), 2) AS p95_invoice,
  ROUND(AVG(CASE WHEN invoice_value < 0 THEN 1 ELSE 0 END), 6) AS negative_share
FROM billing_facts
WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL
GROUP BY invoice_year
ORDER BY invoice_year;
