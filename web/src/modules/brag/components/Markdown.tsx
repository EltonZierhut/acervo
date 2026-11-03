import ReactMarkdown from 'react-markdown'

// react-markdown não interpreta HTML cru, então o texto digitado não vira script nem estilo.
export function Markdown({ children }: { children: string }) {
  return (
    <div className="markdown">
      <ReactMarkdown
        components={{ a: ({ node: _node, ...props }) => <a {...props} target="_blank" rel="noopener noreferrer" /> }}
        urlTransform={(url) => (/^(https?:|mailto:|#|\/)/i.test(url) ? url : '')}
      >
        {children}
      </ReactMarkdown>
    </div>
  )
}
