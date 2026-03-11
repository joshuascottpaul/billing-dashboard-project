const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

// Screenshot output directory
const SCREENSHOT_DIR = path.join(__dirname, '..', 'screenshots');

// Ensure screenshot directory exists
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

test.describe('Dashboard Screenshots', () => {
  test.beforeEach(async ({ page }) => {
    // Set viewport for consistent screenshots
    await page.setViewportSize({ width: 1440, height: 900 });
  });

  test('Screenshot: Default Overview', async ({ page }) => {
    // Navigate to dashboard with default view
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(2000); // Wait for charts to render

    // Take full page screenshot
    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, '01-default-overview.png'),
      fullPage: true
    });

    expect(true).toBe(true);
  });

  test('Screenshot: KPI Cards', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(2000);

    // Screenshot just the KPI section
    const kpiSection = await page.$('#kpis');
    if (kpiSection) {
      await kpiSection.screenshot({
        path: path.join(SCREENSHOT_DIR, '02-kpi-cards.png')
      });
    }

    expect(true).toBe(true);
  });

  test('Screenshot: Charts Grid', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=1&cm=0');
    await page.waitForTimeout(2000);

    // Screenshot charts section
    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, '03-charts-grid.png'),
      fullPage: false
    });

    expect(true).toBe(true);
  });

  test('Screenshot: Collections Risk View', async ({ page }) => {
    await page.goto('/dashboard/?yf=2025&yt=2025&fy=2025&n=20&fc=0&cm=0');
    await page.waitForTimeout(2000);

    // Select Collections Review preset
    const presetSelect = await page.$('#viewPreset');
    if (presetSelect) {
      await presetSelect.selectOption('collections');
      await page.waitForTimeout(1000);
    }

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, '04-collections-view.png'),
      fullPage: true
    });

    expect(true).toBe(true);
  });

  test('Screenshot: Customer Drill-Down', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(2000);

    // Click first customer link in table
    const customerLink = await page.$('.customer-link');
    if (customerLink) {
      await customerLink.click();
      await page.waitForTimeout(1000);

      // Screenshot with drawer open
      await page.screenshot({
        path: path.join(SCREENSHOT_DIR, '05-customer-drilldown.png'),
        fullPage: true
      });
    }

    expect(true).toBe(true);
  });

  test('Screenshot: Filter Bar', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(1000);

    // Screenshot just the filter section
    const filterSection = await page.$('section[role="region"]');
    if (filterSection) {
      await filterSection.screenshot({
        path: path.join(SCREENSHOT_DIR, '06-filter-bar.png')
      });
    }

    expect(true).toBe(true);
  });

  test('Screenshot: Data Coverage Card', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(1000);

    // Screenshot data coverage section
    const coverageSection = await page.$('#dataCoverage');
    if (coverageSection) {
      await coverageSection.screenshot({
        path: path.join(SCREENSHOT_DIR, '07-data-coverage.png')
      });
    }

    expect(true).toBe(true);
  });

  test('Screenshot: Active Filter Chips', async ({ page }) => {
    await page.goto('/dashboard/?yf=2024&yt=2025&fy=2025&n=10&fc=0&cm=0');
    await page.waitForTimeout(1000);

    // Screenshot active filters
    const chipsSection = await page.$('#activeFilters');
    if (chipsSection) {
      await chipsSection.screenshot({
        path: path.join(SCREENSHOT_DIR, '08-filter-chips.png')
      });
    }

    expect(true).toBe(true);
  });
});
