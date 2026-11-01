# Especificação da feature: Execução de tarefas por IA até o pull request

**Branch da feature**: `006-ai-task-automation`

**Criada em**: 2026-11-01

**Status**: Rascunho

**Entrada**: Descrição do usuário: "A parte dos projetos, quero fazer uma mudança, onde quero criar as
tarefas com descrição, imagens, links que servirão como base para o desenvolvimento assistido por
parte da IA. Vou querer automatizar isto, colocando uma fila de tarefas, e a saída final deve ser o
PR aberto no GitHub. Veja que cada projeto se conecta a um repositório diferente."

## Cenários de usuário e testes *(obrigatório)*

### História 1 - Detalhar a tarefa com descrição, imagens e links (Prioridade: P1)

Como dono de uma iniciativa, quero registrar numa tarefa tudo o que a IA precisa saber (descrição,
imagens e links), para que o pedido fique completo em um só lugar.

**Por que esta prioridade**: é a base de toda a automação e já tem valor sozinha, porque melhora o
registro das tarefas mesmo sem IA.

**Teste independente**: criar uma tarefa, adicionar descrição, duas imagens e um link, reabri-la e
conferir que tudo continua lá.

**Cenários de aceitação**:

1. **Dado** uma tarefa, **quando** adiciono imagens, **então** vejo as miniaturas, consigo ampliá-las e
   removê-las.
2. **Dado** uma tarefa, **quando** adiciono um link válido com um título opcional, **então** ele aparece
   na tarefa e abre em outra aba.
3. **Dado** um arquivo de tipo não aceito ou grande demais, **quando** tento anexá-lo, **então** ele é
   recusado com uma mensagem que explica o motivo, e o restante da tarefa não se perde.
4. **Dado** uma iniciativa sem repositório, **quando** detalho uma tarefa, **então** tudo funciona, sem
   exigir nada relacionado à IA.

---

### História 2 - Conectar a iniciativa a um repositório (Prioridade: P1)

Como dono de uma iniciativa, quero conectá-la a um repositório do GitHub, para que as tarefas dela
sejam desenvolvidas no código certo.

**Por que esta prioridade**: sem saber o repositório, nenhuma tarefa pode ser executada.

**Teste independente**: conectar duas iniciativas a repositórios diferentes e conferir que cada uma
mostra o seu e que o sistema confirma o acesso a ele.

**Cenários de aceitação**:

1. **Dado** uma iniciativa, **quando** informo um repositório acessível, **então** a conexão é salva e
   aparece como válida.
2. **Dado** um repositório inexistente ou sem acesso, **quando** tento conectá-lo, **então** a conexão é
   recusada com uma mensagem clara.
3. **Dado** uma iniciativa conectada, **quando** troco ou removo o repositório, **então** os PRs já
   abertos continuam registrados nas tarefas e as próximas execuções seguem a nova configuração.

---

### História 3 - Enviar tarefas para a fila e receber o PR (Prioridade: P1)

Como dono de uma iniciativa, quero colocar tarefas numa fila, para que a IA as desenvolva sem a minha
presença e eu receba um pull request aberto para revisar.

**Por que esta prioridade**: é o objetivo da feature.

**Teste independente**: enviar para a fila uma tarefa de uma iniciativa conectada a um repositório de
teste e conferir que o PR é aberto no repositório certo, com o link registrado na tarefa.

**Cenários de aceitação**:

1. **Dado** uma tarefa com descrição numa iniciativa conectada, **quando** a envio para a fila, **então**
   ela aparece como "na fila" e é executada sem outra ação minha.
2. **Dado** uma execução concluída com alterações, **quando** ela termina, **então** há um PR aberto no
   repositório da iniciativa e a tarefa mostra o link dele.
3. **Dado** várias tarefas na fila, **quando** elas são processadas, **então** a ordem de chegada é
   respeitada e cada PR é aberto no repositório da iniciativa da tarefa.
4. **Dado** uma tarefa na fila que ainda não começou, **quando** a cancelo, **então** ela sai da fila e
   nada é criado no repositório.
5. **Dado** um PR aberto pela IA, **quando** o abro no GitHub, **então** a descrição resume o que foi
   feito e as decisões tomadas, e ele aguarda a minha revisão, sem merge automático.

---

### História 4 - Acompanhar a fila e recuperar falhas (Prioridade: P2)

Como dono das iniciativas, quero ver o que está na fila, o que está rodando e o que falhou, para
agir quando algo der errado.

**Por que esta prioridade**: a execução sem supervisão só é confiável se as falhas ficarem visíveis,
mas a primeira versão do fluxo pode ser testada pela própria tarefa.

**Teste independente**: provocar uma falha (por exemplo, retirar o acesso ao repositório), conferir a
mensagem e enviar a tarefa de novo depois de corrigir o problema.

**Cenários de aceitação**:

1. **Dado** tarefas em vários estados, **quando** abro a fila, **então** vejo, de todas as iniciativas, a
   tarefa, o repositório, o estado e há quanto tempo está nele.
2. **Dado** uma execução que falhou, **quando** abro a tarefa, **então** vejo o motivo em linguagem clara
   e posso enviá-la de novo.
3. **Dado** uma tarefa executada mais de uma vez, **quando** abro a tarefa, **então** vejo o histórico das
   tentativas, com data, resultado e PR de cada uma.
4. **Dado** uma tarefa em execução, **quando** a cancelo, **então** o trabalho é interrompido e nenhum PR é
   aberto.
5. **Dado** uma execução em que falta informação, **quando** a IA para, **então** a tarefa mostra a pergunta
   como "aguardando resposta"; ao responder, ela volta para a fila e continua considerando a resposta.
6. **Dado** o executor desligado, **quando** abro a fila, **então** vejo que ele está indisponível e as
   tarefas continuam aguardando; ao religá-lo, a fila volta a andar sem outra ação.

### Casos de borda

- Tarefa sem descrição: não pode ir para a fila, e a mensagem explica.
- Tarefa de iniciativa sem repositório: o envio para a fila fica indisponível, com o motivo à vista.
- Tarefa já na fila ou em execução: não pode ser enviada de novo.
- Tarefa editada depois de ir para a fila: a execução usa o conteúdo do momento em que começa; durante
  a execução, a edição não altera o que está rodando.
- A IA conclui que nada precisa mudar: nenhum PR é aberto, e a tarefa mostra a explicação.
- Link inacessível (página privada ou fora do ar): se ele for essencial, a IA pergunta (FR-013); caso
  contrário, a execução continua, e o PR registra qual link não foi lido.
- Tarefa aguardando resposta editada pelo usuário: a edição não substitui a resposta; a execução só volta
  para a fila quando a pergunta é respondida.
- Computador desligado ou executor fechado no meio de uma execução: a tarefa fica como falha por
  interrupção, com opção de reenviar, e as demais continuam na fila.
- Conteúdo de links, imagens ou do repositório que tenta dar ordens à IA: é tratado como informação, sem
  autoridade para mudar as regras da execução.
- Repositório vazio, arquivado ou sem permissão de escrita: a execução falha com uma mensagem clara.
- Execução que passa do tempo limite: é interrompida e marcada como falha, sem PR parcial.
- Tarefa apagada com execução em andamento: a exclusão pede confirmação e cancela a execução antes;
  o PR já aberto continua no GitHub.
- Tarefa concluída manualmente enquanto está na fila: sai da fila.

## Requisitos *(obrigatório)*

### Requisitos funcionais

**Conteúdo da tarefa**

- **FR-001**: O usuário DEVE poder anexar imagens a uma tarefa (PNG, JPEG, WEBP ou GIF; até 10 por
  tarefa; até 10 MB cada), ver, ampliar e remover.
- **FR-002**: O usuário DEVE poder adicionar a uma tarefa links `http` ou `https`, com título opcional, e
  editá-los e removê-los.
- **FR-003**: Imagens e links DEVEM ser opcionais e funcionar em qualquer iniciativa, com ou sem
  repositório. Apagar uma tarefa ou iniciativa DEVE apagar as imagens dela.

**Repositório**

- **FR-004**: Cada iniciativa DEVE poder se conectar a no máximo um repositório do GitHub. A conexão é
  opcional, e iniciativas que não são de software continuam funcionando sem ela.
- **FR-005**: O sistema DEVE verificar o acesso ao repositório pelo computador que executa as tarefas e
  mostrar quando a conexão deixar de funcionar. Com esse computador indisponível, a conexão fica salva
  como "não verificada" até a próxima verificação.
- **FR-006**: O alcance do acesso ao GitHub DEVE ser definido pelo próprio usuário: o sistema não impõe
  conta nem organização, e alcança os repositórios para os quais o usuário configurou acesso no computador
  que executa as tarefas. Sem acesso configurado, a conexão é recusada com instruções do que falta.
- **FR-007**: Credenciais do GitHub DEVEM ficar só no computador que executa as tarefas, nunca no servidor
  do Acervo, e NUNCA DEVEM aparecer na interface, nas respostas da API, nos registros
  de execução ou nos PRs.

**Fila e execução**

- **FR-008**: O usuário DEVE poder enviar para a fila uma tarefa com descrição, de uma iniciativa
  conectada. O envio é a autorização para executar; nenhuma outra aprovação é pedida antes do PR.
- **FR-009**: A fila DEVE processar uma execução por vez, por ordem de chegada, de todas as iniciativas.
- **FR-010**: A execução DEVE usar título, descrição, imagens e links da tarefa, além do repositório da
  iniciativa.
- **FR-011**: As execuções DEVEM ocorrer no computador do usuário. O Acervo publicado guarda as tarefas e
  a fila, e um programa executor, ligado à conta do usuário, busca o próximo item. Com o executor
  indisponível, as tarefas continuam entrando na fila e aguardam, e a interface DEVE mostrar se ele está
  disponível.
- **FR-012**: Cada execução DEVE ter estes estados: na fila, em execução, aguardando resposta, PR aberto,
  sem alterações, falhou ou cancelada. O estado de execução é separado do status da tarefa (a fazer, fazendo, concluída).
- **FR-013**: Quando faltar informação que afete o resultado, a IA DEVE parar e registrar a pergunta na
  tarefa, sem abrir PR. A execução fica como "aguardando resposta" até o usuário responder ou cancelar, sem
  prazo, e esse tempo não conta no limite de FR-015. A espera libera a fila para a próxima tarefa.
- **FR-013a**: Ao responder, a tarefa DEVE voltar para a fila na sua posição original de chegada, e a
  execução DEVE considerar as perguntas e respostas anteriores. Perguntas e respostas ficam no histórico.
- **FR-014**: O usuário DEVE poder cancelar uma execução na fila, em andamento ou aguardando resposta e reenviar uma tarefa
  que falhou, foi cancelada ou já tem PR.
- **FR-015**: Cada execução DEVE ter um limite de 60 minutos.

**Resultado**

- **FR-016**: Uma execução com alterações DEVE terminar com um PR aberto para a branch padrão do
  repositório, a partir de uma branch nova e exclusiva daquela tentativa.
- **FR-017**: A execução NUNCA DEVE fazer merge, fechar PRs, alterar a branch padrão ou escrever em
  repositório diferente do conectado à iniciativa.
- **FR-018**: O PR DEVE descrever o que foi feito, as decisões tomadas, incluindo as perguntas respondidas,
  e os links não lidos, seguindo o
  modelo de PR do repositório, quando existir.
- **FR-019**: A tarefa DEVE guardar o histórico de tentativas, com início, fim, resultado, motivo da falha
  e link do PR.
- **FR-020**: Ao abrir o PR, a tarefa DEVE passar para "fazendo", se estava "a fazer". A conclusão da tarefa
  continua sendo manual.

**Acompanhamento e módulo**

- **FR-021**: DEVE existir uma visão da fila com as execuções de todas as iniciativas, filtrável por estado
  e com busca pelo título da tarefa.
- **FR-022**: Tudo isso DEVE exigir login e fazer parte do módulo Iniciativas, sem depender do módulo Códigos.
- **FR-023**: O executor DEVE acessar o Acervo com uma credencial própria, revogável, que alcança só o necessário
  para processar a fila, em vez do login do usuário. Motivo: ele roda sem navegador e sem supervisão. As demais
  ações continuam exigindo login.
- **FR-024**: A execução DEVE falhar, sem publicar nada, se as alterações incluírem os workflows de automação do
  repositório (`.github/workflows/`), para que um conteúdo malicioso não execute com os segredos dele.

### Entidades principais

- **Tarefa** (existente): passa a ter imagens, links e tentativas de execução.
- **Imagem da tarefa**: arquivo anexado, com nome, tipo, tamanho e ordem.
- **Link da tarefa**: endereço e título opcional.
- **Conexão de repositório**: liga uma iniciativa a um repositório do GitHub, com a situação do acesso.
- **Execução**: uma tentativa de desenvolver uma tarefa. Tem repositório usado, estado, datas de entrada,
  início e fim, motivo da falha, resumo e link do PR.
- **Pergunta da execução**: dúvida feita pela IA, com a resposta do usuário e as datas.
- **Executor**: o programa no computador do usuário que processa a fila, com a última vez em que foi visto.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: Em uma tarefa já escrita, o usuário anexa uma imagem, adiciona um link e envia para a fila em
  menos de 1 minuto.
- **SC-002**: Com o executor disponível, 100% das execuções chegam a um estado visível que não depende mais
  do sistema (PR aberto, sem alterações, falhou, cancelada ou aguardando resposta), sem nenhuma ficar presa
  em execução.
- **SC-003**: 100% dos PRs são abertos no repositório da iniciativa da tarefa, e nenhum recebe merge sem ação
  humana.
- **SC-004**: Em toda falha, o usuário entende o motivo pela mensagem, sem precisar consultar os registros do
  sistema.
- **SC-005**: Pelo menos 7 em cada 10 PRs de tarefas bem descritas são aproveitados pelo usuário, com ou sem
  pequenos ajustes, nas primeiras 20 execuções.
- **SC-006**: Com 3 iniciativas ligadas a repositórios diferentes, 10 tarefas enviadas de uma vez são
  processadas sem intervenção.

## Premissas

- Uso pessoal, com uma única conta, como o restante do Acervo.
- O PR é o ponto de controle humano: a revisão e o merge são sempre do usuário.
- A IA segue as instruções e os testes que já existem em cada repositório. Se os testes do repositório não
  puderem rodar, o PR informa isso em vez de esconder.
- Comentários no PR não geram nova execução, e o merge não conclui a tarefa automaticamente; os dois ficam
  para uma evolução futura.
- Execução em paralelo, prioridade manual na fila, agendamento, vários repositórios por iniciativa e outros
  provedores além do GitHub ficam fora desta versão.
- Anexos que não sejam imagens ficam fora desta versão.
- Esta feature amplia a fase 1 do módulo Iniciativas (spec 005), que deixava anexos de fora.
- O custo de uso da IA é do próprio usuário, pelas ferramentas que ele já usa no computador.
- A fila só avança com o computador ligado e o executor aberto; isso é aceito nesta versão. Execução na
  nuvem fica para uma evolução futura.
- O usuário configura por conta própria o acesso aos repositórios e, nos casos de organização, confere se as
  regras dela permitem o uso de IA no código.
- O código fica no computador do usuário durante a execução, sem passar pelo servidor do Acervo.
