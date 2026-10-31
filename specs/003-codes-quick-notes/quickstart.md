# Guia de validação: Códigos como bloco de notas rápido

## Preparação

```bash
docker compose up -d
cd api && bin/rails db:migrate && bin/rails server   # http://localhost:3000
cd web && npm run dev                                # http://localhost:5173
```

## Antes de publicar

As migrations rodam ao subir a imagem, e esta apaga os projetos. Se houver dados em produção, gere um
backup do banco antes do deploy e confira se algum projeto precisa ser guardado.

## Verificações automáticas

```bash
cd api && bin/rails test && bin/rails db:migrate:redo
cd web && npm run build && npm run lint
```

Tudo deve passar. O `db:migrate:redo` deve terminar sem erro, com as notas intactas (ver
[data-model.md](data-model.md)).

## Cenários no navegador

| # | Ação | Resultado esperado |
|---|------|--------------------|
| 1 | Abrir `/codigos` | Notas mais recentes primeiro; cursor na busca |
| 2 | Nova nota, colar um script com indentação | "Salvo" em até 2 s, sem outro campo nem botão; nota aparece no topo com a primeira linha como nome |
| 3 | Continuar digitando com pausas | Uma única nota na lista, sem duplicatas |
| 4 | Abrir a nota (já editável, sem botão "Editar") e usar "Copiar"; colar em um editor e comparar | Texto idêntico; confirmação visual |
| 5 | Buscar um pedaço do meio do script, um pedaço de tag e `$(date` | Nota encontrada, sem erro |
| 6 | Em uma nota, apagar todo o conteúdo | Aviso; ao recarregar, a versão anterior continua lá |
| 7 | Nota nova sem conteúdo, sair | Nenhuma nota criada |
| 8 | Parar a API, editar, tentar sair; subir a API de novo | "Não salvo", aviso ao sair; salva sozinho quando a API volta |
| 9 | Colar mais de 1 MB | Mensagem de limite; o texto continua na tela |
| 10 | Apagar uma nota | Pede confirmação; some da lista e da busca |
| 11 | Abrir `/codigos/999999` | "Não encontrada", com caminho de volta |
| 12 | Janela estreita (cerca de 400 px) | Lista e nota aparecem uma de cada vez |

## Dados antigos

Os códigos que existiam antes da migration aparecem como notas, com título, conteúdo, tags, linguagem e
descrição intactos, inclusive os que estavam em um projeto. `/codigos/projetos` não existe mais.

## Desempenho (SC-003)

Com 5.000 notas de teste no banco de desenvolvimento, os resultados devem aparecer em menos de 1 s depois
de parar de digitar.

## Logs

Depois de salvar uma nota, `api/log/development.log` deve mostrar `"content"=>"[FILTERED]"`.
