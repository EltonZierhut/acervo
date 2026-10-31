# Plano de implementação: Códigos como bloco de notas rápido

**Branch**: `003-codes-quick-notes` | **Data**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação em `specs/003-codes-quick-notes/spec.md`

## Resumo

Transformar a tela de Códigos em um bloco de notas de dois painéis: lista com busca à esquerda e
nota à direita. Criar é só colar, o salvamento é automático e copiar leva um clique. A área de
Projetos sai do módulo, com remoção da tabela e do vínculo. Os códigos atuais continuam na mesma
tabela, então não há migração de conteúdo. O título passa a ser opcional, e a lista usa a primeira
linha do conteúdo quando ele falta.

## Contexto técnico

**Linguagem/versão**: Ruby 3.2+ com Rails 8 (API); TypeScript com React 19 e Vite

**Dependências principais**: as já existentes (React Router 7, highlight.js). Nenhuma dependência nova.

**Armazenamento**: PostgreSQL 16, tabela `codes_snippets`; remoção de `codes_projects`

**Testes**: Minitest (models e request tests); `npm run build` e `npm run lint` no frontend

**Plataforma**: navegador; produção em Cloud Run com uma instância e um processo

**Tipo de projeto**: aplicação web (`api/` + `web/`)

**Metas de desempenho**: busca em menos de 1 s com 5.000 notas; estado "salvo" em até 2 s (SC-003, SC-006)

**Restrições**: conteúdo idêntico ao colado; até 1 MB por nota; exclusão de Projetos sem volta

**Escala**: uso pessoal, uma conta, milhares de notas

## Constitution Check

*Verificado antes da Fase 0 e novamente depois da Fase 1.*

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | OK | Tudo em `Codes::` e `modules/codes/`. `core/` não muda. |
| II. Simplicidade | OK | Sem dependências novas. Mantém `Snippet` no código, em vez de renomear para `Note`. |
| III. Busca central | OK | Usa `Searchable`; inclui pedaços de tags e descrição; listagem paginada. |
| IV. API estável | OK | Mudança incompatível (remove `projects`, `search`, `project_id` e `content` da listagem), com o frontend migrado na mesma feature. |
| V. Qualidade | **Exceção** | A migration apaga `codes_projects` e `project_id`, e o `down` não recupera esses dados. Ver abaixo. |
| VI. Idioma | OK | "Nota" na interface; `snippet` no código e na API. |

## Estrutura do projeto

### Documentação

```text
specs/003-codes-quick-notes/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/codes-api.md
└── tasks.md             # criado por /speckit-tasks
```

### Código-fonte

```text
api/
├── app/models/codes/snippet.rb              # título opcional, display_title, limites
├── app/models/codes/project.rb              # removido
├── app/models/concerns/normalizes_tags.rb   # correção das tags enviadas como texto
├── app/controllers/api/v1/codes/
│   ├── snippets_controller.rb               # sem projeto; listagem sem conteúdo
│   ├── projects_controller.rb               # removido
│   └── search_controller.rb                 # removido (sem uso no frontend)
├── config/routes.rb, config/modules.yml
├── config/initializers/filter_parameter_logging.rb  # filtra :content dos logs
├── db/migrate/<nova migration>, db/structure.sql, db/seeds.rb
└── test/{models/codes/snippet_test.rb, integration/codes_api_test.rb}

web/src/modules/codes/
├── index.tsx, api.ts, types.ts              # rota única; sem projetos
├── useAutosave.ts                           # fila de salvamento e estados
├── pages/NotesPage.tsx                      # substitui as páginas atuais
├── components/{NoteList,NoteEditor,NoteView,SaveStatus}.tsx
└── components/{CodeBlock,Tags}.tsx          # mantidos; CodeBlock ganha limites e erro ao copiar
```

**Decisão de estrutura**: mantém os diretórios atuais. Saem `Project*Page`, `Snippet*Page` e `SubNav`.

## Riscos

- **Publicação apaga dados**: as migrations rodam ao subir a imagem, então o deploy apaga os projetos
  de produção assim que entrar. Se houver dados lá, é preciso exportá-los antes (ver `quickstart.md`).
- **Vínculo perdido**: uma nota que pertencia a um projeto não guarda mais o nome dele.
- **Alteração acidental**: sem histórico, o que for salvo substitui a versão anterior. Por isso a nota
  abre em modo de leitura, e a edição exige uma ação (ver `research.md`, decisão 3).

## Complexity Tracking

| Exceção | Por que é necessária | Alternativa simples rejeitada |
|---------|----------------------|-------------------------------|
| Migration com perda de dados de Projetos (princípio V) | Decisão do usuário na FR-018: remover a área e os dados | Manter a tabela sem uso: deixa código e dados mortos, sem benefício |
