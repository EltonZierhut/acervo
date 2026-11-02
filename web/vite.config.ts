import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'
import react from '@vitejs/plugin-react'
import { defineConfig, type Plugin } from 'vite'

// Gera o sw.js a partir de sw.template.js, com a lista de arquivos da interface deste build.
// A lista (nomes com hash) faz o sw.js mudar a cada versão nova da interface.
function serviceWorker(): Plugin {
  return {
    name: 'acervo-service-worker',
    apply: 'build',
    generateBundle(_options, bundle) {
      const files = Object.keys(bundle).map((name) => `/${name}`).sort()
      const precache = ['/', '/manifest.webmanifest', '/favicon.svg', '/icons/icon-192.png', '/icons/icon-512.png', '/icons/icon-maskable-512.png', '/icons/apple-touch-icon.png', ...files.filter((f) => f !== '/index.html')]
      const version = createHash('sha256').update(JSON.stringify(precache)).digest('hex').slice(0, 12)
      const source = readFileSync(new URL('./sw.template.js', import.meta.url), 'utf8')
        .replace('__VERSION__', () => version)
        .replace('__PRECACHE__', () => JSON.stringify(precache, null, 2))
      this.emitFile({ type: 'asset', fileName: 'sw.js', source })
    },
  }
}

// Em desenvolvimento, /api é encaminhado para o Rails (porta 3000).
export default defineConfig({
  plugins: [react(), serviceWorker()],
  server: {
    proxy: {
      '/api': 'http://localhost:3000',
    },
  },
})
