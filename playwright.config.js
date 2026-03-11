const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './dashboard/tests/e2e',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
  },
  use: {
    baseURL: 'http://127.0.0.1:4173',
    headless: true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    acceptDownloads: true,
  },
  webServer: {
    command: 'python3 -m http.server 4173 --bind 127.0.0.1',
    url: 'http://127.0.0.1:4173/dashboard/',
    reuseExistingServer: false,
    timeout: 30_000,
  },
  reporter: [['list'], ['html', { open: 'never' }]],
});
