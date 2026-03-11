-- 02_quality_checks.sql
-- Produces quality-check views: missingness, constant columns, and categorical anomalies.

CREATE OR REPLACE VIEW qc_missingness AS
WITH total AS (
  SELECT COUNT(*)::DOUBLE AS total_rows FROM billing_facts
), missing_counts AS (
  SELECT 'row_id' AS column_name, SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS missing_count FROM billing_facts
  UNION ALL SELECT 'invoice_date', SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'invoice_year', SUM(CASE WHEN invoice_year IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'invoice_month', SUM(CASE WHEN invoice_month IS NULL OR TRIM(invoice_month) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'statement_type_raw', SUM(CASE WHEN statement_type_raw IS NULL OR TRIM(statement_type_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'statement_type_norm', SUM(CASE WHEN statement_type_norm IS NULL OR TRIM(statement_type_norm) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'currency_raw', SUM(CASE WHEN currency_raw IS NULL OR TRIM(currency_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'currency_norm', SUM(CASE WHEN currency_norm IS NULL OR TRIM(currency_norm) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'country_raw', SUM(CASE WHEN country_raw IS NULL OR TRIM(country_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'country_norm', SUM(CASE WHEN country_norm IS NULL OR TRIM(country_norm) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'customer_name_raw', SUM(CASE WHEN customer_name_raw IS NULL OR TRIM(customer_name_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'customer_name_norm', SUM(CASE WHEN customer_name_norm IS NULL OR TRIM(customer_name_norm) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'payment_method_raw', SUM(CASE WHEN payment_method_raw IS NULL OR TRIM(payment_method_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'work_order_number_raw', SUM(CASE WHEN work_order_number_raw IS NULL OR TRIM(work_order_number_raw) = '' THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'invoice_amount', SUM(CASE WHEN invoice_amount IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'payment_amount', SUM(CASE WHEN payment_amount IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'invoice_value', SUM(CASE WHEN invoice_value IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'payment_value', SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) FROM billing_facts
  UNION ALL SELECT 'credit_value', SUM(CASE WHEN credit_value IS NULL THEN 1 ELSE 0 END) FROM billing_facts
)
SELECT
  m.column_name,
  m.missing_count::BIGINT AS missing_count,
  t.total_rows::BIGINT AS total_rows,
  ROUND(100.0 * m.missing_count / t.total_rows, 2) AS missing_pct
FROM missing_counts m
CROSS JOIN total t
ORDER BY missing_pct DESC, m.column_name;

CREATE OR REPLACE VIEW qc_constant_columns AS
WITH raw_cast AS (
  SELECT * FROM (
    SELECT
      CAST("Amount of Payment" AS VARCHAR) AS amount_of_payment,
      CAST("Billing Address" AS VARCHAR) AS billing_address,
      CAST("Billing City" AS VARCHAR) AS billing_city,
      CAST("Billing Company" AS VARCHAR) AS billing_company,
      CAST("Billing Contact" AS VARCHAR) AS billing_contact,
      CAST("Billing Contact Address Email" AS VARCHAR) AS billing_contact_email,
      CAST("Billing Country" AS VARCHAR) AS billing_country,
      CAST("Billing Credit Card Name" AS VARCHAR) AS billing_credit_card_name,
      CAST("Billing Fax" AS VARCHAR) AS billing_fax,
      CAST("Billing Purchase Order Number" AS VARCHAR) AS billing_po_number,
      CAST("Billing State" AS VARCHAR) AS billing_state,
      CAST("Billing Telephone" AS VARCHAR) AS billing_telephone,
      CAST("Billing Zip" AS VARCHAR) AS billing_zip,
      CAST("Currency" AS VARCHAR) AS currency,
      CAST("ID_Parent" AS VARCHAR) AS id_parent,
      CAST("ID_Statement Item" AS VARCHAR) AS id_statement_item,
      CAST("Invoice Date" AS VARCHAR) AS invoice_date,
      CAST("Invoice Grand Total" AS VARCHAR) AS invoice_grand_total,
      CAST("Invoice PayPal URL Statement" AS VARCHAR) AS invoice_paypal_url_statement,
      CAST("Payment Method" AS VARCHAR) AS payment_method,
      CAST("Payment Notes" AS VARCHAR) AS payment_notes,
      CAST("Statement Item Type" AS VARCHAR) AS statement_item_type,
      CAST("Sub Total" AS VARCHAR) AS sub_total,
      CAST("Summary Time Billing Total Billed" AS VARCHAR) AS summary_time_billing_total_billed,
      CAST("Tax GST" AS VARCHAR) AS tax_gst,
      CAST("Time Billing Total Billed Hrs" AS VARCHAR) AS time_billing_total_billed_hrs,
      CAST("Total Invoice" AS VARCHAR) AS total_invoice,
      CAST("Total of Inv Charges" AS VARCHAR) AS total_of_inv_charges,
      CAST("Total of Payments" AS VARCHAR) AS total_of_payments,
      CAST("Total of Subtotal" AS VARCHAR) AS total_of_subtotal,
      CAST("Total Outstanding" AS VARCHAR) AS total_outstanding,
      CAST("Total Tax" AS VARCHAR) AS total_tax,
      CAST("Work order budget minus worked" AS VARCHAR) AS work_order_budget_minus_worked,
      CAST("Work order Hours Work Sum" AS VARCHAR) AS work_order_hours_work_sum,
      CAST("Work Order Number" AS VARCHAR) AS work_order_number
    FROM raw_billing
  )
  UNPIVOT(value FOR column_name IN (
    amount_of_payment,
    billing_address,
    billing_city,
    billing_company,
    billing_contact,
    billing_contact_email,
    billing_country,
    billing_credit_card_name,
    billing_fax,
    billing_po_number,
    billing_state,
    billing_telephone,
    billing_zip,
    currency,
    id_parent,
    id_statement_item,
    invoice_date,
    invoice_grand_total,
    invoice_paypal_url_statement,
    payment_method,
    payment_notes,
    statement_item_type,
    sub_total,
    summary_time_billing_total_billed,
    tax_gst,
    time_billing_total_billed_hrs,
    total_invoice,
    total_of_inv_charges,
    total_of_payments,
    total_of_subtotal,
    total_outstanding,
    total_tax,
    work_order_budget_minus_worked,
    work_order_hours_work_sum,
    work_order_number
  ))
)
SELECT
  column_name,
  COUNT(DISTINCT value) FILTER (WHERE value IS NOT NULL AND TRIM(value) <> '') AS distinct_non_null_values,
  MIN(value) FILTER (WHERE value IS NOT NULL AND TRIM(value) <> '') AS example_value,
  CASE WHEN COUNT(DISTINCT value) FILTER (WHERE value IS NOT NULL AND TRIM(value) <> '') <= 1 THEN TRUE ELSE FALSE END AS is_constant
FROM raw_cast
GROUP BY column_name
HAVING COUNT(DISTINCT value) FILTER (WHERE value IS NOT NULL AND TRIM(value) <> '') <= 1
ORDER BY column_name;

CREATE OR REPLACE VIEW qc_bad_categorical_values AS
WITH currency_bad AS (
  SELECT
    'currency' AS field_name,
    COALESCE(currency_raw, '<NULL>') AS bad_value,
    COUNT(*) AS row_count,
    MIN(customer_name_norm) AS example_customer
  FROM billing_facts
  WHERE currency_raw IS NULL OR currency_norm = 'OTHER'
  GROUP BY 1, 2
), country_bad AS (
  SELECT
    'country' AS field_name,
    COALESCE(country_raw, '<NULL>') AS bad_value,
    COUNT(*) AS row_count,
    MIN(customer_name_norm) AS example_customer
  FROM billing_facts
  WHERE country_raw IS NULL OR country_norm = 'OTHER'
  GROUP BY 1, 2
), statement_bad AS (
  SELECT
    'statement_item_type' AS field_name,
    COALESCE(statement_type_raw, '<NULL>') AS bad_value,
    COUNT(*) AS row_count,
    MIN(customer_name_norm) AS example_customer
  FROM billing_facts
  WHERE statement_type_raw IS NULL OR statement_type_norm = 'other'
  GROUP BY 1, 2
)
SELECT * FROM currency_bad
UNION ALL
SELECT * FROM country_bad
UNION ALL
SELECT * FROM statement_bad
ORDER BY field_name, row_count DESC, bad_value;
