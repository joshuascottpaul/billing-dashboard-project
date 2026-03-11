# Billing Dashboard Project

Reproducible billing analysis + executive dashboard built from plain text artifacts.

## Start here

From project root:

```bash
bash analysis/run.sh
```

Open dashboard directly:

```bash
open dashboard/index.html
```

If browser blocks local CSV loading via `file://`, host on port `8000`:

```bash
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000/dashboard/
```

## Key docs

- `STRATEGIC_INTENT.md`: goals, scope, decision principles, success signals
- `analysis/README.md`: pipeline runbook and output catalog
- `dashboard/README.md`: dashboard usage and help model
- `OVERVIEW.MD`: orchestration and governance model
- `OUTCOMES.md`: metrics and review cadence
- `tasks.yaml` / `TASKS.md`: planning backlog (source/generated)

## Dashboard E2E tests (headless)

From project root:

```bash
npm install
npx playwright install --with-deps chromium
npm run test:e2e
```

What this covers:
- dashboard load and KPI rendering
- global master filter behavior
- preset application and active filter chips
- customer drill-down drawer
- resizable table columns
- CSV/PNG export actions in headless mode
- URL query-arg state coverage with explicit scenarios:
  - `?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0`
  - `?yf=2018&yt=2020&fy=2019&n=5&fc=1&cm=1`
  - `?yf=2002&yt=2006&fy=2004&n=20&fc=0&cm=1`
  - `?yf=2025&yt=2025&fy=2025&n=8&fc=1&cm=0`
  - invalid args clamp case `?yf=1900&yt=9999&fy=9999&n=999&fc=0&cm=1`

Run only URL query-arg tests:

```bash
npm run test:e2e:query
```
