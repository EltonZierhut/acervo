import { expect, test } from '@playwright/test'
import type { Page } from '@playwright/test'
import { mockApi } from './mock-api'

// Princípio VII: toda tela funciona a partir de 360 px, sem rolagem horizontal da página,
// nos temas claro e escuro, e em tela larga.
const ROUTES = [
  '/codigos',
  '/codigos/novo',
  '/codigos/1',
  '/iniciativas',
  '/iniciativas/nova',
  '/iniciativas/contextos',
  '/iniciativas/fila',
  '/iniciativas/1',
  '/iniciativas/1?aba=tarefas',
  '/iniciativas/1?aba=tarefas&tarefa=1',
  '/iniciativas/1?aba=marcos',
  '/iniciativas/1?aba=detalhes',
]

const VIEWPORTS = [
  { name: '360 px', size: { width: 360, height: 740 } },
  { name: 'tela larga', size: { width: 1280, height: 800 } },
]

async function settle(page: Page) {
  await page.waitForLoadState('networkidle')
  await page.waitForTimeout(300)
}

async function horizontalOverflow(page: Page) {
  return page.evaluate(() => {
    const root = document.documentElement
    return { scroll: root.scrollWidth, client: root.clientWidth, body: document.body.scrollWidth }
  })
}

for (const viewport of VIEWPORTS) {
  for (const colorScheme of ['light', 'dark'] as const) {
    test.describe(`${viewport.name}, tema ${colorScheme}`, () => {
      test.use({ viewport: viewport.size, colorScheme })

      test('login não rola na horizontal', async ({ page }) => {
        await mockApi(page, { loggedIn: false })
        await page.goto('/login')
        await settle(page)
        const size = await horizontalOverflow(page)
        expect(size.scroll).toBeLessThanOrEqual(size.client)
        expect(size.body).toBeLessThanOrEqual(size.client)
      })

      for (const route of ROUTES) {
        test(`${route} não rola na horizontal`, async ({ page }) => {
          await mockApi(page)
          await page.goto(route)
          await settle(page)
          const size = await horizontalOverflow(page)
          expect(size.scroll, `scrollWidth em ${route}`).toBeLessThanOrEqual(size.client)
          expect(size.body, `body.scrollWidth em ${route}`).toBeLessThanOrEqual(size.client)
        })
      }
    })
  }
}

test.describe('celular (360 px)', () => {
  test.use({ viewport: { width: 360, height: 740 } })

  test('navegação fica na barra inferior e o Sair no menu da conta', async ({ page }) => {
    await mockApi(page)
    await page.goto('/codigos')
    const bar = page.locator('.bottom-nav')
    await expect(bar).toBeVisible()
    await expect(page.locator('.sidebar')).toBeHidden()
    const box = await bar.boundingBox()
    expect(box!.y + box!.height).toBeCloseTo(740, 0)
    await expect(bar.getByRole('link', { name: 'Códigos' })).toBeVisible()
    await expect(bar.getByRole('link', { name: 'Iniciativas' })).toBeVisible()
    await expect(page.getByRole('menuitem', { name: 'Sair' })).toHaveCount(0)
    await bar.getByRole('button', { name: 'Conta' }).tap()
    await expect(page.getByRole('menuitem', { name: 'Sair' })).toBeVisible()
    await bar.getByRole('link', { name: 'Iniciativas' }).tap()
    await expect(page).toHaveURL(/\/iniciativas/)
    await expect(page.getByRole('menuitem', { name: 'Sair' })).toHaveCount(0)
  })

  test('barra lateral continua no computador', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 })
    await mockApi(page)
    await page.goto('/codigos')
    await expect(page.locator('.sidebar')).toBeVisible()
    await expect(page.locator('.bottom-nav')).toBeHidden()
  })

  // Alvos de toque de 44 x 44 px e campos de 16 px (o iPhone dá zoom ao focar abaixo disso).
  for (const route of ROUTES) {
    test(`${route}: alvos de toque e fontes`, async ({ page }) => {
      await mockApi(page)
      await page.goto(route)
      await settle(page)
      const problems = await page.evaluate(() => {
        const out: string[] = []
        const describe = (el: Element) => `${el.tagName.toLowerCase()}.${(el as HTMLElement).className}`.slice(0, 80)
        const visible = (el: Element) => {
          const r = el.getBoundingClientRect()
          return r.width > 0 && r.height > 0 && getComputedStyle(el).visibility !== 'hidden'
        }
        const targets = 'button, select, summary, [role=tab], .nav-item, .bottom-item, .note-item, .back, input:not([type=hidden]):not(.visually-hidden), textarea'
        document.querySelectorAll(targets).forEach((el) => {
          if (!visible(el) || el.closest('.sidebar')) return
          const isCheck = el instanceof HTMLInputElement && (el.type === 'checkbox' || el.type === 'radio')
          // Caixa de seleção: vale a área tocável do rótulo que a envolve, ou o quadrado mais a margem.
          const label = isCheck ? el.closest('label') : null
          const r = (label ?? el).getBoundingClientRect()
          const margin = isCheck && !label ? 2 * parseFloat(getComputedStyle(el).marginLeft) : 0
          const w = r.width + margin
          const h = r.height + margin
          if (w < 43.5 || h < 43.5) out.push(`alvo pequeno ${Math.round(w)}x${Math.round(h)}: ${describe(el)}`)
        })
        document.querySelectorAll('input:not([type=checkbox]):not([type=radio]):not([type=hidden]), select, textarea, .cm-content, .rich-content').forEach((el) => {
          if (visible(el) && parseFloat(getComputedStyle(el).fontSize) < 16) out.push(`fonte < 16 px: ${describe(el)}`)
        })
        return out
      })
      expect(problems).toEqual([])
    })
  }

  test('modal da tarefa ocupa a tela e mantém o botão de fechar à vista', async ({ page }) => {
    await mockApi(page)
    await page.goto('/iniciativas/1?aba=tarefas&tarefa=1')
    const modal = page.getByRole('dialog')
    await expect(modal).toBeVisible()
    const box = await modal.boundingBox()
    expect(box).toMatchObject({ x: 0, width: 360, height: 740 })
    await modal.evaluate((el) => el.scrollTo(0, el.scrollHeight))
    await expect(page.getByRole('button', { name: 'Fechar' })).toBeInViewport()
  })

  test('Códigos mostra um painel por vez, com voltar', async ({ page }) => {
    await mockApi(page)
    await page.goto('/codigos')
    await expect(page.locator('.notes-side')).toBeVisible()
    await expect(page.locator('.notes-pane')).toBeHidden()
    await page.goto('/codigos/1')
    await expect(page.locator('.notes-side')).toBeHidden()
    await expect(page.getByRole('link', { name: /Voltar para a lista/ })).toBeVisible()
  })

  test('editor: busca dentro da nota abre e cabe na tela', async ({ page }) => {
    await mockApi(page)
    await page.goto('/codigos/1')
    const content = page.locator('.cm-content')
    await expect(content).toBeVisible()
    await content.click()
    await page.keyboard.press('Control+f')
    const field = page.locator('.cm-search input[name=search]')
    await expect(field).toBeVisible()
    await field.fill('const')
    await expect(page.locator('.cm-searchMatch').first()).toBeVisible()
    const size = await horizontalOverflow(page)
    expect(size.scroll).toBeLessThanOrEqual(size.client)
  })
})
