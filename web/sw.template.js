// Service worker do Acervo. Guarda só a interface (HTML, JS, CSS, ícones); nunca /api nem /up.
// O build (plugin em vite.config.ts) preenche a versão e a lista de arquivos, então cada build gera um
// sw.js diferente e o navegador detecta a versão nova. Ela só assume quando a página pede
// (mensagem SKIP_WAITING), para nunca trocar a interface no meio de uma edição.
const VERSION = '__VERSION__'
const CACHE = `acervo-ui-${VERSION}`
const PRECACHE = __PRECACHE__
const SHELL = '/'

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      // cache: 'reload' evita guardar uma resposta velha do cache HTTP.
      cache.addAll(PRECACHE.map((url) => new Request(url, { cache: 'reload' }))),
    ),
  )
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('acervo-ui-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  )
})

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting()
})

function isUiAsset(url) {
  return url.pathname.startsWith('/assets/') || url.pathname.startsWith('/icons/') || url.pathname === '/favicon.svg'
}

self.addEventListener('fetch', (event) => {
  const { request } = event
  if (request.method !== 'GET') return
  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return
  if (url.pathname.startsWith('/api') || url.pathname.startsWith('/up')) return

  if (request.mode === 'navigate') {
    // Rede primeiro; sem rede, a interface guardada (ela mostra o aviso de offline).
    event.respondWith(
      fetch(request).catch(() => caches.open(CACHE).then((cache) => cache.match(SHELL)).then((r) => r || Response.error())),
    )
    return
  }

  if (isUiAsset(url)) {
    event.respondWith(
      caches.open(CACHE).then(async (cache) => {
        const hit = await cache.match(request)
        if (hit) return hit
        const response = await fetch(request)
        if (response.ok) cache.put(request, response.clone())
        return response
      }),
    )
  }
})
