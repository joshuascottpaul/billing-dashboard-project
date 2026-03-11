# Data Quality Report

## Sanity Checks

- Row count (`billing_facts`): **5000**
- Date range: **2024-01-01** to **2026-02-28**
- Statement rows: invoice=2494, payment=1243, credit=1263
- Invoice sum from facts: **12417953.93**
- Invoice sum from yearly summary: **12417953.93**
- Sum difference (facts - yearly): **0.0**

## Missingness (Top 15)

| column_name           | missing_count | total_rows | missing_pct |
| --------------------- | ------------- | ---------- | ----------- |
| payment_method_raw    | 3757          | 5000       | 75.14       |
| work_order_number_raw | 2519          | 5000       | 50.38       |
| country_norm          | 0             | 5000       | 0.0         |
| country_raw           | 0             | 5000       | 0.0         |
| credit_value          | 0             | 5000       | 0.0         |
| currency_norm         | 0             | 5000       | 0.0         |
| currency_raw          | 0             | 5000       | 0.0         |
| customer_name_norm    | 0             | 5000       | 0.0         |
| customer_name_raw     | 0             | 5000       | 0.0         |
| invoice_amount        | 0             | 5000       | 0.0         |
| invoice_date          | 0             | 5000       | 0.0         |
| invoice_month         | 0             | 5000       | 0.0         |
| invoice_value         | 0             | 5000       | 0.0         |
| invoice_year          | 0             | 5000       | 0.0         |
| payment_amount        | 0             | 5000       | 0.0         |

## Constant Columns

| column_name | distinct_non_null_values | example_value | is_constant |
| ----------- | ------------------------ | ------------- | ----------- |

## Bad Categorical Values (Top 25)

| field_name | bad_value | row_count | example_customer |
| ---------- | --------- | --------- | ---------------- |
| country    | DE        | 1264      | ACME CORPORATION |
| currency   | EUR       | 1234      | ACME CORPORATION |

## Yearly Summary

| year | invoice_rows | payment_rows | credit_rows | invoices_total | payments_total | credits_total | net_total  |
| ---- | ------------ | ------------ | ----------- | -------------- | -------------- | ------------- | ---------- |
| 2024 | 1106         | 548          | 622         | 5506369.14     | 4139684.16     | 1574429.53    | 2941114.51 |
| 2025 | 1198         | 621          | 566         | 5931880.26     | 4437765.03     | 1451831.66    | 2945946.89 |
| 2026 | 190          | 74           | 75          | 979704.53      | 562538.29      | 180647.95     | 597814.19  |

## Top Customers 2025 (Top 15)

| rank_2025 | customer_name_norm  | invoice_rows | invoice_total | share_of_2025 | cumulative_share_2025 | in_2025_pareto_80 |
| --------- | ------------------- | ------------ | ------------- | ------------- | --------------------- | ----------------- |
| 1         | SMART BUSINESS CO   | 185          | 936966.29     | 0.157954      | 0.157954              | 1                 |
| 2         | INNOVATION LABS     | 165          | 836569.12     | 0.141029      | 0.298984              | 1                 |
| 3         | CLOUD SYSTEMS       | 157          | 831644.9      | 0.140199      | 0.439183              | 1                 |
| 4         | TECHSTART INC       | 150          | 749190.89     | 0.126299      | 0.565482              | 1                 |
| 5         | DIGITAL SOLUTIONS   | 131          | 681220.3      | 0.114841      | 0.680322              | 1                 |
| 6         | ACME CORPORATION    | 145          | 672177.86     | 0.113316      | 0.793639              | 1                 |
| 7         | DATAFLOW PARTNERS   | 138          | 642046.44     | 0.108237      | 0.901875              | 0                 |
| 8         | GLOBAL SERVICES LLC | 127          | 582064.46     | 0.098125      | 1.0                   | 0                 |

## Invoice Drift (Most Recent 10 Years)

| year | invoice_rows | invoices_total | median_invoice | p75_invoice | p90_invoice | p95_invoice | negative_share |
| ---- | ------------ | -------------- | -------------- | ----------- | ----------- | ----------- | -------------- |
| 2026 | 190          | 979704.53      | 3994.06        | 8162.14     | 11527.13    | 12853.14    | 0.0            |
| 2025 | 1198         | 5931880.26     | 3792.06        | 7249.4      | 12037.95    | 13582.74    | 0.0            |
| 2024 | 1106         | 5506369.14     | 3758.2         | 7211.82     | 11926.5     | 13515.06    | 0.0            |
