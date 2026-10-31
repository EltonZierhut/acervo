# Especificação da feature: Editor de código nas notas

**Branch da feature**: `004-codes-codemirror`

**Criada em**: 2026-10-31

**Status**: Rascunho

**Entrada**: Descrição do usuário: "podemos trocar o editor de texto para um CodeMirror?" O campo de conteúdo das notas do módulo Códigos é hoje um `textarea` monoespaçado sem realce. O comportamento atual deve ser mantido: foco ao abrir, sem correção ortográfica, sem quebra automática de linha, placeholder, salvamento automático (imediato ao colar), restauração de rascunho e botão Copiar, nos temas claro e escuro.

## Cenários de uso e testes *(obrigatório)*

### História 1 - Editar a nota em um editor de código (Prioridade: P1)

O dono do Acervo abre uma nota e edita o conteúdo em um editor próprio para código, com números de
linha, destaque da linha atual e indentação com a tecla Tab, no tema claro ou escuro do sistema.

**Por que esta prioridade**: é o motivo da troca. Sem ela, o campo atual continua igual.

**Teste independente**: abrir uma nota com várias linhas, ver os números de linha, indentar um trecho
com Tab e confirmar que o texto salvo é o que aparece na tela.

**Cenários de aceitação**:

1. **Dado** uma nota com várias linhas, **quando** ela é aberta, **então** o conteúdo aparece com números de linha, em fonte monoespaçada e sem quebra automática de linha.
2. **Dado** o cursor no conteúdo, **quando** o usuário pressiona Tab, **então** a linha é indentada e o foco permanece no editor.
3. **Dado** o sistema em tema escuro, **quando** a nota é aberta, **então** o editor segue o tema escuro; o mesmo vale para o tema claro.

---

### História 2 - Manter o fluxo atual de colar e salvar (Prioridade: P1)

O dono do Acervo continua criando e alterando notas como hoje: abre a nota, cola o conteúdo e o
salvamento acontece sozinho, sem que nada do que já funcionava mude.

**Por que esta prioridade**: guardar um script colando é a função principal do módulo, e a troca não
pode colocá-la em risco nem alterar o texto guardado.

**Teste independente**: criar uma nota colando um script, recarregar a página e comparar o conteúdo
com o original; depois repetir os demais comportamentos dos cenários abaixo.

**Cenários de aceitação**:

1. **Dado** uma nota aberta, **quando** a página termina de carregar, **então** o cursor já está no conteúdo, pronto para digitar ou colar.
2. **Dado** uma nota nova e vazia, **quando** ela é exibida, **então** aparece o texto de orientação atual.
3. **Dado** um script na área de transferência, **quando** ele é colado, **então** o salvamento começa imediatamente e o texto guardado é idêntico ao colado.
4. **Dado** uma digitação no conteúdo, **quando** o usuário para de digitar, **então** o salvamento automático ocorre com o mesmo intervalo de hoje e o status de salvamento é atualizado.
5. **Dado** um rascunho não salvo, **quando** o usuário escolhe "Restaurar", **então** o conteúdo do rascunho aparece no editor.
6. **Dado** uma nota com conteúdo, **quando** o usuário clica em "Copiar", **então** a área de transferência recebe o conteúdo integral, mesmo o trecho fora da tela.
7. **Dado** alterações ainda não salvas, **quando** o usuário sai da nota, **então** o sistema tenta salvar antes de sair, como hoje.

---

### História 3 - Ler o código com realce de sintaxe (Prioridade: P2)

Ao informar a linguagem da nota em "Mais detalhes", o dono do Acervo passa a ver o conteúdo com realce
de sintaxe daquela linguagem, o que facilita conferir um script antes de usá-lo.

**Por que esta prioridade**: melhora a leitura, mas o editor já tem valor sem realce.

**Teste independente**: definir a linguagem de uma nota como `sql` e confirmar que o realce aparece;
remover a linguagem e confirmar que o conteúdo volta a texto simples.

**Cenários de aceitação**:

1. **Dado** uma nota cuja linguagem está na lista sugerida, **quando** ela é aberta, **então** o conteúdo aparece com o realce dessa linguagem.
2. **Dado** uma nota aberta, **quando** o usuário altera a linguagem, **então** o realce muda sem recarregar a página, sem mover o cursor e sem perder texto.
3. **Dado** uma nota sem linguagem ou com uma linguagem fora da lista, **quando** ela é aberta, **então** o conteúdo aparece como texto simples, sem erro.

---

### Edge Cases

- **Busca dentro da nota**: em uma nota longa, a busca do navegador pode não alcançar o trecho fora da tela; o usuário precisa continuar conseguindo encontrar qualquer trecho da nota aberta com Ctrl+F.
- **Nota no limite de 1 MB**: abrir, rolar e digitar continuam utilizáveis.
- **Sair do editor pelo teclado**: como Tab passa a indentar, é preciso haver um caminho de teclado documentado para levar o foco ao próximo campo (Esc seguido de Tab).
- **Abrir uma nota sem alterá-la**: não dispara salvamento, inclusive em nota antiga com quebras de linha CRLF.
- **Conteúdo com tabulações, espaços no fim da linha ou linhas muito longas**: permanece como está; linhas longas geram rolagem horizontal.
- **Erro ao carregar o editor**: se o código do editor não puder ser baixado, a página mostra um erro claro em vez de ficar em branco.

## Requisitos *(obrigatório)*

### Requisitos funcionais

- **FR-001**: O campo de conteúdo da nota DEVE ser um editor de código, com números de linha, destaque da linha atual e indentação com Tab.
- **FR-002**: O editor DEVE usar fonte monoespaçada, não quebrar linhas automaticamente e não aplicar correção ortográfica, autocorreção nem sugestões de preenchimento.
- **FR-003**: O editor DEVE receber o foco ao abrir a nota e exibir o texto de orientação atual quando estiver vazio.
- **FR-004**: O editor DEVE seguir automaticamente o tema claro ou escuro, com cores coerentes com o restante da interface.
- **FR-005**: O salvamento automático DEVE manter as regras atuais: espera após a digitação, salvamento imediato ao colar, status visível e tentativa de salvar ao sair.
- **FR-006**: O conteúdo salvo DEVE ser idêntico ao texto do editor. O editor não pode reformatar, reindentar ou remover espaços do texto colado.
- **FR-007**: Restaurar um rascunho DEVE atualizar o conteúdo exibido, e "Copiar" DEVE copiar o conteúdo integral.
- **FR-008**: Abrir uma nota sem editá-la NÃO DEVE gerar salvamento nem aviso de alterações pendentes.
- **FR-009**: O editor DEVE aplicar realce de sintaxe às linguagens da lista sugerida (bash, css, go, html, java, javascript, json, python, ruby, rust, sql, typescript e yaml), conforme a linguagem informada na nota, e tratar os demais casos como texto simples.
- **FR-010**: O usuário DEVE conseguir buscar qualquer trecho da nota aberta com Ctrl+F, inclusive fora da área visível.
- **FR-011**: O editor DEVE ser identificado como "Conteúdo" para leitores de tela, e o foco DEVE poder sair dele pelo teclado.
- **FR-012**: O editor DEVE manter a altura mínima atual (60% da altura da tela) e continuar ajustável na vertical.
- **FR-013**: Os demais campos da nota (título, tags, linguagem e descrição), a API e os dados guardados NÃO DEVEM mudar.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: Em 100% das verificações com scripts colados (incluindo tabulações, espaços no fim da linha e caracteres acentuados), o conteúdo guardado é idêntico ao original.
- **SC-002**: Todos os comportamentos da História 2 funcionam como antes da troca, sem nenhuma etapa adicional para o usuário.
- **SC-003**: Uma nota de 1 MB abre em até 2 segundos e a digitação aparece sem atraso perceptível.
- **SC-004**: As páginas que não abrem uma nota, como o login, não ficam perceptivelmente mais lentas para carregar.

## Premissas

- O editor será o CodeMirror, por escolha do usuário. Isso substitui a decisão 4 de `specs/003-codes-quick-notes/research.md` (`textarea` sem realce), e a dependência nova será justificada no `plan.md`, como pede o princípio II.
- Números de linha, destaque da linha atual, indentação com Tab, realce de sintaxe e busca na nota são recursos assumidos nesta spec: o pedido nomeou o editor, sem listar recursos.
- A linguagem vem apenas do campo já existente na nota; não há detecção automática.
- Só o campo de conteúdo muda. O campo "Descrição" continua sendo um texto simples.
- A edição continua sempre ativa, sem modo de leitura, conforme a decisão da feature 003.
- A busca entre notas não muda: continua na lista do módulo.
