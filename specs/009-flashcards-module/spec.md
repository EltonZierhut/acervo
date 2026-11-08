# Especificação da feature: Módulo Flashcards (fase 1)

**Branch da feature**: `009-flashcards-module`

**Criada em**: 2026-11-07

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Conhece o aplicativo AnkiDroid? Monta essa mesma ideia para um módulo no Acervo."

## Visão geral e fases

O módulo **Flashcards** traz para o Acervo o estudo por repetição espaçada do Anki/AnkiDroid: o dono do
Acervo escreve notas com frente e verso, estuda os cartões que vencem no dia e responde quanto lembrou.
O sistema agenda cada cartão para perto do momento em que ele seria esquecido.

Fases, cada uma com spec própria:

1. **Esta feature**: baralhos, notas (Básico e Básico + invertido), estudo com quatro respostas,
   agendamento SM-2, limites diários e busca nas notas.
2. Estatísticas (revisões por dia, acertos, previsão de vencimentos), navegador de cartões com
   filtros por estado e importação de CSV.
3. Algoritmo FSRS (usando o histórico de revisões guardado desde a fase 1), cartões com lacunas
   (cloze), imagens e importação de `.apkg`.

Fora de todas as fases por ora: estudo sem internet (o service worker não guarda dados da API,
princípio VII), sincronização com o AnkiWeb e subbaralhos.

## Cenários de uso e testes *(obrigatório)*

### História 1 - Criar baralhos e notas (Prioridade: P1)

O dono do Acervo cria um baralho por assunto e escreve notas com frente e verso em Markdown.

**Por que esta prioridade**: sem cartões não há o que estudar.

**Teste independente**: criar um baralho, adicionar uma nota Básico e uma Básico + invertido e ver
que o baralho tem três cartões novos.

**Cenários de aceitação**:

1. **Dado** que estou no módulo Flashcards, **quando** crio um baralho informando só o nome, **então**
   ele aparece na lista com os limites padrão (20 novos e 200 revisões por dia).
2. **Dado** que estou num baralho, **quando** salvo uma nota Básico, **então** ela gera um cartão
   (frente → verso); uma nota Básico + invertido gera dois (frente → verso e verso → frente).
3. **Dado** que acabei de salvar uma nota, **quando** a tela volta, **então** o formulário fica
   pronto para a próxima nota no mesmo baralho, para cadastrar várias em sequência.
4. **Dado** que mudo uma nota de Básico + invertido para Básico, **quando** salvo, **então** o cartão
   invertido é removido e o cartão da frente mantém seu agendamento e histórico.
5. **Dado** que apago um baralho, **quando** confirmo, **então** ele some com suas notas, cartões e
   histórico.

---

### História 2 - Estudar os cartões do dia (Prioridade: P1)

O dono do Acervo abre um baralho, vê a frente, revela o verso e responde Errei, Difícil, Bom ou Fácil.

**Por que esta prioridade**: é o propósito do módulo.

**Teste independente**: com um cartão novo, responder Bom duas vezes (1 min e 10 min de intervalo
entre elas) e ver o cartão agendado para o dia seguinte.

**Cenários de aceitação**:

1. **Dado** que o baralho tem cartões a estudar, **quando** abro o estudo, **então** vejo a frente de
   um cartão e as contagens de novos, em aprendizado e para revisar.
2. **Dado** que revelei o verso, **quando** olho os quatro botões, **então** cada um mostra o
   intervalo que dará ao cartão (ex.: "10 min", "1 dia", "4 dias").
3. **Dado** que respondo, **quando** a resposta é salva, **então** aparece o próximo cartão sem
   recarregar a página.
4. **Dado** que só restam cartões em aprendizado que vencem daqui a alguns minutos, **quando** termino
   os demais, **então** vejo quando o próximo fica disponível.
5. **Dado** que não há mais nada para hoje, **quando** termino, **então** vejo "Parabéns, terminou por
   hoje" e quantos cartões venceram amanhã.
6. **Dado** que estou no computador, **quando** estudo, **então** posso usar espaço para revelar e as
   teclas 1 a 4 para responder; no celular, tudo funciona por toque.

---

### História 3 - Encontrar e manter notas (Prioridade: P2)

O dono do Acervo busca uma nota por um trecho da frente, do verso ou de uma tag para corrigi-la,
suspendê-la ou apagá-la.

**Teste independente**: criar duas notas, buscar um trecho do verso de uma delas e vê-la sozinha.

**Cenários de aceitação**:

1. **Dado** que digito um trecho, **quando** existe nota com ele na frente, no verso ou nas tags,
   **então** ela aparece na lista sem confirmar a busca, paginada.
2. **Dado** que suspendo uma nota, **quando** estudo, **então** seus cartões não aparecem até eu
   reativá-la.
3. **Dado** que quero recomeçar uma nota, **quando** escolho "Recomeçar", **então** seus cartões voltam
   a ser novos.

## Requisitos

### Funcionais

- **FR-001**: Baralho tem nome (obrigatório, até 100 caracteres, único sem diferenciar maiúsculas),
  descrição opcional, limite de novos por dia (0 a 9999, padrão 20) e de revisões por dia (0 a 9999,
  padrão 200).
- **FR-002**: Nota pertence a um baralho e tem tipo (`basic` ou `basic_reversed`), frente e verso
  obrigatórios em Markdown (até 100 KB cada) e tags (mesmas regras dos outros módulos).
- **FR-003**: Cada nota gera um cartão por direção; mudar o tipo cria ou remove só o cartão invertido.
- **FR-004**: Cartão tem estado (novo, aprendizado, revisão, reaprendizado), vencimento, intervalo em
  dias, facilidade (ease), passo atual, número de revisões e de esquecimentos (lapsos).
- **FR-005**: Agendamento SM-2 no padrão do Anki (ver `research.md`): passos de aprendizado de 1 e
  10 min, reaprendizado de 10 min, graduação em 1 dia, "Fácil" gradua em 4 dias, facilidade inicial
  2,5 e mínima 1,3, intervalo máximo de 36.500 dias.
- **FR-006**: Toda resposta é guardada no histórico (nota dada, estado e intervalo antes e depois,
  facilidade depois, tempo de resposta) e nunca é alterada.
- **FR-007**: A fila do baralho mostra primeiro os cartões em aprendizado já vencidos, depois as
  revisões vencidas até o fim do dia, depois os novos, respeitando os limites diários.
- **FR-008**: O "dia" do estudo vira às 4h no fuso America/Sao_Paulo, como no Anki.
- **FR-009**: A lista de baralhos mostra, para cada um, as contagens de hoje (novos, aprendizado e
  revisão) e o total de cartões.
- **FR-010**: Notas são pesquisáveis por frente, verso e tags (palavras inteiras e trechos), com
  paginação.
- **FR-011**: Suspender uma nota tira seus cartões da fila; "Recomeçar" volta os cartões a novos sem
  apagar o histórico.
- **FR-012**: Telas funcionam a partir de 360 px, por toque e no app instalado (princípio VII).

### Entidades

- **Baralho**: agrupa notas e define os limites diários.
- **Nota**: o conteúdo escrito (frente, verso, tags, tipo).
- **Cartão**: o que é estudado; guarda o agendamento.
- **Revisão**: uma resposta dada a um cartão.

## Critérios de sucesso

- **SC-001**: Estudar um cartão (revelar + responder) leva dois toques e menos de 300 ms entre a
  resposta e o próximo cartão, em rede normal.
- **SC-002**: As regras do agendamento são cobertas por testes, cenário por cenário.
- **SC-003**: Lista de baralhos e fila de estudo respondem em menos de 1 s com 10.000 cartões.
