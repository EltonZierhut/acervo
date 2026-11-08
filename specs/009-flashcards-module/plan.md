# Plano de implementação: Módulo Flashcards (fase 1)

**Branch**: `009-flashcards-module` | **Data**: 2026-11-07 | **Spec**: [spec.md](spec.md)

## Resumo

Novo módulo `flashcards`, inspirado no Anki/AnkiDroid: quatro tabelas (`flashcards_decks`, `flashcards_notes`,
`flashcards_cards`, `flashcards_reviews`), um agendador SM-2 sem acesso ao banco (`Flashcards::Scheduler`), um
serviço que monta a fila do dia (`Flashcards::StudyQueue`), API em `/api/v1/flashcards/...` e a área
`/flashcards` no frontend: lista de baralhos com as contagens do dia, notas do baralho com busca, editor de nota
e tela de estudo.

## Contexto técnico

**Linguagem/versão**: Ruby 3.3 com Rails 8 (API); TypeScript com React 19 e Vite

**Dependências principais**: as já existentes (`react-markdown` para frente e verso). Nenhuma dependência nova.

**Armazenamento**: PostgreSQL 16; quatro tabelas novas com prefixo `flashcards_`

**Testes**: Minitest (Scheduler cenário por cenário, models e request tests); `npm run build` e `npm run lint`

**Metas de desempenho**: lista de baralhos e fila em menos de 1 s com 10.000 cartões (SC-003): as contagens
saem de três consultas agregadas por `deck_id`, não de uma por baralho.

**Restrições**: módulo não importa nada de outro módulo; sem `user_id`; dia de estudo vira às 4h em
America/Sao_Paulo.

## Constitution Check

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | OK | Namespace `Flashcards::`, tabelas `flashcards_*`, controllers em `api/v1/flashcards/`, `web/src/modules/flashcards/`, registro em `modules.yml` e `modules/index.ts`. O componente de Markdown é uma cópia local (módulos não importam uns dos outros). |
| II. Simplicidade | OK | Sem dependências novas; limites no próprio baralho, passos fixos no `Scheduler`; sem subbaralhos. |
| III. Busca central | OK | Notas usam `Searchable` (frente, verso, tags) com lista paginada. Baralhos são poucos e listados inteiros. |
| IV. API estável | OK | Só rotas novas; erros no formato padrão; `types.ts` espelha `contracts/flashcards-api.md`. |
| V. Qualidade | OK | Testes do `Scheduler`, dos models e request tests; migration reversível por `change`. |
| VI. Idioma | OK | Interface em português; código e API em inglês. |
| VII. Responsivo e instalável | OK | Estudo pensado para o celular (botões grandes, por toque); teclado é atalho, não exigência. Nada da API vai para o service worker. Rotas novas entram em `e2e/responsive.spec.ts`. |

## Estrutura

```text
api/
├── db/migrate/20261107000001_create_flashcards_module.rb
├── app/models/flashcards.rb
├── app/models/flashcards/{deck,note,card,review,scheduler,study_day,study_queue}.rb
├── app/controllers/api/v1/flashcards/{decks,notes,study,cards}_controller.rb
├── app/controllers/api/v1/flashcards/serialization.rb
└── test/{models/flashcards/*,integration/flashcards_api_test.rb}
web/src/modules/flashcards/
├── api.ts, types.ts, index.tsx
├── components/{Markdown,NoteForm}.tsx
└── pages/{DecksPage,DeckPage,NotePage,StudyPage}.tsx
```

Rotas do frontend: `/flashcards`, `/flashcards/:deckId`, `/flashcards/:deckId/estudar`,
`/flashcards/:deckId/notas/nova`, `/flashcards/notas/:id`.
