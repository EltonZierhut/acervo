import { StreamLanguage } from '@codemirror/language'
import type { Extension } from '@codemirror/state'

// Cada linguagem é baixada só quando uma nota precisa dela.
const loaders = new Map<string, () => Promise<Extension>>([
  ['bash', async () => StreamLanguage.define((await import('@codemirror/legacy-modes/mode/shell')).shell)],
  ['css', async () => (await import('@codemirror/lang-css')).css()],
  ['go', async () => (await import('@codemirror/lang-go')).go()],
  ['html', async () => (await import('@codemirror/lang-html')).html()],
  ['java', async () => (await import('@codemirror/lang-java')).java()],
  ['javascript', async () => (await import('@codemirror/lang-javascript')).javascript()],
  ['json', async () => (await import('@codemirror/lang-json')).json()],
  ['python', async () => (await import('@codemirror/lang-python')).python()],
  ['ruby', async () => StreamLanguage.define((await import('@codemirror/legacy-modes/mode/ruby')).ruby)],
  ['rust', async () => (await import('@codemirror/lang-rust')).rust()],
  ['sql', async () => (await import('@codemirror/lang-sql')).sql()],
  ['typescript', async () => (await import('@codemirror/lang-javascript')).javascript({ typescript: true })],
  ['yaml', async () => (await import('@codemirror/lang-yaml')).yaml()],
])

// Linguagem vazia ou fora da lista é texto simples.
export async function loadLanguage(language: string): Promise<Extension> {
  const loader = loaders.get(language.trim().toLowerCase())
  return loader ? loader() : []
}
