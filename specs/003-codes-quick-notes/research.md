# Pesquisa: Códigos como bloco de notas rápido

Não restaram pontos em aberto. As decisões abaixo foram tomadas a partir do código atual.

## 1. Manter `Codes::Snippet` no código

- **Decisão**: "nota" só na interface; tabela, model e rota continuam como `snippet`.
- **Motivo**: evita migração e renomeação sem ganho para o usuário (princípio II).
- **Alternativa**: renomear para `Note`. Rejeitada pelo custo e pelo risco.

## 2. Salvamento automático

- **Decisão**: hook `useAutosave` com uma fila de um único envio por vez. Dispara 800 ms depois da
  última digitação, na hora ao colar, e ao sair da nota. Se o texto mudar durante um envio, a versão
  mais recente vai em seguida.
- **Sem duplicatas**: a criação (`POST`) só ocorre uma vez; os envios seguintes usam o `id` devolvido
  (`PATCH`). A URL muda de `/codigos/novo` para `/codigos/:id` sem desmontar o editor, usando uma única
  rota `:id?`.
- **Sem sobrescrita**: a resposta do servidor nunca substitui o texto da tela, apenas atualiza o estado
  e a lista.
- **Falhas**: novas tentativas a cada 5 s. Enquanto houver falha, o texto fica em `sessionStorage` e é
  oferecido de volta ao reabrir, o que cobre a sessão expirada, que leva ao login. O rascunho é apagado
  ao salvar.
- **Sair da nota**: `useBlocker` na navegação interna e `beforeunload` ao fechar a aba, ambos só quando
  há alteração não salva.
- **Alternativa**: salvar a cada tecla. Rejeitada pelo volume de requisições, sem ganho perceptível.

## 3. Nota sempre editável

- **Decisão**: toda nota abre direto no editor, com foco no conteúdo e botões de copiar e apagar, por
  pedido do usuário depois de experimentar a primeira versão.
- **Risco aceito**: sem histórico e com salvamento automático, uma tecla acidental altera a nota de
  forma definitiva.
- **Alternativa**: modo de leitura com botão "Editar". Foi a primeira versão, removida por esse pedido.

## 4. Editor em `<textarea>`

> Substituída pela decisão de usar o CodeMirror: `specs/004-codes-codemirror/research.md`.

- **Decisão**: `textarea` monoespaçado, sem realce. O highlight.js deixa de ser usado e sai das dependências.
- **Motivo**: realce durante a edição exigiria uma dependência nova (princípio II).

## 5. Limite de tamanho e erros do banco

- **Verificado**: 31.000 palavras distintas (cerca de 1 MB) causam `string is too long for tsvector`, e
  `\u0000` causa `ArgumentError: string contains null byte`. Hoje os dois resultam em erro 500.
- **Decisão**: validar até 1 MB e rejeitar byte nulo no model. O `SnippetsController` converte o erro
  `PG::ProgramLimitExceeded` em 422 com uma mensagem clara, para textos menores que 1 MB que ainda
  estourem o limite.
- **Alternativa**: indexar só parte do conteúdo. Rejeitada por deixar trechos fora da busca.

## 6. Correção das tags

- **Causa confirmada**: o tipo array interpreta `"React, hooks"` como literal do Postgres antes do
  `normalizes`, resultando em `["eact"]`.
- **Decisão**: sobrescrever `tags=` em `NormalizesTags`, separando o texto por vírgulas antes da
  conversão. Testado no console: `"React, hooks, react"` vira `["react", "hooks"]`, `""` vira `[]` e
  `["A"]` vira `["a"]`.

## 7. Busca por pedaços de tags

- **Decisão**: coluna gerada `tags_text` (texto) incluída em `searchable_partial_columns`, junto com
  `description`.
- **Motivo**: FR-007 pede pedaços de texto nas tags, e `Searchable` só aceita colunas simples. Assim, o
  concern não muda. Índices trigram novos não são necessários nesta escala; SC-003 é conferido no
  `quickstart.md`.

## 8. Listagem sem conteúdo

- **Decisão**: a listagem devolve `display_title`, tags, linguagem e datas, sem `content`.
- **Motivo**: 20 notas de até 1 MB deixariam a lista lenta. O conteúdo vem ao abrir a nota.

## 9. Conteúdo fora dos logs

- **Verificado**: `filter_parameters` não cobre `content`, e o salvamento automático gravaria cada versão
  dos scripts de produção nos logs.
- **Decisão**: adicionar `content` à lista de filtros.

## 10. Descrição existente

- **Decisão**: manter a coluna `description`, para não perder dados; o campo fica em "Mais detalhes",
  junto com título, tags e linguagem.
- **Alternativa**: juntar ao conteúdo. Rejeitada porque alteraria o texto que será copiado.
