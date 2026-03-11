# Strategic Intent

## Purpose

Create a reliable decision system for billing, collections, and customer concentration risk using deterministic, text-first analytics and an accessible dashboard.

## Primary outcomes

- Faster, higher-confidence monthly and quarterly financial reviews.
- Earlier detection of cashflow risk (A/R aging, DSO deterioration, unmatched balances).
- Better concentration risk management (top customer dependency by year).
- Repeatable refresh process when new source data arrives.

## Scope

In scope:
- Source ingestion and normalization from `nc-2002-2026.xlsx`.
- SQL-first analytics pipeline (`analysis/*.sql`) with CSV/MD outputs.
- Executive dashboard (`dashboard/index.html`) with KPI/chart/table definitions.
- Operational docs and planning artifacts.

Out of scope (current phase):
- Real-time/streaming ingestion.
- ERP-grade invoice-level settlement ledger.
- Multi-user auth, permissions, or backend services.

## Decision principles

- Determinism over convenience.
- Text artifacts over opaque state.
- SQL-first for aggregations and lifecycle logic.
- Explicit assumptions and validation checks in docs.
- Small, auditable changes and measurable outcomes.

## Success signals

- New workbook can be dropped in and refreshed with one command.
- Output diffs are reviewable in git.
- Dashboard terms are understandable without analyst support (hover + persistent help).
- Run-level validation checks consistently pass.
