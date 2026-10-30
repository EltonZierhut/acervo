# Contrato: API de sessão e regras de autenticação

Base: `/api/v1`. Corpo em JSON. A credencial trafega somente no cookie `session_token`
(assinado, `HttpOnly`, `SameSite=Lax`, `Secure` em produção, validade de 30 dias renovável).
Nenhum token aparece no corpo das respostas.

## Regras gerais (todas as rotas)

| Situação | Resposta |
|---|---|
| Rota de dados sem cookie válido, ou com sessão expirada ou apagada | `401` `{ "error": "Não autenticado" }` |
| `POST`/`PUT`/`PATCH`/`DELETE` sem `Content-Type: application/json` | `415` `{ "error": "Use JSON (Content-Type: application/json)" }` |
| `GET /up` (health check) | `200`, sem login |

Rotas públicas: `GET /up`, `POST /api/v1/session`. Todas as outras exigem login, incluindo
`GET /api/v1/modules` e todo o módulo Códigos, que não muda de contrato.

## `POST /api/v1/session`: entrar

Requisição:
```json
{ "email_address": "voce@exemplo.com", "password": "senha-com-12+" }
```

| Resultado | Status | Corpo | Cookie |
|---|---|---|---|
| Credenciais válidas | `201` | `{ "user": { "id": 1, "email_address": "voce@exemplo.com" } }` | define `session_token` |
| E-mail inexistente ou senha errada | `401` | `{ "error": "E-mail ou senha inválidos" }` | — |
| Campos ausentes | `400` | `{ "error": "..." }` | — |
| Mais de 10 tentativas em 3 min (mesmo IP) | `429` | `{ "error": "Muitas tentativas. Aguarde alguns minutos e tente novamente." }` | — |

O e-mail é normalizado (`strip` + `downcase`) antes da busca.

## `GET /api/v1/session`: sessão atual

| Resultado | Status | Corpo |
|---|---|---|
| Logado | `200` | `{ "user": { "id": 1, "email_address": "voce@exemplo.com" } }` |
| Não logado | `401` | `{ "error": "Não autenticado" }` |

Usado pelo frontend ao carregar para saber se mostra o app ou o login.

## `DELETE /api/v1/session`: sair

| Resultado | Status | Efeito |
|---|---|---|
| Logado | `204` | apaga o registro `Session` e o cookie |
| Não logado | `401` | — |

## Comportamento do frontend

| Evento | Ação |
|---|---|
| App carrega e `GET /session` retorna `401` | redireciona para `/login?next=<rota atual>` |
| Qualquer chamada retorna `401` durante o uso | redireciona para `/login?next=<rota atual>&expired=1` e mostra "Sua sessão expirou. Entre novamente." |
| Login com sucesso | navega para `next` (apenas caminhos internos, começando com `/`) ou `/` |
| `429` no login | mostra a mensagem retornada |
| Clique em **Sair** | `DELETE /session` e vai para `/login` |
