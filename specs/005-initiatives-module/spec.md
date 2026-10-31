# Especificação da feature: Módulo Iniciativas (fase 1)

**Branch da feature**: `005-initiatives-module`

**Criada em**: 2026-10-31

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Quero um novo módulo para gerenciar projetos de que participo. Por
exemplo, como tech leader, participo de diversos projetos, que envolvem decisões, documentos,
tarefas etc. Quero um módulo completo, separado do que já temos, que sirva para qualquer tipo de
projeto, inclusive pessoal (como o jogo que estou planejando). Não preciso de cadastro de pessoas."

## Visão geral e fases

O módulo **Iniciativas** organiza qualquer projeto com objetivo, etapas e coisas a lembrar: um
projeto do trabalho, o desenvolvimento de um jogo, uma reforma, uma viagem. "Iniciativa" é o nome
usado na interface para não confundir com o antigo uso de "projeto" no módulo Códigos.

O módulo completo foi dividido em fases, cada uma com spec própria:

1. **Esta feature**: contextos, iniciativas, marcos e tarefas, com seções opcionais por iniciativa.
2. Decisões (formato ADR) e notas.
3. Ideias, documentos/links e riscos.
4. Painel geral entre iniciativas, linha do tempo e busca em todo o módulo.

Não há cadastro de pessoas em nenhuma fase.

## Cenários de uso e testes *(obrigatório)*

### História 1 - Cadastrar e encontrar iniciativas (Prioridade: P1)

O dono do Acervo cria uma iniciativa para cada coisa que está tocando, com nome, descrição, status,
prioridade e datas, e a encontra depois pela busca ou pelos filtros.

**Por que esta prioridade**: sem a iniciativa não existe onde pendurar marcos e tarefas.

**Teste independente**: criar duas iniciativas, buscar por um trecho do nome de uma delas e vê-la
na lista; filtrar por status e ver só as que se encaixam.

**Cenários de aceitação**:

1. **Dado** que estou no módulo Iniciativas, **quando** crio uma iniciativa informando só o nome,
   **então** ela é salva com status "planejada" e prioridade "média" e aparece na lista.
2. **Dado** que tenho várias iniciativas, **quando** abro o módulo, **então** vejo as ativas
   primeiro e, dentro de cada status, as alteradas mais recentemente no topo, com o progresso de
   tarefas de cada uma.
3. **Dado** que digito um trecho do nome, da descrição ou de uma tag, **quando** a iniciativa
   existe, **então** ela aparece na lista sem que eu precise confirmar a busca.
4. **Dado** que quero ver só um grupo, **quando** filtro por status ou contexto, **então** a lista
   mostra apenas as iniciativas desse grupo, e o filtro fica no endereço da página.
5. **Dado** que uma iniciativa terminou ou não vai mais acontecer, **quando** mudo o status para
   "encerrada", **então** ela sai da lista padrão, mas continua acessível pelo filtro.
6. **Dado** que quero apagar uma iniciativa, **quando** confirmo, **então** ela some junto com seus
   marcos e tarefas.

---

### História 2 - Organizar tarefas de uma iniciativa (Prioridade: P1)

Dentro de uma iniciativa, o dono anota o que precisa ser feito, marca o que terminou e vê o que
está atrasado.

**Por que esta prioridade**: tarefas são o uso mais frequente do módulo. Com a História 1, formam o
produto mínimo.

**Teste independente**: abrir uma iniciativa, criar três tarefas digitando só o título, concluir
uma e confirmar que o progresso mostra 1 de 3.

**Cenários de aceitação**:

1. **Dado** que estou na iniciativa, **quando** digito o título de uma tarefa e confirmo, **então** a
   tarefa é criada como "a fazer" e o campo fica pronto para a próxima.
2. **Dado** que uma tarefa existe, **quando** a marco como concluída, **então** ela vai para o grupo
   de concluídas, registra a data de conclusão e o progresso da iniciativa é atualizado.
3. **Dado** que quero detalhar, **quando** edito a tarefa, **então** posso informar descrição,
   status (a fazer, fazendo, concluída), prioridade, prazo e marco, todos opcionais.
4. **Dado** que uma tarefa não concluída passou do prazo, **quando** vejo a lista, **então** ela
   aparece destacada como atrasada.
5. **Dado** que a iniciativa tem muitas tarefas, **quando** busco por um trecho do título ou da
   descrição, **então** vejo só as tarefas que combinam.
6. **Dado** que uma tarefa não serve mais, **quando** confirmo a exclusão, **então** ela some.

---

### História 3 - Acompanhar marcos (Prioridade: P2)

O dono define as grandes entregas de uma iniciativa ("protótipo jogável", "go-live do cliente"),
liga tarefas a elas e acompanha o progresso de cada uma.

**Por que esta prioridade**: dá a visão de andamento, mas tarefas soltas já resolvem no começo.

**Teste independente**: criar um marco com data, ligar duas tarefas a ele, concluir uma e ver o
marco com 50% de progresso.

**Cenários de aceitação**:

1. **Dado** que estou na iniciativa, **quando** crio um marco com título e data-alvo opcional,
   **então** ele aparece na lista de marcos, ordenado pela data-alvo (sem data por último).
2. **Dado** que um marco tem tarefas, **quando** vejo a lista de marcos, **então** cada um mostra
   quantas tarefas estão concluídas do total.
3. **Dado** que a entrega aconteceu, **quando** marco o marco como concluído, **então** ele registra
   a data de conclusão e aparece como concluído.
4. **Dado** que um marco não concluído passou da data-alvo, **quando** vejo a lista, **então** ele
   aparece destacado como atrasado.
5. **Dado** que apago um marco, **quando** confirmo, **então** as tarefas ligadas a ele continuam
   existindo, apenas sem marco.

---

### História 4 - Separar por contexto e escolher as seções (Prioridade: P2)

O dono cria os próprios contextos ("Trabalho", "Casa", "Jogo", "Estudos"), cada um com uma cor,
para misturar iniciativas de áreas diferentes sem bagunça. E escolhe, em cada iniciativa, quais
seções ela usa: uma viagem talvez só precise de tarefas.

**Por que esta prioridade**: melhora a organização, mas o módulo funciona sem isso.

**Teste independente**: criar dois contextos, atribuir um a cada iniciativa, filtrar por um deles;
desligar a seção Marcos de uma iniciativa e confirmar que a aba some.

**Cenários de aceitação**:

1. **Dado** que estou na tela de contextos, **quando** crio um contexto com nome e cor, **então** ele
   fica disponível para as iniciativas e como filtro na lista.
2. **Dado** que um contexto já existe, **quando** tento criar outro com o mesmo nome (ignorando
   maiúsculas), **então** vejo uma mensagem dizendo que o nome já existe.
3. **Dado** que apago um contexto, **quando** confirmo, **então** as iniciativas dele continuam
   existindo, sem contexto.
4. **Dado** que estou numa iniciativa, **quando** desligo uma seção, **então** a aba dela some, mas
   os dados continuam guardados e voltam se eu religar a seção.
5. **Dado** que crio uma iniciativa, **quando** não escolho seções, **então** todas as seções
   disponíveis vêm ligadas.

### Casos de borda

- Nome de iniciativa vazio ou só com espaços: não é salva, e a mensagem explica.
- Data-alvo anterior à data de início: não é salva, e a mensagem explica.
- Tarefa ligada a um marco de outra iniciativa: é recusada.
- Tarefa marcada como concluída e depois reaberta: a data de conclusão é apagada.
- Iniciativa sem tarefas: o progresso aparece como "sem tarefas", não como 0%.
- Iniciativa com todas as seções desligadas: a página mostra só os detalhes e um aviso de como
  religar as seções.
- Iniciativa aberta por link direto que não existe mais: mensagem de "não encontrada" com caminho
  de volta para a lista.
- Busca com caracteres especiais (`$`, `*`, `'`, `%`): não causa erro.

## Requisitos *(obrigatório)*

### Requisitos funcionais

- **FR-001**: O sistema DEVE permitir criar uma iniciativa informando só o nome (até 200
  caracteres). Descrição, contexto, status, prioridade, data de início, data-alvo e tags são
  opcionais.
- **FR-002**: Status de iniciativa: ideia, planejada (padrão), ativa, pausada, encerrada.
  Prioridade: baixa, média (padrão), alta.
- **FR-003**: A data-alvo, quando informada junto com a data de início, NÃO DEVE ser anterior a ela.
- **FR-004**: A lista de iniciativas DEVE ser paginada, ordenada por status (ativa, planejada, ideia,
  pausada, encerrada) e depois pela última alteração, e esconder as encerradas por padrão.
- **FR-005**: A lista DEVE permitir buscar por nome, descrição e tags (palavras inteiras e pedaços de
  texto) e filtrar por status e por contexto; busca e filtros ficam no endereço da página.
- **FR-006**: Cada iniciativa na lista DEVE mostrar contexto, status, prioridade, data-alvo e
  progresso (tarefas concluídas / total).
- **FR-007**: O usuário DEVE poder criar, renomear, mudar a cor e apagar contextos. Nomes de
  contexto são únicos, sem diferenciar maiúsculas. Apagar um contexto não apaga as iniciativas.
- **FR-008**: Cada iniciativa DEVE ter uma lista de seções ligadas. Nesta fase existem as seções
  "Tarefas" e "Marcos", ambas ligadas por padrão. Desligar uma seção esconde a aba, sem apagar dados.
- **FR-009**: O usuário DEVE poder criar tarefas informando só o título (até 300 caracteres), e
  depois editar descrição, status (a fazer, fazendo, concluída), prioridade, prazo e marco.
- **FR-010**: Ao concluir uma tarefa, o sistema DEVE registrar a data de conclusão; ao reabri-la,
  DEVE apagar essa data.
- **FR-011**: As tarefas de uma iniciativa DEVEM aparecer agrupadas por status, com as não concluídas
  ordenadas por prazo (sem prazo por último) e as concluídas pela data de conclusão, mais recente
  primeiro. Tarefas atrasadas DEVEM ser destacadas.
- **FR-012**: As tarefas DEVEM ser pesquisáveis por título e descrição dentro da iniciativa, e
  filtráveis por status e marco.
- **FR-013**: O usuário DEVE poder criar, editar, concluir, reabrir e apagar marcos (título até 200
  caracteres, descrição e data-alvo opcionais). Cada marco mostra o progresso das tarefas ligadas a
  ele. Apagar um marco não apaga as tarefas.
- **FR-014**: Uma tarefa só pode ser ligada a um marco da mesma iniciativa.
- **FR-015**: Apagar uma iniciativa DEVE apagar seus marcos e tarefas, depois de confirmação.
- **FR-016**: Toda exclusão DEVE pedir confirmação.
- **FR-017**: Cada iniciativa DEVE ter um endereço próprio, com a aba aberta no endereço.
- **FR-018**: O módulo DEVE exigir login como o restante do Acervo e ser independente do módulo
  Códigos.

### Entidades principais

- **Contexto**: agrupa iniciativas por área da vida. Nome (único, até 60 caracteres) e cor.
- **Iniciativa**: algo com objetivo e etapas. Nome, descrição, contexto, status, prioridade, data
  de início, data-alvo, tags e seções ligadas. Pesquisável por nome, descrição e tags.
- **Marco**: uma entrega ou fase de uma iniciativa. Título, descrição, data-alvo e data
  de conclusão.
- **Tarefa**: algo a fazer numa iniciativa, opcionalmente ligado a um marco. Título, descrição,
  status, prioridade, prazo e data de conclusão. Pesquisável por título e descrição.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: A partir do módulo aberto, o usuário cria uma iniciativa e a primeira tarefa dela em
  até 20 segundos.
- **SC-002**: Criar uma tarefa só com o título leva no máximo uma digitação e uma confirmação, e o
  campo fica pronto para a próxima.
- **SC-003**: Com 500 iniciativas e 10.000 tarefas, a lista e a busca respondem em menos de 1 segundo.
- **SC-004**: O progresso exibido de uma iniciativa e de cada marco bate com a contagem real de
  tarefas concluídas em 100% dos casos.
- **SC-005**: O mesmo módulo atende, sem campos irrelevantes obrigatórios, a pelo menos três tipos
  de iniciativa diferentes (trabalho, jogo, pessoal).

## Premissas

- Uso pessoal, com uma única conta, como o restante do Acervo. Não há cadastro de pessoas; quem faz
  uma tarefa pode ser anotado na descrição.
- O nome "Iniciativas" é provisório e pode mudar sem impacto nos dados.
- Arrastar e soltar (kanban), subtarefas, tarefas recorrentes, lembretes e anexos ficam fora desta
  fase.
- Decisões, notas, ideias, documentos, riscos, painel geral e linha do tempo entram nas fases 2 a 4.
  A lista de seções já prevê que novas seções sejam adicionadas sem mudar as iniciativas existentes.
- Sem integração com o módulo Códigos nesta fase.
- Depende da autenticação existente (feature 001).
