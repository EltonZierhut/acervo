# Guia de validação: Módulo Iniciativas (fase 1)

## Preparação

```bash
docker compose up -d
cd api && bundle install && bin/rails db:migrate && bin/rails db:migrate:redo && bin/rails test
cd ../web && npm install && npm run build && npm run lint && npm run dev
```

`db:migrate:redo` precisa terminar sem erro e deixar `db/structure.sql` sem diferença.

## Roteiro manual (http://localhost:5173/iniciativas)

1. **Contextos**: em "Contextos", crie "Trabalho" e "Jogo" com cores diferentes. Tente criar
   "trabalho" de novo: aparece a mensagem de nome repetido.
2. **Iniciativa só com nome**: "Nova iniciativa", digite "Jogo para a Steam" e salve. Ela abre na aba
   Tarefas, com status "Planejada" e prioridade "Média".
3. **Tarefas**: digite três títulos, apertando Enter em cada um; o campo continua em foco. Marque uma
   como concluída: o progresso mostra 1/3. Reabra-a: a data de conclusão some.
4. **Atraso**: edite uma tarefa com prazo de ontem: aparece como atrasada.
5. **Marcos**: na aba Marcos, crie "Protótipo jogável". Ligue duas tarefas a ele (edição da tarefa).
   Conclua uma: o marco mostra 1/2. Apague o marco: as tarefas continuam, sem marco.
6. **Detalhes e seções**: na aba Detalhes, escolha o contexto "Jogo", status "Ativa", tags
   "godot, steam", e desligue "Marcos". A aba some; religue e os marcos voltam.
7. **Lista**: volte para a lista. A iniciativa ativa aparece primeiro, com cor do contexto e
   progresso. Busque "stea" (pedaço de tag) e "Steam" (palavra). Filtre por contexto e status;
   recarregue a página e os filtros continuam.
8. **Encerrar**: mude o status para "Encerrada": some da lista padrão e aparece com o filtro "Todas"
   ou "Encerrada".
9. **Apagar**: apague a iniciativa (com confirmação); as tarefas e marcos dela somem.
10. **Link quebrado**: abra `/iniciativas/999999`: aparece "não encontrada" com link para a lista.
