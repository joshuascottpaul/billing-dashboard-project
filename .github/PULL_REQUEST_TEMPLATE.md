# Pull Request Template

## Description

<!-- Brief summary of changes (3-5 lines) -->

## Related Issues

<!-- Link any related issues or tasks (e.g., "Closes #123" or "T-005") -->

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Dashboard Changes Only

If this PR modifies the dashboard (`dashboard/` or `docs/DASHBOARD_GLOSSARY.md`), complete the strategic alignment checklist:

### Strategic Alignment Checklist

- [ ] **Purpose alignment:** Change supports one of the 4 primary outcomes in `STRATEGIC_INTENT.md`
- [ ] **Definition clarity:** New/modified KPIs have clear formula and data source
- [ ] **Help text:** New/modified elements have hover tooltip and glossary entry
- [ ] **Risk thresholds:** 🟢🟡🔴 bands added if used for risk monitoring
- [ ] **Stakeholder test:** Terms understandable without analyst support
- [ ] **Determinism:** Output is reproducible from source + SQL
- [ ] **Git reviewable:** Output diffs are reviewable in git
- [ ] **Glossary updated:** `docs/DASHBOARD_GLOSSARY.md` updated with new/changed metrics

## Testing

### Evidence

<!-- Describe tests added/updated and their results -->

### E2E Tests

- [ ] `npm run test:e2e` passes
- [ ] Playwright report shows all tests green

### Analytics Pipeline (if applicable)

- [ ] `bash analysis/run.sh` completes successfully
- [ ] `analysis/out/data_quality_report.md` shows no new warnings

## Risks and Tradeoffs

<!-- Known limitations, performance considerations, or rollback notes -->

## Screenshots (if applicable)

<!-- For UI changes, include before/after screenshots -->

## Release Impact

- [ ] **none** - No user-visible changes
- [ ] **app** - Dashboard or analytics changes (requires deploy)
- [ ] **homebrew** - Formula update needed (see `RELEASE.md`)

## Checklist

- [ ] Code follows project conventions (`CLAUDE.md`)
- [ ] Self-review of changes completed
- [ ] Comments are minimal and explain "why" not "what"
- [ ] `TASKS.md` is in sync with `tasks.yaml` (run `python scripts/generate_tasks.py`)
- [ ] `OUTCOMES.md` updated (if instrumentation changed)
- [ ] `docs/DASHBOARD_GLOSSARY.md` updated (if dashboard metrics changed)
- [ ] `CHANGELOG.md` updated (if user-visible change)
