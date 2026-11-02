import { useEffect, useState } from 'react'

// Avisos do app instalável: sem internet, nova versão e dica de instalação no iPhone.
// A versão nova só é aplicada quando a pessoa clica em "Atualizar", nunca sozinha.

const IOS_HINT_KEY = 'acervo:ios-install-hint-dismissed'

function isIos() {
  return /iphone|ipad|ipod/i.test(navigator.userAgent)
}

function isStandalone() {
  return window.matchMedia('(display-mode: standalone)').matches || (navigator as { standalone?: boolean }).standalone === true
}

function useOnline() {
  const [online, setOnline] = useState(() => navigator.onLine)
  useEffect(() => {
    const on = () => setOnline(true)
    const off = () => setOnline(false)
    window.addEventListener('online', on)
    window.addEventListener('offline', off)
    return () => {
      window.removeEventListener('online', on)
      window.removeEventListener('offline', off)
    }
  }, [])
  return online
}

function useServiceWorkerUpdate() {
  const [waiting, setWaiting] = useState<ServiceWorker | null>(null)

  useEffect(() => {
    if (!import.meta.env.PROD || !('serviceWorker' in navigator)) return
    let reloading = false
    const onControllerChange = () => {
      if (reloading) return
      reloading = true
      window.location.reload()
    }
    // Só recarrega se a pessoa pediu a atualização (havia um worker anterior no controle).
    const hadController = Boolean(navigator.serviceWorker.controller)
    const guarded = () => hadController && onControllerChange()
    navigator.serviceWorker.addEventListener('controllerchange', guarded)

    const watch = (reg: ServiceWorkerRegistration) => {
      if (reg.waiting && navigator.serviceWorker.controller) setWaiting(reg.waiting)
      reg.addEventListener('updatefound', () => {
        const worker = reg.installing
        worker?.addEventListener('statechange', () => {
          if (worker.state === 'installed' && navigator.serviceWorker.controller) setWaiting(worker)
        })
      })
    }

    let timer: number | undefined
    navigator.serviceWorker
      .register('/sw.js')
      .then((reg) => {
        watch(reg)
        timer = window.setInterval(() => reg.update().catch(() => {}), 60 * 60 * 1000)
      })
      .catch(() => {})

    return () => {
      navigator.serviceWorker.removeEventListener('controllerchange', guarded)
      if (timer) window.clearInterval(timer)
    }
  }, [])

  return waiting
}

export function PwaNotices() {
  const online = useOnline()
  const waiting = useServiceWorkerUpdate()
  const [hintDismissed, setHintDismissed] = useState(() => localStorage.getItem(IOS_HINT_KEY) === '1')
  const showIosHint = !hintDismissed && isIos() && !isStandalone()

  return (
    <div className="pwa-notices">
      {!online && (
        <div className="pwa-notice offline" role="status">
          Você está offline. Listas e notas precisam de conexão.
        </div>
      )}
      {waiting && (
        <div className="pwa-notice" role="status">
          <span>Nova versão disponível</span>
          <button type="button" className="btn small-btn primary" onClick={() => waiting.postMessage({ type: 'SKIP_WAITING' })}>
            Atualizar
          </button>
        </div>
      )}
      {showIosHint && (
        <div className="pwa-notice" role="note">
          <span>Para instalar: toque em Compartilhar e depois em “Adicionar à Tela de Início”.</span>
          <button
            type="button"
            className="btn small-btn"
            onClick={() => {
              localStorage.setItem(IOS_HINT_KEY, '1')
              setHintDismissed(true)
            }}
          >
            Dispensar
          </button>
        </div>
      )}
    </div>
  )
}
