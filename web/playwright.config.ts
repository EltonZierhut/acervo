import { defineConfig } from '@playwright/test'

// Testes de responsividade (princípio VII). A API é simulada em e2e/mock-api.ts, então só o Vite sobe.
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  reporter: 'list',
  use: { baseURL: 'http://localhost:5174', hasTouch: true },
  webServer: {
    command: 'npm run dev -- --port 5174 --strictPort',
    url: 'http://localhost:5174',
    reuseExistingServer: !process.env.CI,
  },
})
