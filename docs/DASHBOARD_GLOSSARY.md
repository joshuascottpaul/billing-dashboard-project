# Dashboard Glossary

This document defines all KPIs, charts, and tables in the Billing Intelligence Dashboard. Use this reference when reviewing dashboard changes or adding new metrics.

**Last updated:** 2026-03-10  
**Strategic alignment:** See `STRATEGIC_INTENT.md` for purpose and success signals.

---

## KPI Cards

### Invoices Total (Focus Year)
- **Definition:** Sum of all invoice amounts for the focus year.
- **Formula:** `SUM(invoice_value) WHERE invoice_year = focus_year`
- **Source:** `yearly_summary.csv`
- **Why it matters:** Primary revenue signal for the selected year.
- **Strategic link:** Faster financial reviews (Purpose #1).

### Payments Total (Focus Year)
- **Definition:** Sum of all payment amounts for the focus year.
- **Formula:** `SUM(payment_value) WHERE invoice_year = focus_year`
- **Source:** `yearly_summary.csv`
- **Why it matters:** Cash collected indicator.
- **Strategic link:** Cashflow risk detection (Purpose #2).

### Net Total (Focus Year)
- **Definition:** Invoices + Credits - Payments for focus year.
- **Formula:** `invoices_total + credits_total - payments_total`
- **Source:** `yearly_summary.csv`
- **Why it matters:** Net position after collections and adjustments.
- **Risk indicator:** Negative = collections lagging or high credits.

### Top-1 Concentration Share
- **Definition:** Largest customer's share of total revenue (focus year).
- **Formula:** `max(customer_invoice_total) / SUM(all_customer_invoice_total)`
- **Source:** `concentration_by_year.csv`
- **Why it matters:** Single-customer dependency risk.
- **Risk thresholds:** 
  - 🟢 < 30%: Healthy diversification
  - 🟡 30-50%: Monitor closely
  - 🔴 > 50%: High concentration risk
- **Strategic link:** Concentration risk management (Purpose #3).

### Latest DSO (Days Sales Outstanding)
- **Definition:** Average days to collect payment (3-month rolling).
- **Formula:** `(AR_end / monthly_sales) * 90` (latest month available)
- **Source:** `dso_monthly_overall.csv`
- **Why it matters:** Collection efficiency metric.
- **Risk thresholds:**
  - 🟢 < 30 days: Excellent
  - 🟡 30-60 days: Monitor
  - 🔴 > 60 days: Action needed
- **Strategic link:** Cashflow risk detection (Purpose #2).

### High-Risk A/R Customers
- **Definition:** Count of customers with >50% of balance in 90+ day bucket.
- **Source:** `collections_risk_latest.csv`
- **Why it matters:** Accounts needing immediate collections attention.
- **Strategic link:** Cashflow risk detection (Purpose #2).

---

## Charts

### Yearly Invoices, Payments, Credits
- **Type:** Grouped bar chart
- **Data:** Annual totals by transaction type
- **Source:** `yearly_summary.csv`
- **Help text:** "Annual totals split by transaction type over selected year range."
- **Strategic link:** Repeatable refresh process (Purpose #4).

### Monthly Invoices + Forecast
- **Type:** Line chart with optional forecast overlay
- **Data:** Monthly invoice totals + 12-month baseline forecast
- **Source:** `monthly_summary.csv`, `forecast_monthly_baseline.csv`
- **Help text:** "Monthly invoice trend with optional forecast projection."
- **Strategic link:** Faster financial reviews (Purpose #1).

### Concentration by Year (Top 1/5/10)
- **Type:** Multi-line chart
- **Data:** Cumulative revenue share for top 1, 5, and 10 customers
- **Source:** `concentration_by_year.csv`
- **Help text:** "Revenue concentration trend over selected year range."
- **Strategic link:** Concentration risk management (Purpose #3).

### Invoice Drift Percentiles
- **Type:** Multi-line chart
- **Data:** Median, P75, P90, P95 invoice amounts by year
- **Source:** `invoice_drift.csv`
- **Help text:** "Distribution shift in invoice amounts over selected year range."
- **Strategic link:** Faster financial reviews (Purpose #1).

### Retention and Churn Cohorts
- **Type:** Stacked bar chart
- **Data:** Customer counts by lifecycle status (new, retained, reactivated, churned)
- **Source:** `retention_cohorts.csv`
- **Help text:** "Customer lifecycle counts by year."
- **Strategic link:** Cashflow risk detection (Purpose #2).

### Invoice Size Mix by Year
- **Type:** 100% stacked bar chart
- **Data:** Revenue share by invoice size bucket (<$500, $500-$1K, $1K-$5K, $5K+)
- **Source:** `invoice_size_mix_by_year.csv`
- **Help text:** "Revenue share by invoice size bucket by year."
- **Strategic link:** Faster financial reviews (Purpose #1).

### Currency Exposure (Focus Year)
- **Type:** Donut chart
- **Data:** Invoice revenue by currency (CAD, USD, OTHER)
- **Source:** `currency_exposure_by_year.csv`
- **Help text:** "Top currencies by focus-year invoice revenue share."
- **Strategic link:** Concentration risk management (Purpose #3).

### Country Exposure (Focus Year)
- **Type:** Donut chart
- **Data:** Invoice revenue by country (CA, US, GB, OTHER)
- **Source:** `country_exposure_by_year.csv`
- **Help text:** "Top countries by focus-year invoice revenue share."
- **Strategic link:** Concentration risk management (Purpose #3).

### Top-N Customers Cross-Tab (Focus vs Prior Year)
- **Type:** Grouped bar chart
- **Data:** Top N customers by focus year sales, compared to prior year
- **Source:** Derived from customer-level aggregations
- **Help text:** "Ranks top N customers by focus-year sales, compares prior-year sales, and overlays YoY%. Green indicates expansion, red indicates contraction."
- **Strategic link:** Concentration risk management (Purpose #3).

---

## Tables

### Top Customers (Focus Year)
| Column | Definition |
|--------|------------|
| Rank | Position by invoice total (descending) |
| Customer | Normalized customer name |
| Invoice Rows | Count of invoice transactions |
| Invoice Total | Sum of invoice amounts |
| Share of Total | Percentage of total revenue |
| Cumulative Share | Running total percentage (Pareto) |

### Year-over-Year Delta (Focus vs Prior)
| Column | Definition |
|--------|------------|
| Customer | Normalized customer name |
| Prior Year Sales | Revenue in year before focus year |
| Focus Year Sales | Revenue in focus year |
| Delta | Absolute change (Focus - Prior) |
| Delta % | Percentage change |

### Collections Risk (Latest)
| Column | Definition |
|--------|------------|
| Customer | Normalized customer name |
| Open Balance | Total outstanding amount |
| Bucket 0-30 | Amount in 0-30 day aging bucket |
| Bucket 31-60 | Amount in 31-60 day aging bucket |
| Bucket 61-90 | Amount in 61-90 day aging bucket |
| Bucket 90+ | Amount in 90+ day aging bucket |
| Share 90+ | Percentage of balance in 90+ bucket |
| High Risk | Flag (1 = >50% in 90+ bucket) |

### Payment Behavior Scorecard
| Column | Definition |
|--------|------------|
| Customer | Normalized customer name |
| Matched Amount | Total invoice-payment matched amount |
| Median Days to Pay | Median collection time |
| Late Share >60d | Percentage of payments >60 days late |

### Unmatched Invoices
| Column | Definition |
|--------|------------|
| Customer | Normalized customer name |
| Debit Date | Original invoice date |
| Unmatched Amount | Outstanding balance not tied to payment |
| Age Days | Days since invoice date |

### Recent Anomalies
| Column | Definition |
|--------|------------|
| Anomaly Type | `invoice_outlier`, `customer_month_spike`, `credit_burst` |
| Event Date | Date of detected anomaly |
| Customer | Normalized customer name |
| Amount | Anomalous amount |
| Threshold | Detection threshold that was exceeded |
| Note | Explanation of anomaly type |

---

## Anomaly Type Definitions

### invoice_outlier
- **Definition:** An invoice amount that is unusually high or low versus normal patterns.
- **Detection:** Amount exceeds P99 threshold for historical invoice distribution.
- **Action:** Review for data entry error or legitimate large transaction.

### customer_month_spike
- **Definition:** A customer's monthly billed amount jumped sharply versus their baseline.
- **Detection:** Monthly total exceeds mean + 3 standard deviations.
- **Action:** Verify with customer or sales team for expected large order.

### credit_burst
- **Definition:** Credits or refunds increased unusually in a short period.
- **Detection:** Monthly credit absolute value exceeds P99 threshold.
- **Action:** Investigate potential service issues or billing corrections.

---

## Strategic Alignment Checklist

When adding new KPIs, charts, or tables, verify:

- [ ] **Purpose alignment:** Supports one of the 4 primary outcomes in `STRATEGIC_INTENT.md`
- [ ] **Definition clarity:** Has clear formula and data source
- [ ] **Help text:** Includes hover tooltip and glossary entry
- [ ] **Risk thresholds:** Has 🟢🟡🔴 bands if used for risk monitoring
- [ ] **Stakeholder test:** Understandable without analyst support (Success Signal #3)
- [ ] **Determinism:** Output is reproducible from source + SQL
- [ ] **Git reviewable:** Output diffs are reviewable (Success Signal #2)

---

## Change Log

| Date | Change | Linked To |
|------|--------|-----------|
| 2026-03-10 | Initial glossary created (T-006) | `STRATEGIC_INTENT.md`, `dashboard/README.md` |
