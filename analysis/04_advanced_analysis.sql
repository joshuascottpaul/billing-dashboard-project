-- 04_advanced_analysis.sql
-- Additional analyses: A/R aging, DSO, payment behavior, revenue quality,
-- retention/churn, mix shift, exposure, anomalies, forecasting, reconciliation.

CREATE OR REPLACE VIEW ledger_events AS
SELECT
  row_id,
  customer_name_norm,
  invoice_date AS event_date,
  CASE
    WHEN statement_type_norm = 'invoice' THEN GREATEST(COALESCE(invoice_value, 0), 0)
    WHEN statement_type_norm = 'credit' AND COALESCE(credit_value, 0) > 0 THEN credit_value
    ELSE 0
  END AS debit_amount,
  CASE
    WHEN statement_type_norm = 'payment' THEN GREATEST(COALESCE(payment_value, 0), 0)
    WHEN statement_type_norm = 'credit' AND COALESCE(credit_value, 0) < 0 THEN -credit_value
    ELSE 0
  END AS settlement_amount
FROM billing_facts
WHERE invoice_date IS NOT NULL;

CREATE OR REPLACE VIEW debit_rows AS
WITH x AS (
  SELECT
    row_id,
    customer_name_norm,
    event_date AS debit_date,
    debit_amount,
    SUM(debit_amount) OVER (PARTITION BY customer_name_norm ORDER BY event_date, row_id) AS cum_debit_curr
  FROM ledger_events
  WHERE debit_amount > 0
)
SELECT
  row_id,
  customer_name_norm,
  debit_date,
  debit_amount,
  cum_debit_curr - debit_amount AS cum_debit_prev,
  cum_debit_curr
FROM x;

CREATE OR REPLACE VIEW settlement_rows AS
WITH x AS (
  SELECT
    row_id,
    customer_name_norm,
    event_date AS settle_date,
    settlement_amount,
    SUM(settlement_amount) OVER (PARTITION BY customer_name_norm ORDER BY event_date, row_id) AS cum_settle_curr
  FROM ledger_events
  WHERE settlement_amount > 0
)
SELECT
  row_id,
  customer_name_norm,
  settle_date,
  settlement_amount,
  cum_settle_curr - settlement_amount AS cum_settle_prev,
  cum_settle_curr
FROM x;

CREATE OR REPLACE VIEW payment_matches AS
SELECT
  d.customer_name_norm,
  d.row_id AS debit_row_id,
  s.row_id AS settlement_row_id,
  d.debit_date,
  s.settle_date,
  date_diff('day', d.debit_date, s.settle_date) AS days_to_pay,
  LEAST(d.cum_debit_curr, s.cum_settle_curr) - GREATEST(d.cum_debit_prev, s.cum_settle_prev) AS matched_amount
FROM debit_rows d
JOIN settlement_rows s
  ON d.customer_name_norm = s.customer_name_norm
 AND s.settle_date >= d.debit_date
 AND LEAST(d.cum_debit_curr, s.cum_settle_curr) > GREATEST(d.cum_debit_prev, s.cum_settle_prev);

CREATE OR REPLACE VIEW payment_behavior_scorecard AS
WITH event_level AS (
  SELECT
    customer_name_norm,
    settle_date,
    SUM(matched_amount) AS matched_amount,
    SUM(matched_amount * days_to_pay) / NULLIF(SUM(matched_amount), 0) AS weighted_days_to_pay,
    CASE WHEN SUM(matched_amount * days_to_pay) / NULLIF(SUM(matched_amount), 0) > 60 THEN 1 ELSE 0 END AS late_event
  FROM payment_matches
  GROUP BY customer_name_norm, settle_date
), streaks AS (
  SELECT
    customer_name_norm,
    late_event,
    ROW_NUMBER() OVER (PARTITION BY customer_name_norm ORDER BY settle_date)
      - ROW_NUMBER() OVER (PARTITION BY customer_name_norm, late_event ORDER BY settle_date) AS grp
  FROM event_level
), late_streak AS (
  SELECT customer_name_norm, COALESCE(MAX(cnt), 0) AS max_late_streak
  FROM (
    SELECT customer_name_norm, grp, COUNT(*) AS cnt
    FROM streaks
    WHERE late_event = 1
    GROUP BY customer_name_norm, grp
  ) z
  GROUP BY customer_name_norm
)
SELECT
  m.customer_name_norm,
  ROUND(SUM(m.matched_amount), 2) AS matched_amount,
  ROUND(AVG(m.days_to_pay), 2) AS avg_days_to_pay,
  ROUND(quantile_cont(m.days_to_pay, 0.5), 2) AS median_days_to_pay,
  ROUND(quantile_cont(m.days_to_pay, 0.9), 2) AS p90_days_to_pay,
  ROUND(AVG(CASE WHEN m.days_to_pay <= 30 THEN 1 ELSE 0 END), 6) AS on_time_share_30d,
  ROUND(AVG(CASE WHEN m.days_to_pay > 60 THEN 1 ELSE 0 END), 6) AS late_share_60d,
  COALESCE(ls.max_late_streak, 0) AS max_late_streak
FROM payment_matches m
LEFT JOIN late_streak ls
  ON m.customer_name_norm = ls.customer_name_norm
GROUP BY m.customer_name_norm, ls.max_late_streak
ORDER BY matched_amount DESC, m.customer_name_norm;

CREATE OR REPLACE VIEW customer_month_flows AS
SELECT
  customer_name_norm,
  date_trunc('month', event_date)::DATE AS month_start,
  SUM(debit_amount) AS debit_month,
  SUM(settlement_amount) AS settlement_month
FROM ledger_events
GROUP BY customer_name_norm, date_trunc('month', event_date)::DATE;

CREATE OR REPLACE VIEW customer_month_cumulative AS
WITH bounds AS (
  SELECT
    MIN(date_trunc('month', event_date)::DATE) AS min_month,
    MAX(date_trunc('month', event_date)::DATE) AS max_month
  FROM ledger_events
), months AS (
  SELECT month_start::DATE AS month_start
  FROM bounds,
  generate_series(min_month, max_month, INTERVAL 1 MONTH) AS t(month_start)
), customers AS (
  SELECT
    customer_name_norm,
    MIN(date_trunc('month', event_date)::DATE) AS first_month
  FROM ledger_events
  GROUP BY customer_name_norm
), grid AS (
  SELECT c.customer_name_norm, m.month_start
  FROM customers c
  JOIN months m
    ON m.month_start >= c.first_month
)
SELECT
  g.customer_name_norm,
  g.month_start,
  last_day(g.month_start) AS month_end,
  COALESCE(f.debit_month, 0) AS debit_month,
  COALESCE(f.settlement_month, 0) AS settlement_month,
  SUM(COALESCE(f.debit_month, 0)) OVER (
    PARTITION BY g.customer_name_norm
    ORDER BY g.month_start
  ) AS cumulative_debit,
  SUM(COALESCE(f.settlement_month, 0)) OVER (
    PARTITION BY g.customer_name_norm
    ORDER BY g.month_start
  ) AS cumulative_settlement,
  GREATEST(
    SUM(COALESCE(f.debit_month, 0)) OVER (
      PARTITION BY g.customer_name_norm
      ORDER BY g.month_start
    ) -
    SUM(COALESCE(f.settlement_month, 0)) OVER (
      PARTITION BY g.customer_name_norm
      ORDER BY g.month_start
    ),
    0
  ) AS ar_end_balance
FROM grid g
LEFT JOIN customer_month_flows f
  ON g.customer_name_norm = f.customer_name_norm
 AND g.month_start = f.month_start;

CREATE OR REPLACE VIEW ar_aging_monthly AS
WITH unpaid AS (
  SELECT
    cm.month_end,
    d.customer_name_norm,
    date_diff('day', d.debit_date, cm.month_end) AS age_days,
    GREATEST(0, d.cum_debit_curr - cm.cumulative_settlement)
      - GREATEST(0, d.cum_debit_prev - cm.cumulative_settlement) AS unpaid_amount
  FROM debit_rows d
  JOIN customer_month_cumulative cm
    ON d.customer_name_norm = cm.customer_name_norm
   AND d.debit_date <= cm.month_end
)
SELECT
  month_end,
  customer_name_norm,
  ROUND(SUM(unpaid_amount), 2) AS open_balance,
  ROUND(SUM(CASE WHEN age_days <= 30 THEN unpaid_amount ELSE 0 END), 2) AS bucket_0_30,
  ROUND(SUM(CASE WHEN age_days BETWEEN 31 AND 60 THEN unpaid_amount ELSE 0 END), 2) AS bucket_31_60,
  ROUND(SUM(CASE WHEN age_days BETWEEN 61 AND 90 THEN unpaid_amount ELSE 0 END), 2) AS bucket_61_90,
  ROUND(SUM(CASE WHEN age_days > 90 THEN unpaid_amount ELSE 0 END), 2) AS bucket_90_plus,
  ROUND(
    SUM(CASE WHEN age_days > 90 THEN unpaid_amount ELSE 0 END) / NULLIF(SUM(unpaid_amount), 0),
    6
  ) AS share_90_plus,
  CASE
    WHEN SUM(CASE WHEN age_days > 90 THEN unpaid_amount ELSE 0 END) >= 10000
      OR SUM(CASE WHEN age_days > 90 THEN unpaid_amount ELSE 0 END) / NULLIF(SUM(unpaid_amount), 0) >= 0.5
    THEN 1 ELSE 0
  END AS high_collections_risk
FROM unpaid
WHERE unpaid_amount > 0
GROUP BY month_end, customer_name_norm
ORDER BY month_end, customer_name_norm;

CREATE OR REPLACE VIEW collections_risk_latest AS
WITH latest AS (SELECT MAX(month_end) AS month_end FROM ar_aging_monthly)
SELECT
  a.*
FROM ar_aging_monthly a
JOIN latest l
  ON a.month_end = l.month_end
ORDER BY a.bucket_90_plus DESC, a.open_balance DESC, a.customer_name_norm;

CREATE OR REPLACE VIEW dso_monthly_overall AS
WITH monthly AS (
  SELECT
    month_start,
    month_end,
    SUM(debit_month) AS monthly_sales,
    SUM(ar_end_balance) AS ar_end
  FROM customer_month_cumulative
  GROUP BY month_start, month_end
)
SELECT
  month_start,
  month_end,
  ROUND(monthly_sales, 2) AS monthly_sales,
  ROUND(ar_end, 2) AS ar_end,
  ROUND(
    ar_end / NULLIF((SUM(monthly_sales) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) / 90.0), 0),
    2
  ) AS dso_3m
FROM monthly
ORDER BY month_start;

CREATE OR REPLACE VIEW dso_monthly_top_customers AS
WITH top_customers AS (
  SELECT customer_name_norm
  FROM ledger_events
  GROUP BY customer_name_norm
  ORDER BY SUM(debit_amount) DESC
  LIMIT 20
)
SELECT
  c.customer_name_norm,
  c.month_start,
  c.month_end,
  ROUND(c.debit_month, 2) AS monthly_sales,
  ROUND(c.ar_end_balance, 2) AS ar_end,
  ROUND(
    c.ar_end_balance / NULLIF((SUM(c.debit_month) OVER (
      PARTITION BY c.customer_name_norm
      ORDER BY c.month_start
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) / 90.0), 0),
    2
  ) AS dso_3m
FROM customer_month_cumulative c
JOIN top_customers t USING (customer_name_norm)
ORDER BY c.customer_name_norm, c.month_start;

CREATE OR REPLACE VIEW revenue_quality_yearly AS
SELECT
  invoice_year AS year,
  ROUND(SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END), 2) AS gross_invoices,
  ROUND(SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value > 0 THEN credit_value ELSE 0 END), 2) AS positive_adjustments,
  ROUND(SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value < 0 THEN -credit_value ELSE 0 END), 2) AS credits_abs,
  ROUND(
    SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END)
    + SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value > 0 THEN credit_value ELSE 0 END)
    - SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value < 0 THEN -credit_value ELSE 0 END),
    2
  ) AS net_invoiced,
  ROUND(SUM(CASE WHEN statement_type_norm = 'payment' THEN GREATEST(payment_value, 0) ELSE 0 END), 2) AS payments,
  ROUND(
    SUM(CASE WHEN statement_type_norm = 'payment' THEN GREATEST(payment_value, 0) ELSE 0 END)
      / NULLIF(
          SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END)
          + SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value > 0 THEN credit_value ELSE 0 END)
          - SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value < 0 THEN -credit_value ELSE 0 END),
          0
        ),
    6
  ) AS collection_ratio
FROM billing_facts
WHERE invoice_year IS NOT NULL
GROUP BY invoice_year
ORDER BY invoice_year;

CREATE OR REPLACE VIEW retention_cohorts AS
WITH invoice_customer_year AS (
  SELECT
    invoice_year AS year,
    customer_name_norm,
    SUM(GREATEST(invoice_value, 0)) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL
  GROUP BY invoice_year, customer_name_norm
), first_year AS (
  SELECT customer_name_norm, MIN(year) AS first_year
  FROM invoice_customer_year
  GROUP BY customer_name_norm
), status AS (
  SELECT
    i.year,
    i.customer_name_norm,
    i.invoice_total,
    CASE
      WHEN f.first_year = i.year THEN 'new'
      WHEN EXISTS (
        SELECT 1 FROM invoice_customer_year p
        WHERE p.customer_name_norm = i.customer_name_norm
          AND p.year = i.year - 1
      ) THEN 'retained'
      ELSE 'reactivated'
    END AS lifecycle_status
  FROM invoice_customer_year i
  JOIN first_year f USING (customer_name_norm)
), churn AS (
  SELECT
    y.year,
    COUNT(*) AS churned_customers,
    ROUND(SUM(prev.invoice_total), 2) AS churned_revenue_prev_year
  FROM (SELECT DISTINCT year FROM invoice_customer_year) y
  JOIN invoice_customer_year prev
    ON prev.year = y.year - 1
  LEFT JOIN invoice_customer_year cur
    ON cur.year = y.year
   AND cur.customer_name_norm = prev.customer_name_norm
  WHERE cur.customer_name_norm IS NULL
  GROUP BY y.year
)
SELECT
  s.year,
  COUNT(*) FILTER (WHERE lifecycle_status = 'new') AS new_customers,
  COUNT(*) FILTER (WHERE lifecycle_status = 'retained') AS retained_customers,
  COUNT(*) FILTER (WHERE lifecycle_status = 'reactivated') AS reactivated_customers,
  ROUND(SUM(invoice_total) FILTER (WHERE lifecycle_status = 'new'), 2) AS new_revenue,
  ROUND(SUM(invoice_total) FILTER (WHERE lifecycle_status = 'retained'), 2) AS retained_revenue,
  ROUND(SUM(invoice_total) FILTER (WHERE lifecycle_status = 'reactivated'), 2) AS reactivated_revenue,
  COALESCE(c.churned_customers, 0) AS churned_customers,
  COALESCE(c.churned_revenue_prev_year, 0) AS churned_revenue_prev_year
FROM status s
LEFT JOIN churn c
  ON s.year = c.year
GROUP BY s.year, c.churned_customers, c.churned_revenue_prev_year
ORDER BY s.year;

CREATE OR REPLACE VIEW invoice_size_mix_by_year AS
WITH binned AS (
  SELECT
    invoice_year AS year,
    CASE
      WHEN invoice_value < 250 THEN '<250'
      WHEN invoice_value < 1000 THEN '250-999'
      WHEN invoice_value < 5000 THEN '1000-4999'
      ELSE '5000+'
    END AS invoice_band,
    invoice_value
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL AND invoice_value > 0
), agg AS (
  SELECT
    year,
    invoice_band,
    COUNT(*) AS invoice_rows,
    ROUND(SUM(invoice_value), 2) AS invoice_total
  FROM binned
  GROUP BY year, invoice_band
)
SELECT
  year,
  invoice_band,
  invoice_rows,
  invoice_total,
  ROUND(invoice_rows::DOUBLE / NULLIF(SUM(invoice_rows) OVER (PARTITION BY year), 0), 6) AS row_share,
  ROUND(invoice_total / NULLIF(SUM(invoice_total) OVER (PARTITION BY year), 0), 6) AS revenue_share
FROM agg
ORDER BY year, invoice_band;

CREATE OR REPLACE VIEW currency_exposure_by_year AS
WITH x AS (
  SELECT
    invoice_year AS year,
    COALESCE(currency_norm, 'UNKNOWN') AS currency,
    SUM(GREATEST(invoice_value, 0)) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL
  GROUP BY invoice_year, COALESCE(currency_norm, 'UNKNOWN')
)
SELECT
  year,
  currency,
  ROUND(invoice_total, 2) AS invoice_total,
  ROUND(invoice_total / NULLIF(SUM(invoice_total) OVER (PARTITION BY year), 0), 6) AS share_of_year
FROM x
ORDER BY year, invoice_total DESC, currency;

CREATE OR REPLACE VIEW country_exposure_by_year AS
WITH x AS (
  SELECT
    invoice_year AS year,
    COALESCE(country_norm, 'UNKNOWN') AS country,
    SUM(GREATEST(invoice_value, 0)) AS invoice_total
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL
  GROUP BY invoice_year, COALESCE(country_norm, 'UNKNOWN')
)
SELECT
  year,
  country,
  ROUND(invoice_total, 2) AS invoice_total,
  ROUND(invoice_total / NULLIF(SUM(invoice_total) OVER (PARTITION BY year), 0), 6) AS share_of_year
FROM x
ORDER BY year, invoice_total DESC, country;

CREATE OR REPLACE VIEW anomalies_detected AS
WITH invoice_stats AS (
  SELECT
    invoice_year AS year,
    quantile_cont(invoice_value, 0.99) AS p99,
    quantile_cont(invoice_value, 0.01) AS p01
  FROM billing_facts
  WHERE statement_type_norm = 'invoice' AND invoice_year IS NOT NULL
  GROUP BY invoice_year
), invoice_outliers AS (
  SELECT
    'invoice_outlier' AS anomaly_type,
    invoice_date AS event_date,
    customer_name_norm,
    ROUND(invoice_value, 2) AS amount,
    ROUND(s.p99, 2) AS threshold,
    'invoice_value_above_p99' AS note
  FROM billing_facts b
  JOIN invoice_stats s
    ON b.invoice_year = s.year
  WHERE b.statement_type_norm = 'invoice'
    AND b.invoice_value > s.p99
), customer_month AS (
  SELECT
    customer_name_norm,
    date_trunc('month', invoice_date)::DATE AS month_start,
    SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END) AS invoice_total
  FROM billing_facts
  WHERE invoice_date IS NOT NULL
  GROUP BY customer_name_norm, date_trunc('month', invoice_date)::DATE
), customer_stats AS (
  SELECT
    customer_name_norm,
    AVG(invoice_total) AS mean_amt,
    STDDEV_SAMP(invoice_total) AS std_amt,
    COUNT(*) AS months_n
  FROM customer_month
  GROUP BY customer_name_norm
), customer_spikes AS (
  SELECT
    'customer_month_spike' AS anomaly_type,
    c.month_start AS event_date,
    c.customer_name_norm,
    ROUND(c.invoice_total, 2) AS amount,
    ROUND(s.mean_amt + 3 * s.std_amt, 2) AS threshold,
    'monthly_invoice_total_above_mean_plus_3sd' AS note
  FROM customer_month c
  JOIN customer_stats s USING (customer_name_norm)
  WHERE s.months_n >= 12
    AND s.std_amt IS NOT NULL
    AND c.invoice_total > s.mean_amt + 3 * s.std_amt
), credit_month AS (
  SELECT
    date_trunc('month', invoice_date)::DATE AS month_start,
    customer_name_norm,
    SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value < 0 THEN -credit_value ELSE 0 END) AS credit_abs
  FROM billing_facts
  WHERE invoice_date IS NOT NULL
  GROUP BY date_trunc('month', invoice_date)::DATE, customer_name_norm
), credit_threshold AS (
  SELECT quantile_cont(credit_abs, 0.99) AS p99_credit
  FROM credit_month
), credit_burst AS (
  SELECT
    'credit_burst' AS anomaly_type,
    c.month_start AS event_date,
    c.customer_name_norm,
    ROUND(c.credit_abs, 2) AS amount,
    ROUND(t.p99_credit, 2) AS threshold,
    'monthly_credit_abs_above_p99' AS note
  FROM credit_month c
  CROSS JOIN credit_threshold t
  WHERE c.credit_abs > t.p99_credit
)
SELECT * FROM invoice_outliers
UNION ALL
SELECT * FROM customer_spikes
UNION ALL
SELECT * FROM credit_burst
ORDER BY event_date DESC, anomaly_type, amount DESC;

CREATE OR REPLACE VIEW forecast_monthly_baseline AS
WITH monthly AS (
  SELECT
    date_trunc('month', invoice_date)::DATE AS month_start,
    ROUND(SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END), 2) AS invoices_total
  FROM billing_facts
  WHERE invoice_date IS NOT NULL
  GROUP BY date_trunc('month', invoice_date)::DATE
), idxed AS (
  SELECT
    month_start,
    invoices_total,
    EXTRACT(MONTH FROM month_start) AS month_num,
    ROW_NUMBER() OVER (ORDER BY month_start) AS idx
  FROM monthly
), bounds AS (
  SELECT MAX(month_start) AS max_month, MAX(idx) AS max_idx FROM idxed
), trend AS (
  SELECT
    COALESCE(regr_slope(invoices_total, idx), 0) AS slope
  FROM idxed
  WHERE month_start >= (SELECT max_month - INTERVAL 24 MONTH FROM bounds)
), seasonal AS (
  SELECT
    month_num,
    AVG(invoices_total) AS seasonal_avg,
    STDDEV_SAMP(invoices_total) AS seasonal_std
  FROM idxed
  WHERE month_start >= (SELECT max_month - INTERVAL 36 MONTH FROM bounds)
  GROUP BY month_num
), future AS (
  SELECT
    gs.month_start::DATE AS month_start,
    EXTRACT(MONTH FROM gs.month_start)::INT AS month_num,
    ROW_NUMBER() OVER (ORDER BY gs.month_start) AS horizon
  FROM bounds,
  generate_series(max_month + INTERVAL 1 MONTH, max_month + INTERVAL 12 MONTH, INTERVAL 1 MONTH) AS gs(month_start)
), forecast AS (
  SELECT
    f.month_start,
    ROUND(GREATEST(0, s.seasonal_avg + t.slope * f.horizon), 2) AS forecast_invoices,
    ROUND(GREATEST(0, s.seasonal_avg + t.slope * f.horizon - COALESCE(s.seasonal_std, 0)), 2) AS forecast_low,
    ROUND(GREATEST(0, s.seasonal_avg + t.slope * f.horizon + COALESCE(s.seasonal_std, 0)), 2) AS forecast_high
  FROM future f
  LEFT JOIN seasonal s USING (month_num)
  CROSS JOIN trend t
)
SELECT
  i.month_start,
  i.invoices_total,
  NULL::DOUBLE AS forecast_invoices,
  NULL::DOUBLE AS forecast_low,
  NULL::DOUBLE AS forecast_high,
  0 AS is_forecast
FROM idxed i
UNION ALL
SELECT
  f.month_start,
  NULL::DOUBLE AS invoices_total,
  f.forecast_invoices,
  f.forecast_low,
  f.forecast_high,
  1 AS is_forecast
FROM forecast f
ORDER BY month_start;

CREATE OR REPLACE VIEW reconciliation_customer_year AS
WITH yearly AS (
  SELECT
    invoice_year AS year,
    customer_name_norm,
    ROUND(SUM(CASE WHEN statement_type_norm = 'invoice' THEN GREATEST(invoice_value, 0) ELSE 0 END), 2) AS gross_invoices,
    ROUND(SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value > 0 THEN credit_value ELSE 0 END), 2) AS positive_adjustments,
    ROUND(SUM(CASE WHEN statement_type_norm = 'credit' AND credit_value < 0 THEN -credit_value ELSE 0 END), 2) AS credits_abs,
    ROUND(SUM(CASE WHEN statement_type_norm = 'payment' THEN GREATEST(payment_value, 0) ELSE 0 END), 2) AS payments
  FROM billing_facts
  WHERE invoice_year IS NOT NULL
  GROUP BY invoice_year, customer_name_norm
), netted AS (
  SELECT
    year,
    customer_name_norm,
    gross_invoices,
    positive_adjustments,
    credits_abs,
    payments,
    ROUND(gross_invoices + positive_adjustments - credits_abs, 2) AS net_invoiced,
    ROUND(gross_invoices + positive_adjustments - credits_abs - payments, 2) AS year_net_delta
  FROM yearly
)
SELECT
  year,
  customer_name_norm,
  gross_invoices,
  positive_adjustments,
  credits_abs,
  net_invoiced,
  payments,
  year_net_delta,
  ROUND(SUM(year_net_delta) OVER (PARTITION BY customer_name_norm ORDER BY year), 2) AS running_balance
FROM netted
ORDER BY customer_name_norm, year;

CREATE OR REPLACE VIEW reconciliation_unmatched_invoices AS
WITH settlement_totals AS (
  SELECT
    customer_name_norm,
    SUM(settlement_amount) AS total_settlement
  FROM ledger_events
  GROUP BY customer_name_norm
), unpaid AS (
  SELECT
    d.customer_name_norm,
    d.debit_row_id,
    d.debit_date,
    d.debit_amount,
    GREATEST(0, d.cum_debit_curr - COALESCE(s.total_settlement, 0))
      - GREATEST(0, d.cum_debit_prev - COALESCE(s.total_settlement, 0)) AS unmatched_amount
  FROM (
    SELECT row_id AS debit_row_id, customer_name_norm, debit_date, debit_amount, cum_debit_prev, cum_debit_curr
    FROM debit_rows
  ) d
  LEFT JOIN settlement_totals s USING (customer_name_norm)
)
SELECT
  customer_name_norm,
  debit_row_id,
  debit_date,
  ROUND(debit_amount, 2) AS debit_amount,
  ROUND(unmatched_amount, 2) AS unmatched_amount,
  date_diff('day', debit_date, (SELECT MAX(event_date) FROM ledger_events)) AS age_days_asof_latest
FROM unpaid
WHERE unmatched_amount > 0
ORDER BY unmatched_amount DESC, customer_name_norm, debit_date;
