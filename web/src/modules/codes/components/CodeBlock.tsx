import hljs from 'highlight.js/lib/common'
import 'highlight.js/styles/github-dark.css'
import { useMemo, useState } from 'react'

interface Props {
  code: string
  language?: string | null
  maxLines?: number
  copyable?: boolean
}

export function CodeBlock({ code, language, maxLines, copyable }: Props) {
  const [copied, setCopied] = useState(false)
  const visible = maxLines ? code.split('\n').slice(0, maxLines).join('\n') : code

  const html = useMemo(() => {
    if (language && hljs.getLanguage(language)) {
      return hljs.highlight(visible, { language }).value
    }
    return hljs.highlightAuto(visible).value
  }, [visible, language])

  const copy = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className="code-block">
      {copyable && (
        <button type="button" className="copy-btn" onClick={copy}>
          {copied ? 'Copiado!' : 'Copiar'}
        </button>
      )}
      <pre>
        <code className="hljs" dangerouslySetInnerHTML={{ __html: html }} />
      </pre>
    </div>
  )
}
