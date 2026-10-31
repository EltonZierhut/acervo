# Pesquisa: Editor de código nas notas

Os valores abaixo foram medidos em um build de teste, fora do repositório, com Vite 8, `codemirror`
6.0.2, `@codemirror/view` 6.43.15 e `@codemirror/state` 6.7.6.

## 1. CodeMirror 6 direto, sem wrapper para React

- **Decisão**: usar os pacotes `@codemirror/*` em um componente próprio, criando o `EditorView` em um `useEffect`.
- **Motivo**: o componente precisa controlar quando uma mudança vem do usuário (decisão 3) e quais extensões entram (decisão 2).
- **Alternativa**: `@uiw/react-codemirror`. Rejeitada por ser mais uma dependência, com `@babel/runtime` e `@codemirror/theme-one-dark` entre as dependências de par, para evitar poucas linhas de integração.

## 2. Lista própria de extensões, sem `basicSetup`

- **Decisão**: incluir só `lineNumbers`, `highlightActiveLine`, `highlightActiveLineGutter`, `history`, `drawSelection`, `bracketMatching`, `search`, `placeholder` e os atalhos de edição, histórico e busca, além de `indentWithTab`.
- **Motivo**: o `basicSetup` traz preenchimento automático, fechamento de colchetes e reindentação ao digitar, que contrariam o FR-002 e o FR-006.
- **Alternativa**: `basicSetup` com partes desligadas. Rejeitada porque ele não foi feito para ser ajustado assim, e o pacote `codemirror` não acrescentaria mais nada.

## 3. Sincronização com o formulário e quebras de linha

- **Verificado**: `EditorState.create({ doc: 'a\r\nb\rc' })` devolve `"a\nb\nc"`. O CodeMirror converte as quebras para `\n` ao carregar o texto.
- **Decisão**: o editor recebe o texto só ao montar (`initialValue`) e avisa as edições por `onChange`, que não dispara ao carregar. Assim, uma nota antiga com CRLF não parece alterada ao abrir (FR-008). O único texto vindo de fora é o rascunho restaurado: "Restaurar" muda a `key` e remonta o editor.
- **Alternativa**: sincronizar uma propriedade `value` a cada renderização, ideia inicial deste plano. Rejeitada na implementação: o CodeMirror lê parte da digitação fora dos eventos do React, então uma renderização atrasada poderia sobrescrever teclas recentes.
- **Efeito aceito**: ao editar uma nota com CRLF, o texto salvo passa a usar `\n`. O `textarea` já faz o mesmo, pois sua propriedade `value` entrega `\n`. Assim, o FR-006 vale para o conteúdo das linhas, não para o tipo de quebra.
- **Colagem**: o salvamento imediato usa `transaction.isUserEvent('input.paste')`, no lugar do `onPaste` com ref.

## 4. Carregamento sob demanda

- **Medido**: núcleo com `basicSetup`, 129 kB em gzip; as 13 linguagens somadas, cerca de 172 kB em gzip, de 1,2 kB (shell) a 34,6 kB. O código atual soma 321 kB sem compressão.
- **Medido no código final**: `CodeEditor` 107,7 kB em gzip; linguagens de 1,2 kB a 33,6 kB. O `index-*.js` tem 331 kB sem compressão (104,9 kB em gzip) e não inclui o editor.
- **Decisão**: carregar o `CodeEditor` com `React.lazy` e cada linguagem com `import()` dinâmico. Login e lista não baixam o editor (SC-004), e abrir uma nota só baixa a linguagem dela.
- **Falha**: um limite de erro em volta do editor mostra "Não foi possível carregar o editor. Recarregue a página." Isso também cobre arquivos antigos que somem depois de um deploy. Se só a linguagem falhar, o conteúdo fica como texto simples.
- **Alternativa**: tudo em um só pacote. Rejeitada por pesar em todas as páginas, sem necessidade.

## 5. Busca na nota (FR-010)

- **Motivo**: o CodeMirror só desenha o trecho visível, então a busca do navegador não alcança o resto de uma nota longa.
- **Decisão**: usar o painel do `@codemirror/search`, aberto com Ctrl+F dentro do editor, e traduzir os textos com `EditorState.phrases` (princípio VI).
- **Efeito aceito**: com o foco fora do editor, Ctrl+F continua sendo a busca do navegador. O painel também traz substituição, que vem junto e não foi retirada.

## 6. Temas e realce

- **Decisão**: `EditorView.theme` e `HighlightStyle.define` usam variáveis CSS (`var(--surface)`, `var(--syntax-keyword)`…), definidas no `index.css` para os dois temas. A troca de tema acompanha o sistema sem JavaScript e sem recriar o editor.
- **Alternativa**: `@codemirror/theme-one-dark`. Rejeitada por exigir troca via JavaScript e por trazer cores alheias à interface.

## 7. Linguagens

- **Decisão**: um mapa em `editorLanguages.ts` cobre a lista `LANGUAGES`. `bash` e `ruby` usam `StreamLanguage` com os modos de `@codemirror/legacy-modes`, por não terem pacote próprio; as demais têm pacote `lang-*`, e `typescript` usa `javascript({ typescript: true })`. O nome é comparado sem diferenciar maiúsculas e sem espaços nas pontas; fora do mapa, vale texto simples.
- **Troca de linguagem**: um `Compartment` reconfigura o realce sem recriar o editor, sem mover o cursor e sem criar item no desfazer. Se o usuário trocar de novo durante o download, o resultado antigo é descartado.
- **Alternativa**: `@codemirror/language-data`. Rejeitada por incluir muito mais linguagens do que a lista usa.

## 8. Teclado, leitor de tela e altura

- **Decisão**: `EditorView.contentAttributes` define `aria-label="Conteúdo"`, `spellcheck="false"`, `autocorrect="off"` e `autocapitalize="off"`. `indentWithTab` faz o Tab indentar; Esc seguido de Tab leva o foco adiante, como o CodeMirror já prevê.
- **Altura**: um contêiner com `height: 60vh`, `min-height: 60vh` e `resize: vertical`, com o editor ocupando 100% dele. Sem `lineWrapping`, linhas longas geram rolagem horizontal.
