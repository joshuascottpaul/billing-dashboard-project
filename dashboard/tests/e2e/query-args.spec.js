const { test, expect } = require('@playwright/test');

async function waitForDashboardReady(page) {
  await expect(page.getByRole('heading', { name: 'Financial Health Dashboard' })).toBeVisible();
  await expect(page.locator('#errorBox')).toHaveClass(/hidden/);
  await expect(page.locator('#kpis .kpi-badge')).toHaveCount(6);
}

async function readDashboardState(page) {
  return page.evaluate(() => {
    const yearlyChart = window.Chart?.getChart?.('yearlyChart');
    const yearlyLabels = (yearlyChart?.data?.labels || []).map((v) => Number(v));
    const selectYears = [...document.querySelectorAll('#yearFrom option')].map((o) => Number(o.value));
    const minYear = Math.min(...selectYears);
    const maxYear = Math.max(...selectYears);
    const headerCells = [...document.querySelectorAll('#topCrossTabTable th')].map((x) =>
      x.textContent.replace(/\s+/g, ' ').trim()
    );

    return {
      yearFrom: document.getElementById('yearFrom')?.value,
      yearTo: document.getElementById('yearTo')?.value,
      focusYear: document.getElementById('focusYear')?.value,
      topN: document.getElementById('topN')?.value,
      includeForecast: document.getElementById('includeForecast')?.checked,
      compareMode: document.getElementById('compareMode')?.checked,
      activeFilters: document.getElementById('activeFilters')?.innerText.replace(/\s+/g, ' ').trim(),
      yearlyLabels,
      minYear,
      maxYear,
      headerCells,
    };
  });
}

test.describe('Dashboard query-arg state', () => {
  const cases = [
    {
      name: 'applies 2024-2025 window from URL',
      query: 'yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0',
      expected: { yearFrom: '2024', yearTo: '2025', focusYear: '2025', topN: '10', includeForecast: false, compareMode: false, yearlyLabels: [2024, 2025] },
    },
    {
      name: 'keeps focus year independent of date range',
      query: 'yf=2024&yt=2025&fy=2023&n=10&fc=0&cm=0',
      expected: { yearFrom: '2024', yearTo: '2025', focusYear: '2023', topN: '10', includeForecast: false, compareMode: false, yearlyLabels: [2024, 2025] },
    },
    {
      name: 'applies 2018-2020 window with compare mode on',
      query: 'yf=2018&yt=2020&fy=2019&n=5&fc=1&cm=1',
      expected: { yearFrom: '2018', yearTo: '2020', focusYear: '2019', topN: '5', includeForecast: true, compareMode: true, yearlyLabels: [2018, 2019, 2020] },
    },
    {
      name: 'applies 2002-2006 window with focus 2004',
      query: 'yf=2002&yt=2006&fy=2004&n=20&fc=0&cm=1',
      expected: { yearFrom: '2002', yearTo: '2006', focusYear: '2004', topN: '20', includeForecast: false, compareMode: true, yearlyLabels: [2002, 2003, 2004, 2005, 2006] },
    },
    {
      name: 'supports single-year scope',
      query: 'yf=2025&yt=2025&fy=2025&n=8&fc=1&cm=0',
      expected: { yearFrom: '2025', yearTo: '2025', focusYear: '2025', topN: '8', includeForecast: true, compareMode: false, yearlyLabels: [2025] },
    },
  ];

  for (const tc of cases) {
    test(tc.name, async ({ page }) => {
      await page.goto(`/dashboard/?${tc.query}`);
      await waitForDashboardReady(page);

      const state = await readDashboardState(page);
      expect(state.yearFrom).toBe(tc.expected.yearFrom);
      expect(state.yearTo).toBe(tc.expected.yearTo);
      expect(state.focusYear).toBe(tc.expected.focusYear);
      expect(state.topN).toBe(tc.expected.topN);
      expect(state.includeForecast).toBe(tc.expected.includeForecast);
      expect(state.compareMode).toBe(tc.expected.compareMode);
      expect(state.yearlyLabels).toEqual(tc.expected.yearlyLabels);
      expect(state.activeFilters).toContain(`Year range: ${tc.expected.yearFrom}-${tc.expected.yearTo}`);
      expect(state.activeFilters).toContain(`Focus year: ${tc.expected.focusYear}`);
      expect(state.activeFilters).toContain(`Top N: ${tc.expected.topN}`);
      expect(state.activeFilters).toContain(`Forecast: ${tc.expected.includeForecast ? 'On' : 'Off'}`);
      expect(state.activeFilters).toContain(`Compare mode: ${tc.expected.compareMode ? 'On' : 'Off'}`);
      expect(state.headerCells[1]).toContain(`${Number(tc.expected.focusYear) - 1} Sales`);
      expect(state.headerCells[2]).toContain(`${tc.expected.focusYear} Sales`);
    });
  }

  test('clamps invalid URL arguments to valid dashboard bounds', async ({ page }) => {
    await page.goto('/dashboard/?yf=1900&yt=9999&fy=9999&n=999&fc=0&cm=1');
    await waitForDashboardReady(page);

    const state = await readDashboardState(page);
    expect(state.yearFrom).toBe(String(state.minYear));
    expect(state.yearTo).toBe(String(state.maxYear));
    expect(state.focusYear).toBe(String(state.maxYear));
    expect(state.topN).toBe('8');
    expect(state.includeForecast).toBe(false);
    expect(state.compareMode).toBe(true);
    expect(state.yearlyLabels[0]).toBe(state.minYear);
    expect(state.yearlyLabels[state.yearlyLabels.length - 1]).toBe(state.maxYear);
    expect(state.activeFilters).toContain(`Year range: ${state.minYear}-${state.maxYear}`);
    expect(state.activeFilters).toContain(`Focus year: ${state.maxYear}`);
    expect(state.activeFilters).toContain('Top N: 8');
    expect(state.activeFilters).toContain('Forecast: Off');
    expect(state.activeFilters).toContain('Compare mode: On');
  });
});
