<!--
Sync Impact Report
- Versão: 1.0.1 → 1.0.2 (PATCH): realce de código removido da stack, sem uso (feature 003)
- Versão: 1.0.0 → 1.0.1 (PATCH): descrição do módulo Códigos, que deixou de ter projetos (feature 003)
- Versão anterior: (template) → 1.0.0
- Princípios definidos: I. Modularidade, II. Simplicidade, III. Busca é recurso central,
  IV. Contrato de API estável, V. Qualidade verificável, VI. Idioma e consistência
- Seções adicionadas: Restrições técnicas, Fluxo de desenvolvimento, Governança
- Templates: plan-template.md, spec-template.md e tasks-template.md compatíveis (sem alterações)
- Pendências: nenhuma
-->

# Constituição do Acervo

O Acervo é um organizador pessoal dividido em módulos. Cada módulo organiza uma área da
vida do usuário (o primeiro é **Códigos**: notas e scripts para colar,
com busca). Novos módulos são adicionados ao longo do tempo.

## Princípios

### I. Modularidade (INEGOCIÁVEL)

Cada funcionalidade pertence a um módulo, e módulos são independentes entre si.

- Backend: cada módulo tem namespace próprio (`Codes::`, `Finance::`…), tabelas com
  prefixo do módulo (`codes_`, `finance_`…), controllers em `app/controllers/api/v1/<modulo>/`
  e rotas em `namespace :<modulo>` dentro de `api/v1`.
- Frontend: cada módulo vive em `web/src/modules/<modulo>/` e exporta um `OrganizerModule`
  registrado em `web/src/modules/index.ts`.
- Todo módulo é registrado em `api/config/modules.yml`.
- Um módulo NÃO importa código de outro módulo. O que for compartilhado vai para o núcleo:
  `api/app/models/concerns/`, `api/app/controllers/application_controller.rb` e `web/src/core/`.
- O núcleo NÃO depende de nenhum módulo específico.
- Integrações entre módulos, se necessárias, passam por um contrato explícito no núcleo e
  precisam ser justificadas no plano.

### II. Simplicidade

É um projeto pessoal mantido por uma pessoa. A solução mais simples que atende à spec vence.

- Sem microsserviços, filas, cache ou camadas de abstração sem uma necessidade concreta (YAGNI).
- Preferir recursos nativos do Rails, do PostgreSQL e do React antes de adicionar dependências.
- Toda dependência nova (gem ou pacote npm) precisa ser justificada no `plan.md`.

### III. Busca é recurso central

Encontrar informação rapidamente é o propósito do Acervo.

- Toda entidade principal de um módulo deve ser pesquisável, usando o concern `Searchable`
  (coluna `searchable` tsvector gerada + índice GIN, e colunas parciais com índice trigram
  quando fizer sentido).
- A busca deve encontrar palavras inteiras (full-text, configuração `simple`) e pedaços de
  texto (ILIKE).
- Listagens com busca devem ser paginadas.

### IV. Contrato de API estável

- A API é JSON, versionada em `/api/v1`, e é a única forma do frontend acessar dados.
- Erros de validação retornam `422` com `{ errors: [...], fields: {...} }`; registro
  inexistente retorna `404` com `{ error: "..." }`.
- Mudanças incompatíveis exigem nova versão de rota ou migração planejada do frontend na
  mesma feature.
- Tipos do frontend (`types.ts` do módulo) devem refletir exatamente o JSON da API.

### V. Qualidade verificável

- Backend: testes automatizados (Minitest) para models com regras próprias e request tests
  para os endpoints de cada módulo. Bugs corrigidos ganham um teste que os reproduz.
- Frontend: TypeScript estrito; `npm run build` e `npm run lint` passam sem erros.
- Migrations são reversíveis (`down` ou `change` reversível) e não perdem dados existentes.
- Nenhuma tarefa é marcada como concluída com testes, build ou lint falhando.

### VI. Idioma e consistência

- Interface, mensagens de erro, documentação, specs e commits: **português do Brasil**.
- Código (nomes de classes, métodos, variáveis, tabelas, rotas da API): **inglês**.
  Rotas do frontend visíveis ao usuário podem ser em português (`/codigos`).
- Seguir os padrões já existentes no código antes de criar novos.

## Restrições técnicas

- Backend: Ruby 3.2+, Rails 8 em modo API, PostgreSQL 14+ (extensão `pg_trgm`).
  Schema salvo em SQL (`db/structure.sql`).
- Frontend: React 19, TypeScript, Vite, React Router.
- Datas e horários no fuso `America/Sao_Paulo`.
- Uso pessoal: sem multiusuário por enquanto. Autenticação, quando entrar, será uma feature
  própria com spec.
- Segredos nunca entram no repositório (`.env`, `config/master.key`).

## Fluxo de desenvolvimento

1. Toda feature nova passa pelo Spec Kit: `/speckit-specify` → (`/speckit-clarify`) →
   `/speckit-plan` → `/speckit-tasks` → (`/speckit-analyze`) → `/speckit-implement`.
2. Correções pequenas e ajustes de texto ou estilo podem ser feitos direto, sem spec.
3. Um módulo novo sempre começa com uma spec própria, descrevendo suas entidades e o que
   deve ser pesquisável.
4. Cada feature é desenvolvida em uma branch própria (criada pelo `/speckit-specify`) e
   integrada à `main` depois de passar pelas verificações do princípio V.

## Governança

- Esta constituição prevalece sobre outras práticas. Planos (`plan.md`) devem conferir a
  conformidade com cada princípio na seção "Constitution Check" e justificar exceções.
- Alterações na constituição são feitas com `/speckit-constitution`, registradas no Sync
  Impact Report e versionadas: MAJOR para remover ou redefinir princípios, MINOR para
  adicionar princípios ou seções, PATCH para esclarecimentos.
- Orientações práticas do dia a dia ficam em `CLAUDE.md`.

**Versão**: 1.0.2 | **Ratificada**: 2026-10-30 | **Última alteração**: 2026-10-30
