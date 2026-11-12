# Pesquisa: Módulo Mentoria (fase 1)

## 1. O que as plataformas de mentoria oferecem

Fontes consultadas em 2026-11-11: páginas de produto e blogs de MentorcliQ, Qooper, Together, MentorPRO, PushFar e
Mentorloop; comparativos de People Managing People, GetApp e Capterra; questionários de entrada publicados (DoD Mentoring
Resource Portal, UNM STEM, Parlour, Qooper, Makeform).

- **Questionário de entrada**: todas coletam objetivos, habilidades e áreas a desenvolver antes de começar (Together chama
  de "registration questionnaires"). Os modelos públicos também perguntam contexto de carreira, expectativas sobre o
  mentor, disponibilidade, como a pessoa aprende e recebe feedback, e limites da relação.
- **Objetivos com marcos e progresso**: recurso mais citado; avaliadores do GetApp marcam acompanhamento de progresso como
  importante em 84% das avaliações. Algumas deixam o mentor validar o progresso informado pelo mentorado.
- **Encontros**: agenda, pauta e anotações por sessão; MentorPRO e outras pedem uma nota curta depois de cada encontro.
- **Itens de ação** ("action item tracking"): compromissos com prazo saídos dos encontros.
- **Avaliação de habilidades** ("skills assessment") e, em algumas, registro de humor.
- **Painéis e relatórios**: progresso dos objetivos, frequência de encontros, notas das sessões. Voltados para o
  administrador do programa (taxa de engajamento, pares em risco).

**Decisão**: ficar com o que serve a um mentorado só (questionário, objetivos, encontros, ações, autoavaliação e um
painel). Pareamento, relatórios de programa e saúde dos pares ficam de fora (ver tabela da spec).

## 2. Perguntas sugeridas do questionário

Escritas a partir dos modelos acima, na ordem em que entram (FR-002):

1. Qual é o seu objetivo principal com esta mentoria? O que precisa ser verdade ao final dela?
2. Onde você está hoje na carreira e onde quer estar daqui a 1 e a 3 anos?
3. Quais pontos fortes você quer aproveitar mais?
4. Quais habilidades ou comportamentos você quer desenvolver?
5. Quais desafios ou obstáculos estão travando seu crescimento agora?
6. O que você já tentou para resolver esses desafios, e o que aconteceu?
7. Como você aprende melhor? (exemplos práticos, leitura, conversas, desafios…)
8. Como você prefere receber feedback?
9. O que você espera do seu mentor, e o que ele pode esperar de você?
10. Com que frequência e por quanto tempo vocês vão se encontrar? Por quantos meses?
11. Como você vai saber que a mentoria deu certo? Quais sinais ou números vai observar?
12. Há assuntos fora do escopo ou combinados de confidencialidade a definir?

As perguntas são copiadas para a mentoria na criação; depois disso são dados da pessoa (editar a lista sugerida no
código não muda mentorias existentes).

## 3. Competências sugeridas

Só sugestões no campo (`datalist`), nada é criado sozinho: Comunicação, Liderança de pessoas, Visão estratégica,
Influência, Tomada de decisão, Gestão do tempo, Feedback, Delegação, Conhecimento técnico, Inteligência emocional.

## 4. Escala e cálculos

- Escala 1 a 5 na autoavaliação e na nota do encontro (padrão das plataformas, um toque por item).
- **Evolução de uma competência**: última nota − primeira nota (por data). Só existe com duas notas ou mais.
- **Evolução média**: média das evoluções das competências que têm duas notas ou mais, com uma casa decimal.
- **Progresso médio dos objetivos**: média de `progress` dos objetivos não abandonados, arredondada.
- **Encontro realizado**: `held_on` até hoje; com data futura é "agendado".

## 5. Nomes no código

- `Mentoring::Meeting` (encontro) em vez de `Session`, que já é a sessão de login.
- `Mentoring::ActionItem` em vez de `Action`: `action` é parâmetro reservado nos controllers do Rails.
