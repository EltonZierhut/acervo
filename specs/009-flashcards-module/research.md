# Pesquisa: Módulo Flashcards (fase 1)

## Algoritmo: SM-2 no padrão do Anki

**Decisão**: SM-2 na variante do Anki (antes do FSRS), num objeto Ruby sem acesso ao banco
(`Flashcards::Scheduler`).

**Motivo**: regras simples, previsíveis e fáceis de testar uma a uma. O histórico de revisões guardado desde
já permite trocar por FSRS na fase 3 sem perder dados.

**Alternativa rejeitada**: FSRS já na fase 1. Precisa de parâmetros treinados no histórico, que ainda não existe.

### Regras (respostas: 1 Errei, 2 Difícil, 3 Bom, 4 Fácil)

Constantes: passos de aprendizado `[1, 10]` min; passos de reaprendizado `[10]` min; graduação em 1 dia;
"Fácil" gradua em 4 dias; facilidade inicial 2500 (‰, = 2,5), mínima 1300; bônus do Fácil 1,3; multiplicador
do Difícil 1,2; intervalo máximo 36.500 dias.

**Novo ou em aprendizado** (o novo entra no passo 0):

| Resposta | Efeito |
| --- | --- |
| Errei | volta ao passo 0 |
| Difícil | repete o passo atual; no passo 0 com dois passos, usa a média dos dois (5,5 min) |
| Bom | próximo passo; depois do último, vira revisão com 1 dia |
| Fácil | vira revisão com 4 dias |

**Em revisão**:

| Resposta | Intervalo novo | Facilidade |
| --- | --- | --- |
| Errei | vai para reaprendizado (passo 0); intervalo guardado = 1 dia | −200 e lapso + 1 |
| Difícil | máx(intervalo + 1, intervalo × 1,2) | −150 |
| Bom | máx(intervalo + 1, intervalo × facilidade) | igual |
| Fácil | máx(intervalo + 1, intervalo × facilidade × 1,3) | +150 |

Revisões feitas com atraso não ganham bônus nesta fase (simplificação em relação ao Anki).

**Em reaprendizado**: Errei volta ao passo 0; Difícil repete; Bom avança e, depois do último passo, volta à
revisão com o intervalo guardado; Fácil volta à revisão com o intervalo guardado + 1.

**Variação ("fuzz")**: em intervalos de revisão acima de 2 dias, ±5% (pelo menos ±1 dia), para os cartões
criados juntos não vencerem todos no mesmo dia. O sorteio é injetável para os testes.

**Vencimento**: passos em minutos vencem em `agora + passo`; intervalos em dias vencem no início do dia de
estudo correspondente (4h, fuso America/Sao_Paulo).

## Dia de estudo começa às 4h

**Decisão**: o dia vira às 4h, como no Anki. Quem estuda à 1h da manhã continua no "dia anterior" e não
recebe as revisões do dia seguinte antes de dormir.

## Configuração no próprio baralho

**Decisão**: `new_per_day` e `reviews_per_day` ficam no baralho, sem tabela de "presets" como no Anki.
Os passos e fatores ficam fixos no `Scheduler` (princípio II); se um dia precisar mudar por baralho, viram
colunas.

## Sem `deck_id` no cartão

**Decisão**: o cartão pertence à nota e a nota ao baralho. Mover a nota de baralho move os cartões.

## Fila de estudo: um cartão por vez

**Decisão**: `GET /study` e a resposta de `POST /review` devolvem o próximo cartão e as contagens. Evita
lógica de fila duplicada no frontend e mantém a ordem sempre correta (um cartão em aprendizado que vence
reaparece na hora certa).

## Estudo sem internet

**Decisão**: fora do escopo. O princípio VII proíbe guardar respostas da API no service worker; sem
conexão, o app mostra o aviso de offline que já existe.
