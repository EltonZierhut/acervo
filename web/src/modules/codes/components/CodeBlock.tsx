import hljs from 'highlight.js/lib/common'
import 'highlight.js/styles/github-dark.css'
import { useMemo, useState } from 'react'

// Acima disso o realce automático trava a tela.
const HIGHLIGHT_LIMIT = 100_000

interface Props {
  code: string
  language?: string | null
}

export function CodeBlock({ code, language }: Props) {
  const [copy, setCopy] = useState<'idle' | 'copied' | 'failed'>('idle')

  const html = useMemo(() => {
    if (code.length > HIGHLIGHT_LIMIT) return null
    if (language && hljs.getLanguage(language)) {
      return hljs.highlight(code, { language }).value
    }
    return hljs.highlightAuto(code).value
  }, [code, language])

  const copyCode = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setCopy('copied')
    } catch {
      setCopy('failed')
    }
    setTimeout(() => setCopy('idle'), 4000)
  }

  return (
    <div className="code-block">
      <button type="button" className="copy-btn" onClick={() => void copyCode()}>
        {copy === 'copied' ? 'Copiado!' : 'Copiar'}
      </button>
      {copy === 'failed' && (
        <p className="error small">Não foi possível copiar. Selecione o texto manualmente.</p>
      )}
      <pre>
        {html === null ? (
          <code className="hljs">{code}</code>
        ) : (
          <code className="hljs" dangerouslySetInnerHTML={{ __html: html }} />
        )}
      </pre>
    </div>
  )
}
