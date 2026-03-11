-- 01_ingest.sql
-- Loads CSV converted from nc-2002-2026.xlsx and normalizes core fields.

CREATE OR REPLACE TABLE raw_billing AS
SELECT *
FROM read_csv_auto(
  'analysis/tmp/nc-2002-2026.csv',
  header = true,
  all_varchar = true,
  nullstr = ['', 'NULL', 'null', 'N/A', 'n/a']
);

CREATE OR REPLACE TABLE billing_norm AS
WITH base AS (
  SELECT
    row_number() OVER () AS row_id,
    NULLIF(TRIM("Invoice Date"), '') AS invoice_date_raw,
    NULLIF(TRIM("Statement Item Type"), '') AS statement_type_raw,
    NULLIF(TRIM("Currency"), '') AS currency_raw,
    NULLIF(TRIM("Billing Country"), '') AS country_raw,
    NULLIF(TRIM("Billing Company"), '') AS billing_company_raw,
    NULLIF(TRIM("Billing Contact"), '') AS billing_contact_raw,
    NULLIF(TRIM("Billing Contact Address Email"), '') AS billing_email_raw,
    NULLIF(TRIM("Payment Method"), '') AS payment_method_raw,
    NULLIF(TRIM("Work Order Number"), '') AS work_order_number_raw,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Invoice Grand Total"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS invoice_amount,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Amount of Payment"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS payment_amount,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Tax GST"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS tax_gst,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Sub Total"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS sub_total,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Total Invoice"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS total_invoice_legacy,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Total of Payments"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS total_payments_legacy,
    TRY_CAST(NULLIF(regexp_replace(TRIM("Total Outstanding"), '[^0-9\\.-]', '', 'g'), '') AS DOUBLE) AS total_outstanding_legacy,
    *
  FROM raw_billing
)
SELECT
  row_id,
  invoice_date_raw,
  COALESCE(
    CAST(try_strptime(invoice_date_raw, '%Y-%m-%d %H:%M:%S') AS DATE),
    CAST(try_strptime(invoice_date_raw, '%Y-%m-%d') AS DATE),
    CAST(try_strptime(invoice_date_raw, '%m/%d/%Y') AS DATE),
    CAST(try_strptime(invoice_date_raw, '%Y/%m/%d') AS DATE)
  ) AS invoice_date,
  statement_type_raw,
  CASE
    WHEN lower(statement_type_raw) IN ('invoice', 'invoicermvd') THEN 'invoice'
    WHEN lower(statement_type_raw) = 'payment' THEN 'payment'
    WHEN lower(statement_type_raw) IN ('credit', 'credit note', 'debit memo') THEN 'credit'
    ELSE 'other'
  END AS statement_type_norm,
  currency_raw,
  CASE
    WHEN currency_raw IS NULL THEN NULL
    WHEN upper(currency_raw) IN ('CDN', 'CDN$', 'CAD', 'CAD$') THEN 'CAD'
    WHEN upper(currency_raw) IN ('CDN', 'CDN ') THEN 'CAD'
    WHEN upper(currency_raw) IN ('US', 'USA', 'USD', 'US$', 'U.S.') THEN 'USD'
    WHEN upper(currency_raw) = 'CANADA' THEN 'CAD'
    ELSE 'OTHER'
  END AS currency_norm,
  country_raw,
  CASE
    WHEN country_raw IS NULL THEN NULL
    WHEN upper(country_raw) IN ('CANADA', 'CA', 'CAN') THEN 'CA'
    WHEN upper(country_raw) IN ('USA', 'US', 'UNITED STATES', 'UNITED STATES OF AMERICA') THEN 'US'
    WHEN upper(country_raw) IN ('UK', 'UNITED KINGDOM', 'GB', 'GREAT BRITAIN') THEN 'GB'
    WHEN upper(country_raw) IN ('IRELAND', 'IE') THEN 'IE'
    WHEN upper(country_raw) IN ('SPAIN', 'ES') THEN 'ES'
    WHEN upper(country_raw) IN ('ISRAEL', 'IL') THEN 'IL'
    WHEN upper(country_raw) IN ('MEXICO', 'MX') THEN 'MX'
    WHEN upper(country_raw) IN ('MOROCCO', 'MA') THEN 'MA'
    WHEN upper(country_raw) IN ('SWITZERLAND', 'CH') THEN 'CH'
    WHEN upper(country_raw) IN ('SWEDEN', 'SE') THEN 'SE'
    ELSE 'OTHER'
  END AS country_norm,
  billing_company_raw,
  billing_contact_raw,
  billing_email_raw,
  COALESCE(billing_company_raw, billing_contact_raw, billing_email_raw, 'UNKNOWN') AS customer_name_raw,
  UPPER(TRIM(regexp_replace(COALESCE(billing_company_raw, billing_contact_raw, billing_email_raw, 'UNKNOWN'), '\\s+', ' ', 'g'))) AS customer_name_norm,
  payment_method_raw,
  work_order_number_raw,
  invoice_amount,
  payment_amount,
  tax_gst,
  sub_total,
  total_invoice_legacy,
  total_payments_legacy,
  total_outstanding_legacy,
  * EXCLUDE (
    row_id,
    invoice_date_raw,
    statement_type_raw,
    currency_raw,
    country_raw,
    billing_company_raw,
    billing_contact_raw,
    billing_email_raw,
    payment_method_raw,
    work_order_number_raw,
    invoice_amount,
    payment_amount,
    tax_gst,
    sub_total,
    total_invoice_legacy,
    total_payments_legacy,
    total_outstanding_legacy
  )
FROM base;

CREATE OR REPLACE TABLE billing_facts AS
SELECT
  row_id,
  invoice_date,
  EXTRACT(YEAR FROM invoice_date) AS invoice_year,
  strftime(invoice_date, '%Y-%m') AS invoice_month,
  statement_type_raw,
  statement_type_norm,
  currency_raw,
  currency_norm,
  country_raw,
  country_norm,
  customer_name_raw,
  customer_name_norm,
  payment_method_raw,
  work_order_number_raw,
  invoice_amount,
  payment_amount,
  CASE WHEN statement_type_norm = 'invoice' THEN COALESCE(invoice_amount, 0) ELSE 0 END AS invoice_value,
  CASE WHEN statement_type_norm = 'payment' THEN COALESCE(payment_amount, 0) ELSE 0 END AS payment_value,
  CASE WHEN statement_type_norm = 'credit' THEN COALESCE(invoice_amount, 0) ELSE 0 END AS credit_value,
  total_invoice_legacy,
  total_payments_legacy,
  total_outstanding_legacy
FROM billing_norm;
