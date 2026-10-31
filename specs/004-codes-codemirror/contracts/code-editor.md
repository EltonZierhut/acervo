# Contrato: componente `CodeEditor`

Interface entre o `NoteEditor` e o editor. A API HTTP não muda.

| Propriedade | Tipo | Significado |
|-------------|------|-------------|
| `initialValue` | `string` | Texto do editor ao montar. Mudanças depois disso são ignoradas. |
| `language` | `string` | Linguagem da nota; texto livre. |
| `placeholder` | `string` | Texto exibido com o editor vazio. |
| `ariaLabel` | `string` | Nome do campo para leitores de tela. |
| `onChange` | `(value: string, pasted: boolean) => void` | Chamado só em edições do documento. `pasted` indica colagem, que salva de imediato. |

## Garantias

- Recebe o foco ao montar.
- Não chama `onChange` ao montar nem ao trocar de linguagem.
- Para trocar o texto por fora, o `NoteEditor` muda a `key` do componente, como em "Restaurar" um rascunho.
- Usa sempre a versão mais recente de `onChange`.
- Destrói o `EditorView` ao desmontar.
- É exportado como `default`, para uso com `React.lazy`. O `NoteEditor` o envolve em `Suspense` e em um limite de erro, de modo que uma falha não apague o restante da nota.
