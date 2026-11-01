import { useRef, useState } from 'react'
import type { ChangeEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import type { TaskImage } from '../types'

const ACCEPT = 'image/png,image/jpeg,image/webp,image/gif'

export function TaskImages({ taskId, onChanged }: { taskId: number; onChanged: () => void }) {
  const images = useAsync(() => initiativesApi.listImages(taskId), [taskId])
  const [enlarged, setEnlarged] = useState<TaskImage | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const input = useRef<HTMLInputElement>(null)

  const upload = async (event: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files ?? [])
    setBusy(true)
    setError(null)
    // Um por vez: se um for recusado, os outros continuam e a mensagem diz qual foi.
    const failures: string[] = []
    for (const file of files) {
      try {
        await initiativesApi.uploadImage(taskId, file)
      } catch (err) {
        failures.push(`${file.name}: ${err instanceof Error ? err.message : 'não foi possível enviar'}`)
      }
    }
    if (failures.length > 0) setError(failures.join(' · '))
    setBusy(false)
    if (input.current) input.current.value = ''
    images.reload()
    onChanged()
  }

  const remove = async (image: TaskImage) => {
    if (!window.confirm(`Remover a imagem "${image.filename}"?`)) return
    setError(null)
    try {
      await initiativesApi.deleteImage(image.id)
      images.reload()
      onChanged()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível remover')
    }
  }

  return (
    <section className="task-section">
      <h4>Imagens</h4>
      {images.error && <p className="error small">{images.error}</p>}
      {images.data && images.data.length > 0 && (
        <ul className="task-images">
          {images.data.map((image) => (
            <li key={image.id}>
              <button type="button" className="thumb" onClick={() => setEnlarged(image)} aria-label={`Ampliar ${image.filename}`}>
                <img src={image.url} alt={image.filename} loading="lazy" />
              </button>
              <button type="button" className="link-button small" onClick={() => void remove(image)}>Remover</button>
            </li>
          ))}
        </ul>
      )}
      <label className="btn file-button">
        {busy ? 'Enviando…' : 'Adicionar imagens'}
        <input ref={input} type="file" accept={ACCEPT} multiple disabled={busy} onChange={(e) => void upload(e)} className="visually-hidden" />
      </label>
      <span className="muted small"> PNG, JPEG, WEBP ou GIF; até 10 por tarefa, com até 10 MB cada.</span>
      {error && <p className="error small">{error}</p>}

      {enlarged && (
        <button type="button" className="image-viewer" onClick={() => setEnlarged(null)} aria-label="Fechar imagem ampliada">
          <img src={enlarged.url} alt={enlarged.filename} />
        </button>
      )}
    </section>
  )
}
