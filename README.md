# Billing Intelligence Dashboard

[![CI](https://github.com/joshuascottpaul/billing-dashboard-project/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuascottpaul/billing-dashboard-project/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/joshuascottpaul/billing-dashboard-project)](https://github.com/joshuascottpaul/billing-dashboard-project/releases)
[![Homebrew](https://img.shields.io/homebrew/v/billing-dashboard?homebrew_tap=joshuascottpaul/homebrew-tap)](https://github.com/joshuascottpaul/homebrew-tap)
[![License](https://img.shields.io/github/license/joshuascottpaul/billing-dashboard-project)](LICENSE)

> **Executive dashboard for billing analytics, collections risk, and customer concentration analysis**

---

## Quick Start

### Option 1: Homebrew (Recommended)

```bash
# Install
brew tap joshuascottpaul/homebrew-tap
brew install billing-dashboard

# Run analytics
billing-dashboard run

# Start dashboard server
billing-dashboard serve

# Open in browser
open http://localhost:8000/dashboard/
```

### Option 2: From Source

```bash
# Clone repository
git clone https://github.com/joshuascottpaul/billing-dashboard-project.git
cd billing-dashboard-project

# Use sample data (included)
cp nc-2002-2026-sample.xlsx nc-2002-2026.xlsx

# Run analytics pipeline
bash analysis/run.sh

# Open dashboard
open dashboard/index.html
```

---

## Features

### 📊 Analytics Pipeline

- **4 SQL stages** (DuckDB) for deterministic analysis
- **23 output files** including:
  - Yearly/monthly summaries
  - Customer concentration analysis
  - A/R aging and DSO metrics
  - Payment behavior scorecards
  - Retention/churn cohorts
  - Anomaly detection
  - Forecast baseline
  - Reconciliation reports

### 📈 Executive Dashboard

- **6 KPI cards** with risk indicators (🟢🟡🔴)
- **9 interactive charts** (Chart.js)
- **6 sortable/resizable tables**
- **Global filter bar** with preset views
- **Customer drill-down** drawer
- **Export capabilities** (CSV, PNG, ZIP bundle)
- **Bookmarkable URLs** with state preservation

### 🧪 Testing

- **12 E2E tests** (Playwright)
- **16 unit tests** (task generator)
- **CI/CD pipeline** (GitHub Actions)
- **Headless browser testing**

### 🤖 Automation

- **Task generator** (tasks.yaml → TASKS.md)
- **Schema validation** with actionable errors
- **Auto-updating Homebrew formula**
- **DORA metrics tracking**

---

## Installation

### Homebrew (macOS/Linux)

```bash
# Tap repository
brew tap joshuascottpaul/homebrew-tap

# Install
brew install billing-dashboard

# Verify installation
billing-dashboard version
```

### From Source

**Requirements:**
- Python 3.14+
- Node.js 18+
- DuckDB

```bash
# Clone
git clone https://github.com/joshuascottpaul/billing-dashboard-project.git
cd billing-dashboard-project

# Install dependencies
npm install

# Run analytics
bash analysis/run.sh

# Run tests
npm run test:e2e
```

---

## Usage

### CLI Commands

| Command | Description |
|---------|-------------|
| `billing-dashboard run` | Run analytics pipeline |
| `billing-dashboard serve [--port PORT]` | Start dashboard server |
| `billing-dashboard generate` | Generate TASKS.md |
| `billing-dashboard test` | Run E2E tests |
| `billing-dashboard version` | Show version |
| `billing-dashboard help` | Show help |

### Dashboard Filters

| Filter | Description |
|--------|-------------|
| **Year from/to** | Time window for charts |
| **Focus year** | KPI year + YoY comparison |
| **Customer** | Filter by customer name |
| **Top N** | Number of top customers to show |
| **Include forecast** | Toggle forecast overlay |
| **Compare vs prior year** | Enable YoY comparison |
| **Saved view** | Quick presets (Default, Collections, Growth, Risk) |

### URL State

Dashboard state is preserved in URL params:

```
http://localhost:8000/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0
```

| Param | Description |
|-------|-------------|
| `yf` | Year from |
| `yt` | Year to |
| `fy` | Focus year |
| `n` | Top N customers |
| `fc` | Include forecast (0/1) |
| `cm` | Compare mode (0/1) |

---

## Data Flow

```
nc-2002-2026.xlsx (source)
         ↓
  analysis/tmp/ (intermediate)
         ↓
   analysis/out/ (CSV outputs)
         ↓
  dashboard/index.html (visualization)
```

### Source Schema

**Required columns:**
- `Invoice Date`
- `Statement Item Type`
- `Invoice Grand Total`
- `Amount of Payment`
- `Billing Company` / `Billing Contact` / `Billing Contact Address Email`
- `Currency`
- `Billing Country`

**Data file:** `nc-2002-2026.xlsx` (not included - contains sensitive billing data)

**Sample data:** `nc-2002-2026-sample.xlsx` (included - 5000 rows of fake data for testing)

```bash
# Use sample data (included in repo)
cp nc-2002-2026-sample.xlsx nc-2002-2026.xlsx
bash analysis/run.sh
```

See `analysis/README.md` for full schema documentation.

---

## Project Structure

```
billing-dashboard-project/
├── analysis/                 # Analytics pipeline
│   ├── 01_ingest.sql        # Data ingestion
│   ├── 02_quality_checks.sql # Quality validation
│   ├── 03_metrics.sql       # Core metrics
│   ├── 04_advanced_analysis.sql # Advanced analytics
│   ├── run.sh               # Pipeline runner
│   └── out/                 # Output CSVs
├── dashboard/                # Executive dashboard
│   ├── index.html           # Single-file dashboard
│   └── tests/e2e/           # Playwright tests
├── scripts/                  # Automation scripts
│   ├── generate_tasks.py    # Task generator
│   └── check_tasks_sync.sh  # CI sync check
├── Formula/                  # Homebrew formula
├── cmd/                      # CLI wrapper
├── docs/                     # Documentation
│   ├── DASHBOARD_GLOSSARY.md
│   └── archive/
├── .github/workflows/        # CI/CD
├── tasks.yaml                # Task backlog (source)
├── TASKS.md                  # Task board (generated)
├── OUTCOMES.md               # DORA metrics
├── STRATEGIC_INTENT.md       # Project goals
└── CHANGELOG.md              # Release notes
```

---

## Testing

### Run All Tests

```bash
# E2E tests (headless)
npm run test:e2e

# Unit tests (task generator)
python tests/test_tasks_generator.py

# CI sync check
./scripts/check_tasks_sync.sh
```

### Test Coverage

| Test Type | Count | Coverage |
|-----------|-------|----------|
| E2E | 12 | Dashboard load, filters, presets, exports, URL state |
| Unit | 16 | Task generator formatting, validation, edge cases |
| Schema | Auto | tasks.yaml validation |

---

## CI/CD

### GitHub Actions Workflows

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | Push, PR | Tasks sync, unit tests, analytics pipeline, E2E tests |
| `homebrew-update.yml` | Release published | Trigger tap update |

### Status Badges

[![CI](https://github.com/joshuascottpaul/billing-dashboard-project/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuascottpaul/billing-dashboard-project/actions)
[![Tasks Sync](https://github.com/joshuascottpaul/billing-dashboard-project/actions/workflows/ci.yml/badge.svg?job=tasks-sync)](https://github.com/joshuascottpaul/billing-dashboard-project/actions)
[![Analytics Pipeline](https://github.com/joshuascottpaul/billing-dashboard-project/actions/workflows/ci.yml/badge.svg?job=analytics-pipeline)](https://github.com/joshuascottpaul/billing-dashboard-project/actions)

---

## FAQ

### Q: Browser blocks CSV loading

**A:** Use a local server instead of `file://`:

```bash
python3 -m http.server 8000
open http://localhost:8000/dashboard/
```

### Q: Schema validation fails

**A:** Check that your Excel file has all required columns. Run:

```bash
bash analysis/run.sh
```

Error message will list missing columns and available columns.

### Q: Dashboard shows no data

**A:** Run the analytics pipeline first:

```bash
bash analysis/run.sh
```

Then refresh the dashboard.

### Q: Homebrew install fails

**A:** Try installing dependencies first:

```bash
brew install python@3.14 node duckdb
brew install billing-dashboard
```

### Q: Playwright tests fail

**A:** Install browsers:

```bash
npx playwright install --with-deps chromium
```

### Q: How do I update the dashboard with new data?

**A:** Replace the Excel file and re-run:

```bash
# Replace nc-2002-2026.xlsx with new data
bash analysis/run.sh
```

### Q: Can I customize the dashboard?

**A:** Yes! Edit `dashboard/index.html`. All styling is Tailwind CSS, charts use Chart.js.

### Q: How do I add new metrics?

**A:** 
1. Add SQL in `analysis/03_metrics.sql` or `04_advanced_analysis.sql`
2. Add export in `analysis/run.sh`
3. Update `dashboard/index.html` to read new CSV
4. Add glossary entry in `docs/DASHBOARD_GLOSSARY.md`

---

## Documentation

| Document | Purpose |
|----------|---------|
| [`STRATEGIC_INTENT.md`](STRATEGIC_INTENT.md) | Project goals, scope, decision principles |
| [`OVERVIEW.MD`](OVERVIEW.MD) | Multi-agent orchestration model |
| [`OUTCOMES.md`](OUTCOMES.md) | DORA metrics and reporting |
| [`analysis/README.md`](analysis/README.md) | Pipeline runbook and output catalog |
| [`dashboard/README.md`](dashboard/README.md) | Dashboard usage guide |
| [`docs/DASHBOARD_GLOSSARY.md`](docs/DASHBOARD_GLOSSARY.md) | KPI/chart/table definitions |
| [`CHANGELOG.md`](CHANGELOG.md) | Release notes |
| [`IMPROVEMENTS.md`](IMPROVEMENTS.md) | Tech debt backlog |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### PR Requirements

- [ ] Tests pass (`npm run test:e2e`, `python tests/test_tasks_generator.py`)
- [ ] `TASKS.md` in sync (`python scripts/generate_tasks.py --check`)
- [ ] `CHANGELOG.md` updated
- [ ] `docs/DASHBOARD_GLOSSARY.md` updated (if dashboard changed)

See [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) for full template.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Links

- **Main Repository:** https://github.com/joshuascottpaul/billing-dashboard-project
- **Homebrew Tap:** https://github.com/joshuascottpaul/homebrew-tap
- **Issues:** https://github.com/joshuascottpaul/billing-dashboard-project/issues
- **Releases:** https://github.com/joshuascottpaul/billing-dashboard-project/releases

---

*Built with DuckDB, Chart.js, Tailwind CSS, and Playwright*
