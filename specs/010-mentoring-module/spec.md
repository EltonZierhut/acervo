# Especificação da feature: Módulo Mentoria (fase 1)

**Branch da feature**: `010-mentoring-module`

**Criada em**: 2026-11-11

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Novo módulo, agora sobre receber mentoria. Estarei começando a receber mentoria e
quero um módulo para ajudar a gerenciar isto. De início, preciso responder perguntas que irão nortear a mentoria. Mas
quero que você analise o mercado e construa um módulo que eu possa gerenciar e avaliar meu progresso."

## Visão geral e fases

O módulo **Mentoria** acompanha o lado de quem **recebe** mentoria (o mentorado). Ele organiza uma ou mais mentorias, e
em cada uma: o questionário inicial que norteia o trabalho, os objetivos, os encontros com o mentor, as ações combinadas
e autoavaliações periódicas que mostram a evolução.

### O que o mercado faz (pesquisa de 2026-11)

As plataformas de mentoria corporativa (MentorcliQ, Qooper, Together, MentorPRO, PushFar, Mentorloop) repetem o mesmo
núcleo, pensado para administradores de programas com muitos pares:

| Recurso do mercado | Entra no Acervo? | Por quê |
| --- | --- | --- |
| Questionário de entrada (objetivos, pontos fortes, áreas a desenvolver, expectativas, disponibilidade, como aprende e recebe feedback) | Sim, fase 1 | É o pedido inicial: perguntas que norteiam a mentoria |
| Objetivos com marcos e progresso | Sim, fase 1 | Centro do acompanhamento em todas as plataformas |
| Registro de encontros (pauta, anotações, aprendizados, avaliação do encontro) | Sim, fase 1 | Memória da mentoria; o que mais se consulta depois |
| Itens de ação com prazo | Sim, fase 1 | "Action item tracking" é o que transforma conversa em progresso |
| Avaliação de habilidades ao longo do tempo | Sim, fase 1 (autoavaliação) | É como o próprio mentorado mede a evolução |
| Painel de progresso | Sim, fase 1 | Visão única: objetivos, ações, encontros e evolução |
| Pareamento por algoritmo, painéis de RH, relatórios de programa, saúde dos pares | Não | Servem a quem administra programas; aqui há um mentorado e poucos mentores |
| Lembretes, agenda integrada, chat com o mentor | Fase 2 ou fora | Exigem notificações, agenda ou conta para o mentor |

Fases, cada uma com spec própria:

1. **Esta feature**: mentorias, questionário inicial com perguntas sugeridas, objetivos, encontros, ações, autoavaliação
   por competências e painel de progresso.
2. Resumo para levar ao próximo encontro (ações abertas, objetivos, perguntas pendentes) em formato para copiar ou
   exportar; diário de reflexões entre encontros; lembretes de ações vencendo (se o Acervo ganhar notificações).
3. Acesso do mentor (somente leitura ou com comentários), quando houver multiusuário.

Fora de todas as fases por ora: pareamento com mentores, chat e videochamada, uso sem internet (princípio VII).

## Cenários de uso e testes *(obrigatório)*

### História 1 - Começar uma mentoria e responder o questionário inicial (Prioridade: P1)

O dono do Acervo cadastra a mentoria (nome do mentor, tema, início, frequência) e responde as perguntas que vão nortear
o trabalho, podendo usar as sugeridas, trocar o texto delas ou acrescentar as que o mentor enviou.

**Por que esta prioridade**: é o primeiro passo pedido e a base para definir os objetivos.

**Teste independente**: criar uma mentoria com as perguntas sugeridas, responder três delas e ver "3 de 12 respondidas".

**Cenários de aceitação**:

1. **Dado** que estou no módulo, **quando** crio uma mentoria informando só o nome do mentor, **então** ela aparece como
   ativa, com data de início hoje e o questionário com as perguntas sugeridas.
2. **Dado** que criei uma mentoria desmarcando "usar perguntas sugeridas", **quando** abro o questionário, **então** ele
   está vazio e posso adicionar minhas perguntas.
3. **Dado** que estou no questionário, **quando** escrevo uma resposta e salvo, **então** a pergunta aparece como
   respondida e o contador de respondidas aumenta.
4. **Dado** que o mentor me enviou outras perguntas, **quando** adiciono uma pergunta, **então** ela entra no fim da lista;
   posso mudar o texto de qualquer pergunta, mudar a ordem (subir e descer, por toque) e apagar.
5. **Dado** que existem respostas, **quando** escolho "Copiar questionário", **então** perguntas e respostas vão para a
   área de transferência como texto, para enviar ao mentor.

---

### História 2 - Definir objetivos e acompanhar o progresso deles (Prioridade: P1)

A partir do questionário, o dono do Acervo define objetivos com critério de sucesso e prazo, e atualiza o andamento.

**Por que esta prioridade**: objetivo é o que dá direção à mentoria e é a principal medida de progresso.

**Teste independente**: criar dois objetivos, marcar um como alcançado e ver o progresso geral dos objetivos em 50%.

**Cenários de aceitação**:

1. **Dado** que estou na mentoria, **quando** crio um objetivo com título, critério de sucesso e prazo, **então** ele
   aparece como "Não iniciado" com 0% de progresso.
2. **Dado** um objetivo, **quando** mudo o progresso (0 a 100, de 10 em 10) ou a situação, **então** a mudança fica salva;
   marcar "Alcançado" leva o progresso a 100%.
3. **Dado** um objetivo com prazo vencido e não alcançado, **quando** vejo a lista, **então** ele aparece destacado como
   atrasado.
4. **Dado** que desisto de um objetivo, **quando** marco "Abandonado", **então** ele deixa de contar no progresso geral.

---

### História 3 - Registrar encontros e as ações combinadas (Prioridade: P1)

Antes do encontro, o dono do Acervo escreve a pauta; durante ou depois, as anotações, os principais aprendizados, uma nota
para o encontro e as ações combinadas, que ficam numa lista única com prazo.

**Por que esta prioridade**: o registro dos encontros é a memória da mentoria, e as ações são o que gera mudança.

**Teste independente**: criar um encontro com pauta e anotações, adicionar duas ações nele, concluir uma e ver na visão
geral "1 de 2 ações concluídas" e o encontro como o último realizado.

**Cenários de aceitação**:

1. **Dado** que estou na mentoria, **quando** crio um encontro, **então** ele vem com a data de hoje e campos para pauta,
   anotações e aprendizados em Markdown, e uma nota de 1 a 5 opcional ("quanto este encontro me ajudou").
2. **Dado** um encontro, **quando** adiciono ações nele, **então** cada ação fica ligada ao encontro e pode ter prazo e um
   objetivo relacionado.
3. **Dado** que estou na aba Ações, **quando** vejo a lista, **então** aparecem primeiro as abertas por prazo (atrasadas
   destacadas), depois as concluídas; posso criar ações soltas, sem encontro.
4. **Dado** uma ação aberta, **quando** marco como concluída, **então** guarda a data da conclusão; desmarcar volta a abrir.
5. **Dado** vários encontros, **quando** busco um trecho da pauta, das anotações, dos aprendizados ou das tags, **então**
   aparecem só os encontros com esse trecho, paginados, do mais recente para o mais antigo.
6. **Dado** que apago um encontro, **quando** confirmo, **então** suas ações continuam existindo, sem o vínculo.

---

### História 4 - Autoavaliar competências e ver a evolução (Prioridade: P2)

O dono do Acervo escolhe as competências que quer desenvolver (ex.: Comunicação, Liderança de pessoas) e, de tempos em
tempos, dá uma nota de 1 a 5 para cada uma. O módulo mostra a nota inicial, a atual e a variação.

**Por que esta prioridade**: completa a medição do progresso, mas a mentoria já funciona sem ela.

**Teste independente**: cadastrar duas competências, fazer uma autoavaliação com notas 2 e 3 e outra com 4 e 3, e ver
"+2" na primeira e "0" na segunda.

**Cenários de aceitação**:

1. **Dado** que estou na aba Autoavaliação, **quando** adiciono uma competência, **então** ela entra na lista, com nomes
   sugeridos para escolher ou digitar livre.
2. **Dado** competências cadastradas, **quando** faço uma autoavaliação, **então** escolho a data (padrão hoje) e dou uma
   nota de 1 a 5 para cada competência, com um comentário opcional; posso deixar alguma sem nota.
3. **Dado** que já fiz uma autoavaliação na mesma data, **quando** salvo de novo nessa data, **então** as notas são
   substituídas, sem duplicar.
4. **Dado** duas ou mais autoavaliações, **quando** abro a aba, **então** vejo para cada competência a primeira nota, a
   última, a variação e a sequência de notas no tempo.
5. **Dado** que renomeio uma competência, **quando** vejo o histórico, **então** as notas antigas continuam nela; apagar a
   competência apaga as notas dela.

---

### História 5 - Ver o progresso da mentoria num painel (Prioridade: P2)

Ao abrir uma mentoria, a primeira aba é a visão geral, com tudo o que mostra se a mentoria está andando.

**Teste independente**: com dados das histórias anteriores, abrir a mentoria e conferir cada número do painel.

**Cenários de aceitação**:

1. **Dado** uma mentoria, **quando** abro a visão geral, **então** vejo: questionário respondido (x de y), progresso médio
   dos objetivos (sem os abandonados) e quantos foram alcançados, ações concluídas (x de y) e quantas estão atrasadas,
   número de encontros, data do último e dias desde ele, nota média dos encontros e a evolução média das competências.
2. **Dado** que há ações abertas, **quando** vejo a visão geral, **então** aparecem as próximas cinco por prazo, com a
   opção de concluir ali mesmo.
3. **Dado** a lista de mentorias, **quando** abro o módulo, **então** cada mentoria mostra mentor, tema, situação e um
   resumo (objetivos, ações abertas, último encontro).

### Casos de borda

- Mentoria sem nada cadastrado: o painel mostra cada indicador como "—" e um convite para o próximo passo (responder o
  questionário, criar o primeiro objetivo).
- Ação ligada a um objetivo de outra mentoria: recusada.
- Prazo de ação no passado ao criar: permitido (registro retroativo), já aparece como atrasada.
- Encontro com data futura: permitido, aparece como "agendado" e não conta como realizado no painel.
- Apagar uma mentoria apaga tudo dela, com confirmação.

## Requisitos

### Funcionais

- **FR-001**: Mentoria tem nome do mentor (obrigatório, até 100 caracteres), tema/foco (opcional, até 200), descrição em
  Markdown (opcional), data de início (padrão hoje), data de término opcional (não antes do início), frequência combinada
  (texto livre curto, ex.: "quinzenal, 1 h") e situação (`active`, `paused`, `finished`; padrão ativa).
- **FR-002**: Ao criar uma mentoria, por padrão o questionário recebe as **perguntas sugeridas** (lista em
  `research.md`); a pessoa pode recusar. Cada pergunta tem texto (obrigatório, até 500), resposta em Markdown (até
  100 KB) e posição; "respondida" é ter resposta não vazia.
- **FR-003**: Perguntas podem ser criadas, editadas, reordenadas (subir/descer) e apagadas.
- **FR-004**: Objetivo tem título (obrigatório, até 200), critério de sucesso e descrição em Markdown (opcionais), prazo
  opcional, situação (`not_started`, `in_progress`, `achieved`, `dropped`) e progresso de 0 a 100. "Alcançado" força
  100; progresso acima de 0 num objetivo não iniciado o passa a "Em andamento".
- **FR-005**: Encontro tem data (obrigatória, padrão hoje), pauta, anotações e aprendizados em Markdown (até 100 KB cada),
  nota de 1 a 5 opcional e tags.
- **FR-006**: Ação tem título (obrigatório, até 200), prazo opcional, data de conclusão (vazia = aberta), encontro e
  objetivo opcionais, ambos da mesma mentoria. Apagar o encontro ou o objetivo mantém a ação, sem o vínculo.
- **FR-007**: Competência tem nome (obrigatório, até 100, único na mentoria sem diferenciar maiúsculas) e posição.
- **FR-008**: Nota de autoavaliação liga competência e data, com valor de 1 a 5 e comentário opcional (até 1.000); uma
  por competência e data (salvar de novo substitui).
- **FR-009**: Encontros são pesquisáveis por pauta, anotações, aprendizados e tags (palavras inteiras e trechos), com
  paginação. Perguntas, objetivos e ações são listas curtas por mentoria, mostradas inteiras.
- **FR-010**: O painel da mentoria calcula os indicadores da História 5 no servidor, numa única chamada.
- **FR-011**: "Hoje", atrasos e "dias desde o último encontro" usam o fuso America/Sao_Paulo.
- **FR-012**: Telas funcionam a partir de 360 px, por toque (sem arrastar para reordenar) e no app instalado
  (princípio VII).

### Entidades

- **Mentoria**: a relação com um mentor, com período e situação.
- **Pergunta**: item do questionário inicial, com a resposta.
- **Objetivo**: o que se quer alcançar, com progresso.
- **Encontro**: uma sessão com o mentor e o que se registrou nela.
- **Ação**: compromisso combinado, com prazo e conclusão.
- **Competência**: habilidade que se quer desenvolver.
- **Nota de autoavaliação**: o valor dado a uma competência numa data.

## Premissas

- Uso pessoal, sem multiusuário: o mentor não acessa o Acervo nesta fase; o que precisar chegar a ele sai por "copiar".
- O mentor é só um nome na mentoria (sem cadastro de pessoas, como nas Iniciativas).
- Pode haver mais de uma mentoria (mentores diferentes ou ciclos sucessivos); a lista mostra as ativas primeiro.
- Escala 1 a 5 na autoavaliação e na nota do encontro, comum nas plataformas e rápida de responder no celular.

## Critérios de sucesso

- **SC-001**: Criar a mentoria e chegar à primeira pergunta do questionário leva menos de 1 minuto.
- **SC-002**: Registrar uma ação durante o encontro leva no máximo três toques depois de abrir o encontro.
- **SC-003**: Todos os indicadores do painel conferem com os dados cadastrados (cobertos por testes, indicador por
  indicador).
- **SC-004**: A busca nos encontros responde em menos de 1 s com 1.000 encontros.
