# Modelo de dados: Editor de código nas notas

Não há mudanças. Sem migration, sem alteração em `codes_snippets` nem na API.

Os campos existentes são usados assim:

| Campo | Uso nesta feature |
|-------|-------------------|
| `content` | Texto do editor; continua sujeito ao limite de 1 MB e à validação atuais. |
| `language` | Só leitura pelo editor, para escolher o realce. Continua texto livre; valores fora da lista sugerida dão texto simples. |

O rascunho em `sessionStorage` e o estado de salvamento em `useAutosave` também não mudam.
