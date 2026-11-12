# Plano de implementação: Módulo Mentoria (fase 1)

**Branch**: `010-mentoring-module` | **Data**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Resumo

Novo módulo `mentoring`, para quem recebe mentoria: sete tabelas (`mentoring_mentorships`, `_questions`, `_goals`,
`_meetings`, `_action_items`, `_competencies`, `_ratings`), um serviço que calcula o painel
(`Mentoring::Overview`) e outro que monta a evolução das competências (`Mentoring::Assessments`), API em
`/api/v1/mentoring/...` e a área `/mentoria` no frontend: lista de mentorias e uma página por mentoria com abas
(Visão geral, Questionário, Objetivos, Encontros, Ações, Autoavaliação, Detalhes) e a página do encontro.

## Contexto técnico

**Linguagem/versão**: Ruby 3.3 com Rails 8 (API); TypeScript com React 19 e Vite

**Dependências principais**: as já existentes (`react-markdown` para os textos). Nenhuma dependência nova.

**Armazenamento**: PostgreSQL 16; sete tabelas novas com prefixo `mentoring_`

**Testes**: Minitest (models com regras, `Overview` indicador por indicador, `Assessments`, request tests);
`npm run build`, `npm run lint` e `npm run test:e2e`

**Metas de desempenho**: o painel sai de poucas consultas agregadas (sem N+1); a lista de mentorias usa contagens
agrupadas por `mentorship_id`. Busca nos encontros com índice GIN (SC-004).

**Restrições**: módulo não importa nada de outro módulo; sem `user_id`; "hoje" em America/Sao_Paulo (`Date.current`,
já configurado no Rails).

## Constitution Check

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | OK | Namespace `Mentoring::`, tabelas `mentoring_*`, controllers em `api/v1/mentoring/`, `web/src/modules/mentoring/`, registro em `modules.yml` e `modules/index.ts`. Componente de Markdown copiado localmente. |
| II. Simplicidade | OK | Sem dependências novas; reordenar perguntas por subir/descer (sem biblioteca de arrastar); evolução das competências em tabela com a sequência de notas, sem biblioteca de gráficos. |
| III. Busca central | OK | Encontros (a entidade com mais texto e mais registros) usam `Searchable` com lista paginada. Perguntas, objetivos, ações e competências são listas curtas por mentoria, mostradas inteiras. |
| IV. API estável | OK | Só rotas novas; erros no formato padrão; `types.ts` espelha `contracts/mentoring-api.md`. |
| V. Qualidade | OK | Testes de models, serviços e request tests; migration reversível por `change`. |
| VI. Idioma | OK | Interface em português; código e API em inglês. |
| VII. Responsivo e instalável | OK | Abas com rolagem horizontal própria; ações e notas por toque (botões 1 a 5, caixas de 44 px); nada da API vai para o service worker; rotas novas em `e2e/responsive.spec.ts`. |

## Estrutura

```text
api/
├── db/migrate/20261111000001_create_mentoring_module.rb
├── app/models/mentoring.rb
├── app/models/mentoring/{mentorship,question,goal,meeting,action_item,competency,rating}.rb
├── app/models/mentoring/{suggested_questions,overview,assessments}.rb
├── app/controllers/api/v1/mentoring/{mentorships,questions,goals,meetings,action_items,competencies,assessments}_controller.rb
├── app/controllers/api/v1/mentoring/serialization.rb
└── test/{models/mentoring/*,integration/mentoring_api_test.rb}
web/src/modules/mentoring/
├── api.ts, types.ts, labels.ts, index.tsx
├── components/{Markdown,MarkdownField,MentorshipForm,ActionItemList,ScorePicker}.tsx
├── components/tabs/{OverviewTab,QuestionsTab,GoalsTab,MeetingsTab,ActionItemsTab,AssessmentTab}.tsx
└── pages/{MentorshipsPage,NewMentorshipPage,MentorshipPage,MeetingPage}.tsx
```

Rotas do frontend: `/mentoria`, `/mentoria/nova`, `/mentoria/:id?aba=visao-geral|questionario|objetivos|encontros|acoes|autoavaliacao|detalhes`,
`/mentoria/encontros/:id`. "Novo encontro" cria o encontro com a data de hoje e abre a página dele (SC-002).
