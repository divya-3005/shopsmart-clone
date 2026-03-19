import { test, expect } from '@playwright/test';

test.describe('ShopSmart User Flow', () => {
  test('User can load the page and see the shop status', async ({ page }) => {
    // 1. Visit the frontend
    await page.goto('http://localhost:5173');

    // 2. Check header
    await expect(page.locator('text=ShopSmart')).toBeVisible();

    // 3. Check if backend status shows up (simulating an interaction/result)
    // Normally we'd do: login -> action -> result. We're testing a basic initial view -> result.
    await expect(page.locator('text=Backend Running')).toBeVisible({ timeout: 10000 });
  });
});
