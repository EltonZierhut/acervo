# Pesquisa: Módulo Iniciativas (fase 1)

## 1. Nome do módulo e da entidade

- **Decisão**: módulo `initiatives`, entidade `Initiatives::Initiative`, interface "Iniciativas" em
  `/iniciativas`.
- **Motivo**: "projeto" já foi usado (e removido) no módulo Códigos; o usuário pensa em projetos de
  trabalho e pessoais, e "iniciativa" cobre os dois.
- **Alternativas**: `projects` (confunde com o histórico de Códigos e com o próprio Acervo);
  `ventures` (estranho em português).

## 2. Status e prioridade como texto validado

- **Decisão**: colunas `string` com `validates inclusion` e `enum` do Rails com valores em texto
  (`enum :status, { idea: "idea", ... }`) e `CHECK` no banco.
- **Motivo**: legível no banco e no JSON, sem mapa de inteiros. O `CHECK` protege contra escrita
  fora do Rails.
- **Alternativa**: tipo `enum` do PostgreSQL — mais difícil de alterar nas próximas fases.

## 3. Seções ligadas por iniciativa

- **Decisão**: `sections text[] NOT NULL DEFAULT '{tasks,milestones}'`, validado contra
  `Initiative::SECTIONS`.
- **Motivo**: simples, sem tabela extra; a ordem das abas é a da constante, não a do array.
- **Alternativa**: colunas booleanas por seção — exigiria migration por seção nova.

## 4. Progresso calculado

- **Decisão**: `Initiative.with_progress` faz `LEFT JOIN` agregando `count(*)` e
  `count(*) FILTER (WHERE status = 'done')` das tarefas; marcos usam o mesmo padrão.
- **Motivo**: sempre bate com a contagem real (SC-004) e é rápido com índice em
  `initiatives_tasks(initiative_id, status)`.
- **Alternativa**: `counter_cache` — dois contadores, callbacks e risco de divergência.

## 5. Ordenação da lista de iniciativas

- **Decisão**: `ORDER BY array_position(ARRAY['active','planned','idea','paused','done'], status),
  updated_at DESC`; com busca, a relevância vem primeiro (comportamento do `Searchable`).
- **Motivo**: o que está em andamento aparece primeiro (FR-004).
- **Detalhe**: `updated_at` da iniciativa é tocado quando tarefas ou marcos mudam
  (`belongs_to ..., touch: true`), para "alteradas recentemente" refletir o trabalho real.

## 6. Tarefas sem paginação

- **Decisão**: `GET .../initiatives/:id/tasks` devolve todas as tarefas da iniciativa (limite de
  segurança de 1.000), com busca e filtros.
- **Motivo**: a tela agrupa por status; paginar quebraria os grupos. Uma iniciativa pessoal raramente
  passa de algumas centenas de tarefas. A constituição pede paginação em "listagens com busca"; aqui
  a lista é limitada pela iniciativa e tem teto fixo, o que cumpre o objetivo do princípio III
  (resposta rápida). Se o teto for atingido, `meta.truncated` avisa a interface.

## 7. Busca em marcos e contextos

- **Decisão**: sem `Searchable` em marcos e contextos.
- **Motivo**: são poucos por iniciativa (marcos) ou no total (contextos) e aparecem inteiros na tela.
  A busca geral do módulo (fase 4) pode incluí-los depois.

## 8. Cor do contexto

- **Decisão**: `color` em formato `#rrggbb`, escolhida de uma paleta fixa de 8 cores na interface,
  com padrão `#6b7380`.
- **Motivo**: contraste previsível em tema claro e escuro; o model aceita qualquer hex válido.

## 9. Data de conclusão

- **Decisão**: `completed_at` em tarefas e marcos, preenchido/limpo no model ao mudar o status
  (tarefa) ou via `completed: true/false` (marco).
- **Motivo**: FR-010; a interface não envia datas de conclusão.
