# Especificação da feature: Códigos como bloco de notas rápido

**Branch da feature**: `003-codes-quick-notes`

**Criada em**: 2026-10-30

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Reformular o módulo Códigos para funcionar como um bloco de notas no estilo Evernote: o usuário cria notas/códigos apenas colando o conteúdo (por exemplo, scripts que precisa rodar em produção) e consegue encontrá-los e acessá-los rapidamente. As notas não precisam ser vinculadas a projetos."

## Cenários de uso e testes *(obrigatório)*

### História 1 - Colar e guardar uma nota (Prioridade: P1)

O dono do Acervo tem um script ou texto na área de transferência. Ele abre o módulo Códigos, cria
uma nota e cola o conteúdo, sem precisar preencher nenhum outro campo nem acionar "salvar". A nota
é salva automaticamente, exatamente como foi colada.

**Por que esta prioridade**: guardar precisa ser mais fácil do que deixar o script perdido em um
arquivo solto. Se exigir formulário, o Acervo não é usado.

**Teste independente**: criar uma nota informando apenas o conteúdo e confirmar que ela aparece
na lista, com o texto idêntico ao colado.

**Cenários de aceitação**:

1. **Dado** que estou no módulo Códigos, **quando** crio uma nota e colo o conteúdo, **então** a
   nota é guardada automaticamente, e vejo a indicação de que foi salva, sem que nenhum outro campo
   ou ação tenha sido pedido.
2. **Dado** que colei um script com indentação, linhas em branco e caracteres especiais,
   **quando** abro a nota salva, **então** o conteúdo é idêntico ao colado.
3. **Dado** que não informei título, **quando** a nota é salva, **então** a lista a identifica
   pela primeira linha não vazia do conteúdo.
4. **Dado** que quero organizar melhor, **quando** crio ou edito a nota, **então** posso informar
   título e tags, ambos opcionais.
5. **Dado** que abri uma nota nova, **quando** saio dela sem escrever nada ou só com espaços,
   **então** nenhuma nota é criada.
6. **Dado** que estou digitando, **quando** paro por um instante ou saio da nota, **então** o que
   escrevi está salvo, e fechar a aba logo depois não perde o conteúdo já indicado como salvo.

---

### História 2 - Encontrar e copiar rapidamente (Prioridade: P1)

Na hora de rodar algo em produção, o dono abre o módulo, digita parte do que lembra (um pedaço do
título, do script ou uma tag), abre a nota certa e copia o conteúdo com uma única ação.

**Por que esta prioridade**: é o motivo de guardar as notas. Junto com a História 1, forma o
produto mínimo.

**Teste independente**: com várias notas salvas, buscar por um trecho do meio de um script, abrir
o resultado e colar o conteúdo copiado em outro programa, conferindo que é idêntico ao original.

**Cenários de aceitação**:

1. **Dado** que abri o módulo Códigos, **quando** a tela carrega, **então** vejo as notas das mais
   recentemente alteradas para as mais antigas e o campo de busca já pronto para digitar.
2. **Dado** que digito um trecho, **quando** ele existe no título, no conteúdo ou nas tags de uma
   nota, **então** a lista mostra essa nota sem que eu precise confirmar a busca.
3. **Dado** que a lista mostra uma nota, **quando** a seleciono, **então** vejo o conteúdo completo
   sem perder a lista de vista em telas largas.
4. **Dado** que estou vendo uma nota, **quando** aciono copiar, **então** todo o conteúdo vai para
   a área de transferência e recebo uma confirmação visual.
5. **Dado** que a busca não encontra nada, **quando** a lista fica vazia, **então** vejo uma
   mensagem dizendo isso e tenho como limpar a busca.

---

### História 3 - Editar e apagar notas (Prioridade: P2)

O dono corrige um script que mudou ou apaga um que não serve mais.

**Por que esta prioridade**: as notas envelhecem, mas dá para começar a usar o produto mínimo sem
isso por um curto período.

**Teste independente**: editar o conteúdo de uma nota e confirmar a mudança ao reabri-la; apagar
outra e confirmar que ela sumiu da lista e da busca.

**Cenários de aceitação**:

1. **Dado** que estou vendo uma nota, **quando** altero o conteúdo, **então** a alteração é salva
   automaticamente e a nota sobe para o topo da lista.
2. **Dado** que há uma alteração ainda não salva, **quando** tento fechar a aba ou sair da nota,
   **então** o sistema tenta salvar e me avisa antes de sair se não conseguir.
3. **Dado** que apaguei todo o conteúdo de uma nota existente, **quando** o salvamento automático
   ocorre, **então** a nota NÃO é apagada: a última versão válida é mantida e vejo um aviso.
4. **Dado** que quero apagar uma nota, **quando** aciono apagar, **então** preciso confirmar antes
   de ela ser removida.

---

### História 4 - Manter o que já existe (Prioridade: P2)

Os códigos já cadastrados continuam disponíveis como notas depois da mudança.

**Por que esta prioridade**: a reformulação não pode custar dados já guardados.

**Teste independente**: com códigos cadastrados antes da mudança, conferir depois dela que todos
aparecem como notas, com título, conteúdo e tags intactos.

**Cenários de aceitação**:

1. **Dado** que já existiam códigos, **quando** a mudança entra em uso, **então** cada um aparece
   como nota, com título, conteúdo e tags preservados.
2. **Dado** que um código estava vinculado a um projeto, **quando** a mudança entra em uso,
   **então** ele continua disponível como nota, sem vínculo com projeto.

### Casos de borda

- Conteúdo com mais de 1 MB: a nota não é salva e a mensagem explica o limite; nada do que foi
  colado se perde da tela.
- Primeira linha muito longa em nota sem título: a lista mostra a linha cortada, sem quebrar o
  layout.
- Duas notas com o mesmo conteúdo ou título: são permitidas.
- Falha ao salvar (rede ou sessão expirada): a tela mostra "não salvo", mantém o texto, tenta de novo
  quando possível e não descarta nada sem aviso.
- Colar ou digitar enquanto um salvamento está em andamento: a versão mais recente é a que fica; uma
  resposta atrasada não sobrescreve o que está na tela.
- Criação de nota nova com pausas na digitação: o salvamento automático não gera notas duplicadas.
- A mesma nota aberta em duas abas: vale a última alteração salva.
- Navegador sem acesso à área de transferência: o usuário é avisado e consegue selecionar o texto
  manualmente.
- Busca com caracteres especiais comuns em scripts (`$`, `*`, `'`, `--`): não causa erro.
- Nota aberta por link direto que não existe mais: aparece uma mensagem de "não encontrada" com
  caminho de volta para a lista.

## Requisitos *(obrigatório)*

### Requisitos funcionais

- **FR-001**: O sistema DEVE permitir criar uma nota informando apenas o conteúdo.
- **FR-002**: O sistema DEVE guardar e devolver o conteúdo exatamente como foi colado, incluindo
  indentação, linhas em branco e caracteres especiais.
- **FR-003**: O sistema NÃO DEVE guardar conteúdo vazio, só com espaços ou acima de 1 MB; nesses
  casos mantém a última versão válida, se houver, e mostra uma mensagem clara.
- **FR-004**: Título, tags, linguagem e descrição DEVEM ser opcionais em toda nota.
- **FR-005**: Uma nota sem título DEVE ser identificada na lista pela primeira linha não vazia do
  conteúdo.
- **FR-006**: A tela inicial do módulo DEVE listar as notas por data da última alteração, da mais
  recente para a mais antiga, com o campo de busca já em foco.
- **FR-007**: A busca DEVE encontrar palavras inteiras e pedaços de texto no título, no conteúdo e
  nas tags, atualizando os resultados enquanto o usuário digita.
- **FR-008**: A listagem DEVE ser paginada ou carregada aos poucos, para continuar rápida com muitas
  notas.
- **FR-009**: Em telas largas, a lista e o conteúdo da nota selecionada DEVEM aparecer lado a lado;
  em telas estreitas, um de cada vez.
- **FR-010**: O usuário DEVE poder copiar todo o conteúdo de uma nota com uma única ação, com
  confirmação visual.
- **FR-011**: O conteúdo DEVE ser exibido em fonte monoespaçada, sem alterar o texto copiado. O
  realce de sintaxe é aplicado quando a linguagem for informada ou puder ser detectada.
- **FR-012**: O usuário DEVE poder editar e apagar notas; apagar exige confirmação.
- **FR-013**: Criações e alterações DEVEM ser salvas automaticamente logo após colar, ao parar de
  digitar por um instante e ao sair da nota, sem botão de salvar. A tela DEVE indicar o estado
  ("salvando", "salvo", "não salvo") e avisar antes de sair se houver alteração que não pôde ser salva.
- **FR-014**: Cada nota DEVE ter um endereço próprio, que possa ser aberto diretamente.
- **FR-015**: Notas NÃO DEVEM ter vínculo com projetos, nem pedir esse dado em nenhuma tela.
- **FR-016**: Os códigos já existentes DEVEM continuar disponíveis como notas, sem perda de título,
  conteúdo, tags, linguagem ou descrição.
- **FR-017**: As telas e os dados de notas DEVEM continuar exigindo login, como o restante do Acervo.
- **FR-018**: A área de Projetos DEVE ser removida do módulo Códigos, e os projetos cadastrados são
  apagados. Os códigos vinculados a eles continuam disponíveis como notas.

### Entidades principais

- **Nota**: um texto ou script guardado. Tem conteúdo (obrigatório), título, tags, linguagem e
  descrição (opcionais), além das datas de criação e de última alteração. É pesquisável por título, conteúdo
  e tags. Não se relaciona com nenhuma outra entidade.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: Com o conteúdo na área de transferência e o módulo aberto, o usuário guarda uma nota
  nova em até 10 segundos, sem acionar "salvar".
- **SC-006**: Uma alteração aparece como salva em até 2 segundos depois de o usuário parar de digitar.
- **SC-002**: A partir do módulo aberto, o usuário encontra uma nota conhecida e copia o conteúdo em
  até 15 segundos.
- **SC-003**: Com 5.000 notas, os resultados da busca aparecem em menos de 1 segundo após parar de
  digitar.
- **SC-004**: Em 100% dos testes com scripts reais, o texto copiado é idêntico ao colado, byte a byte
  depois da normalização de quebras de linha feita pelo navegador.
- **SC-005**: 100% dos códigos existentes antes da mudança continuam acessíveis depois dela.

## Premissas

- Continua sendo uso pessoal, com uma única conta. Compartilhar notas está fora do escopo.
- O módulo continua se chamando "Códigos" na interface; "nota" é o nome de cada item.
- Notas são texto puro: formatação rica, imagens e anexos (como no Evernote) estão fora do escopo.
- Cadernos, pastas, favoritos e histórico de versões ficam fora desta feature. Sem histórico, uma
  alteração salva automaticamente não pode ser desfeita depois que a nota é fechada.
- O Acervo não executa os scripts; apenas os guarda.
- O conteúdo não recebe criptografia própria nem tratamento especial para segredos. Senhas e chaves
  não devem ser guardadas nas notas, já que ficam em texto legível no banco e na tela.
- Tags continuam sendo opcionais e passam a funcionar corretamente quando informadas como texto
  separado por vírgulas (hoje `React, hooks` é salvo como `["eact"]`).
- Depende da autenticação existente (feature 001).
