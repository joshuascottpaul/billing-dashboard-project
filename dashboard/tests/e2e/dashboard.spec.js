const { test, expect } = require('@playwright/test');

async function waitForDashboardReady(page) {
  await expect(page.getByRole('heading', { name: 'Financial Health Dashboard' })).toBeVisible();
  await expect(page.locator('#errorBox')).toHaveClass(/hidden/);
  await expect(page.locator('#kpis .kpi-badge')).toHaveCount(6);
}

test.describe('Billing Dashboard', () => {
  test('loads successfully with KPI cards and no data error', async ({ page }) => {
    await page.goto('/dashboard/');

    await waitForDashboardReady(page);
  });

  test('uses master filter model (no table-local filters)', async ({ page }) => {
    await page.goto('/dashboard/');
    await waitForDashboardReady(page);

    await expect(page.locator('#focusYear')).toBeVisible();
    await expect(page.locator('#topN')).toBeVisible();

    await page.click('#tabDateDashboard');
    await expect(page.locator('#yearFrom')).toBeVisible();
    await expect(page.locator('#yearTo')).toBeVisible();
    await expect(page.locator('#customerSelector')).toBeVisible();

    await expect(page.locator('.table-filter')).toHaveCount(0);
    await expect(page.locator('#topCustomersTable .text-slate-500')).toContainText('use master filters');
  });

  test('applies saved view presets and updates active filter chips', async ({ page }) => {
    await page.goto('/dashboard/');
    await waitForDashboardReady(page);

    await page.selectOption('#viewPreset', 'collections');
    await page.click('#applyPreset');

    await expect(page.locator('#activeFilters')).toContainText('Preset: collections');
    await expect(page.locator('#activeFilters')).toContainText('Compare mode: On');
    await expect(page.locator('#activeFilters')).toContainText('Top N: 15');
  });

  test('global customer filter affects table outputs', async ({ page }) => {
    await page.goto('/dashboard/');
    await waitForDashboardReady(page);

    const firstCustomer = page.locator('#topCustomersTable .customer-link').first();
    await expect(firstCustomer).toBeVisible();
    const customerName = (await firstCustomer.innerText()).trim();

    await page.fill('#customerSelector', 'zzzz___no_match___zzzz');
    await expect(page.locator('#topCustomersTable')).toContainText('No rows');

    await page.fill('#customerSelector', customerName);
    await expect(page.locator('#topCustomersTable .customer-link').first()).toContainText(customerName);
  });

  test('customer drawer opens and columns are resizable', async ({ page }) => {
    await page.goto('/dashboard/');
    await waitForDashboardReady(page);

    await page.click('#topCustomersTable .customer-link');
    await expect(page.locator('#customerDrawer')).not.toHaveClass(/translate-x-full/);
    await expect(page.locator('#drawerTitle')).not.toHaveText('');

    await page.click('#closeDrawer');
    await expect(page.locator('#customerDrawer')).toHaveClass(/translate-x-full/);

    const table = page.locator('#topCustomersTable');
    const handle = table.locator('.col-resize-handle').nth(1);
    await expect(handle).toBeVisible();

    const box = await handle.boundingBox();
    expect(box).toBeTruthy();

    const col = table.locator('col').nth(1);
    const beforeStyle = await col.getAttribute('style');

    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + box.width / 2 + 80, box.y + box.height / 2);
    await page.mouse.up();

    const afterStyle = await col.getAttribute('style');
    expect(afterStyle).toContain('width:');
    expect(afterStyle).not.toBe(beforeStyle);
  });

  test('exports table CSV and chart artifacts in headless mode', async ({ page }) => {
    await page.goto('/dashboard/');
    await waitForDashboardReady(page);

    const tableDownload = page.waitForEvent('download');
    await page.click('.export-btn[data-table="topCustomersTable"]');
    const tableFile = await tableDownload;
    expect(tableFile.suggestedFilename()).toMatch(/\.csv$/i);

    await page.click('#tabDateDashboard');
    await expect(page.locator('#yearlyChart')).toBeVisible();

    const chartCsvDownload = page.waitForEvent('download');
    await page.click('.chart-csv[data-chart="yearlyChart"]');
    const chartCsv = await chartCsvDownload;
    expect(chartCsv.suggestedFilename()).toMatch(/\.csv$/i);

    const chartPngDownload = page.waitForEvent('download');
    await page.click('.chart-png[data-chart="yearlyChart"]');
    const chartPng = await chartPngDownload;
    expect(chartPng.suggestedFilename()).toMatch(/\.png$/i);
  });
});
