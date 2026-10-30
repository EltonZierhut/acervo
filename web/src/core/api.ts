// Cliente HTTP compartilhado por todos os módulos.
const BASE_URL = (import.meta.env.VITE_API_URL ?? '') + '/api/v1'

export class ApiError extends Error {
  status: number
  errors: string[]

  constructor(status: number, errors: string[]) {
    super(errors.join(', ') || `Erro ${status}`)
    this.status = status
    this.errors = errors
  }
}

type Query = Record<string, string | number | undefined | null>

function buildUrl(path: string, query?: Query) {
  const url = new URL(BASE_URL + path, window.location.origin)
  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value))
  })
  return url.toString()
}

async function request<T>(method: string, path: string, body?: unknown, query?: Query): Promise<T> {
  const response = await fetch(buildUrl(path, query), {
    method,
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  if (response.status === 204) return undefined as T

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    const errors: string[] = data.errors ?? (data.error ? [data.error] : [])
    throw new ApiError(response.status, errors)
  }
  return data as T
}

export const api = {
  get: <T>(path: string, query?: Query) => request<T>('GET', path, undefined, query),
  post: <T>(path: string, body: unknown) => request<T>('POST', path, body),
  patch: <T>(path: string, body: unknown) => request<T>('PATCH', path, body),
  delete: (path: string) => request<void>('DELETE', path),
}
