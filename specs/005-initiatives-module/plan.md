# Plano de implementação: Módulo Iniciativas (fase 1)

**Branch**: `005-initiatives-module` | **Data**: 2026-10-31 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação em `specs/005-initiatives-module/spec.md`

## Resumo

Novo módulo `initiatives`, independente de `codes`, com quatro tabelas (`initiatives_contexts`,
`initiatives_initiatives`, `initiatives_milestones`, `initiatives_tasks`), uma API REST em
`/api/v1/initiatives/...` e uma área `/iniciativas` no frontend: lista com busca e filtros, página da
iniciativa com abas (Tarefas, Marcos, Detalhes) e tela de contextos. O progresso é calculado na
consulta, sem colunas de contagem.

## Contexto técnico

**Linguagem/versão**: Ruby 3.2+ com Rails 8 (API); TypeScript com React 19 e Vite

**Dependências principais**: as já existentes. Nenhuma dependência nova.

**Armazenamento**: PostgreSQL 16; quatro tabelas novas com prefixo `initiatives_`

**Testes**: Minitest (models e request tests); `npm run build` e `npm run lint` no frontend

**Plataforma**: navegador; produção em Cloud Run com uma instância e um processo

**Tipo de projeto**: aplicação web (`api/` + `web/`)

**Metas de desempenho**: lista e busca em menos de 1 s com 500 iniciativas e 10.000 tarefas (SC-003)

**Restrições**: módulo não importa nada de `codes`; sem `user_id` (uso pessoal)

**Escala**: uso pessoal, uma conta, centenas de iniciativas

## Constitution Check

*Verificado antes da Fase 0 e novamente depois da Fase 1.*

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | OK | Namespace `Initiatives::`, tabelas `initiatives_*`, controllers em `api/v1/initiatives/`, `web/src/modules/initiatives/`, registro em `modules.yml` e `modules/index.ts`. Nada importado de `codes`. |
| II. Simplicidade | OK | Sem dependências novas. Progresso por subconsulta agregada, sem contadores. Sem arrastar e soltar. |
| III. Busca central | OK | Iniciativas e tarefas usam `Searchable` (tsvector gerado + GIN, trigram em nome/título). Marcos e contextos são poucos por iniciativa e listados inteiros, sem busca (ver `research.md`). Listagem de iniciativas paginada; tarefas carregadas por iniciativa (ver `research.md`). |
| IV. API estável | OK | Só rotas novas; erros no formato `{ errors, fields }` e `404 { error }`. `types.ts` espelha o contrato. |
| V. Qualidade | OK | Testes de models e request tests; migration com `change` reversível. |
| VI. Idioma | OK | Interface em português ("Iniciativas", `/iniciativas`); código e API em inglês. |

## Estrutura do projeto

### Documentação

```text
specs/005-initiatives-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/initiatives-api.md
├── checklists/requirements.md
└── tasks.md
```

### Código-fonte

```text
api/
├── app/models/initiatives.rb                     # namespace + table_name_prefix
├── app/models/initiatives/{context,initiative,milestone,task}.rb
├── app/controllers/api/v1/initiatives/
│   ├── contexts_controller.rb
│   ├── initiatives_controller.rb
│   ├── milestones_controller.rb
│   └── tasks_controller.rb
├── config/routes.rb, config/modules.yml
├── db/migrate/20261031000001_create_initiatives_module.rb, db/structure.sql, db/seeds.rb
└── test/
    ├── models/initiatives/{context,initiative,milestone,task}_test.rb
    └── integration/initiatives_api_test.rb

web/src/modules/initiatives/
├── index.tsx, api.ts, types.ts, labels.ts
├── pages/{InitiativesPage,InitiativePage,NewInitiativePage,ContextsPage}.tsx
└── components/{InitiativeForm,TaskList,TaskItem,MilestoneList,ProgressBar,ContextBadge}.tsx
```

**Decisão de estrutura**: segue o padrão do módulo Códigos. Estilos novos vão em
`web/src/index.css`, numa seção própria do módulo, como os de Códigos.

## Riscos

- **Nome do model `Initiatives::Initiative`**: rotas ficam `/api/v1/initiatives/initiatives`.
  Aceito para manter o padrão `namespace :<módulo>` (como `/codes/snippets`).
- **Marco de outra iniciativa**: validado no model (FR-014), não só no frontend.
- **Seções futuras**: `sections` é um array de texto validado contra a lista do model; novas seções
  das fases 2 a 4 só ampliam a lista. Iniciativas antigas não ganham seções novas sozinhas — a
  migration de cada fase decide se liga a seção nas existentes.

## Complexity Tracking

Nenhuma exceção à constituição.
